import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movimientos_controller.dart';
import '../utils/formatters.dart';
import '../widgets/estado_vista.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/resumen_cards.dart';
import '../widgets/selector_periodo.dart';
import 'movimiento_form_screen.dart';

class DiaTab extends StatelessWidget {
  const DiaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MovimientosController>();
    return EstadoVista(
      contenido: () => Obx(() {
        final dia = c.diaSeleccionado.value;
        final items = c.movimientosDia..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            SelectorPeriodo(
              texto: formatearDiaLargo(dia),
              onAnterior: () => c.seleccionarDia(DateTime(dia.year, dia.month, dia.day - 1)),
              onSiguiente: () => c.seleccionarDia(DateTime(dia.year, dia.month, dia.day + 1)),
              onElegir: () async {
                final f = await showDatePicker(
                  context: context,
                  initialDate: dia,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('es'),
                );
                if (f != null) c.seleccionarDia(f);
              },
            ),
            ResumenCards(ingresos: c.totalIngresosDia, gastos: c.totalGastosDia),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 56, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 8),
                    const Text('No hay movimientos este día.\nToca Agregar para crear uno.',
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              for (final m in items)
                MovimientoTile(
                  movimiento: m,
                  onTap: () => Get.to(() => MovimientoFormScreen(tipo: m.tipo, existente: m)),
                  onEliminar: () => c.eliminar(m),
                ),
          ],
        );
      }),
    );
  }
}
