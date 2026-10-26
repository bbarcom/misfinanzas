import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controllers/auth_controller.dart';
import 'controllers/movimientos_controller.dart';
import 'controllers/nav_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/cache_local.dart';
import 'services/ia_service.dart';
import 'services/movimiento_service.dart';
import 'services/token_storage.dart';

/// Inyección de dependencias: servicios → controladores (GetX).
void registrarDependencias() {
  final tokens = TokenStorage();
  final api = ApiClient(tokens);
  final cache = CacheLocal();
  final movimientos = Get.put(MovimientosController(MovimientoService(api), IaService(api), cache));
  final auth = Get.put(AuthController(AuthService(api, tokens), cache));
  Get.put(NavController());
  api.onSesionExpirada = auth.sesionExpirada;
  // Cuando hay usuario con sesión se cargan sus movimientos.
  ever(auth.usuario, (u) {
    if (u != null) movimientos.iniciarPara(u.id);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  registrarDependencias();
  runApp(const MisFinanzasApp());
}

class MisFinanzasApp extends StatelessWidget {
  const MisFinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
    );
  }
}

/// Decide qué pantalla mostrar según la sesión.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.cargando.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return auth.usuario.value == null ? const LoginScreen() : const HomeScreen();
    });
  }
}
