import 'api_client.dart';

class ResumenIa {
  final String texto;

  /// 'ia' si lo generó el modelo; 'local' si fue el resumen de respaldo del servidor.
  final String fuente;
  const ResumenIa(this.texto, this.fuente);
}

/// Asistente de IA: la app solo habla con nuestro servidor (nunca con el proveedor).
class IaService {
  final ApiClient _api;

  IaService(this._api);

  Future<ResumenIa> resumenDelMes(DateTime mes) async {
    final m = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
    final r = await _api.post('/ia/resumen', {'mes': m}) as Map<String, dynamic>;
    return ResumenIa(r['resumen'] as String, r['fuente'] as String);
  }
}
