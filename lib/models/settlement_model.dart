import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una liquidación (pago) entre dos participantes de un evento.
///
/// [fromId] le pagó [amount] a [toId] para saldar una deuda.
/// El [status] puede ser 'pending' (pendiente de confirmación) o
/// 'confirmed' (confirmado por el receptor).
class SettlementModel {
  final String id;
  final String eventId;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;
  final DateTime createdAt;
  final String status;

  const SettlementModel({
    required this.id,
    required this.eventId,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
    required this.createdAt,
    this.status = 'pending',
  });

  SettlementModel copyWith({
    String? id,
    String? eventId,
    String? fromId,
    String? fromName,
    String? toId,
    String? toName,
    double? amount,
    DateTime? createdAt,
    String? status,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      fromId: fromId ?? this.fromId,
      fromName: fromName ?? this.fromName,
      toId: toId ?? this.toId,
      toName: toName ?? this.toName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'fromId': fromId,
      'fromName': fromName,
      'toId': toId,
      'toName': toName,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory SettlementModel.fromMap(Map<String, dynamic> map) {
    final amount = map['amount'];
    final createdAt = map['createdAt'];
    return SettlementModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      fromId: map['fromId'] ?? '',
      fromName: map['fromName'] ?? '',
      toId: map['toId'] ?? '',
      toName: map['toName'] ?? '',
      amount: amount is num ? amount.toDouble() : 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}