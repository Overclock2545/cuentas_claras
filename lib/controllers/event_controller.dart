import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

class EventController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRespondingToInvitation = false;
  final List<EventModel> _createdEvents = [];

  bool get isLoading => _isLoading;
  bool get isRespondingToInvitation => _isRespondingToInvitation;

  // ✅ FIX: Antes estos eran getters que llamaban a EventService.getEvents()
  // cada vez que se accedía a ellos. Como HomeScreen los usa dentro de
  // build(), cada rebuild (apertura del teclado, notifyListeners, etc.)
  // creaba una consulta NUEVA de Firestore, tirando la suscripción anterior.
  // Eso producía el parpadeo/"aparece y desaparece" reportado. Ahora el
  // stream se crea UNA sola vez (perezosamente) y se reutiliza siempre.
  Stream<List<EventModel>>? _eventsStream;
  Stream<List<EventModel>>? _pendingInvitationsStream;

  // ✅ FIX 2: Como EventController es un singleton que vive durante toda la
  // app (se crea una sola vez en main.dart), el caché de arriba puede quedar
  // atado al usuario que estaba logueado cuando se creó el stream por
  // primera vez. Si el usuario cierra sesión y entra con otro (o el mismo)
  // usuario, ese stream viejo se queda "colgado" sin volver a emitir nunca.
  // Por eso escuchamos los cambios de sesión y invalidamos el caché cada
  // vez que el usuario efectivamente cambia (incluyendo logout → login).
  StreamSubscription<User?>? _authSubscription;
  String? _lastUid;

  EventController() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == _lastUid) return;
      _lastUid = uid;
      _eventsStream = null;
      _pendingInvitationsStream = null;
      _createdEvents.clear();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Stream<List<EventModel>> get events {
    return _eventsStream ??= EventService.getEvents().map(
      (events) {
        final merged = {for (final event in events) event.id: event};
        for (final event in _createdEvents) {
          merged[event.id] = event;
        }
        return merged.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    ).asBroadcastStream();
  }

  Stream<List<EventModel>> get pendingInvitations {
    return _pendingInvitationsStream ??=
        EventService.streamPendingInvitations().asBroadcastStream();
  }

  Future<void> respondToInvitation(String eventId, bool accept) async {
    try {
      _isRespondingToInvitation = true;
      notifyListeners();
      await EventService.respondToInvitation(eventId: eventId, accept: accept);
    } catch (error, stackTrace) {
      debugPrint('❌ Error al responder invitación: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      _isRespondingToInvitation = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String name,
    required String description,
    required DateTime date,
  }) async {
    try {
      // ✅ FIX 1.2: Validaciones antes de intentar guardar
      if (name.trim().isEmpty) {
        throw Exception('El nombre del evento es obligatorio');
      }
      if (date.isBefore(DateTime.now())) {
        throw Exception('La fecha del evento debe ser en el futuro');
      }

      _isLoading = true;
      notifyListeners();

      final event = await EventService.createEvent(
        name: name,
        description: description,
        date: date,
      );

      // ✅ Solo añadir DESPUÉS de confirmar que se guardó en Firestore
      _createdEvents.add(event);
      debugPrint('✅ Evento creado exitosamente: ${event.id}');

      // ✅ Notificar a listeners (por ej, StreamBuilder en HomeScreen)
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('❌ Error al crear evento: $error');
      debugPrintStack(stackTrace: stackTrace);

      // ✅ Limpiar estado local si falló (eventos creados hace más de 5 segundos que no se guardaron)
      _createdEvents.removeWhere((e) =>
          e.createdAt.difference(DateTime.now()).inSeconds.abs() > 5);

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}