import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Representa cuánto le corresponde pagar a UN participante de UN gasto
/// específico. Se calcula y se guarda ya resuelto en pesos/soles (no en
/// porcentajes) para que el cálculo de deudas (Flujo 5) sea un simple sumar,
/// sin importar si el gasto se dividió en partes iguales, por porcentaje o
/// con montos exactos.
class ExpenseSplitModel {
  final String participantId;
  final String participantName;
  final double amount;

  const ExpenseSplitModel({
    required this.participantId,
    required this.participantName,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'amount': amount,
    };
  }

  factory ExpenseSplitModel.fromMap(Map<String, dynamic> map) {
    final amount = map['amount'];
    return ExpenseSplitModel(
      participantId: map['participantId'] ?? '',
      participantName: map['participantName'] ?? '',
      amount: amount is num ? amount.toDouble() : 0,
    );
  }
}

/// Cómo se repartió el gasto entre los participantes seleccionados.
enum ExpenseSplitType { equal, percentage, fixed }

extension ExpenseSplitTypeX on ExpenseSplitType {
  String get value => switch (this) {
        ExpenseSplitType.equal => 'equal',
        ExpenseSplitType.percentage => 'percentage',
        ExpenseSplitType.fixed => 'fixed',
      };

  static ExpenseSplitType fromValue(String? value) => switch (value) {
        'percentage' => ExpenseSplitType.percentage,
        'fixed' => ExpenseSplitType.fixed,
        _ => ExpenseSplitType.equal,
      };
}

/// Categoría del gasto. Sirve para clasificar y, más adelante, para el
/// Resumen (Flujo 9) poder agrupar el gasto total por categoría.
enum ExpenseCategory {
  food,
  transport,
  accommodation,
  entertainment,
  shopping,
  health,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get value => switch (this) {
        ExpenseCategory.food => 'food',
        ExpenseCategory.transport => 'transport',
        ExpenseCategory.accommodation => 'accommodation',
        ExpenseCategory.entertainment => 'entertainment',
        ExpenseCategory.shopping => 'shopping',
        ExpenseCategory.health => 'health',
        ExpenseCategory.other => 'other',
      };

  String get label => switch (this) {
        ExpenseCategory.food => 'Comida',
        ExpenseCategory.transport => 'Transporte',
        ExpenseCategory.accommodation => 'Alojamiento',
        ExpenseCategory.entertainment => 'Entretenimiento',
        ExpenseCategory.shopping => 'Compras',
        ExpenseCategory.health => 'Salud',
        ExpenseCategory.other => 'Otros',
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.transport => Icons.directions_car,
        ExpenseCategory.accommodation => Icons.hotel,
        ExpenseCategory.entertainment => Icons.celebration,
        ExpenseCategory.shopping => Icons.shopping_bag,
        ExpenseCategory.health => Icons.local_hospital,
        ExpenseCategory.other => Icons.category,
      };

  static ExpenseCategory fromValue(String? value) => switch (value) {
        'food' => ExpenseCategory.food,
        'transport' => ExpenseCategory.transport,
        'accommodation' => ExpenseCategory.accommodation,
        'entertainment' => ExpenseCategory.entertainment,
        'shopping' => ExpenseCategory.shopping,
        'health' => ExpenseCategory.health,
        _ => ExpenseCategory.other,
      };
}

class ExpenseModel {
  final String id;
  final String eventId;
  final String title;
  final double amount;
  final String paidById; // UID del usuario que pagó
  final String
      paidByName; // Nombre del usuario que pagó (para ahorrar lecturas)
  final DateTime createdAt;
  final ExpenseSplitType splitType;
  final List<ExpenseSplitModel> splits;
  final ExpenseCategory category;

  ExpenseModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.createdAt,
    this.splitType = ExpenseSplitType.equal,
    this.splits = const [],
    this.category = ExpenseCategory.other,
  });

  /// Copia el gasto reemplazando solo los campos indicados. Útil para
  /// reconstruir el modelo antes de guardar una edición.
  ExpenseModel copyWith({
    String? title,
    double? amount,
    ExpenseSplitType? splitType,
    List<ExpenseSplitModel>? splits,
    ExpenseCategory? category,
  }) {
    return ExpenseModel(
      id: id,
      eventId: eventId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidById: paidById,
      paidByName: paidByName,
      createdAt: createdAt,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      category: category ?? this.category,
    );
  }

  // Convertir a Mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'amount': amount,
      'paidById': paidById,
      'paidByName': paidByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'splitType': splitType.value,
      'splits': splits.map((s) => s.toMap()).toList(),
      'category': category.value,
    };
  }

  // Crear instancia desde Firestore
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final amount = map['amount'];
    final createdAt = map['createdAt'];
    final rawSplits = map['splits'];
    return ExpenseModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      title: map['title'] ?? '',
      amount: amount is num ? amount.toDouble() : 0,
      paidById: map['paidById'] ?? '',
      paidByName: map['paidByName'] ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      splitType: ExpenseSplitTypeX.fromValue(map['splitType'] as String?),
      splits: rawSplits is List
          ? rawSplits
              .whereType<Map<String, dynamic>>()
              .map(ExpenseSplitModel.fromMap)
              .toList()
          : const [],
      category: ExpenseCategoryX.fromValue(map['category'] as String?),
    );
  }
}