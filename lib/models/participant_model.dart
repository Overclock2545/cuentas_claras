import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String id; // Será el UID del usuario en Firebase
  final String name; // Nombre del participante (facilitará pintar la UI rápido)
  final String email; // Correo para validaciones e invitaciones
  final String role; // 'admin' o 'participante'
  final String status; // 'pendiente', 'aceptado', 'rechazado'
  final DateTime joinedAt;

  ParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    final joinedAt = map['joinedAt'];
    return ParticipantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'participante',
      status: map['status'] ?? 'pendiente',
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : DateTime.now(),
    );
  }
}
