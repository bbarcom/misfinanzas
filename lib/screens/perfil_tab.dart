import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.usuarioActual;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
        const SizedBox(height: 16),
        Text(u?.nombre ?? '',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        Text(u?.correo ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
