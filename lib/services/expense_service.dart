import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  ExpenseService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene los gastos de un evento específico ordenados por fecha
  static Stream<List<ExpenseModel>> streamExpenses(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data()))
            .toList());
  }

  /// Registra un nuevo gasto dentro de la subcolección del evento
  static Future<void> addExpense(ExpenseModel expense) async {
    final docRef = _db
        .collection('events')
        .doc(expense.eventId)
        .collection('expenses')
        .doc(); // Genera un ID automático para el gasto

    // Creamos una copia del modelo pero asignándole el ID generado
    final finalExpense = ExpenseModel(
      id: docRef.id,
      eventId: expense.eventId,
      title: expense.title,
      amount: expense.amount,
      paidById: expense.paidById,
      paidByName: expense.paidByName,
      createdAt: expense.createdAt,
    );

    await docRef.set(finalExpense.toMap());
  }
}