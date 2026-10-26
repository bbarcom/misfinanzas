import '../models/gasto.dart';
import '../models/ingreso.dart';
import '../models/movimiento.dart';
import 'app_database.dart';

/// Repositorio genérico para las tablas ingresos y gastos (misma estructura).
/// Todas las consultas filtran por usuarioId y usan parámetros (sin concatenar texto).
class MovimientoRepository<T extends Movimiento> {
  /// Nombre de tabla fijo definido en el código (nunca viene del usuario).
  final String _tabla;
  final T Function(Map<String, Object?>) _desdeMapa;

  MovimientoRepository(this._tabla, this._desdeMapa);

  Future<int> insertar(T m) async {
    final db = await AppDatabase.instance.database;
    return db.insert(_tabla, m.toMap()..remove('id'));
  }

  Future<void> actualizar(T m) async {
    final db = await AppDatabase.instance.database;
    await db.update(_tabla, m.toMap()..remove('id'),
        where: 'id = ? AND usuarioId = ?', whereArgs: [m.id, m.usuarioId]);
  }

  Future<void> eliminar(int usuarioId, int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(_tabla,
        where: 'id = ? AND usuarioId = ?', whereArgs: [id, usuarioId]);
  }

  /// Solo movimientos de modo 'diario' de esa fecha.
  Future<List<T>> listarPorDia(int usuarioId, DateTime fecha) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(_tabla,
        where: "usuarioId = ? AND fecha = ? AND modo = 'diario'",
        whereArgs: [usuarioId, fechaAIso(fecha)],
        orderBy: 'id DESC');
    return filas.map(_desdeMapa).toList();
  }

  /// Movimientos del mes en ambos modos.
  Future<List<T>> listarPorMes(int usuarioId, int anio, int mes) async {
    final db = await AppDatabase.instance.database;
    final r = _rangoMes(anio, mes);
    final filas = await db.query(_tabla,
        where: 'usuarioId = ? AND fecha >= ? AND fecha < ?',
        whereArgs: [usuarioId, r.$1, r.$2],
        orderBy: 'fecha DESC, id DESC');
    return filas.map(_desdeMapa).toList();
  }

  /// Total del mes (centavos): suma modos 'diario' y 'mensual'.
  Future<int> totalPorMes(int usuarioId, int anio, int mes) async {
    final db = await AppDatabase.instance.database;
    final r = _rangoMes(anio, mes);
    final res = await db.rawQuery(
        'SELECT COALESCE(SUM(monto), 0) AS total FROM $_tabla '
        'WHERE usuarioId = ? AND fecha >= ? AND fecha < ?',
        [usuarioId, r.$1, r.$2]);
    return (res.first['total'] as num).toInt();
  }

  /// Total del día (centavos): solo modo 'diario'.
  Future<int> totalPorDia(int usuarioId, DateTime fecha) async {
    final db = await AppDatabase.instance.database;
    final res = await db.rawQuery(
        "SELECT COALESCE(SUM(monto), 0) AS total FROM $_tabla "
        "WHERE usuarioId = ? AND fecha = ? AND modo = 'diario'",
        [usuarioId, fechaAIso(fecha)]);
    return (res.first['total'] as num).toInt();
  }

  /// Total por categoría del mes (ambos modos), de mayor a menor.
  Future<Map<String, int>> totalesPorCategoriaMes(
      int usuarioId, int anio, int mes) async {
    final db = await AppDatabase.instance.database;
    final r = _rangoMes(anio, mes);
    final res = await db.rawQuery(
        'SELECT categoria, SUM(monto) AS total FROM $_tabla '
        'WHERE usuarioId = ? AND fecha >= ? AND fecha < ? '
        'GROUP BY categoria ORDER BY total DESC',
        [usuarioId, r.$1, r.$2]);
    return {
      for (final f in res) f['categoria'] as String: (f['total'] as num).toInt()
    };
  }

  /// Rango [primer día del mes, primer día del mes siguiente) como texto ISO.
  (String, String) _rangoMes(int anio, int mes) =>
      (fechaAIso(DateTime(anio, mes, 1)), fechaAIso(DateTime(anio, mes + 1, 1)));
}

class IngresoRepository extends MovimientoRepository<Ingreso> {
  IngresoRepository() : super('ingresos', Ingreso.fromMap);
}

class GastoRepository extends MovimientoRepository<Gasto> {
  GastoRepository() : super('gastos', Gasto.fromMap);
}
