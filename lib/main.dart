import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';
import 'config/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'controllers/login_controller.dart';
import 'controllers/register_controller.dart';
import 'controllers/event_controller.dart';
import 'controllers/profile_controller.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Firebase Messaging para notificaciones push
  // En web Firebase Messaging no está soportado de la misma forma,
  // por eso se captura cualquier error para no bloquear la app.
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase Messaging no disponible en esta plataforma: $e');
  }

  runApp(buildApp());
}

Widget buildApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => LoginController(),
      ),
      ChangeNotifierProvider(
        create: (_) => RegisterController(),
      ),
      ChangeNotifierProvider(
        create: (_) => EventController(),
      ),
      ChangeNotifierProvider(
        create: (_) => ProfileController(),
      ),
    ],
    child: const CuentasClarasApp(),
  );
}

class CuentasClarasApp extends StatelessWidget {
  const CuentasClarasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cuentas Claras',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.splash,
    );
  }
}