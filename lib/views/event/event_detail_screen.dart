import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/event_detail_controller.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../config/routes/app_routes.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibimos los argumentos enviados desde el HomeScreen (pasaremos un Map con id y nombre)
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String eventId = args['id'] ?? '';
    final String eventName = args['name'] ?? 'Detalle del Evento';

    final detailController = context.watch<EventDetailController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(eventName),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: ExpenseService.streamExpenses(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los gastos'));
          }

          final expenses = snapshot.data ?? [];
          
          // Sincronizamos los datos con el controlador para cálculos internos
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<EventDetailController>().setExpenses(expenses);
          });

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tarjeta de Balance General
                _TotalSummaryCard(totalAmount: detailController.totalAmount),
                const SizedBox(height: 24),

                Text(
                  'Historial de Gastos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // 2. Lista de Gastos
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
      // Botón flotante para registrar un nuevo gasto más adelante
// Botón flotante para registrar un nuevo gasto
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.addExpense,
            arguments: eventId, // Pasamos el ID del evento actual como argumento directo
          );
        },
        icon: const Icon(Icons.add_card),
        label: const Text('Agregar Gasto'),
      ),
    );
  }
}

class _TotalSummaryCard extends StatelessWidget {
  final double totalAmount;

  const _TotalSummaryCard({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha((0.4 * 255).round()),
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
                    color: Theme.of(context).colorScheme.primary, // Tu color #18B58A
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
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha((0.1 * 255).round())),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.monetization_on_outlined),
            ),
            title: Text(
              expense.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Pagado por: ${expense.paidByName}'),
            trailing: Text(
              'S/ ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Aún no hay gastos registrados',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const Text(
            'Presiona el botón de abajo para añadir el primero.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}