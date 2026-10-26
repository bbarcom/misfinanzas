import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:misfinanzas_backend/config.dart';
import 'package:misfinanzas_backend/seed.dart';
import 'package:misfinanzas_backend/server.dart';
import 'package:misfinanzas_backend/store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Config cfg([String? key]) => Config(
    port: 0, jwtSecret: 'secreto-de-prueba-123456', anthropicKey: key, aiModel: 'x', dataFile: '');

Future<Response> llamar(Handler h, String metodo, String ruta,
    {Object? cuerpo, String? token, String? crudo}) {
  return Future.sync(() => h(Request(metodo, Uri.parse('http://x$ruta'),
      body: crudo ?? (cuerpo == null ? null : jsonEncode(cuerpo)),
      headers: {if (token != null) 'authorization': 'Bearer $token'})));
}

Future<Map<String, dynamic>> j(Response r) async => jsonDecode(await r.readAsString());

void main() {
  late Handler api;
  late Store store;

  setUp(() {
    store = Store();
    sembrarSiVacio(store);
    api = construirApi(store, cfg());
  });

  Future<String> login([String c = 'demo@misfinanzas.app', String p = 'demo1234']) async =>
      (await j(await llamar(api, 'POST', '/auth/login', cuerpo: {'correo': c, 'password': p})))['token'];

  test('seed: usuario demo con al menos 20 movimientos', () {
    expect(store.movimientos.length, greaterThanOrEqualTo(20));
  });

  test('login correcto y errores 401 / 400', () async {
    expect(await login(), isNotEmpty);
    expect((await llamar(api, 'POST', '/auth/login', cuerpo: {'correo': 'demo@misfinanzas.app', 'password': 'mala'})).statusCode, 401);
    expect((await llamar(api, 'POST', '/auth/login', crudo: 'no-json')).statusCode, 400);
  });

  test('registro: 201, duplicado 409, inválido 422', () async {
    final ok = await llamar(api, 'POST', '/auth/registro',
        cuerpo: {'nombre': 'Ana', 'correo': 'ana@x.co', 'password': 'secreta1'});
    expect(ok.statusCode, 201);
    final dup = await llamar(api, 'POST', '/auth/registro',
        cuerpo: {'nombre': 'Ana', 'correo': 'ANA@x.co', 'password': 'secreta1'});
    expect(dup.statusCode, 409);
    final mal = await llamar(api, 'POST', '/auth/registro',
        cuerpo: {'nombre': '', 'correo': 'x', 'password': '1'});
    expect(mal.statusCode, 422);
    expect((await j(mal))['campos'], containsPair('correo', isA<String>()));
    // La contraseña no se guarda en claro
    expect(jsonEncode(store.usuarios), isNot(contains('secreta1')));
  });

  test('rutas protegidas rechazan sin token o con token falso (401)', () async {
    expect((await llamar(api, 'GET', '/movimientos')).statusCode, 401);
    expect((await llamar(api, 'GET', '/movimientos', token: 'falso')).statusCode, 401);
    expect((await llamar(api, 'POST', '/ia/resumen', cuerpo: {'mes': '2026-10'})).statusCode, 401);
  });

  test('CRUD de movimientos y validación 422', () async {
    final t = await login();
    final nuevo = {'tipo': 'gasto', 'monto': 1250, 'categoria': 'Salud', 'descripcion': 'x', 'fecha': '2026-10-05', 'modo': 'diario'};
    final c = await llamar(api, 'POST', '/movimientos', cuerpo: nuevo, token: t);
    expect(c.statusCode, 201);
    final id = (await j(c))['id'];
    final u = await llamar(api, 'PUT', '/movimientos/$id', cuerpo: {...nuevo, 'monto': 999}, token: t);
    expect((await j(u))['monto'], 999);
    expect((await llamar(api, 'POST', '/movimientos', cuerpo: {...nuevo, 'monto': 0}, token: t)).statusCode, 422);
    expect((await llamar(api, 'POST', '/movimientos', cuerpo: {...nuevo, 'modo': 'mensual'}, token: t)).statusCode, 422); // fecha no es día 1
    expect((await llamar(api, 'DELETE', '/movimientos/$id', token: t)).statusCode, 204);
    expect((await llamar(api, 'DELETE', '/movimientos/$id', token: t)).statusCode, 404);
  });

  test('un usuario no ve ni toca los movimientos de otro', () async {
    await llamar(api, 'POST', '/auth/registro', cuerpo: {'nombre': 'B', 'correo': 'b@x.co', 'password': 'secreta1'});
    final tb = await login('b@x.co', 'secreta1');
    final lista = jsonDecode(await (await llamar(api, 'GET', '/movimientos', token: tb)).readAsString()) as List;
    expect(lista, isEmpty);
    final idAjeno = store.movimientos.first['id'];
    expect((await llamar(api, 'DELETE', '/movimientos/$idAjeno', token: tb)).statusCode, 404);
  });

  test('IA: respaldo local sin clave; con clave usa el modelo; si falla, respaldo', () async {
    final t = await login();
    final mes = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final local = await j(await llamar(api, 'POST', '/ia/resumen', cuerpo: {'mes': mes}, token: t));
    expect(local['fuente'], 'local');

    late http.Request visto;
    final ok = MockClient((req) async {
      visto = req;
      return http.Response(jsonEncode({'content': [{'type': 'text', 'text': 'Resumen IA'}]}), 200);
    });
    final conIa = construirApi(store, cfg('clave-falsa'), clienteIa: ok);
    final r = await j(await llamar(conIa, 'POST', '/ia/resumen', cuerpo: {'mes': mes}, token: t));
    expect(r, {'resumen': 'Resumen IA', 'fuente': 'ia'});
    expect(visto.headers['x-api-key'], 'clave-falsa'); // la clave solo viaja servidor → proveedor

    final falla = MockClient((_) async => http.Response('boom', 500));
    final conFalla = construirApi(store, cfg('clave-falsa'), clienteIa: falla);
    expect((await j(await llamar(conFalla, 'POST', '/ia/resumen', cuerpo: {'mes': mes}, token: t)))['fuente'], 'local');
  });
}
