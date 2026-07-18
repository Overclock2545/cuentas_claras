import 'package:cuentas_claras/services/service_locator.dart';
import 'package:cuentas_claras/services/settlement_service.dart';
import 'package:flutter/material.dart';

import '../../models/debt_model.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import '../../models/settlement_model.dart';
import '../../services/expense_service.dart';
import '../../services/participant_service.dart';
import '../../utils/balance_calculator.dart';

/// Pantalla que permite liquidar deudas entre participantes.
///
/// Muestra las deudas pendientes y permite al usuario registar pagos
/// a otros participantes. También muestra el historial de liquidaciones.
class SettleScreen extends StatelessWidget {
  final String eventId;

  const SettleScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final expensesStream = ExpenseService.streamExpenses(eventId);
    final participantsStream = ParticipantService.streamParticipants(eventId);
    final settlementsStream = SettlementService.streamSettlements(eventId);

    return StreamBuilder<List<SettlementModel>>(
      stream: settlementsStream,
      builder: (context, settlementsSnapshot) {
        final settlements = settlementsSnapshot.data ?? [];
        final isLoadingSettlements =
            settlementsSnapshot.connectionState == ConnectionState.waiting;

        return StreamBuilder<List<ExpenseModel>>(
          stream: expensesStream,
          builder: (context, expensesSnapshot) {
            final expenses = expensesSnapshot.data ?? [];
            final isLoadingExpenses =
                expensesSnapshot.connectionState == ConnectionState.waiting;

            return StreamBuilder<List<ParticipantModel>>(
              stream: participantsStream,
              builder: (context, participantsSnapshot) {
                final participants = (participantsSnapshot.data ?? [])
                    .where((p) => p.status == 'accepted')
                    .toList();
                final isLoadingParticipants =
                    participantsSnapshot.connectionState ==
                        ConnectionState.waiting;

                if (isLoadingExpenses ||
                    isLoadingParticipants ||
                    isLoadingSettlements) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (expenses.isEmpty || participants.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aún no hay gastos registrados para calcular deudas.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Calculamos balances incluyendo liquidaciones confirmadas
                final balances = BalanceCalculator.calculateBalances(
                  expenses: expenses,
                  participants: participants,
                  settlements: settlements,
                );
                final debts = BalanceCalculator.simplifyDebts(
                  balances: balances,
                  participants: participants,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sección: Deudas pendientes
                      _SectionHeader(
                        title: 'Deudas pendientes',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(height: 12),
                      if (debts.isEmpty)
                        _EmptyState(
                          icon: Icons.check_circle_outline,
                          message: '¡Todas las cuentas están saldadas! 🎉',
                          color: Colors.green,
                        )
                      else
                        ...debts.map((debt) {
                          final currentUserId = authService.currentUser?.uid;
                          // El botón de pago solo tiene sentido si el
                          // usuario actual es una de las dos partes de
                          // esta deuda en particular.
                          final isPayer = currentUserId == debt.fromId;
                          final isReceiver = currentUserId == debt.toId;
                          if (!isPayer && !isReceiver) {
                            return _DebtCard(debt: debt, onPay: null);
                          }
                          return _DebtCard(
                            debt: debt,
                            onPay: () => _showPayDialog(
                              context,
                              debt,
                              currentUserIsPayer: isPayer,
                            ),
                          );
                        }),
                      const SizedBox(height: 28),

                      // Sección: Balance individual
                      _SectionHeader(
                        title: 'Balance individual',
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 12),
                      ...balances.entries.map((entry) =>
                          _BalanceCard(entry: entry, participants: participants)),
                      const SizedBox(height: 28),

                      // Sección: Historial de liquidaciones
                      _SectionHeader(
                        title: 'Historial de pagos',
                        icon: Icons.history,
                      ),
                      const SizedBox(height: 12),
                      if (settlements.isEmpty)
                        const _EmptyState(
                          icon: Icons.payments_outlined,
                          message: 'No hay pagos registrados aún.',
                          color: Colors.grey,
                        )
                      else
                        ...settlements.map((settlement) =>
                            _SettlementCard(
                              settlement: settlement,
                              onConfirm: settlement.status == 'pending'
                                  ? () => _confirmSettlement(
                                      context, settlement)
                                  : null,
                              onDelete: settlement.status == 'pending'
                                  ? () => _deleteSettlement(
                                      context, settlement)
                                  : null,
                            )),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPayDialog(
    BuildContext context,
    DebtModel debt, {
    required bool currentUserIsPayer,
  }) {
    final amountController =
        TextEditingController(text: debt.amount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();
    bool isPaying = false;

    // Quien no es "yo" en esta deuda: si yo soy el que paga, la contraparte
    // es quien recibe, y viceversa.
    final otherPartyId = currentUserIsPayer ? debt.toId : debt.fromId;
    final otherPartyName = currentUserIsPayer ? debt.toName : debt.fromName;
    final dialogTitle =
        currentUserIsPayer ? 'Pagar a ${debt.toName}' : 'Registrar cobro';
    final dialogDescription = currentUserIsPayer
        ? 'Vas a registrar que le pagaste a ${debt.toName}.'
        : 'Vas a registrar que ${debt.fromName} ya te pagó.';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dialogDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      enabled: !isPaying,
                      decoration: const InputDecoration(
                        labelText: 'Monto (S/)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el monto';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Ingresa un monto válido mayor a cero';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isPaying ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isPaying
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isPaying = true);

                          try {
                            await SettlementService.addSettlement(
                              eventId: eventId,
                              otherPartyId: otherPartyId,
                              otherPartyName: otherPartyName,
                              amount: double.parse(amountController.text.trim()),
                              currentUserIsPayer: currentUserIsPayer,
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ Pago registrado. Esperando confirmación de $otherPartyName.'),
                                  backgroundColor: Colors.green.shade600,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => isPaying = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isPaying
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrar pago'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSettlement(
      BuildContext context, SettlementModel settlement) async {
    try {
      await SettlementService.confirmSettlement(
        eventId: eventId,
        settlementId: settlement.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago confirmado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar: $e')),
        );
      }
    }
  }

  Future<void> _deleteSettlement(
      BuildContext context, SettlementModel settlement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
            '¿Seguro que quieres eliminar el pago de ${settlement.fromName} a ${settlement.toName} por S/ ${settlement.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SettlementService.deleteSettlement(
        eventId: eventId,
        settlementId: settlement.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago eliminado.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback? onPay;

  const _DebtCard({required this.debt, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.sync_alt, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.fromName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'le debe a ${debt.toName}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${debt.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (onPay != null)
                  TextButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Pagar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final MapEntry<String, double> entry;
  final List<ParticipantModel> participants;

  const _BalanceCard({required this.entry, required this.participants});

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
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
          style:
              TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final SettlementModel settlement;
  final VoidCallback? onConfirm;
  final VoidCallback? onDelete;

  const _SettlementCard({
    required this.settlement,
    this.onConfirm,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = settlement.status == 'pending';
    final currentUserId = authService.currentUser?.uid;

    return Card(
      elevation: 0,
      color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending
              ? Colors.orange.shade200
              : Colors.green.shade200,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPending ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(
            isPending ? Icons.hourglass_empty : Icons.check_circle,
            color: isPending ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(
          '${settlement.fromName} → ${settlement.toName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isPending
              ? 'Pendiente de confirmación'
              : 'Confirmado',
          style: TextStyle(
            color: isPending ? Colors.orange.shade700 : Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'S/ ${settlement.amount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // Solo puede confirmar la CONTRAPARTE de quien registró el pago
            // (nunca quien lo registró, para evitar autoconfirmación).
            if (isPending &&
                onConfirm != null &&
                currentUserId != settlement.registeredBy &&
                (settlement.fromId == currentUserId ||
                    settlement.toId == currentUserId)) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Confirmar pago',
                onPressed: onConfirm,
              ),
            ],
            // Solo puede eliminarlo quien lo registró, y solo mientras
            // siga pendiente (una vez confirmado, ya no se puede deshacer
            // unilateralmente).
            if (isPending &&
                onDelete != null &&
                settlement.registeredBy == currentUserId) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                tooltip: 'Eliminar',
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}