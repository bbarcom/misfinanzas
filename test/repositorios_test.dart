import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:misfinanzas/data/movimiento_repository.dart';
import 'package:misfinanzas/data/usuario_repository.dart';
import 'package:misfinanzas/models/gasto.dart';
import 'package:misfinanzas/models/ingreso.dart';
import 'package:misfinanzas/models/modo_registro.dart';
import 'package:misfinanzas/models/usuario.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Ingreso ing(int u, int monto, DateTime f, ModoRegistro m, [String cat = 'Sueldo']) => Ingreso(
    usuarioId: u, monto: monto, categoria: cat, fecha: f, modo: m, creadoEn: DateTime.now());

Gasto gas(int u, int monto, DateTime f, ModoRegistro m, [String cat = 'Otros']) => Gasto(
    usuarioId: u, monto: monto, categoria: cat, fecha: f, modo: m, creadoEn: DateTime.now());

void main() {
  late int u1, u2;
  final ingresos = IngresoRepository();
  final gastos = GastoRepository();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('misfinanzas_test');
    await databaseFactory.setDatabasesPath(dir.path);

    final repo = UsuarioRepository();
    Usuario u(String c) => Usuario(
        nombre: c, correo: c, passwordHash: 'h', salt: 's', creadoEn: DateTime.now());
    u1 = await repo.crear(u('a@a.co'));
    u2 = await repo.crear(u('b@b.co'));

    // Usuario 1, octubre 2026
    await ingresos.insertar(ing(u1, 100000, DateTime(2026, 10, 1), ModoRegistro.mensual));
    await ingresos.insertar(ing(u1, 5000, DateTime(2026, 10, 31), ModoRegistro.diario));
    await ingresos.insertar(ing(u1, 7000, DateTime(2026, 11, 1), ModoRegistro.diario)); // otro mes
    await gastos.insertar(gas(u1, 30000, DateTime(2026, 10, 1), ModoRegistro.mensual, 'Servicios'));
    await gastos.insertar(gas(u1, 1250, DateTime(2026, 10, 31), ModoRegistro.diario, 'Transporte'));
    await gastos.insertar(gas(u1, 750, DateTime(2026, 10, 31), ModoRegistro.diario, 'Transporte'));
    // Usuario 2 no debe mezclarse
    await ingresos.insertar(ing(u2, 999999, DateTime(2026, 10, 31), ModoRegistro.diario));
  });

  test('total mensual suma diario y mensual, incluyendo el último día del mes', () async {
    expect(await ingresos.totalPorMes(u1, 2026, 10), 105000);
    expect(await gastos.totalPorMes(u1, 2026, 10), 32000);
    expect(await ingresos.totalPorMes(u1, 2026, 11), 7000);
  });

  test('total y lista por día solo incluyen modo diario', () async {
    expect(await ingresos.totalPorDia(u1, DateTime(2026, 10, 1)), 0);
    expect(await ingresos.listarPorDia(u1, DateTime(2026, 10, 1)), isEmpty);
    expect(await gastos.totalPorDia(u1, DateTime(2026, 10, 31)), 2000);
    expect((await gastos.listarPorDia(u1, DateTime(2026, 10, 31))).length, 2);
  });

  test('cada usuario ve solo sus datos', () async {
    expect(await ingresos.totalPorMes(u2, 2026, 10), 999999);
    expect(await gastos.totalPorMes(u2, 2026, 10), 0);
  });

  test('totales por categoría', () async {
    expect(await gastos.totalesPorCategoriaMes(u1, 2026, 10),
        {'Servicios': 30000, 'Transporte': 2000});
  });

  test('actualizar y eliminar respetan usuarioId', () async {
    final id = await ingresos.insertar(ing(u1, 100, DateTime(2026, 12, 5), ModoRegistro.diario));
    await ingresos.eliminar(u2, id); // otro usuario: no borra
    expect((await ingresos.listarPorDia(u1, DateTime(2026, 12, 5))).length, 1);
    await ingresos.eliminar(u1, id);
    expect(await ingresos.listarPorDia(u1, DateTime(2026, 12, 5)), isEmpty);
  });

  test('CHECK rechaza monto 0 y correo duplicado falla', () async {
    expect(() => ingresos.insertar(ing(u1, 0, DateTime(2026, 10, 2), ModoRegistro.diario)),
        throwsA(isA<DatabaseException>()));
    expect(
        () => UsuarioRepository().crear(Usuario(
            nombre: 'x', correo: 'a@a.co', passwordHash: 'h', salt: 's', creadoEn: DateTime.now())),
        throwsA(isA<DatabaseException>()));
  });
}
