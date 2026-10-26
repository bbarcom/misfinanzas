import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'ia.dart';
import 'store.dart';

final _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _regexFecha = RegExp(r'^\d{4}-\d{2}-\d{2}$');

Response _json(int status, Object cuerpo) => Response(status,
    body: jsonEncode(cuerpo), headers: {'content-type': 'application/json; charset=utf-8'});

/// Errores con código HTTP propio: 400 petición mal formada, 401 sin autenticar,
/// 404 no existe, 409 conflicto, 422 datos inválidos.
class ApiError implements Exception {
  final int status;
  final String mensaje;
  final Map<String, String>? campos;
  ApiError(this.status, this.mensaje, [this.campos]);
}

Map<String, dynamic> _usuarioPublico(Map<String, dynamic> u) =>
    {'id': u['id'], 'nombre': u['nombre'], 'correo': u['correo']};

Future<Map<String, dynamic>> _cuerpo(Request req) async {
  try {
    final j = jsonDecode(await req.readAsString());
    if (j is Map<String, dynamic>) return j;
  } catch (_) {}
  throw ApiError(400, 'El cuerpo de la petición no es un JSON válido.');
}

/// Valida un movimiento; devuelve el mapa limpio o lanza 422 con errores por campo.
Map<String, dynamic> _validarMovimiento(Map<String, dynamic> j) {
  final e = <String, String>{};
  final tipo = j['tipo'];
  if (tipo != 'ingreso' && tipo != 'gasto') e['tipo'] = "Debe ser 'ingreso' o 'gasto'.";
  final monto = j['monto'];
  if (monto is! int || monto <= 0) e['monto'] = 'Debe ser un entero mayor a 0 (centavos).';
  final cat = j['categoria'];
  if (cat is! String || cat.trim().isEmpty) e['categoria'] = 'Es obligatoria.';
  final modo = j['modo'];
  if (modo != 'diario' && modo != 'mensual') e['modo'] = "Debe ser 'diario' o 'mensual'.";
  final fecha = j['fecha'];
  if (fecha is! String || !_regexFecha.hasMatch(fecha) || DateTime.tryParse(fecha) == null) {
    e['fecha'] = 'Formato yyyy-MM-dd.';
  } else if (modo == 'mensual' && !fecha.endsWith('-01')) {
    e['fecha'] = 'En modo mensual debe ser el día 1.';
  }
  if (e.isNotEmpty) throw ApiError(422, 'Datos inválidos.', e);
  return {
    'tipo': tipo,
    'monto': monto,
    'categoria': (cat as String).trim(),
    'descripcion': ((j['descripcion'] as String?) ?? '').trim(),
    'fecha': fecha,
    'modo': modo,
  };
}

