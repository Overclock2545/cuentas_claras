import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/textfields/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos del perfil al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(ProfileController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => controller.loadProfile(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar y nombre
            _buildAvatarSection(controller),
            const SizedBox(height: 36),

            // Campos del formulario
            CustomTextField(
              label: 'Nombre completo',
              controller: controller.nameController,
              keyboardType: TextInputType.name,
              prefixIcon: Icons.person_outline,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 18),

            // Selector de moneda
            _buildCurrencySelector(controller),
            const SizedBox(height: 32),

            // Mensaje de error
            if (controller.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón guardar
            controller.isSaving
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Guardar cambios',
                  onPressed: () async {
                      try {
                        await controller.saveProfile();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Perfil actualizado correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ProfileController controller) {
    final initials = (controller.user?.name.isNotEmpty == true)
        ? controller.user!.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initials,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          controller.user?.name ?? 'Sin nombre',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          controller.user?.email ?? '',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moneda preferida',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.preferredCurrency,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          items: ProfileController.currencies.map((currency) {
            return DropdownMenuItem(
              value: currency,
              child: Text(_currencyLabel(currency)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) controller.setCurrency(value);
          },
        ),
      ],
    );
  }

  String _currencyLabel(String code) {
    const labels = {
      'PEN': 'S/ - Sol peruano',
      'USD': '\$ - Dólar estadounidense',
      'EUR': '€ - Euro',
      'COP': '\$ - Peso colombiano',
      'MXN': '\$ - Peso mexicano',
      'CLP': '\$ - Peso chileno',
      'ARS': '\$ - Peso argentino',
      'BRL': 'R\$ - Real brasileño',
    };
    return labels[code] ?? code;
  }
}