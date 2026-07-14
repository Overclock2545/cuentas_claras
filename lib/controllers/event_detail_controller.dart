import 'package:flutter/material.dart';
import '../models/expense_model.dart';

/// DEPRECATED: La lógica de este controlador ha sido simplificada y movida
/// directamente a la vista `EventDetailScreen` para evitar anti-patrones
/// con `addPostFrameCallback` y `StreamBuilder`.
/// Se puede eliminar este archivo y su referencia en el `main.dart` o donde se provea.
class EventDetailController extends ChangeNotifier {
  final List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;
}
