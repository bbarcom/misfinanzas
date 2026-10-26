/// Usuario autenticado (lo devuelve la API; la contraseña nunca llega a la app).
class Usuario {
  final int id;
  final String nombre;
  final String correo;

  const Usuario({required this.id, required this.nombre, required this.correo});

  factory Usuario.fromJson(Map<String, dynamic> j) =>
      Usuario(id: j['id'] as int, nombre: j['nombre'] as String, correo: j['correo'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'correo': correo};
}
