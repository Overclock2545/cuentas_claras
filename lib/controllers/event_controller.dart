import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

class EventController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRespondingToInvitation = false;
  final List<EventModel> _createdEvents = [];

  bool get isLoading => _isLoading;
  bool get isRespondingToInvitation => _isRespondingToInvitation;

  Stream<List<EventModel>> get events => EventService.getEvents().map(
        (events) {
          final merged = {for (final event in events) event.id: event};
          for (final event in _createdEvents) {
            merged[event.id] = event;
          }
          return merged.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        },
      );
  
  Stream<List<EventModel>> get pendingInvitations =>
      EventService.streamPendingInvitations();

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
