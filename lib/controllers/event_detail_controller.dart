import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class EventDetailController extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  double _totalAmount = 0.0;
  double get totalAmount => _totalAmount;

  /// Escucha los gastos y calcula los totales automáticamente
  void setExpenses(List<ExpenseModel> newExpenses) {
    final newTotal = newExpenses.fold(0.0, (sum, item) => sum + item.amount);
    final hasChanged =
        _totalAmount != newTotal || _expenses.length != newExpenses.length;

    _expenses = newExpenses;
    _totalAmount = newTotal;

    // La actualización se programa después del build en la vista, por lo que
    // es seguro notificar para refrescar el total mostrado.
    if (hasChanged) {
      notifyListeners();
    }
  }
}
