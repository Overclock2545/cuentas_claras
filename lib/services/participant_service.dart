import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/participant_model.dart';

class ParticipantService {
  ParticipantService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Transmite en tiempo real los participantes asignados a un evento
  static Stream<List<ParticipantModel>> streamParticipants(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipantModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Busca un usuario por correo e intenta invitarlo al evento
  static Future<void> inviteUserByEmail({
    required String eventId,
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Buscar si el usuario existe en el sistema global
    final userQuery = await _db
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('El correo ingresado no está registrado en la app.');
    }

    final userDoc = userQuery.docs.first;
    final userData = userDoc.data();
    final String targetUid = userDoc.id;
    final String targetName = userData['name'] ?? 'Usuario';

    // 2. Verificar si ya fue agregado previamente al evento
    final participantDoc = await _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(targetUid)
        .get();

    if (participantDoc.exists) {
      throw Exception('Este usuario ya forma parte del evento o tiene una invitación.');
    }

    // 3. Crear el nuevo participante con estado pendiente
    final newParticipant = ParticipantModel(
      id: targetUid,
      name: targetName,
      email: cleanEmail,
      role: 'participante',
      status: 'pendiente',
      joinedAt: DateTime.now(),
    );

    // Guardar en la subcolección del evento
    await _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(targetUid)
        .set(newParticipant.toMap());
  }
}