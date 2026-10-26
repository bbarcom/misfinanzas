import 'modo_registro.dart';

/// Tipo de movimiento (determina las categorías disponibles).
enum TipoMovimiento {
  ingreso,
  gasto;

  String get etiqueta => name;
}

/// Ingreso o gasto del usuario. Monto en centavos; para modo mensual, fecha = día 1.
class Movimiento {
  final int? id;
  final TipoMovimiento tipo;
  final int monto;
  final String categoria;
  final String descripcion;
  final DateTime fecha;
  final ModoRegistro modo;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
    required this.modo,
  });

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as int?,
        tipo: TipoMovimiento.values.byName(j['tipo'] as String),
        monto: j['monto'] as int,
        categoria: j['categoria'] as String,
        descripcion: (j['descripcion'] as String?) ?? '',
        fecha: fechaDesdeIso(j['fecha'] as String),
        modo: ModoRegistro.fromDb(j['modo'] as String),
      );

  /// Cuerpo que espera la API (sin id).
  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fechaAIso(fecha),
        'modo': modo.toDb(),
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
