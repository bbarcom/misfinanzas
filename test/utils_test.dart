import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:misfinanzas/models/gasto.dart';
import 'package:misfinanzas/models/modo_registro.dart';
import 'package:misfinanzas/models/usuario.dart';
import 'package:misfinanzas/utils/formatters.dart';
import 'package:misfinanzas/utils/password_utils.dart';

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

  test('hash y verificación de contraseña', () {
    final salt = generarSal();
    final hash = calcularHash('secreto1', salt);
    expect(hash, isNot(contains('secreto1')));
    expect(verificarPassword('secreto1', salt, hash), isTrue);
    expect(verificarPassword('otra-clave', salt, hash), isFalse);
    expect(generarSal(), isNot(salt));
  });

  test('modelos: toMap/fromMap ida y vuelta', () {
    final g = Gasto(
      id: 3,
      usuarioId: 1,
      monto: 1999,
      categoria: 'Salud',
      descripcion: 'Farmacia',
      fecha: DateTime(2026, 10, 25),
      modo: ModoRegistro.diario,
      creadoEn: DateTime(2026, 10, 25, 8, 30),
    );
    expect(g.toMap()['fecha'], '2026-10-25');
    final r = Gasto.fromMap(g.toMap());
    expect(r.fecha, g.fecha);
    expect(r.monto, 1999);
    expect(r.modo, ModoRegistro.diario);
    expect(r.creadoEn, g.creadoEn);

    final u = Usuario(
        nombre: 'Ana', correo: 'a@b.co', passwordHash: 'h', salt: 's', creadoEn: DateTime(2026));
    expect(Usuario.fromMap(u.toMap()).correo, 'a@b.co');
  });
}
