import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../config/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(
  title: const Text('Mis Eventos'),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      tooltip: 'Cerrar Sesión',
      onPressed: () async {
        // Ejecutamos el servicio
        await AuthService.signOut();
        if (context.mounted) {
          // Limpiamos el historial de rutas y lo mandamos al Login
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      },
    ),
  ],
),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.createEvent,
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<EventModel>>(
        stream: controller.events,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No tienes eventos aún',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para crear tu primer evento.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {

              final event = events[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event),
                  ),
                  title: Text(event.name),
                  subtitle: Text(event.description),
                  trailing: IconButton(
  icon: const Icon(Icons.delete_outline, color: Colors.grey),
  onPressed: () {
    // Diálogo de confirmación antes de borrar
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: const Text('Esta acción borrará el evento de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cierra el diálogo
              try {
                await EventService.deleteEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento eliminado con éxito')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  },
),
                  
                  // Conectamos el click para viajar al detalle
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetail,
                      arguments: {
                        'id': event.id,     // Le pasa el ID único del evento en Firestore
                        'name': event.name, // Le pasa el nombre para pintarlo en la AppBar del detalle
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}