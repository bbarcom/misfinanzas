import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/formatters.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/resumen_cards.dart';
import '../widgets/selector_periodo.dart';
import 'movimiento_form_screen.dart';

class DiaTab extends StatelessWidget {
  const DiaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MovimientosProvider>();
    final dia = p.diaSeleccionado;
    final items = <Movimiento>[...p.ingresosDia, ...p.gastosDia]
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        SelectorPeriodo(
          texto: formatearDiaLargo(dia),
          onAnterior: () => p.seleccionarDia(dia.subtract(const Duration(days: 1))),
          onSiguiente: () => p.seleccionarDia(DateTime(dia.year, dia.month, dia.day + 1)),
          onElegir: () async {
            final f = await showDatePicker(
              context: context,
              initialDate: dia,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              locale: const Locale('es'),
            );
            if (f != null) p.seleccionarDia(f);
          },
        ),
        ResumenCards(ingresos: p.totalIngresosDia, gastos: p.totalGastosDia),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.receipt_long,
                    size: 56, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 8),
                const Text('No hay movimientos este día.\nToca + para agregar uno.',
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else
          for (final m in items)
            MovimientoTile(
              movimiento: m,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MovimientoFormScreen(tipo: m.tipo, existente: m)),
              ),
              onEliminar: () => p.eliminar(m),
            ),
      ],
    );
  }
}
