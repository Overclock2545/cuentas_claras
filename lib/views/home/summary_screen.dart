import 'package:flutter/material.dart';

import '../../models/debt_model.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import '../../models/settlement_model.dart';
import '../../services/expense_service.dart';
import '../../services/participant_service.dart';
import '../../services/settlement_service.dart';
import '../../utils/balance_calculator.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String eventId = args['id'] ?? '';
    final String eventName = args['name'] ?? 'Resumen del Evento';

    return _SummaryView(eventId: eventId, eventName: eventName);
  }
}

class _SummaryView extends StatelessWidget {
  final String eventId;
  final String eventName;

  const _SummaryView({required this.eventId, required this.eventName});

  @override
  Widget build(BuildContext context) {
    final expensesStream = ExpenseService.streamExpenses(eventId);
    final participantsStream = ParticipantService.streamParticipants(eventId);
    final settlementsStream = SettlementService.streamSettlements(eventId);

    return Scaffold(
      appBar: AppBar(
        title: Text(eventName),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SettlementModel>>(
        stream: settlementsStream,
        builder: (context, settlementsSnapshot) {
          final settlements = settlementsSnapshot.data ?? [];

          return StreamBuilder<List<ExpenseModel>>(
            stream: expensesStream,
            builder: (context, expensesSnapshot) {
              final expenses = expensesSnapshot.data ?? [];
              final isLoadingExpenses =
                  expensesSnapshot.connectionState == ConnectionState.waiting;

              return StreamBuilder<List<ParticipantModel>>(
                stream: participantsStream,
                builder: (context, participantsSnapshot) {
                  final allParticipants = participantsSnapshot.data ?? [];
                  final acceptedParticipants =
                      allParticipants.where((p) => p.status == 'accepted').toList();
                  final isLoadingParticipants =
                      participantsSnapshot.connectionState == ConnectionState.waiting;

                  if (isLoadingExpenses || isLoadingParticipants) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final totalAmount =
                      expenses.fold(0.0, (sum, e) => sum + e.amount);
                  final expenseCount = expenses.length;
                  final participantCount = acceptedParticipants.length;

                  final balances = BalanceCalculator.calculateBalances(
                    expenses: expenses,
                    participants: acceptedParticipants,
                    settlements: settlements,
                  );
                  final debts = BalanceCalculator.simplifyDebts(
                    balances: balances,
                    participants: acceptedParticipants,
                  );

                  final pendingSettlements =
                      settlements.where((s) => s.status == 'pending').length;
                  final confirmedSettlements =
                      settlements.where((s) => s.status == 'confirmed').length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tarjeta de total general
                        _TotalCard(
                          totalAmount: totalAmount,
                          expenseCount: expenseCount,
                          participantCount: participantCount,
                        ),
                        const SizedBox(height: 20),

                        // Gastos por categoría
                        if (expenses.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Gastos por categoría',
                            icon: Icons.pie_chart_outline,
                          ),
                          const SizedBox(height: 12),
                          _CategoryBreakdown(expenses: expenses),
                          const SizedBox(height: 24),
                        ],

                        // Balance individual
                        _SectionHeader(
                          title: 'Balance individual',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(height: 12),
                        if (acceptedParticipants.isEmpty)
                          _EmptyCard(
                            message: 'No hay participantes en este evento.',
                          )
                        else
                          ...balances.entries.map((entry) =>
                              _BalanceRow(
                                entry: entry,
                                participants: acceptedParticipants,
                              )),
                        const SizedBox(height: 24),

                        // Deudas pendientes
                        _SectionHeader(
                          title: 'Deudas pendientes',
                          icon: Icons.sync_alt,
                        ),
                        const SizedBox(height: 12),
                        if (debts.isEmpty)
                          _EmptyCard(
                            message: '¡Todas las cuentas están saldadas! 🎉',
                            color: Colors.green,
                          )
                        else
                          ...debts.map((debt) => _DebtRow(debt: debt)),
                        const SizedBox(height: 24),

                        // Liquidaciones
                        _SectionHeader(
                          title: 'Liquidaciones',
                          icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatChip(
                              label: 'Pendientes',
                              value: pendingSettlements.toString(),
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: 'Confirmados',
                              value: confirmedSettlements.toString(),
                              color: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Resumen de gastos recientes
                        _SectionHeader(
                          title: 'Últimos gastos',
                          icon: Icons.receipt_long_outlined,
                        ),
                        const SizedBox(height: 12),
                        if (expenses.isEmpty)
                          _EmptyCard(
                            message: 'No hay gastos registrados.',
                          )
                        else
                          ...expenses.take(5).map((expense) =>
                              _ExpenseRow(expense: expense)),
                        if (expenses.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/event-detail',
                                  arguments: {
                                    'id': eventId,
                                    'name': eventName,
                                  },
                                );
                              },
                              child: Text(
                                  'Ver todos los ${expenses.length} gastos →'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- Widgets auxiliares ---

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final Color? color;

  const _EmptyCard({required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;
    return Card(
      elevation: 0,
      color: c.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: c, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double totalAmount;
  final int expenseCount;
  final int participantCount;

  const _TotalCard({
    required this.totalAmount,
    required this.expenseCount,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Gasto Total',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  label: 'Gastos',
                  value: expenseCount.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatChip(
                  label: 'Participantes',
                  value: participantCount.toString(),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const _CategoryBreakdown({required this.expenses});

  @override
  Widget build(BuildContext context) {
    // Agrupar gastos por categoría
    final byCategory = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }

    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sorted.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(entry.key.icon, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'S/ ${entry.value.toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final MapEntry<String, double> entry;
  final List<ParticipantModel> participants;

  const _BalanceRow({required this.entry, required this.participants});

  @override
  Widget build(BuildContext context) {
    final nameById = {for (final p in participants) p.id: p.name};
    final name = nameById[entry.key] ?? 'Participante';
    final value = entry.value;
    final isSettled = value.abs() <= 0.01;
    final color = isSettled
        ? Colors.grey
        : (value > 0 ? Colors.green : Colors.red);
    final label = isSettled
        ? 'Está al día'
        : (value > 0
            ? 'Le deben S/ ${value.toStringAsFixed(2)}'
            : 'Debe S/ ${value.abs().toStringAsFixed(2)}');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isSettled
                ? Icons.check
                : (value > 0
                    ? Icons.arrow_downward
                    : Icons.arrow_upward),
            color: color,
          ),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final DebtModel debt;

  const _DebtRow({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.sync_alt, color: Colors.orange),
        title: Text(
          '${debt.fromName} → ${debt.toName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          'S/ ${debt.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseRow({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(expense.category.icon, size: 18),
        ),
        title: Text(expense.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Pagado por ${expense.paidByName}'),
        trailing: Text(
          'S/ ${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}