import 'package:cuentas_claras/services/service_locator.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/constants/app_assets.dart';
import '../../config/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Espera intencional para mostrar el branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. Cumplimos Regla #2: Usar el servicio estático en lugar de llamar directo a Firebase SDK
    final user = authService.currentUser;

    // 2. Cumplimos Regla de Navegación: Usar rutas nombradas centralizadas
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Respeta tu AppColors.background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.logo,
              width: 120,
            ),
            const SizedBox(height: 25),
            Text(
              "Cuentas Claras",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 35), // Un poco más de aire visual
            const CircularProgressIndicator(), // Indicador nativo Material 3
          ],
        ),
      ),
    );
  }
}