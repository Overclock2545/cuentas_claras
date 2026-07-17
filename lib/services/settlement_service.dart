import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/settlement_model.dart';

class SettlementService {
  SettlementService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream en tiempo real de las liquidaciones de un evento.
  static Stream<List<SettlementModel>> streamSettlements(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('settlements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SettlementModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Registra un nuevo pago entre dos participantes.
  /// El usuario autenticado será el que paga (fromId).
  static Future<void> addSettlement({
    required String eventId,
    required String toId,
    required String toName,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');

    if (amount <= 0) throw Exception('El monto debe ser mayor a cero.');

    final fromName = user.displayName ?? 'Participante';

    // Obtenemos el nombre más reciente desde Firestore
    final userDoc =
        await _db.collection('users').doc(user.uid).get();
    final freshName = userDoc.data()?['name'] ?? fromName;

    final docRef = _db
        .collection('events')
        .doc(eventId)
        .collection('settlements')
        .doc();

    final settlement = SettlementModel(
      id: docRef.id,
      eventId: eventId,
      fromId: user.uid,
      fromName: freshName,
      toId: toId,
      toName: toName,
      amount: amount,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await docRef.set(settlement.toMap());
  }

  /// Confirma una liquidación (solo el receptor puede hacerlo).
  static Future<void> confirmSettlement({
    required String eventId,
    required String settlementId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');

    final docRef = _db
        .collection('events')
        .doc(eventId)
        .collection('settlements')
        .doc(settlementId);

    await docRef.update({'status': 'confirmed'});
  }

  /// Elimina una liquidación (solo el creador puede hacerlo).
  static Future<void> deleteSettlement({
    required String eventId,
    required String settlementId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');

    final docRef = _db
        .collection('events')
        .doc(eventId)
        .collection('settlements')
        .doc(settlementId);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception('La liquidación ya no existe.');

    final data = doc.data() as Map<String, dynamic>;
    if (data['fromId'] != user.uid) {
      throw Exception('Solo quien registró el pago puede eliminarlo.');
    }

    await docRef.delete();
  }
}