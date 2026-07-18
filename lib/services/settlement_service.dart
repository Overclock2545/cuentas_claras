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

  /// Registra un pago entre el usuario autenticado y otro participante.
  /// Puede registrarlo cualquiera de los dos: [currentUserIsPayer] indica
  /// si quien registra es quien pagó (true) o quien recibió el pago
  /// (false, "me pagaron"). Siempre nace en 'pending': la CONTRAPARTE de
  /// quien registra es quien debe confirmarlo.
  static Future<void> addSettlement({
    required String eventId,
    required String otherPartyId,
    required String otherPartyName,
    required double amount,
    required bool currentUserIsPayer,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay un usuario autenticado.');

    if (amount <= 0) throw Exception('El monto debe ser mayor a cero.');
    if (otherPartyId == user.uid) {
      throw Exception('Selecciona a otra persona distinta de ti.');
    }

    // Obtenemos el nombre más reciente desde Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final myName =
        userDoc.data()?['name'] ?? user.displayName ?? 'Participante';

    final fromId = currentUserIsPayer ? user.uid : otherPartyId;
    final fromName = currentUserIsPayer ? myName : otherPartyName;
    final toId = currentUserIsPayer ? otherPartyId : user.uid;
    final toName = currentUserIsPayer ? otherPartyName : myName;

    final docRef = _db
        .collection('events')
        .doc(eventId)
        .collection('settlements')
        .doc();

    final settlement = SettlementModel(
      id: docRef.id,
      eventId: eventId,
      fromId: fromId,
      fromName: fromName,
      toId: toId,
      toName: toName,
      amount: amount,
      createdAt: DateTime.now(),
      status: 'pending',
      registeredBy: user.uid,
    );

    await docRef.set(settlement.toMap());
  }

  /// Confirma una liquidación pendiente. Debe llamarlo la contraparte de
  /// quien la registró (lo valida también la regla de Firestore).
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

  /// Cancela una liquidación mientras siga pendiente. Solo puede hacerlo
  /// quien la registró — una vez CONFIRMADA por la contraparte, ya no se
  /// puede borrar unilateralmente (protege el balance de manipulaciones).
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
    if (data['status'] == 'confirmed') {
      throw Exception('No se puede eliminar un pago ya confirmado.');
    }
    if (data['registeredBy'] != user.uid) {
      throw Exception('Solo quien registró el pago puede eliminarlo.');
    }

    await docRef.delete();
  }
}