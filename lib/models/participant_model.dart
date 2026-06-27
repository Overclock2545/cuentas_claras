import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String id;
  final String role;
  final String status;
  final DateTime joinedAt;

  const ParticipantModel({
    required this.id,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory ParticipantModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ParticipantModel(
      id: id,
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'accepted',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }
}