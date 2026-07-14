import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense(String eventId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Usuario no identificado');

      // Obtenemos el documento del usuario desde Firestore para asegurar el nombre más reciente
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final paidByName = userDoc.data()?['name'] ?? currentUser.displayName ?? 'Participante';


      final newExpense = ExpenseModel(
        id: '', // El servicio generará el ID automáticamente
        eventId: eventId,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paidById: currentUser.uid,
        paidByName: paidByName,
        createdAt: DateTime.now(),
      );

      await ExpenseService.addExpense(newExpense);

      if (mounted) {
        Navigator.pop(context); // Regresa al detalle del evento
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto registrado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el gasto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recibimos el ID del evento desde los argumentos de la ruta
    final eventId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Gasto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿En qué se gastó y cuánto fue?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              
              // Campo: Descripción del gasto
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del gasto',
                  hintText: 'Ej. Compras del supermercado',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty 
                    ? 'Ingresa una descripción' 
                    : null,
              ),
              const SizedBox(height: 16),

              // Campo: Monto
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto (S/)',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido';
                  if (double.parse(value) <= 0) return 'El monto debe ser mayor a cero';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botón de guardar
              ElevatedButton(
                onPressed: _isSaving ? null : () => _submitExpense(eventId),
                child: _isSaving 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text('Registrar Gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}