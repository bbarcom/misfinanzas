import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modo_registro.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/categorias.dart';
import '../utils/formatters.dart';

/// Formulario para crear o editar un ingreso/gasto, por día o por mes.
class MovimientoFormScreen extends StatefulWidget {
  final TipoMovimiento tipo;
  final Movimiento? existente;

  /// Fecha inicial sugerida al crear.
  final DateTime? fechaInicial;

  const MovimientoFormScreen({
    super.key,
    required this.tipo,
    this.existente,
    this.fechaInicial,
  });

  @override
  State<MovimientoFormScreen> createState() => _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends State<MovimientoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  late ModoRegistro _modo;
  late DateTime _fecha;
  String? _categoria;
  bool _guardando = false;

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _monto = TextEditingController(text: e == null ? '' : (e.monto / 100).toStringAsFixed(2));
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    _modo = e?.modo ?? ModoRegistro.diario;
    _fecha = e?.fecha ?? widget.fechaInicial ?? DateTime.now();
    _categoria = e?.categoria;
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    final navigator = Navigator.of(context);
    await context.read<MovimientosProvider>().guardar(
          tipo: widget.tipo,
          existente: widget.existente,
          monto: montoACentavos(_monto.text)!,
          categoria: _categoria!,
          descripcion: _descripcion.text,
          fecha: _fecha,
          modo: _modo,
        );
    navigator.pop();
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Seguro que deseas eliminarlo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<MovimientosProvider>().eliminar(widget.existente!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = widget.tipo == TipoMovimiento.ingreso;
    final categorias = categoriasPara(widget.tipo);
    final anioActual = DateTime.now().year;
    final anios = {for (var a = anioActual - 5; a <= anioActual + 1; a++) a, _fecha.year}.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_editando ? 'Editar' : 'Nuevo'} ${widget.tipo.etiqueta}'),
        actions: [
          if (_editando)
            IconButton(
                tooltip: 'Eliminar', icon: const Icon(Icons.delete), onPressed: _eliminar),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ModoRegistro>(
                  segments: const [
                    ButtonSegment(
                        value: ModoRegistro.diario,
                        label: Text('Por día'),
                        icon: Icon(Icons.today)),
                    ButtonSegment(
                        value: ModoRegistro.mensual,
                        label: Text('Por mes'),
                        icon: Icon(Icons.calendar_month)),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (s) => setState(() => _modo = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monto,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _modo == ModoRegistro.mensual ? 'Monto del mes' : 'Monto',
                    prefixText: r'$ ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final c = montoACentavos(v ?? '');
                    if (c == null) return 'Ingresa un monto válido';
                    if (c <= 0) return 'El monto debe ser mayor a 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                      labelText: 'Categoría', border: OutlineInputBorder()),
                  items: [
                    for (final c in categorias) DropdownMenuItem(value: c, child: Text(c))
                  ],
                  onChanged: (v) => setState(() => _categoria = v),
                  validator: (v) => v == null ? 'Elige una categoría' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcion,
                  decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                if (_modo == ModoRegistro.diario)
                  OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.event),
                    label: Text('Fecha: ${formatearFecha(_fecha)}'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          initialValue: _fecha.month,
                          decoration: const InputDecoration(
                              labelText: 'Mes', border: OutlineInputBorder()),
                          items: [
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(formatearMes(DateTime(2000, m)).split(' ').first),
                              ),
                          ],
                          onChanged: (m) =>
                              setState(() => _fecha = DateTime(_fecha.year, m!, 1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: _fecha.year,
                          decoration: const InputDecoration(
                              labelText: 'Año', border: OutlineInputBorder()),
                          items: [
                            for (final a in anios) DropdownMenuItem(value: a, child: Text('$a'))
                          ],
                          onChanged: (a) =>
                              setState(() => _fecha = DateTime(a!, _fecha.month, 1)),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: Icon(esIngreso ? Icons.add_circle : Icons.remove_circle),
                  label: Text(_editando ? 'Guardar cambios' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
