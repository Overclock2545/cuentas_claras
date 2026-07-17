import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/participant_model.dart';

/// Calcula balances y deudas a partir de los gastos de un evento.
///
/// No toca Firestore: los gastos ya guardan cuánto pagó cada uno
/// (`paidById` + `amount`) y cuánto le correspondía a cada participante
/// (`splits`), así que el balance y las deudas se derivan siempre en el
/// cliente. Esto evita tener una colección "debts" que se pueda
/// desincronizar de los gastos reales.
class BalanceCalculator {
  BalanceCalculator._();

  /// Balance neto de cada participante.
  /// Positivo = le deben plata (pagó más de lo que le correspondía).
  /// Negativo = debe plata (le correspondía pagar más de lo que pagó).
  static Map<String, double> calculateBalances({
    required List<ExpenseModel> expenses,
    required List<ParticipantModel> participants,
  }) {
    final balances = {for (final p in participants) p.id: 0.0};

    for (final expense in expenses) {
      balances[expense.paidById] =
          (balances[expense.paidById] ?? 0) + expense.amount;
      for (final split in expense.splits) {
        balances[split.participantId] =
            (balances[split.participantId] ?? 0) - split.amount;
      }
    }

    // Redondeamos a centavos para no arrastrar errores de punto flotante.
    return balances
        .map((id, value) => MapEntry(id, (value * 100).round() / 100));
  }

  /// Reduce los balances netos a la menor cantidad posible de pagos,
  /// cruzando siempre al mayor acreedor con el mayor deudor (greedy).
  static List<DebtModel> simplifyDebts({
    required Map<String, double> balances,
    required List<ParticipantModel> participants,
  }) {
    final namesById = {for (final p in participants) p.id: p.name};

    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    balances.forEach((id, value) {
      if (value > 0.01) creditors.add(MapEntry(id, value));
      if (value < -0.01) debtors.add(MapEntry(id, -value));
    });

    // De mayor a menor para minimizar el número de transacciones.
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    final debts = <DebtModel>[];
    var ci = 0, di = 0;

    while (ci < creditors.length && di < debtors.length) {
      final payAmount = creditorAmounts[ci] < debtorAmounts[di]
          ? creditorAmounts[ci]
          : debtorAmounts[di];

      if (payAmount > 0.01) {
        debts.add(DebtModel(
          fromId: debtors[di].key,
          fromName: namesById[debtors[di].key] ?? 'Participante',
          toId: creditors[ci].key,
          toName: namesById[creditors[ci].key] ?? 'Participante',
          amount: (payAmount * 100).round() / 100,
        ));
      }

      creditorAmounts[ci] -= payAmount;
      debtorAmounts[di] -= payAmount;

      if (creditorAmounts[ci] <= 0.01) ci++;
      if (debtorAmounts[di] <= 0.01) di++;
    }

    return debts;
  }
}