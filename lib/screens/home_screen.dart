import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movimientos_controller.dart';
import '../controllers/nav_controller.dart';
import '../models/movimiento.dart';
import 'dia_tab.dart';
import 'mes_tab.dart';
import 'movimiento_form_screen.dart';
import 'perfil_tab.dart';

/// Pantalla principal con pestañas Día / Mes / Perfil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _nuevo(BuildContext context) async {
    final nav = Get.find<NavController>();
    final c = Get.find<MovimientosController>();
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
    if (tipo == null) return;
    // En la pestaña Mes se sugiere el mes visible; en Día, el día visible.
    final fecha = nav.indice.value == 1 ? c.mesSeleccionado.value : c.diaSeleccionado.value;
    Get.to(() => MovimientoFormScreen(tipo: tipo, fechaInicial: fecha));
  }

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    const titulos = ['Día', 'Mes', 'Perfil'];
    return Obx(() => Scaffold(
          appBar: AppBar(title: Text('MisFinanzas · ${titulos[nav.indice.value]}')),
          body: IndexedStack(
            index: nav.indice.value,
            children: const [DiaTab(), MesTab(), PerfilTab()],
          ),
          floatingActionButton: nav.indice.value == 2
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _nuevo(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: nav.indice.value,
            onDestinationSelected: (i) => nav.indice.value = i,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.today), label: 'Día'),
              NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Mes'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ));
  }
}
