import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/movimientos_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const MisFinanzasApp());
}

class MisFinanzasApp extends StatelessWidget {
  const MisFinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarSesion()),
        // Los movimientos se recargan cada vez que cambia el usuario con sesión.
        ChangeNotifierProxyProvider<AuthProvider, MovimientosProvider>(
          create: (_) => MovimientosProvider(),
          update: (_, auth, mov) =>
              (mov ?? MovimientosProvider())..actualizarUsuario(auth.usuarioActual?.id),
        ),
      ],
      child: MaterialApp(
        title: 'MisFinanzas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _Raiz(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según la sesión.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.usuarioActual == null ? const LoginScreen() : const HomeScreen();
  }
}
