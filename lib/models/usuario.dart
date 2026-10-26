/// Usuario de la app. La contraseña nunca se guarda: solo hash + sal.
class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String passwordHash;
  final String salt;
  final DateTime creadoEn;

  const Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.passwordHash,
    required this.salt,
    required this.creadoEn,
  });

  Usuario copyWith({
    int? id,
    String? nombre,
    String? correo,
    String? passwordHash,
    String? salt,
    DateTime? creadoEn,
  }) =>
      Usuario(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        correo: correo ?? this.correo,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
        creadoEn: creadoEn ?? this.creadoEn,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'correo': correo,
        'passwordHash': passwordHash,
        'salt': salt,
        'creadoEn': creadoEn.toIso8601String(),
      };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        correo: map['correo'] as String,
        passwordHash: map['passwordHash'] as String,
        salt: map['salt'] as String,
        creadoEn: DateTime.parse(map['creadoEn'] as String),
      );
}
