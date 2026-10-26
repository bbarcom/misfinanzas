import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../utils/formatters.dart';

/// Fila de un movimiento: toque para editar, deslizar para eliminar (con confirmación).
class MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final VoidCallback onTap;
  final Future<void> Function() onEliminar;

  const MovimientoTile({
    super.key,
    required this.movimiento,
    required this.onTap,
    required this.onEliminar,
  });

  Future<bool> _confirmar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
            '¿Eliminar este ${movimiento.tipo.etiqueta} de ${formatearMoneda(movimiento.monto)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    final color = esIngreso ? Colors.green.shade700 : Colors.red.shade700;
    return Dismissible(
      key: ValueKey('${movimiento.tipo.name}-${movimiento.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (!await _confirmar(context)) return false;
        await onEliminar();
        return false; // la lista se reconstruye al recargar
      },
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(esIngreso ? Icons.arrow_downward : Icons.arrow_upward, color: color),
        ),
        title: Text(movimiento.categoria),
        subtitle: movimiento.descripcion.isEmpty ? null : Text(movimiento.descripcion),
        trailing: Text(
          '${esIngreso ? '+' : '-'}${formatearMoneda(movimiento.monto)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
