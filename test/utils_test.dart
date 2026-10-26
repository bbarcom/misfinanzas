import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:misfinanzas/models/modo_registro.dart';
import 'package:misfinanzas/models/movimiento.dart';
import 'package:misfinanzas/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('montoACentavos convierte sin errores de redondeo', () {
    expect(montoACentavos('12.50'), 1250);
    expect(montoACentavos('12,5'), 1250);
    expect(montoACentavos('0.99'), 99);
    expect(montoACentavos('1000'), 100000);
    expect(montoACentavos('19.99'), 1999);
    expect(montoACentavos('abc'), isNull);
    expect(montoACentavos(''), isNull);
  });

  test('formatos en español', () {
    expect(formatearMoneda(125050), r'$1,250.50');
    expect(formatearFecha(DateTime(2026, 10, 5)), '05/10/2026');
    expect(formatearMes(DateTime(2026, 10, 1)), 'octubre 2026');
  });

  test('Movimiento: JSON ida y vuelta con la forma que espera la API', () {
    final m = Movimiento(
      id: 3,
      tipo: TipoMovimiento.gasto,
      monto: 1999,
      categoria: 'Salud',
      descripcion: 'Farmacia',
      fecha: DateTime(2026, 10, 25),
      modo: ModoRegistro.diario,
    );
    expect(m.toJson(), {
      'tipo': 'gasto',
      'monto': 1999,
      'categoria': 'Salud',
      'descripcion': 'Farmacia',
      'fecha': '2026-10-25',
      'modo': 'diario',
    });
    final r = Movimiento.fromJson({'id': 3, ...m.toJson()});
    expect(r.fecha, m.fecha);
    expect(r.tipo, TipoMovimiento.gasto);
    expect(r.modo, ModoRegistro.diario);
  });
}
