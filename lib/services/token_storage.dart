import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el JWT en el almacenamiento seguro del sistema (Keystore en Android).
class TokenStorage {
  static const _clave = 'jwt';
  final FlutterSecureStorage _s;

  TokenStorage([FlutterSecureStorage? s]) : _s = s ?? const FlutterSecureStorage();

  Future<String?> leer() async {
    try {
      return await _s.read(key: _clave);
    } catch (_) {
      return null; // almacenamiento corrupto: se trata como sin sesión
    }
  }

  Future<void> guardar(String token) => _s.write(key: _clave, value: token);

  Future<void> borrar() => _s.delete(key: _clave);
}
