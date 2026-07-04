import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String eventId;
  final String title;
  final double amount;
  final String paidById; // UID del usuario que pagó
  final String paidByName; // Nombre del usuario que pagó (para ahorrar lecturas)
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.createdAt,
  });

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
    };
  }

  // Crear instancia desde Firestore
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      paidById: map['paidById'] ?? '',
      paidByName: map['paidByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}