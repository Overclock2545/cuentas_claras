import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_assets.dart';
import '../../controllers/register_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/layouts/auth_layout.dart';
import '../../widgets/textfields/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();

    return AuthLayout(
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _HeaderSection(),
            SizedBox(height: 36),

            _RegisterForm(),
            SizedBox(height: 28),

            _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppAssets.logo,
          width: 70,
        ),
        const SizedBox(height: 14),
        Text(
          'Crear cuenta',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Únete para empezar a dividir tus gastos de forma clara.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();

    return Column(
      children: [
        CustomTextField(
          label: 'Nombre completo',
          controller: controller.nameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline,
          validator: (value) => value == null || value.trim().isEmpty 
              ? 'Por favor, ingresa tu nombre' 
              : null,
        ),
        const SizedBox(height: 18),

        CustomTextField(
          label: 'Correo electrónico',
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: Validators.email, // Tu lógica centralizada de validaciones
        ),
        const SizedBox(height: 18),

        CustomTextField(
          label: 'Contraseña',
          controller: controller.passwordController,
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: Validators.password,
        ),
        const SizedBox(height: 30),

        controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                text: 'Registrarse',
                onPressed: () async {
                  await controller.register(context);
                },
              ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta?'),
        TextButton(
          onPressed: () {
            // Regresa al Login quitando la pantalla de registro
            Navigator.pop(context);
          },
          child: const Text('Inicia sesión'),
        ),
      ],
    );
  }
}