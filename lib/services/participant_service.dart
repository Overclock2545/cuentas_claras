import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/participant_model.dart';

class ParticipantService {
  ParticipantService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Verifica si el usuario actual es admin del evento
  static Future<bool> _isAdmin(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final eventDoc = await _db.collection('events').doc(eventId).get();
    return eventDoc.data()?['creatorId'] == user.uid;
  }

  /// Busca un usuario por correo e intenta invitarlo al evento.
  ///
  /// - Si quien invita es el **admin** del evento → crea el participante con
  ///   status 'pending' (invitación directa, como antes).
  /// - Si quien invita es un **participante** → crea el participante con
  ///   status 'suggested' y el campo `suggestedBy` con su UID. El admin
  ///   verá la sugerencia y podrá aprobarla (cambiando a 'pending') o
  ///   rechazarla (eliminando el documento).
  static Future<void> inviteUserByEmail({
    required String eventId,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión para invitar.');

    final cleanEmail = email.trim().toLowerCase();

    // Validación temprana del email
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
      final existingStatus = participantDoc.data()?['status'] as String?;
      if (existingStatus == 'suggested') {
        throw Exception(
          'Este usuario ya fue sugerido por otro participante. '
          'El administrador revisará la sugerencia.',
        );
      }
      throw Exception(
        'Este usuario ya forma parte del evento o ya tiene una invitación pendiente.',
      );
    }

    // 3. Determinar si quien invita es admin o participante
    final isAdmin = await _isAdmin(eventId);

    // 4. Obtener el nombre de quien sugiere (para mostrarlo en UI)
    String? suggesterName;
    if (!isAdmin) {
      final suggesterDoc = await _db.collection('users').doc(user.uid).get();
      suggesterName = suggesterDoc.data()?['name'] as String? ?? user.displayName ?? 'Alguien';
    }

    // 5. Crear el nuevo participante
    final newParticipant = ParticipantModel(
      id: targetUid,
      name: targetName,
      email: cleanEmail,
      role: 'participante',
      status: isAdmin ? 'pending' : 'suggested',
      joinedAt: DateTime.now(),
      suggestedBy: isAdmin ? null : user.uid,
      suggestedByName: isAdmin ? null : suggesterName,
    );

    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(targetUid)
          .set(newParticipant.toMap());

      if (isAdmin) {
        debugPrint('✅ Invitación enviada exitosamente a $cleanEmail (UID: $targetUid)');
      } else {
        debugPrint('✅ Sugerencia de invitación enviada al admin para $cleanEmail (UID: $targetUid)');
      }
    } catch (e) {
      debugPrint('❌ Error al crear participante: $e');
      throw Exception(
        'No se pudo enviar la invitación. Verifica los permisos y vuelve a intentar. Error: $e',
      );
    }
  }

  /// El admin aprueba una sugerencia: cambia status de 'suggested' a 'pending'
  /// para que el usuario sugerido reciba la invitación.
  static Future<void> approveSuggestion({
    required String eventId,
    required String participantId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión.');

    await _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(participantId)
        .update({'status': 'pending', 'suggestedBy': null, 'suggestedByName': null});
  }

  /// El admin rechaza una sugerencia: elimina el documento del participante.
  static Future<void> rejectSuggestion({
    required String eventId,
    required String participantId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión.');

    await _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(participantId)
        .delete();
  }
}
