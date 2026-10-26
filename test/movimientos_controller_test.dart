import 'package:flutter_test/flutter_test.dart';
import 'package:misfinanzas/controllers/movimientos_controller.dart';
import 'package:misfinanzas/models/modo_registro.dart';
import 'package:misfinanzas/models/movimiento.dart';
import 'package:misfinanzas/services/api_client.dart';
import 'package:misfinanzas/services/api_exception.dart';
import 'package:misfinanzas/services/cache_local.dart';
import 'package:misfinanzas/services/ia_service.dart';
import 'package:misfinanzas/services/movimiento_service.dart';
import 'package:misfinanzas/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Tokens extends TokenStorage {
  @override
  Future<String?> leer() async => null;
}

class _ServicioFalso extends MovimientoService {
  List<Movimiento> datos = [];
  ApiException? fallo;

  _ServicioFalso() : super(ApiClient(_Tokens()));

  @override
  Future<List<Movimiento>> listar() async {
    if (fallo != null) throw fallo!;
    return datos;
  }
}

Movimiento mov(int id, TipoMovimiento t, int monto, DateTime f, ModoRegistro m, [String cat = 'Otros']) =>
    Movimiento(id: id, tipo: t, monto: monto, categoria: cat, fecha: f, modo: m);

void main() {
  late _ServicioFalso servicio;
  late MovimientosController c;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    servicio = _ServicioFalso();
    c = MovimientosController(servicio, IaService(ApiClient(_Tokens())), CacheLocal());
    c.seleccionarMes(DateTime(2026, 10, 1));
    c.seleccionarDia(DateTime(2026, 10, 31));
  });

  test('balance mensual suma movimientos diarios y mensuales; el día solo los diarios', () async {
    servicio.datos = [
      mov(1, TipoMovimiento.ingreso, 100000, DateTime(2026, 10, 1), ModoRegistro.mensual),
      mov(2, TipoMovimiento.ingreso, 5000, DateTime(2026, 10, 31), ModoRegistro.diario),
      mov(3, TipoMovimiento.gasto, 30000, DateTime(2026, 10, 1), ModoRegistro.mensual, 'Servicios'),
      mov(4, TipoMovimiento.gasto, 2000, DateTime(2026, 10, 31), ModoRegistro.diario, 'Transporte'),
      mov(5, TipoMovimiento.ingreso, 7000, DateTime(2026, 11, 1), ModoRegistro.diario), // otro mes
    ];
    await c.iniciarPara(1);
    expect(c.estado.value, Estado.listo);
    expect(c.totalIngresosMes, 105000);
    expect(c.totalGastosMes, 32000);
    expect(c.totalIngresosMes - c.totalGastosMes, 73000);
    expect(c.totalIngresosDia, 5000);
    expect(c.totalGastosDia, 2000);
    expect(c.gastosPorCategoria.keys.first, 'Servicios');
  });

  test('error del servidor deja estado de error con mensaje', () async {
    servicio.fallo = const ApiException(TipoError.servidor, 'boom', status: 500);
    await c.iniciarPara(1);
    expect(c.estado.value, Estado.error);
    expect(c.mensajeError.value, contains('500'));
  });

  test('sin conexión usa los datos guardados localmente (persistencia local)', () async {
    servicio.datos = [mov(1, TipoMovimiento.gasto, 500, DateTime(2026, 10, 31), ModoRegistro.diario)];
    await c.iniciarPara(7);
    // "Reinicio": nuevo controlador, sin red
    final c2 = MovimientosController(servicio, IaService(ApiClient(_Tokens())), CacheLocal());
    c2.seleccionarMes(DateTime(2026, 10, 1));
    servicio.fallo = const ApiException(TipoError.sinConexion, 'x');
    await c2.iniciarPara(7);
    expect(c2.estado.value, Estado.listo);
    expect(c2.sinConexion.value, isTrue);
    expect(c2.totalGastosMes, 500);
  });

  test('sin conexión y sin datos guardados muestra error', () async {
    servicio.fallo = const ApiException(TipoError.sinConexion, 'x');
    await c.iniciarPara(99);
    expect(c.estado.value, Estado.error);
  });
}
