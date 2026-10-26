import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Tres tarjetas: ingresos, gastos y balance (verde si >= 0, rojo si < 0).
class ResumenCards extends StatelessWidget {
  final int ingresos;
  final int gastos;

  const ResumenCards({super.key, required this.ingresos, required this.gastos});

  @override
  Widget build(BuildContext context) {
    final balance = ingresos - gastos;
    final verde = Colors.green.shade700;
    final rojo = Colors.red.shade700;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _Tarjeta('Ingresos', ingresos, verde, Icons.arrow_downward)),
            const SizedBox(width: 8),
            Expanded(child: _Tarjeta('Gastos', gastos, rojo, Icons.arrow_upward)),
          ],
        ),
        const SizedBox(height: 8),
        _Tarjeta('Balance', balance, balance >= 0 ? verde : rojo, Icons.balance, grande: true),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final int centavos;
  final Color color;
  final IconData icono;
  final bool grande;

  const _Tarjeta(this.titulo, this.centavos, this.color, this.icono, {this.grande = false});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.labelMedium),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatearMoneda(centavos),
                      style: (grande ? tema.headlineSmall : tema.titleMedium)
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
