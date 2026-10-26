import '../models/usuario.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Acceso a /auth y /me. Guarda el token en almacenamiento seguro.
class AuthService {
  final ApiClient _api;
  final TokenStorage _tokens;

  AuthService(this._api, this._tokens);

  Future<Usuario> registrar(String nombre, String correo, String password) =>
      _autenticar('/auth/registro', {'nombre': nombre.trim(), 'correo': correo.trim(), 'password': password});

  Future<Usuario> iniciarSesion(String correo, String password) =>
      _autenticar('/auth/login', {'correo': correo.trim(), 'password': password});

  Future<Usuario> _autenticar(String ruta, Map<String, dynamic> cuerpo) async {
    final r = await _api.post(ruta, cuerpo) as Map<String, dynamic>;
    await _tokens.guardar(r['token'] as String);
    return Usuario.fromJson(r['usuario'] as Map<String, dynamic>);
  }

  /// Usuario de la sesión guardada, o null si no hay token. Lanza si el token ya no sirve.
  Future<Usuario?> sesionActual() async {
    if (await _tokens.leer() == null) return null;
    return Usuario.fromJson(await _api.get('/me') as Map<String, dynamic>);
  }

  Future<void> cerrarSesion() => _tokens.borrar();
}
