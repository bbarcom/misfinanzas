import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_storage.dart';

/// Única puerta de salida HTTP de la app. Las pantallas nunca la usan directamente.
/// Dirección por entorno: --dart-define=API_URL=... (por defecto, emulador Android).
class ApiClient {
  static const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final http.Client _http;
  final TokenStorage _tokens;

  /// Se llama cuando el servidor responde 401 con un token guardado (sesión vencida).
  void Function()? onSesionExpirada;

  ApiClient(this._tokens, [http.Client? cliente]) : _http = cliente ?? http.Client();

  Future<dynamic> get(String ruta) => _enviar('GET', ruta);
  Future<dynamic> post(String ruta, [Object? cuerpo]) => _enviar('POST', ruta, cuerpo);
  Future<dynamic> put(String ruta, Object cuerpo) => _enviar('PUT', ruta, cuerpo);
  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Future<dynamic> _enviar(String metodo, String ruta, [Object? cuerpo]) async {
    final token = await _tokens.leer();
    final req = http.Request(metodo, Uri.parse('$baseUrl$ruta'))
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'application/json';
    if (token != null) req.headers['authorization'] = 'Bearer $token';
    if (cuerpo != null) req.body = jsonEncode(cuerpo);

    http.Response r;
    try {
      r = await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 25)));
    } on SocketException {
      throw const ApiException(TipoError.sinConexion, 'Sin conexión');
    } on TimeoutException {
      throw const ApiException(TipoError.sinConexion, 'Tiempo de espera agotado');
    } on http.ClientException {
      throw const ApiException(TipoError.sinConexion, 'Sin conexión');
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    }

    String mensaje = 'Error';
    Map<String, String> campos = {};
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      mensaje = (j['error'] as String?) ?? mensaje;
      campos = ((j['campos'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {}

    final tipo = switch (r.statusCode) {
      400 => TipoError.peticionInvalida,
      401 => TipoError.noAutenticado,
      404 => TipoError.noEncontrado,
      409 => TipoError.conflicto,
      422 => TipoError.datosInvalidos,
      _ => TipoError.servidor,
    };
    if (tipo == TipoError.noAutenticado && token != null) onSesionExpirada?.call();
    throw ApiException(tipo, mensaje, status: r.statusCode, campos: campos);
  }
}
