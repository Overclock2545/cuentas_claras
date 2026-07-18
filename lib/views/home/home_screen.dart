import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../models/settlement_with_event.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_locator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas Claras'),
        actions: [
          StreamBuilder<List<SettlementWithEvent>>(
            stream: NotificationService.streamMyPendingSettlements(),
            builder: (context, snapshot) {
              final myUid = authService.currentUser?.uid;
              final pendingForMe = (snapshot.data ?? [])
                  .where((s) => s.settlement.registeredBy != myUid)
                  .length;

              return IconButton(
                icon: Badge(
                  isLabelVisible: pendingForMe > 0,
                  label: Text('$pendingForMe'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: 'Notificaciones',
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.notifications),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =========================================================
              // SECCIÓN 1: SECCIÓN DE INVITACIONES PENDIENTES
              // =========================================================
              StreamBuilder<List<EventModel>>(
                stream: eventController.pendingInvitations,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _InvitationStatusCard(
                      icon: Icons.error_outline,
                      title: 'No se pudieron cargar las invitaciones',
                      message:
                          'Revisa que las reglas de Firestore estén desplegadas.',
                      color: Colors.red,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _InvitationStatusCard(
                      icon: Icons.mail_outline,
                      title: 'Invitaciones',
                      message: 'Buscando invitaciones pendientes…',
                      color: Colors.orange,
                    );
                  }

                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const _InvitationStatusCard(
                      icon: Icons.mark_email_read_outlined,
                      title: 'Invitaciones',
                      message: 'No tienes invitaciones pendientes.',
                      color: Colors.grey,
                    );
                  }

                  final invitations = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invitaciones Pendientes (${invitations.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invitations.length,
                        itemBuilder: (context, index) {
                          final event = invitations[index];
                          return Card(
                            color: Colors.orange.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.orange.shade200),
                            ),
                            child: ListTile(
                              title: Text(event.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(event.description,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón de Rechazar (X)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    tooltip: 'Rechazar invitación',
                                    onPressed:
                                        eventController.isRespondingToInvitation
                                            ? null
                                            : () => _respondToInvitation(
                                                  context,
                                                  eventController,
                                                  event.id,
                                                  false,
                                                ),
                                  ),
                                  // Botón de Aceptar (Check)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    tooltip: 'Aceptar invitación',
                                    onPressed:
                                        eventController.isRespondingToInvitation
                                            ? null
                                            : () => _respondToInvitation(
                                                  context,
                                                  eventController,
                                                  event.id,
                                                  true,
                                                ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                    ],
                  );
                },
              ),

              // =========================================================
              // SECCIÓN 2: LISTA DE EVENTOS DEL USUARIO
              // =========================================================
              Text(
                'Mis Eventos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<EventModel>>(
                stream: eventController.events,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  if (snapshot.hasError) {
                    return const _InvitationStatusCard(
                      icon: Icons.error_outline,
                      title: 'No se pudieron cargar los eventos',
                      message:
                          'Revisa la conexión con Firestore o las reglas de seguridad.',
                      color: Colors.red,
                    );
                  }

                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Aún no tienes eventos activos',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1)),
                        ),
                        child: ListTile(
                          title: Text(event.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(event.description,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () => _confirmDelete(context, event.id),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.eventDetail,
                              arguments: {'id': event.id, 'name': event.name},
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createEvent),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToInvitation(
    BuildContext context,
    EventController controller,
    String eventId,
    bool accept,
  ) async {
    try {
      await controller.respondToInvitation(eventId, accept);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Invitación aceptada. El evento ya está en Mis Eventos.'
                : 'Invitación rechazada.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo responder la invitación: $error')),
      );
    }
  }

  void _confirmDelete(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content:
            const Text('Esta acción borrará el evento de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await EventService.deleteEvent(eventId);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InvitationStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _InvitationStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.25)),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(message),
        ),
      ),
    );
  }
}