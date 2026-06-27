import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Guardar o actualizar los datos de un usuario en la colección 'users'
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al guardar el usuario en Firestore: $e');
    }
  }

  // Obtener los datos de un usuario por su UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener el usuario desde Firestore: $e');
    }
  }
}