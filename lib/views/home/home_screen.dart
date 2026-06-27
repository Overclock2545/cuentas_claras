import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../config/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Eventos'),
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

                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}