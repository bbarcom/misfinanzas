import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/usuario_repository.dart';
import '../models/usuario.dart';
import '../utils/password_utils.dart';

/// Maneja registro, inicio y cierre de sesión. La sesión persiste con shared_preferences.
class AuthProvider extends ChangeNotifier {
  static const _claveSesion = 'usuarioId';

  final UsuarioRepository _repo;
  Usuario? usuarioActual;

  /// False hasta que se termine de restaurar la sesión al abrir la app.
  bool cargando = true;

  AuthProvider([UsuarioRepository? repo]) : _repo = repo ?? UsuarioRepository();

  /// Restaura la sesión guardada (si existe).
  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_claveSesion);
    if (id != null) usuarioActual = await _repo.buscarPorId(id);
    cargando = false;
    notifyListeners();
  }

  /// Devuelve null si todo salió bien, o el mensaje de error.
  Future<String?> registrar(String nombre, String correo, String password) async {
    final correoNorm = correo.trim().toLowerCase();
    if (await _repo.buscarPorCorreo(correoNorm) != null) {
      return 'Ese correo ya está registrado.';
    }
    final salt = generarSal();
    final nuevo = Usuario(
      nombre: nombre.trim(),
      correo: correoNorm,
      passwordHash: calcularHash(password, salt),
      salt: salt,
      creadoEn: DateTime.now(),
    );
    try {
      final id = await _repo.crear(nuevo);
      await _guardarSesion(nuevo.copyWith(id: id));
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return 'Ese correo ya está registrado.';
      return 'No se pudo crear la cuenta. Intenta de nuevo.';
    }
  }

  Future<String?> iniciarSesion(String correo, String password) async {
    final u = await _repo.buscarPorCorreo(correo);
    if (u == null || !verificarPassword(password, u.salt, u.passwordHash)) {
      return 'Correo o contraseña incorrectos.';
    }
    await _guardarSesion(u);
    return null;
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveSesion);
    usuarioActual = null;
    notifyListeners();
  }

  Future<void> _guardarSesion(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveSesion, u.id!);
    usuarioActual = u;
    notifyListeners();
  }
}
