import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/routes/app_routes.dart';

/// Controla el formulario y la autenticación del Login
class LoginController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  Future<void> login(BuildContext context) async {
    if (!validateForm()) return;

    try {
      setLoading(true);

      await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!context.mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      String message = 'Ocurrió un error';

      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con ese correo.';
          break;

        case 'wrong-password':
          message = 'Contraseña incorrecta.';
          break;

        case 'invalid-email':
          message = 'Correo inválido.';
          break;

        case 'invalid-credential':
          message = 'Correo o contraseña incorrectos.';
          break;

        case 'too-many-requests':
          message = 'Demasiados intentos. Inténtalo más tarde.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}