import 'package:get/get.dart';

import '../models/usuario.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/cache_local.dart';
import 'movimientos_controller.dart';

/// Estado de sesión compartido por toda la app.
class AuthController extends GetxController {
  final AuthService _auth;
  final CacheLocal _cache;

  AuthController(this._auth, this._cache);

  final usuario = Rxn<Usuario>();

  /// True mientras se restaura la sesión al abrir la app.
  final cargando = true.obs;

  /// True mientras se envía login/registro.
  final enviando = false.obs;

  /// Error del último intento (o null).
  final error = RxnString();
  final ultimoCorreo = ''.obs;

  @override
  void onInit() {
    super.onInit();
    restaurarSesion();
  }

  Future<void> restaurarSesion() async {
    cargando.value = true;
    ultimoCorreo.value = await _cache.leerCorreo() ?? '';
    try {
      usuario.value = await _auth.sesionActual();
    } on ApiException catch (e) {
      // Sin red conservamos el token (se reintenta luego); si el token es inválido, se limpia.
      if (e.tipo == TipoError.noAutenticado) await _auth.cerrarSesion();
    }
    cargando.value = false;
  }

  Future<bool> iniciarSesion(String correo, String password) =>
      _intentar(() => _auth.iniciarSesion(correo, password), correo);

  Future<bool> registrar(String nombre, String correo, String password) =>
      _intentar(() => _auth.registrar(nombre, correo, password), correo);

  Future<bool> _intentar(Future<Usuario> Function() accion, String correo) async {
    enviando.value = true;
    error.value = null;
    try {
      usuario.value = await accion();
      await _cache.guardarCorreo(correo.trim());
      return true;
    } on ApiException catch (e) {
      error.value = e.paraUsuario;
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.cerrarSesion();
    usuario.value = null;
    if (Get.isRegistered<MovimientosController>()) Get.find<MovimientosController>().limpiar();
  }

  /// El cliente HTTP avisa aquí cuando el servidor rechaza el token.
  void sesionExpirada() {
    if (usuario.value == null) return;
    cerrarSesion();
    Get.snackbar('Sesión expirada', 'Vuelve a iniciar sesión.');
  }
}
