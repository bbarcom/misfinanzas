import 'dart:io';

import 'package:misfinanzas_backend/config.dart';
import 'package:misfinanzas_backend/seed.dart';
import 'package:misfinanzas_backend/server.dart';
import 'package:misfinanzas_backend/store.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  final cfg = Config.load();
  final store = Store(cfg.dataFile);
  sembrarSiVacio(store);
  final server = await io.serve(construirApi(store, cfg), InternetAddress.anyIPv4, cfg.port);
  stdout.writeln('MisFinanzas API en http://localhost:${server.port} '
      '(IA: ${cfg.anthropicKey == null ? "respaldo local" : cfg.aiModel})');
}
