import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

    // ✅ FIX 2.2: Validación temprana del email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      throw Exception('El email "$cleanEmail" no es válido');
    }

    // 1. Buscar si el usuario existe en el sistema global
    final userQuery = await _db
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      // ✅ FIX 2.2: Mensaje de error más descriptivo y accionable
      throw Exception(
        'No encontramos a ningún usuario registrado con el email "$cleanEmail". '
        'Asegúrate de que el usuario esté registrado en Cuentas Claras.',
      );
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
      throw Exception(
        'Este usuario ya forma parte del evento o ya tiene una invitación pendiente.',
      );
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

    // ✅ FIX 2.1: Con la nueva regla de Firestore, esto debería funcionar ahora
    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(targetUid)
          .set(newParticipant.toMap());
      
      debugPrint('✅ Invitación enviada exitosamente a $cleanEmail (UID: $targetUid)');
    } catch (e) {
      debugPrint('❌ Error al crear participante: $e');
      throw Exception(
        'No se pudo enviar la invitación. Verifica los permisos y vuelve a intentar. Error: $e',
      );
    }
  }
}