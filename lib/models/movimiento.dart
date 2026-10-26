import 'modo_registro.dart';

/// Tipo de movimiento (determina la tabla y las categorías).
enum TipoMovimiento {
  ingreso,
  gasto;

  String get etiqueta => this == ingreso ? 'ingreso' : 'gasto';
}

/// Campos comunes de ingresos y gastos (mismas columnas en ambas tablas).
abstract class Movimiento {
  final int? id;
  final int usuarioId;

  /// Monto en centavos (siempre > 0).
  final int monto;
  final String categoria;
  final String descripcion;

  /// Solo fecha. Para modo mensual es siempre el día 1 del mes.
  final DateTime fecha;
  final ModoRegistro modo;
  final DateTime creadoEn;

  const Movimiento({
    this.id,
    required this.usuarioId,
    required this.monto,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
    required this.modo,
    required this.creadoEn,
  });

  TipoMovimiento get tipo;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuarioId': usuarioId,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fechaAIso(fecha),
        'modo': modo.toDb(),
        'creadoEn': creadoEn.toIso8601String(),
      };
}

/// Convierte una fecha a texto yyyy-MM-dd (descarta la hora).
String fechaAIso(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

/// Lee un texto yyyy-MM-dd como fecha local a medianoche.
DateTime fechaDesdeIso(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}
