import '../models/movimiento.dart';
import 'api_client.dart';

/// Repositorio remoto de movimientos (CRUD protegido por JWT).
class MovimientoService {
  final ApiClient _api;

  MovimientoService(this._api);

  Future<List<Movimiento>> listar() async {
    final r = await _api.get('/movimientos') as List;
    return r.map((e) => Movimiento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Movimiento> crear(Movimiento m) async =>
      Movimiento.fromJson(await _api.post('/movimientos', m.toJson()) as Map<String, dynamic>);

  Future<Movimiento> actualizar(Movimiento m) async =>
      Movimiento.fromJson(await _api.put('/movimientos/${m.id}', m.toJson()) as Map<String, dynamic>);

  Future<void> eliminar(int id) => _api.delete('/movimientos/$id');
}
