import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/routes/app_routes.dart';

class RegisterController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
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

  Future<void> register(BuildContext context) async {
    if (!validateForm()) return;

    try {
      setLoading(true);

      // Usamos el AuthService estático que configuramos con el guardado en Firestore
      await authService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!context.mounted) return;

      // Una vez registrado y creado en Firestore, va directo al Home
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false, // Limpia el historial para que no pueda volver atrás al registro
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      String message = 'Ocurrió un error al registrar';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este correo ya está registrado.';
          break;
        case 'invalid-email':
          message = 'El formato del correo es inválido.';
          break;
        case 'weak-password':
          message = 'La contraseña es muy débil (mínimo 6 caracteres).';
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}