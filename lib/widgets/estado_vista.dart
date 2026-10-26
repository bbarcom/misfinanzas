import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movimientos_controller.dart';

/// Muestra carga, error (con reintento) o el contenido. Estados visibles y distintos.
class EstadoVista extends StatelessWidget {
  final Widget Function() contenido;

  const EstadoVista({super.key, required this.contenido});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MovimientosController>();
    return Obx(() {
      switch (c.estado.value) {
        case Estado.cargando:
          return const Center(child: CircularProgressIndicator());
        case Estado.error:
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 56, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(c.mensajeError.value, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: c.cargar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        case Estado.listo:
          return Column(
            children: [
              if (c.sinConexion.value)
                MaterialBanner(
                  content: const Text('Sin conexión: mostrando los últimos datos guardados.'),
                  leading: const Icon(Icons.wifi_off),
                  actions: [TextButton(onPressed: c.cargar, child: const Text('Reintentar'))],
                ),
              Expanded(child: RefreshIndicator(onRefresh: c.cargar, child: contenido())),
            ],
          );
      }
    });
  }
}
