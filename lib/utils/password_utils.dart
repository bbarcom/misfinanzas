import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Genera una sal aleatoria (16 bytes en base64).
String generarSal() {
  final rnd = Random.secure();
  return base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
}

/// SHA-256 de (sal + contraseña), en hexadecimal.
String calcularHash(String password, String salt) =>
    sha256.convert(utf8.encode(salt + password)).toString();

/// Verifica una contraseña contra el hash guardado.
bool verificarPassword(String password, String salt, String hashGuardado) =>
    calcularHash(password, salt) == hashGuardado;
