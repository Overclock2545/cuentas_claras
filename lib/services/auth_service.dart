import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para usar Timestamp y Firestore
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth? auth;
  final FirebaseFirestore? db;

  AuthService({this.auth, this.db});

  User? get currentUser {
    try {
      return auth?.currentUser ?? FirebaseAuth.instance.currentUser;
    } on FirebaseException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return auth?.authStateChanges() ?? FirebaseAuth.instance.authStateChanges();
    } on FirebaseException catch (_) {
      return const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // INICIO DE SESIÓN
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final authInstance = auth ?? FirebaseAuth.instance;
      return authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseException catch (_) {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // REGISTRO EXPANDIDO (Guarda también en Firestore)
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final authInstance = auth ?? FirebaseAuth.instance;
      final dbInstance = db ?? FirebaseFirestore.instance;

      // 1. Crear usuario en Firebase Authentication
      final userCredential = await authInstance.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);

        final newUser = UserModel(
          id: firebaseUser.uid,
          name: name,
          email: normalizedEmail,
          createdAt: DateTime.now(),
        );

        await dbInstance.collection('users').doc(newUser.id).set(
              newUser.toMap(),
              SetOptions(merge: true),
            );
      }

      return userCredential;
    } catch (_) {
      rethrow;
    }
  }

  // CERRAR SESIÓN
  Future<void> signOut() async {
    try {
      await (auth ?? FirebaseAuth.instance).signOut();
    } on FirebaseException catch (_) {
      return;
    } catch (_) {
      return;
    }
  }
}

