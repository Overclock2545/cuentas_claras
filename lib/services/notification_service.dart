import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/settlement_model.dart';
import '../models/settlement_with_event.dart';

/// El "centro de notificaciones" de la app NO es una colección que se
/// escribe en cada acción (invitar, confirmar, etc.) — eso duplicaría
/// datos que ya existen y correría el riesgo de desincronizarse (ej. si
/// alguien cancela una liquidación, la notificación quedaría huérfana).
///
/// En vez de eso, igual que Deudas y Balance, todo se DERIVA en tiempo
/// real de los datos reales usando `collectionGroup`, siguiendo el mismo
/// patrón que ya usa EventService.streamPendingInvitations() para las
/// invitaciones pendientes.
///
/// Requiere el índice de collection group sobre `settlements` (ver
/// firestore.indexes.json) y la regla `allow list` correspondiente (ver
/// firestore.rules).
class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Todas las liquidaciones pendientes (en cualquier evento) donde el
  /// usuario actual participa, ya sea como quien paga o quien recibe.
  static Stream<List<SettlementWithEvent>> streamMyPendingSettlements() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final asPayer = _db
        .collectionGroup('settlements')
        .where('fromId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);

    final asReceiver = _db
        .collectionGroup('settlements')
        .where('toId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);

    return _mergeAndEnrich(asPayer, asReceiver);
  }

  /// Combina las dos consultas (por si Firestore no soporta bien el OR
  /// entre dos campos distintos en collectionGroup en esta versión), quita
  /// duplicados y agrega el nombre del evento a cada liquidación.
  static Stream<List<SettlementWithEvent>> _mergeAndEnrich(
    Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> a,
    Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> b,
  ) {
    late final StreamController<List<SettlementWithEvent>> controller;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? latestA;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? latestB;
    StreamSubscription? subA;
    StreamSubscription? subB;

    // Cache simple en memoria del nombre de cada evento, para no repetir
    // la misma lectura si el usuario tiene varias liquidaciones del mismo
    // evento.
    final eventNameCache = <String, String>{};

    Future<String> eventName(String eventId) async {
      if (eventNameCache.containsKey(eventId)) return eventNameCache[eventId]!;
      final doc = await _db.collection('events').doc(eventId).get();
      final name = doc.data()?['name'] as String? ?? 'Evento';
      eventNameCache[eventId] = name;
      return name;
    }

    Future<void> emit() async {
      if (latestA == null || latestB == null) return;
      final byId = {
        for (final doc in [...latestA!, ...latestB!])
          doc.id: SettlementModel.fromMap({'id': doc.id, ...doc.data()}),
      };

      final enriched = await Future.wait(byId.values.map((settlement) async {
        return SettlementWithEvent(
          settlement: settlement,
          eventName: await eventName(settlement.eventId),
        );
      }));

      enriched.sort((x, y) => y.settlement.createdAt.compareTo(x.settlement.createdAt));
      if (!controller.isClosed) controller.add(enriched);
    }

    controller = StreamController<List<SettlementWithEvent>>.broadcast(
      onListen: () {
        subA = a.listen((docs) {
          latestA = docs;
          emit();
        }, onError: (_) {
          latestA = latestA ?? [];
          emit();
        });
        subB = b.listen((docs) {
          latestB = docs;
          emit();
        }, onError: (_) {
          latestB = latestB ?? [];
          emit();
        });
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );

    return controller.stream;
  }

  // =============================================================================
  // Firebase Cloud Messaging - Notificaciones Push
  // =============================================================================

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inicializa Firebase Messaging. Debe llamarse al iniciar la app.
  /// Solicita permisos y guarda el token en el usuario.
  static Future<void> initialize() async {
    try {
      // Solicitar permiso para recibir notificaciones
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Obtener y guardar el token FCM
        await _saveFCMToken();

        // Escuchar cambios en el token (cuando se renueva)
        _messaging.onTokenRefresh.listen((token) {
          _saveFCMToken();
        });
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase Messaging: $e');
    }
  }

  /// Obtiene el token FCM actual y lo guarda en Firestore.
  static Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final user = _auth.currentUser;
      if (token != null && user != null) {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        debugPrint('✅ Token FCM guardado: $token');
      }
    } catch (e) {
      debugPrint('❌ Error al guardar token FCM: $e');
    }
  }

  /// Stream de mensajes en foreground. Conecta con el widget que desee
  /// reaccionar a notificaciones mientras la app está activa.
  static Stream<RemoteMessage> get onMessage {
    return FirebaseMessaging.onMessage;
  }

  /// Stream de mensajes en background/terminated. Se devuelve cuando el
  /// usuario abre la app desde una notificación.
  static Stream<RemoteMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp;
  }
}
