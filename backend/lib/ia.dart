import 'dart:convert';

import 'package:http/http.dart' as http;

String _dolares(int c) => '\$${(c / 100).toStringAsFixed(2)}';

/// Resumen determinista sin modelo (también sirve de respaldo si falla la IA).
String resumenLocal(Map<String, dynamic> d) {
  final ing = d['totalIngresos'] as int;
  final gas = d['totalGastos'] as int;
  final balance = ing - gas;
  final cats = (d['gastosPorCategoria'] as Map<String, int>);
  final b = StringBuffer(
      'Este mes ingresaste ${_dolares(ing)} y gastaste ${_dolares(gas)}; '
      'tu balance es ${_dolares(balance)}. ');
  if (cats.isNotEmpty) {
    final top = cats.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final pct = gas == 0 ? 0 : (top.value * 100 / gas).round();
    b.write('Tu mayor gasto es ${top.key} (${_dolares(top.value)}, $pct% del total). ');
  }
  b.write(balance < 0
      ? 'Estás gastando más de lo que ingresas: revisa tus categorías más altas.'
      : ing > 0 && gas > ing * 0.8
          ? 'Gastas más del 80% de tus ingresos; intenta ahorrar una parte.'
          : 'Vas bien; considera destinar parte del saldo al ahorro.');
  return b.toString();
}

/// Pide el resumen a la API del modelo. La clave vive solo en el servidor.
/// Lanza si la API falla (el llamador usa el resumen local).
Future<String> resumenConModelo(
    Map<String, dynamic> datos, String apiKey, String modelo,
    {http.Client? cliente}) async {
  final c = cliente ?? http.Client();
  final r = await c
      .post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': modelo,
          'max_tokens': 400,
          'system': 'Eres un asistente de finanzas personales. Responde en español, '
              'en máximo 4 frases: resume el mes y da 2 consejos concretos. '
              'Los montos están en dólares. No inventes datos.',
          'messages': [
            {'role': 'user', 'content': jsonEncode(datos)}
          ],
        }),
      )
      .timeout(const Duration(seconds: 20));
  if (r.statusCode != 200) throw Exception('IA respondió ${r.statusCode}');
  final j = jsonDecode(r.body) as Map<String, dynamic>;
  return ((j['content'] as List).first as Map)['text'] as String;
}
