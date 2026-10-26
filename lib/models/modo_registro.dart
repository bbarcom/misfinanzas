/// Modo de registro de un movimiento: con fecha exacta o consolidado por mes.
enum ModoRegistro {
  diario,
  mensual;

  /// Valor guardado en la base de datos.
  String toDb() => name;

  static ModoRegistro fromDb(String valor) => ModoRegistro.values.firstWhere(
        (m) => m.name == valor,
        orElse: () => throw ArgumentError('Modo de registro inválido: $valor'),
      );
}
