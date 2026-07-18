import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final String preferredCurrency; // Ej: "PEN", "USD"
  final String? fcmToken; // Token de Firebase Cloud Messaging

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.preferredCurrency = 'PEN', // Por defecto Soles de Perú
    this.fcmToken,
  });

  // Convertir el objeto a un Map para guardarlo en Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt), // Firestore usa Timestamps
      'preferredCurrency': preferredCurrency,
      'fcmToken': fcmToken,
    };
  }

  // Crear un UserModel a partir de un documento de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final createdAt = map['createdAt'];
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      preferredCurrency: map['preferredCurrency'] ?? 'PEN',
      fcmToken: map['fcmToken'],
    );
  }
}
