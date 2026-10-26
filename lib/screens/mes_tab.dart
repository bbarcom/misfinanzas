import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modo_registro.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/formatters.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/resumen_cards.dart';
import '../widgets/selector_periodo.dart';
import 'movimiento_form_screen.dart';

class MesTab extends StatelessWidget {
  const MesTab({super.key});

  Future<void> _elegirMes(BuildContext context, MovimientosProvider p) async {
    // Se reutiliza el calendario: solo importan el mes y el año elegidos.
    final f = await showDatePicker(
      context: context,
      initialDate: p.mesSeleccionado,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
      helpText: 'Elige cualquier día del mes',
    );
    if (f != null) p.seleccionarMes(f);
  }

  void _editar(BuildContext context, Movimiento m) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovimientoFormScreen(tipo: m.tipo, existente: m)),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MovimientosProvider>();
    final mes = p.mesSeleccionado;
    final tema = Theme.of(context);

    final todos = <Movimiento>[...p.ingresosMes, ...p.gastosMes];
    final mensuales = todos.where((m) => m.modo == ModoRegistro.mensual).toList();
    final diarios = todos.where((m) => m.modo == ModoRegistro.diario).toList()
      ..sort((a, b) => b.fecha != a.fecha
          ? b.fecha.compareTo(a.fecha)
          : (b.id ?? 0).compareTo(a.id ?? 0));
    final porDia = <DateTime, List<Movimiento>>{};
    for (final m in diarios) {
      porDia.putIfAbsent(m.fecha, () => []).add(m);
    }

    Widget tile(Movimiento m) => MovimientoTile(
          movimiento: m,
          onTap: () => _editar(context, m),
          onEliminar: () => p.eliminar(m),
        );

    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(t, style: tema.textTheme.titleSmall?.copyWith(color: tema.colorScheme.primary)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        SelectorPeriodo(
          texto: formatearMes(mes),
          onAnterior: () => p.seleccionarMes(DateTime(mes.year, mes.month - 1, 1)),
          onSiguiente: () => p.seleccionarMes(DateTime(mes.year, mes.month + 1, 1)),
          onElegir: () => _elegirMes(context, p),
        ),
        ResumenCards(ingresos: p.totalIngresosMes, gastos: p.totalGastosMes),
        if (p.gastosPorCategoria.isNotEmpty) ...[
          titulo('Gastos por categoría'),
          for (final e in p.gastosPorCategoria.entries)
            _FilaCategoria(
              categoria: e.key,
              monto: e.value,
              fraccion: p.totalGastosMes == 0 ? 0 : e.value / p.totalGastosMes,
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
