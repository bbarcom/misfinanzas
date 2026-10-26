/// Tipos de fallo distinguibles para mostrar mensajes distintos en la interfaz.
enum TipoError { sinConexion, peticionInvalida, noAutenticado, noEncontrado, conflicto, datosInvalidos, servidor }

class ApiException implements Exception {
  final TipoError tipo;
  final int? status;
  final String mensaje;

  /// Errores por campo (422), p. ej. {'correo': 'Correo no válido.'}.
  final Map<String, String> campos;

  const ApiException(this.tipo, this.mensaje, {this.status, this.campos = const {}});

  /// Mensaje listo para el usuario, distinto según el tipo de error.
  String get paraUsuario => switch (tipo) {
        TipoError.sinConexion => 'No hay conexión con el servidor. Revisa tu red o que el backend esté encendido.',
        TipoError.peticionInvalida => 'Petición incorrecta (400): $mensaje',
        TipoError.noAutenticado => mensaje,
        TipoError.noEncontrado => mensaje,
        TipoError.conflicto => mensaje,
        TipoError.datosInvalidos =>
          campos.isEmpty ? mensaje : campos.values.join('\n'),
        TipoError.servidor => 'El servidor tuvo un problema ($status). Intenta de nuevo en unos minutos.',
      };

  @override
  String toString() => 'ApiException($status, $mensaje)';
}