/// Construye la API. Cliente HTTP inyectable para probar la IA sin red.
Handler construirApi(Store store, Config cfg, {http.Client? clienteIa}) {
  final r = Router();

  Map<String, dynamic> sesion(Request req) => {'uid': req.context['uid']};

  // ---------- Autenticación ----------
  r.post('/auth/registro', (Request req) async {
    final j = await _cuerpo(req);
    final nombre = (j['nombre'] as String?)?.trim() ?? '';
    final correo = (j['correo'] as String?)?.trim().toLowerCase() ?? '';
    final pass = j['password'] as String? ?? '';
    final e = <String, String>{};
    if (nombre.isEmpty) e['nombre'] = 'Es obligatorio.';
    if (!_regexCorreo.hasMatch(correo)) e['correo'] = 'Correo no válido.';
    if (pass.length < 6) e['password'] = 'Mínimo 6 caracteres.';
    if (e.isNotEmpty) throw ApiError(422, 'Datos inválidos.', e);
    if (store.usuarios.any((u) => u['correo'] == correo)) {
      throw ApiError(409, 'Ese correo ya está registrado.');
    }
    final sal = generarSal();
    final u = {
      'id': store.nuevoIdUsuario(),
      'nombre': nombre,
      'correo': correo,
      'salt': sal,
      'passwordHash': hashPassword(pass, sal),
      'creadoEn': DateTime.now().toIso8601String(),
    };
    store.usuarios.add(u);
    store.guardar();
    return _json(201, {'token': firmarToken(u['id'] as int, cfg.jwtSecret), 'usuario': _usuarioPublico(u)});
  });

  r.post('/auth/login', (Request req) async {
    final j = await _cuerpo(req);
    final correo = (j['correo'] as String?)?.trim().toLowerCase() ?? '';
    final pass = j['password'] as String? ?? '';
    final u = store.usuarios.where((u) => u['correo'] == correo).firstOrNull;
    if (u == null || !verificarPassword(pass, u['salt'] as String, u['passwordHash'] as String)) {
      throw ApiError(401, 'Correo o contraseña incorrectos.');
    }
    return _json(200, {'token': firmarToken(u['id'] as int, cfg.jwtSecret), 'usuario': _usuarioPublico(u)});
  });

  r.get('/me', (Request req) {
    final u = store.usuarios.firstWhere((u) => u['id'] == sesion(req)['uid']);
    return _json(200, _usuarioPublico(u));
  });

  // ---------- Movimientos (CRUD, solo del usuario autenticado) ----------
  r.get('/movimientos', (Request req) {
    final uid = sesion(req)['uid'];
    final tipo = req.url.queryParameters['tipo'];
    final mes = req.url.queryParameters['mes']; // yyyy-MM
    var lista = store.movimientos.where((m) => m['usuarioId'] == uid);
    if (tipo != null) lista = lista.where((m) => m['tipo'] == tipo);
    if (mes != null) lista = lista.where((m) => (m['fecha'] as String).startsWith('$mes-'));
    final out = lista.toList()
      ..sort((a, b) {
        final c = (b['fecha'] as String).compareTo(a['fecha'] as String);
        return c != 0 ? c : (b['id'] as int).compareTo(a['id'] as int);
      });
    return _json(200, out);
  });

  r.post('/movimientos', (Request req) async {
    final datos = _validarMovimiento(await _cuerpo(req));
    final m = {
      'id': store.nuevoIdMovimiento(),
      'usuarioId': sesion(req)['uid'],
      ...datos,
      'creadoEn': DateTime.now().toIso8601String(),
    };
    store.movimientos.add(m);
    store.guardar();
    return _json(201, m);
  });

  Map<String, dynamic> propio(Request req, String id) {
    final m = store.movimientos
        .where((m) => m['id'].toString() == id && m['usuarioId'] == sesion(req)['uid'])
        .firstOrNull;
    if (m == null) throw ApiError(404, 'Movimiento no encontrado.');
    return m;
  }

  r.put('/movimientos/<id>', (Request req, String id) async {
    final m = propio(req, id);
    final datos = _validarMovimiento(await _cuerpo(req));
    m.addAll(datos);
    store.guardar();
    return _json(200, m);
  });

  r.delete('/movimientos/<id>', (Request req, String id) {
    final m = propio(req, id);
    store.movimientos.remove(m);
    store.guardar();
    return Response(204);
  });

  // ---------- Asistente de IA ----------
  r.post('/ia/resumen', (Request req) async {
    final j = await _cuerpo(req);
    final mes = j['mes']; // yyyy-MM
    if (mes is! String || !RegExp(r'^\d{4}-\d{2}$').hasMatch(mes)) {
      throw ApiError(422, 'Datos inválidos.', {'mes': 'Formato yyyy-MM.'});
    }
    final uid = sesion(req)['uid'];
    final movs = store.movimientos
        .where((m) => m['usuarioId'] == uid && (m['fecha'] as String).startsWith('$mes-'));
    var ing = 0, gas = 0;
    final cats = <String, int>{};
    for (final m in movs) {
      if (m['tipo'] == 'ingreso') {
        ing += m['monto'] as int;
      } else {
        gas += m['monto'] as int;
        cats[m['categoria'] as String] = (cats[m['categoria'] as String] ?? 0) + (m['monto'] as int);
      }
    }
    final datos = {
      'mes': mes,
      'totalIngresos': ing,
      'totalGastos': gas,
      'gastosPorCategoria': cats,
    };
    if (movs.isEmpty) {
      return _json(200, {'resumen': 'No hay movimientos en ese mes para analizar.', 'fuente': 'local'});
    }
    final key = cfg.anthropicKey;
    if (key != null) {
      try {
        final t = await resumenConModelo(datos, key, cfg.aiModel, cliente: clienteIa);
        return _json(200, {'resumen': t, 'fuente': 'ia'});
      } catch (_) {
        // Respaldo: el usuario siempre recibe una respuesta útil.
      }
    }
    return _json(200, {'resumen': resumenLocal(datos), 'fuente': 'local'});
  });

  r.get('/salud', (Request _) => _json(200, {'ok': true}));

  final rutasPublicas = {'/auth/registro', '/auth/login', '/salud'};

  Middleware autenticacion = (inner) => (req) {
        if (rutasPublicas.contains('/${req.url.path}')) return inner(req);
        final h = req.headers['authorization'] ?? '';
        final uid = h.startsWith('Bearer ') ? verificarToken(h.substring(7), cfg.jwtSecret) : null;
        if (uid == null || !store.usuarios.any((u) => u['id'] == uid)) {
          return _json(401, {'error': 'No autenticado o sesión expirada.'});
        }
        return inner(req.change(context: {'uid': uid}));
      };

  Middleware errores = (inner) => (req) async {
        try {
          return await inner(req);
        } on ApiError catch (e) {
          return _json(e.status, {'error': e.mensaje, if (e.campos != null) 'campos': e.campos});
        } catch (_) {
          return _json(500, {'error': 'Error interno del servidor.'});
        }
      };

  return const Pipeline()
      .addMiddleware(errores)
      .addMiddleware(autenticacion)
      .addHandler(r.call);
}
