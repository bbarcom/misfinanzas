import 'dart:convert';
import 'dart:io';

/// Almacén sencillo en un archivo JSON (suficiente para el curso; ver README).
/// Con [archivo] == null vive solo en memoria (pruebas).
class Store {
  final File? _archivo;
  final List<Map<String, dynamic>> usuarios = [];
  final List<Map<String, dynamic>> movimientos = [];
  int _sigUsuario = 1;
  int _sigMovimiento = 1;

  Store([String? archivo]) : _archivo = archivo == null ? null : File(archivo) {
    final a = _archivo;
    if (a != null && a.existsSync()) {
      final j = jsonDecode(a.readAsStringSync()) as Map<String, dynamic>;
      usuarios.addAll((j['usuarios'] as List).cast<Map<String, dynamic>>());
      movimientos.addAll((j['movimientos'] as List).cast<Map<String, dynamic>>());
      _sigUsuario = j['sigUsuario'] as int;
      _sigMovimiento = j['sigMovimiento'] as int;
    }
  }

  int nuevoIdUsuario() => _sigUsuario++;
  int nuevoIdMovimiento() => _sigMovimiento++;

  /// Escribe a disco (archivo temporal + renombrar, para no corromper).
  void guardar() {
    final a = _archivo;
    if (a == null) return;
    a.parent.createSync(recursive: true);
    final tmp = File('${a.path}.tmp');
    tmp.writeAsStringSync(jsonEncode({
      'usuarios': usuarios,
      'movimientos': movimientos,
      'sigUsuario': _sigUsuario,
      'sigMovimiento': _sigMovimiento,
    }));
    tmp.renameSync(a.path);
  }
}
