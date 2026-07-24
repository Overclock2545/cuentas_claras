import 'package:flutter_test/flutter_test.dart';
import 'package:cuentas_claras/models/debt_model.dart';
import 'package:cuentas_claras/models/expense_model.dart';
import 'package:cuentas_claras/models/participant_model.dart';
import 'package:cuentas_claras/models/settlement_model.dart';
import 'package:cuentas_claras/utils/balance_calculator.dart';

void main() {
  group('BalanceCalculator.calculateBalances', () {
    final alice = ParticipantModel(
      id: 'alice-uid',
      name: 'Alice',
      email: 'alice@test.com',
      role: 'admin',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );
    final bob = ParticipantModel(
      id: 'bob-uid',
      name: 'Bob',
      email: 'bob@test.com',
      role: 'participante',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );
    final carlos = ParticipantModel(
      id: 'carlos-uid',
      name: 'Carlos',
      email: 'carlos@test.com',
      role: 'participante',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );

    final participants = [alice, bob, carlos];

    test('sin gastos todos tienen balance 0', () {
      final balances = BalanceCalculator.calculateBalances(
        expenses: [],
        participants: participants,
      );
      expect(balances['alice-uid'], 0.0);
      expect(balances['bob-uid'], 0.0);
      expect(balances['carlos-uid'], 0.0);
    });

    test('Alice paga 300, dividido equitativamente entre 3', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        eventId: 'event-1',
        title: 'Cena',
        amount: 300,
        paidById: 'alice-uid',
        paidByName: 'Alice',
        createdAt: DateTime(2026, 1, 2),
        splitType: ExpenseSplitType.equal,
        splits: [
          ExpenseSplitModel(
              participantId: 'alice-uid', participantName: 'Alice', amount: 100),
          ExpenseSplitModel(
              participantId: 'bob-uid', participantName: 'Bob', amount: 100),
          ExpenseSplitModel(
              participantId: 'carlos-uid', participantName: 'Carlos', amount: 100),
        ],
      );

      final balances = BalanceCalculator.calculateBalances(
        expenses: [expense],
        participants: participants,
      );

      // Alice pagó 300, le correspondía 100 → balance +200 (le deben)
      // Bob pagó 0, le correspondía 100 → balance -100 (debe)
      // Carlos pagó 0, le correspondía 100 → balance -100 (debe)
      expect(balances['alice-uid'], 200.0);
      expect(balances['bob-uid'], -100.0);
      expect(balances['carlos-uid'], -100.0);
    });

    test('gastos con splits de montos fijos', () {
      final expense = ExpenseModel(
        id: 'exp-2',
        eventId: 'event-1',
        title: 'Hotel',
        amount: 500,
        paidById: 'bob-uid',
        paidByName: 'Bob',
        createdAt: DateTime(2026, 1, 3),
        splitType: ExpenseSplitType.fixed,
        splits: [
          ExpenseSplitModel(
              participantId: 'alice-uid', participantName: 'Alice', amount: 200),
          ExpenseSplitModel(
              participantId: 'bob-uid', participantName: 'Bob', amount: 200),
          ExpenseSplitModel(
              participantId: 'carlos-uid', participantName: 'Carlos', amount: 100),
        ],
      );

      final balances = BalanceCalculator.calculateBalances(
        expenses: [expense],
        participants: participants,
      );

      // Bob pagó 500, le correspondía 200 → balance +300
      // Alice pagó 0, le correspondía 200 → balance -200
      // Carlos pagó 0, le correspondía 100 → balance -100
      expect(balances['bob-uid'], 300.0);
      expect(balances['alice-uid'], -200.0);
      expect(balances['carlos-uid'], -100.0);
    });

    test('liquidaciones confirmadas se descuentan del balance', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        eventId: 'event-1',
        title: 'Cena',
        amount: 300,
        paidById: 'alice-uid',
        paidByName: 'Alice',
        createdAt: DateTime(2026, 1, 2),
        splitType: ExpenseSplitType.equal,
        splits: [
          ExpenseSplitModel(
              participantId: 'alice-uid', participantName: 'Alice', amount: 100),
          ExpenseSplitModel(
              participantId: 'bob-uid', participantName: 'Bob', amount: 100),
          ExpenseSplitModel(
              participantId: 'carlos-uid', participantName: 'Carlos', amount: 100),
        ],
      );

      // Bob le paga 50 a Alice (parcial)
      final settlement = SettlementModel(
        id: 'sett-1',
        eventId: 'event-1',
        fromId: 'bob-uid',
        fromName: 'Bob',
        toId: 'alice-uid',
        toName: 'Alice',
        amount: 50,
        createdAt: DateTime(2026, 1, 5),
        status: 'confirmed',
        registeredBy: 'bob-uid',
      );

      final balances = BalanceCalculator.calculateBalances(
        expenses: [expense],
        participants: participants,
        settlements: [settlement],
      );

      // Alice: +200 (gasto) - 50 (recibió pago) = +150
      // Bob: -100 (deuda) + 50 (pagó) = -50
      // Carlos: -100 (sin cambios)
      expect(balances['alice-uid'], 150.0);
      expect(balances['bob-uid'], -50.0);
      expect(balances['carlos-uid'], -100.0);
    });

    test('liquidaciones pendientes NO afectan el balance', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        eventId: 'event-1',
        title: 'Cena',
        amount: 300,
        paidById: 'alice-uid',
        paidByName: 'Alice',
        createdAt: DateTime(2026, 1, 2),
        splitType: ExpenseSplitType.equal,
        splits: [
          ExpenseSplitModel(
              participantId: 'alice-uid', participantName: 'Alice', amount: 100),
          ExpenseSplitModel(
              participantId: 'bob-uid', participantName: 'Bob', amount: 100),
          ExpenseSplitModel(
              participantId: 'carlos-uid', participantName: 'Carlos', amount: 100),
        ],
      );

      final settlement = SettlementModel(
        id: 'sett-1',
        eventId: 'event-1',
        fromId: 'bob-uid',
        fromName: 'Bob',
        toId: 'alice-uid',
        toName: 'Alice',
        amount: 50,
        createdAt: DateTime(2026, 1, 5),
        status: 'pending', // Pendiente, NO debe afectar
        registeredBy: 'bob-uid',
      );

      final balances = BalanceCalculator.calculateBalances(
        expenses: [expense],
        participants: participants,
        settlements: [settlement],
      );

      expect(balances['alice-uid'], 200.0);
      expect(balances['bob-uid'], -100.0);
    });

    test('participante sin gastos tiene balance 0', () {
      final diana = ParticipantModel(
        id: 'diana-uid',
        name: 'Diana',
        email: 'diana@test.com',
        role: 'participante',
        status: 'accepted',
        joinedAt: DateTime(2026, 1, 1),
      );

      final expense = ExpenseModel(
        id: 'exp-1',
        eventId: 'event-1',
        title: 'Cena',
        amount: 200,
        paidById: 'alice-uid',
        paidByName: 'Alice',
        createdAt: DateTime(2026, 1, 2),
        splitType: ExpenseSplitType.equal,
        splits: [
          ExpenseSplitModel(
              participantId: 'alice-uid', participantName: 'Alice', amount: 100),
          ExpenseSplitModel(
              participantId: 'bob-uid', participantName: 'Bob', amount: 100),
        ],
      );

      final balances = BalanceCalculator.calculateBalances(
        expenses: [expense],
        participants: [...participants, diana],
      );

      expect(balances['diana-uid'], 0.0);
    });
  });

  group('BalanceCalculator.simplifyDebts', () {
    final alice = ParticipantModel(
      id: 'alice-uid',
      name: 'Alice',
      email: 'alice@test.com',
      role: 'admin',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );
    final bob = ParticipantModel(
      id: 'bob-uid',
      name: 'Bob',
      email: 'bob@test.com',
      role: 'participante',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );
    final carlos = ParticipantModel(
      id: 'carlos-uid',
      name: 'Carlos',
      email: 'carlos@test.com',
      role: 'participante',
      status: 'accepted',
      joinedAt: DateTime(2026, 1, 1),
    );

    test('un deudor y un acreedor genera una deuda', () {
      final balances = {
        'alice-uid': 200.0, // le deben
        'bob-uid': -200.0, // debe
        'carlos-uid': 0.0,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob, carlos],
      );

      expect(debts.length, 1);
      expect(debts[0].fromId, 'bob-uid');
      expect(debts[0].toId, 'alice-uid');
      expect(debts[0].amount, 200.0);
    });

    test('todos en cero no genera deudas', () {
      final balances = {
        'alice-uid': 0.0,
        'bob-uid': 0.0,
        'carlos-uid': 0.0,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob, carlos],
      );

      expect(debts, isEmpty);
    });

    test('tres personas con deudas cruzadas se simplifica a 2 deudas', () {
      // Alice pagó 300, dividido en 3 → Alice +200, Bob -100, Carlos -100
      final balances = {
        'alice-uid': 200.0,
        'bob-uid': -100.0,
        'carlos-uid': -100.0,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob, carlos],
      );

      // Bob le debe 100 a Alice, Carlos le debe 100 a Alice
      expect(debts.length, 2);
      expect(debts.any((d) => d.fromId == 'bob-uid' && d.toId == 'alice-uid' && d.amount == 100.0), true);
      expect(debts.any((d) => d.fromId == 'carlos-uid' && d.toId == 'alice-uid' && d.amount == 100.0), true);
    });

    test('montos con centavos se redondean correctamente', () {
      final balances = {
        'alice-uid': 100.33,
        'bob-uid': -100.33,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob],
      );

      expect(debts.length, 1);
      expect(debts[0].amount, 100.33);
    });

    test('valores menores a 0.01 se ignoran (tolerancia)', () {
      final balances = {
        'alice-uid': 0.005,
        'bob-uid': -0.005,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob],
      );

      expect(debts, isEmpty);
    });

    test('deudas complejas se simplifican al mínimo de transacciones', () {
      // Alice: +300, Bob: -100, Carlos: -200
      final balances = {
        'alice-uid': 300.0,
        'bob-uid': -100.0,
        'carlos-uid': -200.0,
      };

      final debts = BalanceCalculator.simplifyDebts(
        balances: balances,
        participants: [alice, bob, carlos],
      );

      // El algoritmo greedy empareja al mayor deudor con el mayor acreedor
      // Carlos (-200) debe pagar a Alice (+300) → 200
      // Bob (-100) debe pagar a Alice (+300) → 100
      expect(debts.length, 2);
      expect(debts.any((d) => d.fromId == 'carlos-uid' && d.toId == 'alice-uid' && d.amount == 200.0), true);
      expect(debts.any((d) => d.fromId == 'bob-uid' && d.toId == 'alice-uid' && d.amount == 100.0), true);
    });
  });
}