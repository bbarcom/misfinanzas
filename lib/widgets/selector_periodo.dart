import 'package:flutter/material.dart';

/// Barra con flechas anterior/siguiente y un texto central tocable (abre calendario/selector).
class SelectorPeriodo extends StatelessWidget {
  final String texto;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onElegir;

  const SelectorPeriodo({
    super.key,
    required this.texto,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            tooltip: 'Anterior', onPressed: onAnterior, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: TextButton.icon(
            onPressed: onElegir,
            icon: const Icon(Icons.calendar_month),
            label: Flexible(
              child: Text(texto,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ),
        IconButton(
            tooltip: 'Siguiente', onPressed: onSiguiente, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
