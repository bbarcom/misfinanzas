import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movimientos_controller.dart';
import '../models/modo_registro.dart';
import '../models/movimiento.dart';
import '../utils/formatters.dart';
import '../widgets/estado_vista.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/resumen_cards.dart';
import '../widgets/selector_periodo.dart';
import 'movimiento_form_screen.dart';

class MesTab extends StatelessWidget {
  const MesTab({super.key});

  Future<void> _elegirMes(BuildContext context, MovimientosController c) async {
    // Se reutiliza el calendario: solo importan el mes y el año elegidos.
    final f = await showDatePicker(
      context: context,
      initialDate: c.mesSeleccionado.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
      helpText: 'Elige cualquier día del mes',
    );
    if (f != null) c.seleccionarMes(f);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MovimientosController>();
    final tema = Theme.of(context);

    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(t, style: tema.textTheme.titleSmall?.copyWith(color: tema.colorScheme.primary)),
        );

    return EstadoVista(
      contenido: () => Obx(() {
        final mes = c.mesSeleccionado.value;
        final todos = c.movimientosMes;
        final mensuales = todos.where((m) => m.modo == ModoRegistro.mensual).toList();
        final diarios = todos.where((m) => m.modo == ModoRegistro.diario).toList()
          ..sort((a, b) => b.fecha != a.fecha
              ? b.fecha.compareTo(a.fecha)
              : (b.id ?? 0).compareTo(a.id ?? 0));
        final porDia = <DateTime, List<Movimiento>>{};
        for (final m in diarios) {
          porDia.putIfAbsent(m.fecha, () => []).add(m);
        }
        final cats = c.gastosPorCategoria;
        final totalGastos = c.totalGastosMes;

        Widget tile(Movimiento m) => MovimientoTile(
              movimiento: m,
              onTap: () => Get.to(() => MovimientoFormScreen(tipo: m.tipo, existente: m)),
              onEliminar: () => c.eliminar(m),
            );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            SelectorPeriodo(
              texto: formatearMes(mes),
              onAnterior: () => c.seleccionarMes(DateTime(mes.year, mes.month - 1, 1)),
              onSiguiente: () => c.seleccionarMes(DateTime(mes.year, mes.month + 1, 1)),
              onElegir: () => _elegirMes(context, c),
            ),
            ResumenCards(ingresos: c.totalIngresosMes, gastos: totalGastos),
            const _TarjetaIa(),
            if (cats.isNotEmpty) ...[
              titulo('Gastos por categoría'),
              for (final e in cats.entries)
                _FilaCategoria(
                  categoria: e.key,
                  monto: e.value,
                  fraccion: totalGastos == 0 ? 0 : e.value / totalGastos,
                ),
            ],
            if (todos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('No hay movimientos este mes.', textAlign: TextAlign.center),
              ),
            if (mensuales.isNotEmpty) ...[
              titulo('Registros mensuales'),
              for (final m in mensuales) tile(m),
            ],
            for (final e in porDia.entries) ...[
              titulo(formatearDiaLargo(e.key)),
              for (final m in e.value) tile(m),
            ],
          ],
        );
      }),
    );
  }
}

/// Asistente de IA: pide al servidor un resumen y consejos del mes seleccionado.
class _TarjetaIa extends StatelessWidget {
  const _TarjetaIa();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MovimientosController>();
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: tema.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Asistente financiero', style: tema.textTheme.titleSmall)),
                    FilledButton.tonal(
                      onPressed: c.iaCargando.value ? null : c.pedirResumenIa,
                      child: const Text('Analizar mes'),
                    ),
                  ],
                ),
                if (c.iaCargando.value)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (c.iaError.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(c.iaError.value!, style: TextStyle(color: tema.colorScheme.error)),
                  ),
                if (c.iaTexto.value != null) ...[
                  const SizedBox(height: 8),
                  Text(c.iaTexto.value!),
                  const SizedBox(height: 4),
                  Text(
                    c.iaFuente.value == 'ia' ? 'Generado con IA' : 'Resumen automático (sin IA)',
                    style: tema.textTheme.labelSmall,
                  ),
                ],
              ],
            )),
      ),
    );
  }
}

class _FilaCategoria extends StatelessWidget {
  final String categoria;
  final int monto;
  final double fraccion;

  const _FilaCategoria({required this.categoria, required this.monto, required this.fraccion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(categoria, overflow: TextOverflow.ellipsis)),
              Text('${formatearMoneda(monto)}  (${(fraccion * 100).toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: fraccion, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}
