import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

class EventController extends ChangeNotifier {
  bool _isLoading =false;

  bool get isLoading => _isLoading;

  Stream<List<EventModel>> get events =>
      EventService.getEvents();

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

    debugPrint('✅ Evento creado correctamente');
  } catch (e, stackTrace) {
    debugPrint('❌ Error al crear evento: $e');
    debugPrint(stackTrace.toString());
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}