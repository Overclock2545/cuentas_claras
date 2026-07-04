import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class EventDetailController extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  double _totalAmount = 0.0;
  double get totalAmount => _totalAmount;

  /// Escucha los gastos y calcula los totales automáticamente
  void setExpenses(List<ExpenseModel> newExpenses) {
    _expenses = newExpenses;
    _totalAmount = newExpenses.fold(0.0, (sum, item) => sum + item.amount);
    // No llamamos a notifyListeners() aquí si se ejecuta durante el build de un StreamBuilder,
    // pero lo dejamos listo por si extendemos lógica de filtros.
  }
}