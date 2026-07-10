import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String creatorId;
  final DateTime createdAt;
  final String status;

  const EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.creatorId,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory EventModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final date = map['date'];
    final createdAt = map['createdAt'];
    return EventModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      creatorId: map['creatorId'] ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: map['status'] ?? 'active',
    );
  }
}
