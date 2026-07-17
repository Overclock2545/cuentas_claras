import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Eventos creados por el usuario actual.
  static Stream<List<EventModel>> _createdEventsStream(String uid) {
    return _events
        .where('creatorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Eventos donde el usuario aparece como participante (usa collectionGroup).
  /// Requiere que la regla `allow list` de `participants` esté desplegada
  /// en Firebase (ver firestore.rules) y que exista un índice de
  /// collection group para el campo `id` en `participants`.
  static Stream<List<EventModel>> _participantEventsStream(
    String uid, {
    required String requireStatus,
  }) {
    return _db
        .collectionGroup('participants')
        .where('id', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) => _eventsFromParticipants(
              snapshot,
              requireStatus: requireStatus,
            ));
  }

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

  /// Combina dos streams de listas de eventos en uno solo, fusionando por id.
  /// Implementado a mano (sin rxdart) porque el proyecto decidió no usar esa
  /// dependencia.
  ///
  /// IMPORTANTE: si una de las dos fuentes falla (por ejemplo, la query de
  /// `collectionGroup` por falta de índice o de reglas), NO tumbamos el
  /// stream completo. Simplemente esa fuente se trata como lista vacía y se
  /// sigue mostrando lo que sí funciona (ej: "Mis Eventos" creados por mí).
  static Stream<List<EventModel>> _mergeEventStreams(
    Stream<List<EventModel>> a,
    Stream<List<EventModel>> b,
  ) {
    late final StreamController<List<EventModel>> controller;
    List<EventModel>? latestA;
    List<EventModel>? latestB;
    StreamSubscription<List<EventModel>>? subA;
    StreamSubscription<List<EventModel>>? subB;

    void emit() {
      if (latestA == null || latestB == null) return;
      final merged = <String, EventModel>{
        for (final event in latestA!) event.id: event,
        for (final event in latestB!) event.id: event,
      };
      final list = merged.values.toList()
        ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      controller.add(list);
    }

    controller = StreamController<List<EventModel>>.broadcast(
      onListen: () {
        subA = a.listen(
          (value) {
            latestA = value;
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('⚠️ Falló el stream de eventos creados: $error');
            // No matamos el stream combinado: tratamos esta fuente como vacía.
            latestA = latestA ?? [];
            emit();
          },
        );
        subB = b.listen(
          (value) {
            latestB = value;
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('⚠️ Falló el stream de eventos como participante: $error');
            // No matamos el stream combinado: tratamos esta fuente como vacía.
            latestB = latestB ?? [];
            emit();
          },
        );
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );

    return controller.stream;
  }

  /// Eventos creados por el usuario + eventos donde es participante aceptado.
  static Stream<List<EventModel>> getEvents() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final created = _createdEventsStream(user.uid);
    final asParticipant =
        _participantEventsStream(user.uid, requireStatus: 'accepted');

    return _mergeEventStreams(created, asParticipant);
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
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _participantEventsStream(user.uid, requireStatus: 'pending');
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