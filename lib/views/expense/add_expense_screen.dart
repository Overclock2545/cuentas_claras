import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import '../../services/expense_service.dart';
import '../../services/participant_service.dart';

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

  // --- División del gasto ---
  bool _loadingParticipants = true;
  String? _participantsError;
  List<ParticipantModel> _participants = [];
  final Set<String> _selectedIds = {};
  ExpenseSplitType _splitType = ExpenseSplitType.equal;
  ExpenseCategory _category = ExpenseCategory.other;

  // Un controller de texto por participante, reutilizado tanto para
  // porcentaje como para monto exacto (solo se usa el que corresponda).
  final Map<String, TextEditingController> _shareControllers = {};

  String? _eventId;
  // Si no es null, estamos editando este gasto en vez de crear uno nuevo.
  ExpenseModel? _editingExpense;
  bool get _isEditing => _editingExpense != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo necesitamos leer los argumentos una vez, la primera vez que
    // conocemos el eventId (evita relanzar la carga en cada rebuild).
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String eventId = args['eventId'] as String;
    if (_eventId == eventId) return;
    _eventId = eventId;

    final existing = args['expense'] as ExpenseModel?;
    if (existing != null) {
      _editingExpense = existing;
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _splitType = existing.splitType;
      _category = existing.category;
    }

    _loadParticipants(eventId);
  }

  Future<void> _loadParticipants(String eventId) async {
    try {
      final participants = await ParticipantService.streamParticipants(eventId).first;
      final accepted =
          participants.where((p) => p.status == 'accepted').toList();
      if (!mounted) return;

      // Si estamos editando, preseleccionamos a quienes ya tenían una
      // parte del gasto y precargamos sus montos/porcentajes.
      final existing = _editingExpense;
      final existingSplitsById = {
        for (final s in existing?.splits ?? const <ExpenseSplitModel>[])
          s.participantId: s,
      };

      setState(() {
        _participants = accepted;
        _selectedIds
          ..clear()
          ..addAll(existing != null
              ? existingSplitsById.keys
              : accepted.map((p) => p.id));
        for (final p in accepted) {
          final controller = TextEditingController();
          final split = existingSplitsById[p.id];
          if (split != null && existing != null) {
            if (existing.splitType == ExpenseSplitType.percentage &&
                existing.amount > 0) {
              final pct = split.amount / existing.amount * 100;
              controller.text = pct.toStringAsFixed(1);
            } else if (existing.splitType == ExpenseSplitType.fixed) {
              controller.text = split.amount.toStringAsFixed(2);
            }
          }
          _shareControllers[p.id] = controller;
        }
        _loadingParticipants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _participantsError = 'No se pudieron cargar los participantes: $e';
        _loadingParticipants = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0;

  List<ParticipantModel> get _selectedParticipants =>
      _participants.where((p) => _selectedIds.contains(p.id)).toList();

  /// Redondea a centavos (2 decimales) evitando errores de coma flotante.
  int _toCents(double value) => (value * 100).round();

  /// Reparte [totalCents] entre [count] personas en partes iguales,
  /// repartiendo el resto de centavos (por redondeo) entre las primeras
  /// personas para que la suma cierre exacto con el total.
  List<int> _splitCentsEqually(int totalCents, int count) {
    final base = totalCents ~/ count;
    final remainder = totalCents % count;
    return List.generate(
      count,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  /// Calcula los ExpenseSplitModel finales según el tipo de división actual.
  /// Devuelve null si la división no es válida (no cierra con el total).
  List<ExpenseSplitModel>? _computeSplits() {
    final selected = _selectedParticipants;
    if (selected.isEmpty) return null;

    final totalCents = _toCents(_totalAmount);

    switch (_splitType) {
      case ExpenseSplitType.equal:
        final parts = _splitCentsEqually(totalCents, selected.length);
        return [
          for (var i = 0; i < selected.length; i++)
            ExpenseSplitModel(
              participantId: selected[i].id,
              participantName: selected[i].name,
              amount: parts[i] / 100,
            ),
        ];

      case ExpenseSplitType.percentage:
        double sumPct = 0;
        final pctById = <String, double>{};
        for (final p in selected) {
          final pct = double.tryParse(_shareControllers[p.id]!.text.trim()) ?? 0;
          pctById[p.id] = pct;
          sumPct += pct;
        }
        if ((sumPct - 100).abs() > 0.01) return null;

        // Convertimos a centavos y ajustamos el redondeo en el último para
        // que la suma cierre exacto con el total.
        final cents = <int>[];
        var assigned = 0;
        for (var i = 0; i < selected.length; i++) {
          final c = (totalCents * (pctById[selected[i].id]! / 100)).round();
          cents.add(c);
          assigned += c;
        }
        final diff = totalCents - assigned;
        if (cents.isNotEmpty) cents[cents.length - 1] += diff;

        return [
          for (var i = 0; i < selected.length; i++)
            ExpenseSplitModel(
              participantId: selected[i].id,
              participantName: selected[i].name,
              amount: cents[i] / 100,
            ),
        ];

      case ExpenseSplitType.fixed:
        double sum = 0;
        final amountById = <String, double>{};
        for (final p in selected) {
          final amt = double.tryParse(_shareControllers[p.id]!.text.trim()) ?? 0;
          amountById[p.id] = amt;
          sum += amt;
        }
        if ((_toCents(sum) - totalCents).abs() > 1) return null;

        return [
          for (final p in selected)
            ExpenseSplitModel(
              participantId: p.id,
              participantName: p.name,
              amount: amountById[p.id]!,
            ),
        ];
    }
  }

  String? _splitValidationMessage() {
    if (_selectedParticipants.isEmpty) {
      return 'Selecciona al menos un participante.';
    }
    if (_splitType == ExpenseSplitType.percentage) {
      final sum = _selectedParticipants.fold<double>(
        0,
        (acc, p) => acc + (double.tryParse(_shareControllers[p.id]!.text.trim()) ?? 0),
      );
      if ((sum - 100).abs() > 0.01) {
        return 'Los porcentajes deben sumar 100% (llevas ${sum.toStringAsFixed(1)}%).';
      }
    }
    if (_splitType == ExpenseSplitType.fixed) {
      final sum = _selectedParticipants.fold<double>(
        0,
        (acc, p) => acc + (double.tryParse(_shareControllers[p.id]!.text.trim()) ?? 0),
      );
      if ((sum - _totalAmount).abs() > 0.01) {
        return 'Los montos deben sumar S/ ${_totalAmount.toStringAsFixed(2)} (llevas S/ ${sum.toStringAsFixed(2)}).';
      }
    }
    return null;
  }

  Future<void> _submitExpense(String eventId) async {
    if (!_formKey.currentState!.validate()) return;

    final splitError = _splitValidationMessage();
    if (splitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(splitError)),
      );
      return;
    }

    final splits = _computeSplits();
    if (splits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la división del gasto.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updated = _editingExpense!.copyWith(
          title: _titleController.text.trim(),
          amount: _totalAmount,
          splitType: _splitType,
          splits: splits,
          category: _category,
        );
        await ExpenseService.updateExpense(updated);
      } else {
        final currentUser = authService.currentUser;
        if (currentUser == null) throw Exception('Usuario no identificado');

        // Obtenemos el documento del usuario desde Firestore para asegurar el nombre más reciente
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        final paidByName = userDoc.data()?['name'] ?? currentUser.displayName ?? 'Participante';

        final newExpense = ExpenseModel(
          id: '', // El servicio generará el ID automáticamente
          eventId: eventId,
          title: _titleController.text.trim(),
          amount: _totalAmount,
          paidById: currentUser.uid,
          paidByName: paidByName,
          createdAt: DateTime.now(),
          splitType: _splitType,
          splits: splits,
          category: _category,
        );

        await ExpenseService.addExpense(newExpense);
      }

      if (mounted) {
        Navigator.pop(context); // Regresa al detalle del evento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing
              ? 'Gasto actualizado con éxito'
              : 'Gasto registrado con éxito')),
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
    final eventId = _eventId!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Gasto' : 'Nuevo Gasto'),
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
                onChanged: (_) => setState(() {}), // refresca las vistas previas
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido';
                  if (double.parse(value) <= 0) return 'El monto debe ser mayor a cero';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Categoría
              Text(
                'Categoría',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 28),

              Text(
                '¿Cómo se divide?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              _buildParticipantsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _submitExpense(eventId),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Guardar cambios' : 'Registrar Gasto'),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final selected = _category == category;
        return ChoiceChip(
          label: Text(category.label),
          avatar: Icon(category.icon, size: 18),
          selected: selected,
          onSelected: (_) => setState(() => _category = category),
        );
      }).toList(),
    );
  }

  Widget _buildParticipantsSection() {
    if (_loadingParticipants) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_participantsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(_participantsError!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_participants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Este evento todavía no tiene participantes que hayan aceptado la invitación.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector del tipo de división
        SegmentedButton<ExpenseSplitType>(
          segments: const [
            ButtonSegment(
              value: ExpenseSplitType.equal,
              label: Text('Igual'),
              icon: Icon(Icons.balance),
            ),
            ButtonSegment(
              value: ExpenseSplitType.percentage,
              label: Text('Porcentaje'),
              icon: Icon(Icons.percent),
            ),
            ButtonSegment(
              value: ExpenseSplitType.fixed,
              label: Text('Monto exacto'),
              icon: Icon(Icons.tag),
            ),
          ],
          selected: {_splitType},
          onSelectionChanged: (selection) {
            setState(() => _splitType = selection.first);
          },
        ),
        const SizedBox(height: 16),

        Text(
          'Participantes en este gasto',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),

        ..._participants.map(_buildParticipantRow),

        const SizedBox(height: 12),
        _buildSplitSummary(),
      ],
    );
  }

  Widget _buildParticipantRow(ParticipantModel participant) {
    final selected = _selectedIds.contains(participant.id);
    final selectedCount = _selectedParticipants.length;

    Widget trailing;
    switch (_splitType) {
      case ExpenseSplitType.equal:
        final preview = selected && selectedCount > 0
            ? _totalAmount / selectedCount
            : 0.0;
        trailing = SizedBox(
          width: 90,
          child: Text(
            selected ? 'S/ ${preview.toStringAsFixed(2)}' : '—',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
        break;
      case ExpenseSplitType.percentage:
        trailing = SizedBox(
          width: 90,
          child: TextField(
            enabled: selected,
            controller: _shareControllers[participant.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              isDense: true,
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
        );
        break;
      case ExpenseSplitType.fixed:
        trailing = SizedBox(
          width: 100,
          child: TextField(
            enabled: selected,
            controller: _shareControllers[participant.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              isDense: true,
              prefixText: 'S/ ',
              border: OutlineInputBorder(),
            ),
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedIds.add(participant.id);
                } else {
                  _selectedIds.remove(participant.id);
                }
              });
            },
          ),
          Expanded(
            child: Text(
              participant.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSplitSummary() {
    if (_splitType == ExpenseSplitType.equal) return const SizedBox.shrink();

    final sum = _selectedParticipants.fold<double>(
      0,
      (acc, p) => acc + (double.tryParse(_shareControllers[p.id]!.text.trim()) ?? 0),
    );
    final target = _splitType == ExpenseSplitType.percentage ? 100.0 : _totalAmount;
    final ok = (sum - target).abs() <= 0.01;
    final label = _splitType == ExpenseSplitType.percentage
        ? '${sum.toStringAsFixed(1)}% de 100%'
        : 'S/ ${sum.toStringAsFixed(2)} de S/ ${target.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (ok ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline,
              color: ok ? Colors.green : Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}