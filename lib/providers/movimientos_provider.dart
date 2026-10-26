import 'package:flutter/foundation.dart';

import '../data/movimiento_repository.dart';
import '../models/gasto.dart';
import '../models/ingreso.dart';
import '../models/modo_registro.dart';
import '../models/movimiento.dart';

/// Estado de ingresos y gastos del usuario actual, para el día y mes seleccionados.
class MovimientosProvider extends ChangeNotifier {
  final IngresoRepository _ingresos = IngresoRepository();
  final GastoRepository _gastos = GastoRepository();

  int? _usuarioId;

  DateTime diaSeleccionado = _hoy();
  DateTime mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<Ingreso> ingresosDia = [];
  List<Gasto> gastosDia = [];
  List<Ingreso> ingresosMes = [];
  List<Gasto> gastosMes = [];
  int totalIngresosDia = 0;
  int totalGastosDia = 0;
  int totalIngresosMes = 0;
  int totalGastosMes = 0;
  Map<String, int> gastosPorCategoria = {};

  int get balanceDia => totalIngresosDia - totalGastosDia;
  int get balanceMes => totalIngresosMes - totalGastosMes;

  static DateTime _hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Se llama cuando cambia el usuario (login/logout).
  void actualizarUsuario(int? usuarioId) {
    if (usuarioId == _usuarioId) return;
    _usuarioId = usuarioId;
    diaSeleccionado = _hoy();
    mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _limpiar();
    if (usuarioId != null) recargar();
  }

  void _limpiar() {
    ingresosDia = [];
    gastosDia = [];
    ingresosMes = [];
    gastosMes = [];
    totalIngresosDia = totalGastosDia = totalIngresosMes = totalGastosMes = 0;
    gastosPorCategoria = {};
  }

  Future<void> seleccionarDia(DateTime dia) async {
    diaSeleccionado = DateTime(dia.year, dia.month, dia.day);
    notifyListeners();
    await recargar();
  }

  Future<void> seleccionarMes(DateTime mes) async {
    mesSeleccionado = DateTime(mes.year, mes.month, 1);
    notifyListeners();
    await recargar();
  }

  /// Vuelve a consultar día y mes seleccionados.
  Future<void> recargar() async {
    final uid = _usuarioId;
    if (uid == null) return;
    final dia = diaSeleccionado;
    final mes = mesSeleccionado;
    final r = await Future.wait<Object>([
      _ingresos.listarPorDia(uid, dia),
      _gastos.listarPorDia(uid, dia),
      _ingresos.totalPorDia(uid, dia),
      _gastos.totalPorDia(uid, dia),
      _ingresos.listarPorMes(uid, mes.year, mes.month),
      _gastos.listarPorMes(uid, mes.year, mes.month),
      _ingresos.totalPorMes(uid, mes.year, mes.month),
      _gastos.totalPorMes(uid, mes.year, mes.month),
      _gastos.totalesPorCategoriaMes(uid, mes.year, mes.month),
    ]);
    // Si el usuario o la selección cambió mientras consultaba, se descarta el resultado.
    if (uid != _usuarioId || dia != diaSeleccionado || mes != mesSeleccionado) return;
    ingresosDia = r[0] as List<Ingreso>;
    gastosDia = r[1] as List<Gasto>;
    totalIngresosDia = r[2] as int;
    totalGastosDia = r[3] as int;
    ingresosMes = r[4] as List<Ingreso>;
    gastosMes = r[5] as List<Gasto>;
    totalIngresosMes = r[6] as int;
    totalGastosMes = r[7] as int;
    gastosPorCategoria = r[8] as Map<String, int>;
    notifyListeners();
  }

  /// Crea (existente == null) o edita un movimiento. Si el modo es mensual,
  /// la fecha se normaliza al día 1.
  Future<void> guardar({
    required TipoMovimiento tipo,
    Movimiento? existente,
    required int monto,
    required String categoria,
    required String descripcion,
    required DateTime fecha,
    required ModoRegistro modo,
  }) async {
    final uid = _usuarioId!;
    final f = modo == ModoRegistro.mensual
        ? DateTime(fecha.year, fecha.month, 1)
        : DateTime(fecha.year, fecha.month, fecha.day);
    final creado = existente?.creadoEn ?? DateTime.now();
    if (tipo == TipoMovimiento.ingreso) {
      final m = Ingreso(
        id: existente?.id, usuarioId: uid, monto: monto, categoria: categoria,
        descripcion: descripcion.trim(), fecha: f, modo: modo, creadoEn: creado,
      );
      existente == null ? await _ingresos.insertar(m) : await _ingresos.actualizar(m);
    } else {
      final m = Gasto(
        id: existente?.id, usuarioId: uid, monto: monto, categoria: categoria,
        descripcion: descripcion.trim(), fecha: f, modo: modo, creadoEn: creado,
      );
      existente == null ? await _gastos.insertar(m) : await _gastos.actualizar(m);
    }
    await recargar();
  }

  Future<void> eliminar(Movimiento m) async {
    final uid = _usuarioId!;
    if (m.tipo == TipoMovimiento.ingreso) {
      await _ingresos.eliminar(uid, m.id!);
    } else {
      await _gastos.eliminar(uid, m.id!);
    }
    await recargar();
  }
}
