import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/participant_model.dart';
import '../models/event_model.dart';

class EventService {
  EventService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');


/// Crear un nuevo evento
static Future<void> createEvent({
  required String name,
  required String description,
  required DateTime date,
}) async {
  final user = _auth.currentUser;

  if (user == null) {
    throw Exception('No hay un usuario autenticado.');
  }

  final doc = _events.doc();

  final event = EventModel(
    id: doc.id,
    name: name,
    description: description,
    date: date,
    creatorId: user.uid,
    createdAt: DateTime.now(),
    status: 'active',
  );

  final participant = ParticipantModel(
    id: user.uid,
    role: 'admin',
    status: 'accepted',
    joinedAt: DateTime.now(),
  );

  await _db.runTransaction((transaction) async {
    // Crear el documento del evento
    transaction.set(
      doc,
      event.toMap(),
    );

    // Agregar automáticamente al creador como administrador
    transaction.set(
      doc
          .collection('participants')
          .doc(user.uid),
      participant.toMap(),
    );
  });
}


/// Obtener únicamente los eventos del usuario autenticado
  static Stream<List<EventModel>> getEvents() {
    final user = _auth.currentUser;

    // Si no hay sesión iniciada (salvaguarda), devolvemos un flujo vacío
    if (user == null) {
      return Stream.value([]);
    }

    // Filtramos los documentos donde 'creatorId' coincida con el usuario actual
    return _events
        .where('creatorId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => EventModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// Eliminar un evento
  static Future<void> deleteEvent(String eventId) async {
  await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
}

  /// Actualizar un evento
  static Future<void> updateEvent(EventModel event) async {
    await _events.doc(event.id).update(event.toMap());
  }

  
}