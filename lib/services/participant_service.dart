import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/participant_model.dart';

class ParticipantService {
  ParticipantService._();

  static Future<void> addParticipant({
    required DocumentReference<Map<String, dynamic>> eventRef,
    required ParticipantModel participant,
  }) async {
    await eventRef
        .collection('participants')
        .doc(participant.id)
        .set(participant.toMap());
  }
}