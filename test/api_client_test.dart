import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:misfinanzas/services/api_client.dart';
import 'package:misfinanzas/services/api_exception.dart';
import 'package:misfinanzas/services/token_storage.dart';

class _Tokens extends TokenStorage {
  final String? token;
  _Tokens(this.token);
  @override
  Future<String?> leer() async => token;
}

Future<ApiException> fallo(MockClient cli, {String? token}) async {
  try {
    await ApiClient(_Tokens(token), cli).get('/x');
  } on ApiException catch (e) {
    return e;
  }
  throw StateError('Debía fallar');
}

void main() {
  test('cada código HTTP produce un tipo y mensaje distintos', () async {
    final casos = {
      400: TipoError.peticionInvalida,
      401: TipoError.noAutenticado,
      404: TipoError.noEncontrado,
      409: TipoError.conflicto,
      422: TipoError.datosInvalidos,
      500: TipoError.servidor,
      503: TipoError.servidor,
    };
    final mensajes = <String>{};
    for (final e in casos.entries) {
      final err = await fallo(MockClient((_) async =>
          http.Response('{"error":"msg ${e.key}","campos":{"correo":"mal"}}', e.key)));
      expect(err.tipo, e.value, reason: 'status ${e.key}');
      mensajes.add(err.paraUsuario);
    }
    expect(mensajes.length, greaterThanOrEqualTo(5));
  });

  test('sin red: SocketException → sinConexion', () async {
    final err = await fallo(MockClient((_) async => throw const SocketException('x')));
    expect(err.tipo, TipoError.sinConexion);
  });

  test('envía el token como Bearer y avisa si la sesión expiró', () async {
    String? auth;
    var expirada = false;
    final api = ApiClient(_Tokens('abc'), MockClient((r) async {
      auth = r.headers['authorization'];
      return http.Response('{"error":"No autenticado"}', 401);
    }))
      ..onSesionExpirada = () => expirada = true;
    await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
    expect(auth, 'Bearer abc');
    expect(expirada, isTrue);
  });
}
