import 'package:cuentas_claras/utils/color_extensions.dart';
import 'package:flutter/material.dart';

import '../../config/routes/app_routes.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import '../../services/expense_service.dart';
import '../../services/participant_service.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  // ✅ FIX 2.3: Cuadro de diálogo mejorado para invitar con mejor feedback de errores
  void _showInviteDialog(BuildContext context, String eventId) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isInviting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Invitar Participante'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isInviting, // ✅ Deshabilitar mientras se invita
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: const Icon(Icons.mail_outline),
                          errorText: errorMessage, // ✅ Mostrar error inline
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un correo';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      // ✅ Mostrar error detallado si lo hay
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isInviting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isInviting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() {
                            isInviting = true;
                            errorMessage = null; // ✅ Limpiar errores previos
                          });

                          try {
                            await ParticipantService.inviteUserByEmail(
                              eventId: eventId,
                              email: emailController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('✅ ¡Invitación enviada con éxito!'),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              // ✅ Mantener el diálogo abierto para que corrija
                              setState(() {
                                isInviting = false;
                                errorMessage =
                                    e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          }
                        },
                  child: isInviting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Invitar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String eventId = args['id'] ?? '';
    final String eventName = args['name'] ?? 'Detalle del Evento';

    return DefaultTabController(
      length: 2, // Dos pestañas: Gastos y Participantes
      child: Scaffold(
        appBar: AppBar(
          title: Text(eventName),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Gastos'),
              Tab(icon: Icon(Icons.people_outline), text: 'Participantes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: GASTOS
            StreamBuilder<List<ExpenseModel>>(
              stream: ExpenseService.streamExpenses(eventId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = snapshot.data ?? [];                
                final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TotalSummaryCard(totalAmount: totalAmount),
                      const SizedBox(height: 24),
                      Text(
                        'Historial de Gastos',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: expenses.isEmpty
                            ? const _EmptyExpensesView()
                            : _ExpensesList(expenses: expenses),
                      ),
                    ],
                  ),
                );
              },
            ),

            // PESTAÑA 2: PARTICIPANTES
            StreamBuilder<List<ParticipantModel>>(
              stream: ParticipantService.streamParticipants(eventId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final participants = snapshot.data ?? [];

                if (participants.isEmpty) {
                  return const Center(
                      child: Text('No hay participantes asignados.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: participants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacityValue(0.1)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            p.name.trim().isNotEmpty
                                ? p.name.trim().substring(0, 1).toUpperCase()
                                : 'P', // 'P' por defecto si el nombre está vacío
                          ),
                        ),
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(p.email),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.status == 'accepted'
                                ? Colors.green.withOpacityValue(0.1)
                                : Colors.orange.withOpacityValue(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.status == 'accepted' ? 'Aceptado' : 'Pendiente',
                            style: TextStyle(
                              color: p.status == 'accepted'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

        // Menú flotante expandible sencillo usando un Builder para saber en qué pestaña estamos
        floatingActionButton: Builder(
          builder: (tabContext) {
            final tabController = DefaultTabController.of(tabContext);

            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final tabIndex = tabController.index;
                return FloatingActionButton.extended(
                  onPressed: () {
                    // En gastos se registra un gasto; en participantes se envía una invitación.
                    if (tabIndex == 0) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addExpense,
                        arguments: eventId,
                      );
                    } else {
                      _showInviteDialog(context, eventId);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(tabIndex == 0 ? 'Añadir gasto' : 'Invitar'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Mantenemos los widgets privados que ya tenías abajo (_TotalSummaryCard, _ExpensesList, _EmptyExpensesView)
class _TotalSummaryCard extends StatelessWidget {
  final double totalAmount;
  const _TotalSummaryCard({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacityValue(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Gasto Total del Evento',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  const _ExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Theme.of(context).dividerColor.withOpacityValue(0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.monetization_on_outlined),
            ),
            title: Text(expense.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Pagado por: ${expense.paidByName}'),
            trailing: Text(
              'S/ ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyExpensesView extends StatelessWidget {
  const _EmptyExpensesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Aún no hay gastos registrados',
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
