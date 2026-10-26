import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movimiento.dart';
import '../models/usuario.dart';

/// Persistencia local: última lista de movimientos (para verla sin conexión)
/// y último correo usado. Sobrevive al cierre de la app.
class CacheLocal {
  static String _claveMovs(int uid) => 'movimientos_$uid';
  static const _claveCorreo = 'ultimo_correo';

  Future<void> guardarMovimientos(int usuarioId, List<Movimiento> lista) async {
    final p = await SharedPreferences.getInstance();
    final json = lista.map((m) => {'id': m.id, ...m.toJson()}).toList();
    await p.setString(_claveMovs(usuarioId), jsonEncode(json));
  }

  Future<List<Movimiento>?> leerMovimientos(int usuarioId) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_claveMovs(usuarioId));
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List).map((e) => Movimiento.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> borrarMovimientos(int usuarioId) async =>
      (await SharedPreferences.getInstance()).remove(_claveMovs(usuarioId));

  /// Último usuario con sesión, para reabrir la app sin conexión.
  Future<void> guardarUsuario(Usuario u) async =>
      (await SharedPreferences.getInstance()).setString('usuario', jsonEncode(u.toJson()));

  Future<Usuario?> leerUsuario() async {
    final s = (await SharedPreferences.getInstance()).getString('usuario');
    if (s == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> borrarUsuario() async => (await SharedPreferences.getInstance()).remove('usuario');

  Future<void> guardarCorreo(String correo) async =>
      (await SharedPreferences.getInstance()).setString(_claveCorreo, correo);

  Future<String?> leerCorreo() async => (await SharedPreferences.getInstance()).getString(_claveCorreo);
}
