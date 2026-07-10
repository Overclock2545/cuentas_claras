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

  static Future<void> createEvent({
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
        status: 'active');
    final participant = ParticipantModel(
        id: user.uid,
        name: user.displayName ?? 'Administrador',
        email: user.email?.trim().toLowerCase() ?? '',
        role: 'admin',
        status: 'accepted',
        joinedAt: now);

    await _db.runTransaction((transaction) async {
      transaction.set(doc, event.toMap());
      transaction.set(
          doc.collection('participants').doc(user.uid), participant.toMap());
    });
  }

  /// Emite los eventos creados por el usuario y aquellos cuyas invitaciones aceptó.
  static Stream<List<EventModel>> getEvents() {
    final user = _auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (user == null || email == null) return Stream.value([]);

    final ownedEvents = _events
        .where('creatorId', isEqualTo: user.uid)
        .snapshots()
        .map(_eventsFromDocuments);
    final joinedEvents = _db
        .collectionGroup('participants')
        .where('id', isEqualTo: user.uid)
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap(_eventsFromParticipants);
    return _mergeEventStreams(ownedEvents, joinedEvents);
  }

  static List<EventModel> _eventsFromDocuments(
          QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();

  static Future<List<EventModel>> _eventsFromParticipants(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final events = await Future.wait(snapshot.docs.map((participant) async {
      final eventReference = participant.reference.parent.parent;
      if (eventReference == null) return null;
      final event = await eventReference.get();
      if (!event.exists || event.data() == null) return null;
      return EventModel.fromMap(event.id, event.data()!);
    }));
    return events.whereType<EventModel>().toList();
  }

  static Stream<List<EventModel>> _mergeEventStreams(
      Stream<List<EventModel>> ownedEvents,
      Stream<List<EventModel>> joinedEvents) {
    final controller = StreamController<List<EventModel>>();
    var owned = <EventModel>[];
    var joined = <EventModel>[];
    var hasOwned = false;
    var hasJoined = false;

    void emit() {
      if (!hasOwned || !hasJoined) return;
      final eventsById = {
        for (final event in [...owned, ...joined]) event.id: event
      };
      final events = eventsById.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      controller.add(events);
    }

    late final StreamSubscription<List<EventModel>> ownedSubscription;
    late final StreamSubscription<List<EventModel>> joinedSubscription;
    controller.onListen = () {
      ownedSubscription = ownedEvents.listen((events) {
        owned = events;
        hasOwned = true;
        emit();
      }, onError: controller.addError);
      joinedSubscription = joinedEvents.listen((events) {
        joined = events;
        hasJoined = true;
        emit();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await ownedSubscription.cancel();
      await joinedSubscription.cancel();
    };
    return controller.stream;
  }

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
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    if (email == null) return Stream.value([]);
    return _db
        .collectionGroup('participants')
        .where('id', isEqualTo: _auth.currentUser!.uid)
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pendiente')
        .snapshots()
        .asyncMap(_eventsFromParticipants);
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
