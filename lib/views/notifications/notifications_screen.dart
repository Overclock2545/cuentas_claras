import 'package:cuentas_claras/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../models/settlement_with_event.dart';
import '../../services/notification_service.dart';

/// Centro de notificaciones. No lee de una colección propia: todo se
/// deriva en tiempo real de eventos, participantes y liquidaciones ya
/// existentes (ver NotificationService para el porqué).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: StreamBuilder<List<SettlementWithEvent>>(
        stream: NotificationService.streamMyPendingSettlements(),
        builder: (context, settlementsSnapshot) {
          final isLoadingSettlements =
              settlementsSnapshot.connectionState == ConnectionState.waiting;
          final allPending = settlementsSnapshot.data ?? [];

          return StreamBuilder<List<EventModel>>(
            stream: eventController.events,
            builder: (context, eventsSnapshot) {
              final isLoadingEvents =
                  eventsSnapshot.connectionState == ConnectionState.waiting;

              if (isLoadingSettlements || isLoadingEvents) {
                return const Center(child: CircularProgressIndicator());
              }

              if (settlementsSnapshot.hasError) {
                return _ErrorState(error: settlementsSnapshot.error);
              }

              final now = DateTime.now();
              final upcoming = (eventsSnapshot.data ?? [])
                  .where((e) =>
                      e.status == 'active' &&
                      e.date.isAfter(now) &&
                      e.date.difference(now).inDays <= 7)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

              // Pagos donde SOY quien tiene que confirmar (no los registré yo).
              final myUid = authService.currentUser?.uid;
              final needsMyConfirmation = allPending
                  .where((s) => s.settlement.registeredBy != myUid)
                  .toList();
              final waitingOnOthers = allPending
                  .where((s) => s.settlement.registeredBy == myUid)
                  .toList();

              if (needsMyConfirmation.isEmpty &&
                  waitingOnOthers.isEmpty &&
                  upcoming.isEmpty) {
                return const _EmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (needsMyConfirmation.isNotEmpty) ...[
                    _SectionTitle(
                      'Pagos por confirmar',
                      icon: Icons.priority_high_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    ...needsMyConfirmation.map(
                      (item) => _SettlementNotificationTile(
                        item: item,
                        actionable: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (waitingOnOthers.isNotEmpty) ...[
                    _SectionTitle(
                      'Esperando confirmación',
                      icon: Icons.hourglass_empty,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    ...waitingOnOthers.map(
                      (item) => _SettlementNotificationTile(
                        item: item,
                        actionable: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _SectionTitle(
                      'Eventos próximos',
                      icon: Icons.event_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map((event) => _UpcomingEventTile(event: event)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SectionTitle(this.text, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SettlementNotificationTile extends StatelessWidget {
  final SettlementWithEvent item;
  final bool actionable;

  const _SettlementNotificationTile({
    required this.item,
    required this.actionable,
  });

  @override
  Widget build(BuildContext context) {
    final settlement = item.settlement;
    return Card(
      elevation: 0,
      color: actionable
          ? Colors.orange.withValues(alpha: 0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: actionable
              ? Colors.orange.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(
          actionable ? Icons.notifications_active : Icons.schedule,
          color: actionable ? Colors.orange : Colors.grey,
        ),
        title: Text('${settlement.fromName} → ${settlement.toName}'),
        subtitle: Text(
          '${item.eventName} · S/ ${settlement.amount.toStringAsFixed(2)}',
        ),
        trailing: actionable
            ? const Icon(Icons.chevron_right)
            : Text(
                'Pendiente',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {'id': settlement.eventId, 'name': item.eventName},
          );
        },
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  final EventModel event;
  const _UpcomingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final daysLeft = event.date.difference(DateTime.now()).inDays;
    final label = daysLeft <= 0 ? 'Es hoy' : 'En $daysLeft día(s)';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.event_outlined, color: Colors.blue),
        title: Text(event.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {'id': event.id, 'name': event.name},
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No tienes notificaciones por ahora',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object? error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No se pudieron cargar las notificaciones.\n'
          'Revisa que las reglas e índices de Firestore estén desplegados.\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}