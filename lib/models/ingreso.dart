import 'modo_registro.dart';
import 'movimiento.dart';

class Ingreso extends Movimiento {
  const Ingreso({
    super.id,
    required super.usuarioId,
    required super.monto,
    required super.categoria,
    super.descripcion,
    required super.fecha,
    required super.modo,
    required super.creadoEn,
  });

  @override
  TipoMovimiento get tipo => TipoMovimiento.ingreso;

  Ingreso copyWith({
    int? id,
    int? usuarioId,
    int? monto,
    String? categoria,
    String? descripcion,
    DateTime? fecha,
    ModoRegistro? modo,
    DateTime? creadoEn,
  }) =>
      Ingreso(
        id: id ?? this.id,
        usuarioId: usuarioId ?? this.usuarioId,
        monto: monto ?? this.monto,
        categoria: categoria ?? this.categoria,
        descripcion: descripcion ?? this.descripcion,
        fecha: fecha ?? this.fecha,
        modo: modo ?? this.modo,
        creadoEn: creadoEn ?? this.creadoEn,
      );

  factory Ingreso.fromMap(Map<String, Object?> map) => Ingreso(
        id: map['id'] as int?,
        usuarioId: map['usuarioId'] as int,
        monto: map['monto'] as int,
        categoria: map['categoria'] as String,
        descripcion: (map['descripcion'] as String?) ?? '',
        fecha: fechaDesdeIso(map['fecha'] as String),
        modo: ModoRegistro.fromDb(map['modo'] as String),
        creadoEn: DateTime.parse(map['creadoEn'] as String),
      );
}
