import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

class EventController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRespondingToInvitation = false;

  bool get isLoading => _isLoading;
  bool get isRespondingToInvitation => _isRespondingToInvitation;

  Stream<List<EventModel>> get events => EventService.getEvents();
  Stream<List<EventModel>> get pendingInvitations =>
      EventService.streamPendingInvitations();

  Future<void> respondToInvitation(String eventId, bool accept) async {
    try {
      _isRespondingToInvitation = true;
      notifyListeners();
      await EventService.respondToInvitation(eventId: eventId, accept: accept);
    } catch (error, stackTrace) {
      debugPrint('Error al responder invitación: $error');
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
      _isLoading = true;
      notifyListeners();
      await EventService.createEvent(
        name: name,
        description: description,
        date: date,
      );
    } catch (error, stackTrace) {
      debugPrint('Error al crear evento: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
