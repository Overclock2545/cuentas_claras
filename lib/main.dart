import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';
import 'config/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'controllers/login_controller.dart';
import 'controllers/register_controller.dart';
import 'controllers/event_controller.dart';
import 'controllers/event_detail_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        create: (_) => EventDetailController(),
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