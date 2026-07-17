import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ProfileController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _preferredCurrency = 'PEN';
  UserModel? _user;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get preferredCurrency => _preferredCurrency;
  UserModel? get user => _user;

  static const List<String> currencies = ['PEN', 'USD', 'EUR', 'COP', 'MXN', 'CLP', 'ARS', 'BRL'];

  Future<void> loadProfile() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final uid = authService.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final user = await _firestoreService.getUser(uid);
      if (user == null) throw Exception('No se encontraron datos del perfil');

      _user = user;
      nameController.text = user.name;
      emailController.text = user.email;
      _preferredCurrency = user.preferredCurrency;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      final uid = authService.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final updatedUser = UserModel(
        id: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        createdAt: _user?.createdAt ?? DateTime.now(),
        preferredCurrency: _preferredCurrency,
      );

      await _firestoreService.saveUser(updatedUser);
      _user = updatedUser;

      // Actualizar displayName en Firebase Auth
      await authService.currentUser?.updateDisplayName(nameController.text.trim());
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setCurrency(String currency) {
    _preferredCurrency = currency;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}