final _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validarCorreo(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Ingresa tu correo';
  if (!_regexCorreo.hasMatch(t)) return 'Correo no válido';
  return null;
}

String? validarPassword(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}
