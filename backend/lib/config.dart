import 'dart:io';

/// Configuración leída de variables de entorno y, si existe, del archivo .env
/// (nunca versionado; ver .env.example).
class Config {
  final int port;
  final String jwtSecret;
  final String? anthropicKey;
  final String aiModel;
  final String dataFile;

  Config({
    required this.port,
    required this.jwtSecret,
    this.anthropicKey,
    required this.aiModel,
    required this.dataFile,
  });

  factory Config.load() {
    final env = <String, String>{...Platform.environment};
    final f = File('.env');
    if (f.existsSync()) {
      for (final linea in f.readAsLinesSync()) {
        final l = linea.trim();
        if (l.isEmpty || l.startsWith('#') || !l.contains('=')) continue;
        final i = l.indexOf('=');
        env.putIfAbsent(l.substring(0, i).trim(), () => l.substring(i + 1).trim());
      }
    }
    final secret = env['JWT_SECRET'];
    if (secret == null || secret.length < 16) {
      stderr.writeln('Falta JWT_SECRET (mínimo 16 caracteres). Copia .env.example a .env.');
      exit(78);
    }
    final key = env['ANTHROPIC_API_KEY'];
    return Config(
      port: int.tryParse(env['PORT'] ?? '') ?? 8080,
      jwtSecret: secret,
      anthropicKey: (key == null || key.isEmpty) ? null : key,
      aiModel: env['AI_MODEL'] ?? 'claude-haiku-5-5',
      dataFile: env['DATA_FILE'] ?? 'data/db.json',
    );
  }
}
