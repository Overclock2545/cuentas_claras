import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String id; // Será el UID del usuario en Firebase
  final String name; // Nombre del participante (facilitará pintar la UI rápido)
  final String email; // Correo para validaciones e invitaciones
  final String role; // 'admin' o 'participante'
  final String status; // 'pending' | 'accepted' | 'suggested'
  final DateTime joinedAt;
  final String? suggestedBy; // UID de quien sugirió esta invitación (solo para status 'suggested')
  final String? suggestedByName; // Nombre de quien sugirió (para mostrarlo en UI)

  ParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.suggestedBy,
    this.suggestedByName,
  });

  ParticipantModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    DateTime? joinedAt,
    String? suggestedBy,
    String? suggestedByName,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      suggestedByName: suggestedByName ?? this.suggestedByName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (suggestedBy != null) 'suggestedBy': suggestedBy,
      if (suggestedByName != null) 'suggestedByName': suggestedByName,
    };
  }

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    final joinedAt = map['joinedAt'];
    return ParticipantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'participante',
      status: map['status'] ?? 'pending',
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : DateTime.now(),
      suggestedBy: map['suggestedBy'] as String?,
      suggestedByName: map['suggestedByName'] as String?,
    );
  }
}
