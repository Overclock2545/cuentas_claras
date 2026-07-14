import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_assets.dart';
import '../../config/routes/app_routes.dart';
import '../../controllers/login_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/social_button.dart';
import '../../widgets/common/divider_with_text.dart';
import '../../widgets/layouts/auth_layout.dart';
import '../../widgets/textfields/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return AuthLayout(
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _LogoSection(),
            SizedBox(height: 36),

            _WelcomeSection(),
            SizedBox(height: 36),

            _SocialLoginSection(),
            SizedBox(height: 24),

            DividerWithText(),
            SizedBox(height: 24),

            _EmailForm(),
            SizedBox(height: 28),

            _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppAssets.logo,
          width: 90,
        ),

        const SizedBox(height: 14),

        Text(
          'Cuentas Claras',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '¡Bienvenido!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 10),

        Text(
          'Organiza eventos y divide gastos fácilmente con tus amigos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SocialLoginSection extends StatelessWidget {
  const _SocialLoginSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          text: 'Continuar con Google',
          icon: Icons.g_mobiledata,
          onPressed: () {},
        ),

        const SizedBox(height: 12),

        SocialButton(
          text: 'Continuar con Apple',
          icon: Icons.apple,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return Column(
      children: [
        CustomTextField(
          label: 'Correo electrónico',
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: Validators.email,
        ),

        const SizedBox(height: 18),

        CustomTextField(
          label: 'Contraseña',
          controller: controller.passwordController,
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: Validators.password,
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),

        const SizedBox(height: 18),

        controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
        : PrimaryButton(
            text: 'Iniciar sesión',
            onPressed: () async {
              await controller.login(context);
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('¿No tienes cuenta?'),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.register,
            );
          },
          child: const Text('Regístrate'),
        ),
      ],
    );
  }
}