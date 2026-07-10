import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para usar Timestamp y Firestore
import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance; // Instancia estática de Firestore

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // INICIO DE SESIÓN
  static Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // REGISTRO EXPANDIDO (Guarda también en Firestore)
  static Future<UserCredential> register({
    required String
        name, // Añadimos el nombre para guardarlo en la base de datos
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Crear usuario en Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Actualizar el nombre en el perfil nativo de Firebase Auth
        await firebaseUser.updateDisplayName(name);

        // 2. Crear el modelo con los datos del usuario para Firestore
        UserModel newUser = UserModel(
          id: firebaseUser.uid,
          name: name,
          email: normalizedEmail,
          createdAt: DateTime.now(),
        );

        // 3. Guardar el documento en la colección 'users' usando el UID como ID del documento
        await _db.collection('users').doc(newUser.id).set(
              newUser.toMap(),
              SetOptions(merge: true),
            );
      }

      return userCredential;
    } catch (e) {
      rethrow; // Delegamos el manejo del error al controlador de la pantalla
    }
  }

  // CERRAR SESIÓN
  static Future<void> signOut() {
    return _auth.signOut();
  }
}
