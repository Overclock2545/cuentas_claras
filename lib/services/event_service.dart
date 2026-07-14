import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../models/participant_model.dart';

class EventService {
  EventService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  static Future<EventModel> createEvent({
    required String name,
    required String description,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');

    final doc = _events.doc();
    final now = DateTime.now();
    final event = EventModel(
      id: doc.id,
      name: name,
      description: description,
      date: date,
      creatorId: user.uid,
      createdAt: now,
      status: 'active',
    );
    final participant = ParticipantModel(
      id: user.uid,
      name: user.displayName ?? 'Administrador',
      email: user.email?.trim().toLowerCase() ?? '',
      role: 'admin',
      status: 'accepted',
      joinedAt: now,
    );

    await _db.runTransaction((transaction) async {
      transaction.set(doc, event.toMap());
      transaction.set(
        doc.collection('participants').doc(user.uid),
        participant.toMap(),
      );
    });

    return event;
  }

  static Stream<List<EventModel>> getEvents() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // ✅ SOLUCIÓN TEMPORAL: Obtener eventos creados por el usuario
    // Este enfoque es más simple y no requiere cambios en las reglas de Firestore
    // NOTA: Para mostrar eventos donde es participante, desplegaremos nuevas reglas
    
    return _events
        .where('creatorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ✅ TEMPORAL: Comentado hasta que se desplieguen las nuevas reglas de Firestore
  /*
  static Future<List<EventModel>> _eventsFromParticipants(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    String? requireStatus,
  }) async {
    final events = await Future.wait(snapshot.docs.map((participant) async {
      final status = participant.data()['status'] as String?;
      if (requireStatus != null && status != requireStatus) return null;
      final eventReference = participant.reference.parent.parent;
      if (eventReference == null) return null;
      final event = await eventReference.get();
      if (!event.exists || event.data() == null) return null;
      return EventModel.fromMap(event.id, event.data()!);
    }));

    // Usamos un mapa para eliminar duplicados y luego ordenamos.
    final eventsById = {
      for (final event in events.whereType<EventModel>()) event.id: event
    };
    return eventsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  */

  /// Elimina el evento y las subcolecciones que actualmente utiliza la app.
  static Future<void> deleteEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');

    final eventReference = _events.doc(eventId);
    final event = await eventReference.get();
    if (!event.exists) throw Exception('El evento ya no existe.');
    if (event.data()?['creatorId'] != user.uid) {
      throw Exception('No tienes permiso para eliminar este evento.');
    }

    for (final subcollection in ['participants', 'expenses']) {
      final documents = await eventReference.collection(subcollection).get();
      for (var start = 0; start < documents.docs.length; start += 500) {
        final batch = _db.batch();
        final end = (start + 500).clamp(0, documents.docs.length).toInt();
        for (final document in documents.docs.sublist(start, end)) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
    await eventReference.delete();
  }

  static Future<void> updateEvent(EventModel event) =>
      _events.doc(event.id).update(event.toMap());

  static Stream<List<EventModel>> streamPendingInvitations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // ✅ TEMPORAL: Deshabilitado collectionGroup hasta que las reglas se desplieguen
    // Retorna stream vacío de momento
    // TODO: Reactivar cuando se desplieguen las nuevas reglas de Firestore
    return Stream.value([]);
    
    // CÓDIGO ORIGINAL (deshabilitado):
    /*
    return _db
        .collectionGroup('participants')
        .where('id', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) => _eventsFromParticipants(
              snapshot,
              requireStatus: 'pendiente',
            ));
    */
  }

  static Future<void> respondToInvitation(
      {required String eventId, required bool accept}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');
    final participantRef =
        _events.doc(eventId).collection('participants').doc(user.uid);
    if (accept) {
      await participantRef.update(
          {'status': 'accepted', 'name': user.displayName ?? 'Participante'});
    } else {
      await participantRef.delete();
    }
  }
}
