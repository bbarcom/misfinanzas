import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import 'dia_tab.dart';
import 'mes_tab.dart';
import 'movimiento_form_screen.dart';
import 'perfil_tab.dart';

/// Pantalla principal con pestañas Día / Mes / Perfil.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  Future<void> _nuevo() async {
    final tipo = await showModalBottomSheet<TipoMovimiento>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text('Nuevo ingreso'),
              onTap: () => Navigator.pop(ctx, TipoMovimiento.ingreso),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.red),
              title: const Text('Nuevo gasto'),
              onTap: () => Navigator.pop(ctx, TipoMovimiento.gasto),
            ),
          ],
        ),
      ),
    );
    if (tipo == null || !mounted) return;
    final p = context.read<MovimientosProvider>();
    // En la pestaña Mes se sugiere el mes visible; en Día, el día visible.
    final fecha = _indice == 1 ? p.mesSeleccionado : p.diaSeleccionado;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovimientoFormScreen(tipo: tipo, fechaInicial: fecha)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titulos = ['Día', 'Mes', 'Perfil'];
    return Scaffold(
      appBar: AppBar(title: Text('MisFinanzas · ${titulos[_indice]}')),
      body: IndexedStack(
        index: _indice,
        children: const [DiaTab(), MesTab(), PerfilTab()],
      ),
      floatingActionButton: _indice == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Día'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Mes'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
