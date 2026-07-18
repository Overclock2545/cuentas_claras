import 'settlement_model.dart';

/// Envuelve una [SettlementModel] junto con el nombre del evento al que
/// pertenece. Se usa en el centro de notificaciones, donde se muestran
/// liquidaciones de varios eventos a la vez y hace falta decir de cuál es
/// cada una (dentro de EventDetailScreen no hace falta, porque el evento
/// ya es obvio por contexto).
class SettlementWithEvent {
  final SettlementModel settlement;
  final String eventName;

  const SettlementWithEvent({
    required this.settlement,
    required this.eventName,
  });
}