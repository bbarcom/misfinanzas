import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Acceso único (singleton) a la base de datos SQLite local.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), 'misfinanzas.db');
    return openDatabase(
      ruta,
      version: 1,
      // Las claves foráneas (ON DELETE CASCADE) exigen activar el PRAGMA en cada conexión.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            correo TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL,
            salt TEXT NOT NULL,
            creadoEn TEXT NOT NULL
          )''');
        for (final tabla in ['ingresos', 'gastos']) {
          await db.execute('''
            CREATE TABLE $tabla (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuarioId INTEGER NOT NULL,
              monto INTEGER NOT NULL CHECK (monto > 0),
              categoria TEXT NOT NULL,
              descripcion TEXT,
              fecha TEXT NOT NULL,
              modo TEXT NOT NULL CHECK (modo IN ('diario','mensual')),
              creadoEn TEXT NOT NULL,
              FOREIGN KEY (usuarioId) REFERENCES usuarios(id) ON DELETE CASCADE
            )''');
          await db.execute(
              'CREATE INDEX idx_${tabla}_usuario_fecha ON $tabla (usuarioId, fecha)');
        }
      },
    );
  }
}
