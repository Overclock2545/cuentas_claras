import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuentas_claras/models/expense_model.dart';
import 'package:cuentas_claras/models/event_model.dart';
import 'package:cuentas_claras/models/participant_model.dart';
import 'package:cuentas_claras/models/settlement_model.dart';
import 'package:cuentas_claras/models/user_model.dart';

void main() {
  group('ExpenseModel serialization', () {
    test('toMap y fromMap producen el mismo objeto', () {
      final original = ExpenseModel(
        id: 'exp-123',
        eventId: 'event-456',
        title: 'Cena en restaurante',
        amount: 150.50,
        paidById: 'user-1',
        paidByName: 'Alice',
        createdAt: DateTime(2026, 1, 15),
        splitType: ExpenseSplitType.equal,
        splits: [
          ExpenseSplitModel(
              participantId: 'user-1', participantName: 'Alice', amount: 75.25),
          ExpenseSplitModel(
              participantId: 'user-2', participantName: 'Bob', amount: 75.25),
        ],
        category: ExpenseCategory.food,
      );

      final map = original.toMap();
      final restored = ExpenseModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.eventId, original.eventId);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.paidById, original.paidById);
      expect(restored.paidByName, original.paidByName);
      expect(restored.splitType, original.splitType);
      expect(restored.category, original.category);
      expect(restored.splits.length, original.splits.length);
      expect(restored.splits[0].participantId, original.splits[0].participantId);
      expect(restored.splits[0].amount, original.splits[0].amount);
    });

    test('fromMap con valores por defecto para campos nulos', () {
      final map = <String, dynamic>{
        'id': null,
        'eventId': null,
        'title': null,
        'amount': null,
        'paidById': null,
        'paidByName': null,
        'createdAt': null,
        'splitType': null,
        'splits': null,
        'category': null,
      };

      final expense = ExpenseModel.fromMap(map);
      expect(expense.id, '');
      expect(expense.title, '');
      expect(expense.amount, 0.0);
      expect(expense.splitType, ExpenseSplitType.equal);
      expect(expense.category, ExpenseCategory.other);
      expect(expense.splits, isEmpty);
    });

    test('fromMap maneja amount como int', () {
      final map = <String, dynamic>{
        'id': 'exp-1',
        'eventId': 'event-1',
        'title': 'Test',
        'amount': 100, // int en lugar de double
        'paidById': 'user-1',
        'paidByName': 'Alice',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'splitType': 'equal',
        'splits': [],
        'category': 'other',
      };

      final expense = ExpenseModel.fromMap(map);
      expect(expense.amount, 100.0); // debe convertirse a double
    });
  });

  group('EventModel serialization', () {
    test('toMap y fromMap producen el mismo objeto', () {
      final original = EventModel(
        id: 'event-123',
        name: 'Cumpleaños de Alice',
        description: 'Fiesta en la playa',
        date: DateTime(2026, 3, 15),
        creatorId: 'user-1',
        createdAt: DateTime(2026, 1, 10),
        status: 'active',
      );

      final map = original.toMap();
      final restored = EventModel.fromMap(original.id, map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.creatorId, original.creatorId);
      expect(restored.status, original.status);
    });

    test('fromMap con valores por defecto', () {
      final map = <String, dynamic>{
        'name': null,
        'description': null,
        'date': null,
        'creatorId': null,
        'createdAt': null,
        'status': null,
      };

      final event = EventModel.fromMap('event-id', map);
      expect(event.name, '');
      expect(event.description, '');
      expect(event.status, 'active');
    });
  });

  group('ParticipantModel serialization', () {
    test('toMap y fromMap producen el mismo objeto', () {
      final original = ParticipantModel(
        id: 'user-1',
        name: 'Alice',
        email: 'alice@test.com',
        role: 'admin',
        status: 'accepted',
        joinedAt: DateTime(2026, 1, 10),
      );

      final map = original.toMap();
      final restored = ParticipantModel.fromMap({'id': 'user-1', ...map});

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
      expect(restored.status, original.status);
    });

    test('toMap y fromMap con suggestedBy', () {
      final original = ParticipantModel(
        id: 'user-2',
        name: 'Bob',
        email: 'bob@test.com',
        role: 'participante',
        status: 'suggested',
        joinedAt: DateTime(2026, 1, 10),
        suggestedBy: 'user-1',
        suggestedByName: 'Alice',
      );

      final map = original.toMap();
      final restored = ParticipantModel.fromMap({'id': 'user-2', ...map});

      expect(restored.suggestedBy, 'user-1');
      expect(restored.suggestedByName, 'Alice');
      expect(restored.status, 'suggested');
    });

    test('fromMap con valores por defecto', () {
      final map = <String, dynamic>{
        'id': null,
        'name': null,
        'email': null,
        'role': null,
        'status': null,
        'joinedAt': null,
      };

      final participant = ParticipantModel.fromMap(map);
      expect(participant.id, '');
      expect(participant.name, '');
      expect(participant.role, 'participante');
      expect(participant.status, 'pending');
      expect(participant.suggestedBy, isNull);
      expect(participant.suggestedByName, isNull);
    });
  });

  group('SettlementModel serialization', () {
    test('toMap y fromMap producen el mismo objeto', () {
      final original = SettlementModel(
        id: 'sett-1',
        eventId: 'event-1',
        fromId: 'user-2',
        fromName: 'Bob',
        toId: 'user-1',
        toName: 'Alice',
        amount: 100.50,
        createdAt: DateTime(2026, 2, 1),
        status: 'pending',
        registeredBy: 'user-2',
      );

      final map = original.toMap();
      final restored = SettlementModel.fromMap({'id': 'sett-1', ...map});

      expect(restored.id, original.id);
      expect(restored.eventId, original.eventId);
      expect(restored.fromId, original.fromId);
      expect(restored.fromName, original.fromName);
      expect(restored.toId, original.toId);
      expect(restored.toName, original.toName);
      expect(restored.amount, original.amount);
      expect(restored.status, original.status);
      expect(restored.registeredBy, original.registeredBy);
    });

    test('copyWith preserva campos no modificados', () {
      final original = SettlementModel(
        id: 'sett-1',
        eventId: 'event-1',
        fromId: 'user-2',
        fromName: 'Bob',
        toId: 'user-1',
        toName: 'Alice',
        amount: 100,
        createdAt: DateTime(2026, 2, 1),
        status: 'pending',
        registeredBy: 'user-2',
      );

      final modified = original.copyWith(status: 'confirmed');
      expect(modified.id, original.id);
      expect(modified.status, 'confirmed');
      expect(modified.amount, original.amount);
      expect(modified.fromId, original.fromId);
    });

    test('fromMap con fallback para registeredBy', () {
      final map = <String, dynamic>{
        'id': 'sett-1',
        'eventId': 'event-1',
        'fromId': 'user-2',
        'fromName': 'Bob',
        'toId': 'user-1',
        'toName': 'Alice',
        'amount': 50,
        'createdAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'status': 'pending',
        // registeredBy ausente → debe usar fromId como fallback
      };

      final settlement = SettlementModel.fromMap(map);
      expect(settlement.registeredBy, 'user-2'); // fallback a fromId
    });
  });

  group('UserModel serialization', () {
    test('toMap y fromMap producen el mismo objeto', () {
      final original = UserModel(
        id: 'user-1',
        name: 'Alice',
        email: 'alice@test.com',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2026, 1, 10),
        preferredCurrency: 'USD',
        fcmToken: 'fcm-token-123',
      );

      final map = original.toMap();
      final restored = UserModel.fromMap(map, 'user-1');

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.preferredCurrency, original.preferredCurrency);
      expect(restored.fcmToken, original.fcmToken);
    });

    test('valores por defecto en fromMap', () {
      final map = <String, dynamic>{
        'name': null,
        'email': null,
        'photoUrl': null,
        'createdAt': null,
        'preferredCurrency': null,
        'fcmToken': null,
      };

      final user = UserModel.fromMap(map, 'user-id');
      expect(user.id, 'user-id');
      expect(user.name, '');
      expect(user.email, '');
      expect(user.preferredCurrency, 'PEN');
      expect(user.photoUrl, isNull);
      expect(user.fcmToken, isNull);
    });
  });
}