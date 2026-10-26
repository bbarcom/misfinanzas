import 'package:get/get.dart';

import '../models/modo_registro.dart';
import '../models/movimiento.dart';
import '../services/api_exception.dart';
import '../services/cache_local.dart';
import '../services/ia_service.dart';
import '../services/movimiento_service.dart';

enum Estado { cargando, listo, error }

/// Estado compartido de movimientos: lista remota, día/mes seleccionados y totales.
class MovimientosController extends GetxController {
  final MovimientoService _servicio;
  final IaService _ia;
  final CacheLocal _cache;

  MovimientosController(this._servicio, this._ia, this._cache);

  int? _usuarioId;

  final todos = <Movimiento>[].obs;
  final estado = Estado.cargando.obs;
  final mensajeError = ''.obs;

  /// True si se muestran datos guardados localmente porque falló la red.
  final sinConexion = false.obs;

  final diaSeleccionado = _hoy().obs;
  final mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;

  // Asistente de IA
  final iaCargando = false.obs;
  final iaTexto = RxnString();
  final iaFuente = RxnString();
  final iaError = RxnString();

  static DateTime _hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ---------- Vistas derivadas ----------
  List<Movimiento> _de(TipoMovimiento t, bool Function(Movimiento) f) =>
      todos.where((m) => m.tipo == t && f(m)).toList();

  bool _esDia(Movimiento m) => m.modo == ModoRegistro.diario && m.fecha == diaSeleccionado.value;
  bool _esMes(Movimiento m) =>
      m.fecha.year == mesSeleccionado.value.year && m.fecha.month == mesSeleccionado.value.month;

  List<Movimiento> get movimientosDia => todos.where(_esDia).toList();
  List<Movimiento> get movimientosMes => todos.where(_esMes).toList();

  int _suma(Iterable<Movimiento> l) => l.fold(0, (s, m) => s + m.monto);

  int get totalIngresosDia => _suma(_de(TipoMovimiento.ingreso, _esDia));
  int get totalGastosDia => _suma(_de(TipoMovimiento.gasto, _esDia));

  /// El total mensual suma movimientos 'diario' y 'mensual' del mes.
  int get totalIngresosMes => _suma(_de(TipoMovimiento.ingreso, _esMes));
  int get totalGastosMes => _suma(_de(TipoMovimiento.gasto, _esMes));

  /// Gastos del mes por categoría, de mayor a menor.
  Map<String, int> get gastosPorCategoria {
    final m = <String, int>{};
    for (final g in _de(TipoMovimiento.gasto, _esMes)) {
      m[g.categoria] = (m[g.categoria] ?? 0) + g.monto;
    }
    final orden = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in orden) e.key: e.value};
  }

  // ---------- Carga ----------
  /// Se llama cuando hay un usuario con sesión (o cambia).
  Future<void> iniciarPara(int usuarioId) async {
    if (_usuarioId == usuarioId) return;
    _usuarioId = usuarioId;
    await cargar();
  }

  void limpiar() {
    _usuarioId = null;
    todos.clear();
    iaTexto.value = null;
    iaError.value = null;
    estado.value = Estado.cargando;
  }

  Future<void> cargar() async {
    final uid = _usuarioId;
    if (uid == null) return;
    estado.value = Estado.cargando;
    sinConexion.value = false;
    try {
      final lista = await _servicio.listar();
      if (uid != _usuarioId) return;
      todos.assignAll(lista);
      estado.value = Estado.listo;
      await _cache.guardarMovimientos(uid, lista);
    } on ApiException catch (e) {
      if (uid != _usuarioId) return;
      final guardados = e.tipo == TipoError.sinConexion ? await _cache.leerMovimientos(uid) : null;
      if (guardados != null) {
        todos.assignAll(guardados);
        sinConexion.value = true;
        estado.value = Estado.listo;
      } else {
        mensajeError.value = e.paraUsuario;
        estado.value = Estado.error;
      }
    }
  }

  void seleccionarDia(DateTime d) => diaSeleccionado.value = DateTime(d.year, d.month, d.day);
  void seleccionarMes(DateTime d) {
    mesSeleccionado.value = DateTime(d.year, d.month, 1);
    iaTexto.value = null;
    iaError.value = null;
  }

  // ---------- Escritura (lanzan ApiException para que el formulario la muestre) ----------
  Future<void> guardar(Movimiento m) async {
    if (m.id == null) {
      await _servicio.crear(m);
    } else {
      await _servicio.actualizar(m);
    }
    await cargar();
  }

  Future<String?> eliminar(Movimiento m) async {
    try {
      await _servicio.eliminar(m.id!);
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.paraUsuario;
    }
  }

  // ---------- Asistente de IA ----------
  Future<void> pedirResumenIa() async {
    iaCargando.value = true;
    iaError.value = null;
    try {
      final r = await _ia.resumenDelMes(mesSeleccionado.value);
      iaTexto.value = r.texto;
      iaFuente.value = r.fuente;
    } on ApiException catch (e) {
      iaError.value = e.paraUsuario;
    } finally {
      iaCargando.value = false;
    }
  }
}
