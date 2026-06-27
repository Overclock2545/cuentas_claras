import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/event_controller.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;

@override
void dispose() {
  _nameController.dispose();
  _descriptionController.dispose();
  super.dispose();
}

Future<void> _pickDate() async {

  final date = await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime(2035),
    initialDate: DateTime.now(),
  );

  if (date != null) {
    setState(() {
      _selectedDate = date;
    });
  }

}


@override
Widget build(BuildContext context) {

  final controller = context.watch<EventController>();

  return Scaffold(

    appBar: AppBar(
      title: const Text("Crear Evento"),
    ),

    body: Padding(
      padding: const EdgeInsets.all(20),

      child: Form(

        key: _formKey,

        child: ListView(

          children: [

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre del evento",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Ingrese un nombre";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(

              onPressed: _pickDate,

              icon: const Icon(Icons.calendar_month),

              label: Text(

                _selectedDate == null
                    ? "Seleccionar fecha"
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",

              ),
            ),

            const SizedBox(height: 30),

            controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ElevatedButton(

                    onPressed: () async {

                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      if (_selectedDate == null) {

                        ScaffoldMessenger.of(context).showSnackBar(

                          const SnackBar(
                            content: Text("Seleccione una fecha"),
                          ),

                        );

                        return;
                      }

                      await controller.createEvent(

                        name: _nameController.text.trim(),

                        description: _descriptionController.text.trim(),

                        date: _selectedDate!,

                      );

                      if (!context.mounted) return;

                      Navigator.pop(context);

                    },

                    child: const Text("Crear Evento"),
                  ),

          ],

        ),

      ),

    ),

  );
}
}