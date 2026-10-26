import '../models/usuario.dart';
import 'app_database.dart';

class UsuarioRepository {
  /// Inserta el usuario y devuelve su id.
  /// Lanza DatabaseException si el correo ya existe (restricción UNIQUE).
  Future<int> crear(Usuario usuario) async {
    final db = await AppDatabase.instance.database;
    return db.insert('usuarios', usuario.toMap());
  }

  Future<Usuario?> buscarPorCorreo(String correo) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('usuarios',
        where: 'correo = ?', whereArgs: [correo.trim().toLowerCase()], limit: 1);
    return filas.isEmpty ? null : Usuario.fromMap(filas.first);
  }

  Future<Usuario?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;
    final filas =
        await db.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    return filas.isEmpty ? null : Usuario.fromMap(filas.first);
  }
}
