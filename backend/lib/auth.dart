import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Hash de contraseña: SHA-256 iterado (10000 veces) con sal aleatoria.
String generarSal() {
  final r = Random.secure();
  return base64Url.encode(List.generate(16, (_) => r.nextInt(256)));
}

String hashPassword(String password, String sal) {
  List<int> h = utf8.encode('$sal$password');
  for (var i = 0; i < 10000; i++) {
    h = sha256.convert([...h, ...utf8.encode(sal)]).bytes;
  }
  return base64Url.encode(h);
}

bool verificarPassword(String password, String sal, String hash) {
  final calculado = hashPassword(password, sal);
  if (calculado.length != hash.length) return false;
  var diff = 0; // comparación en tiempo constante
  for (var i = 0; i < calculado.length; i++) {
    diff |= calculado.codeUnitAt(i) ^ hash.codeUnitAt(i);
  }
  return diff == 0;
}

String firmarToken(int usuarioId, String secreto) => JWT({'sub': usuarioId})
    .sign(SecretKey(secreto), expiresIn: const Duration(days: 7));

/// Devuelve el id de usuario del token o null si es inválido/expirado.
int? verificarToken(String token, String secreto) {
  try {
    final jwt = JWT.verify(token, SecretKey(secreto));
    return (jwt.payload as Map)['sub'] as int?;
  } catch (_) {
    return null;
  }
}
