/// Representa una deuda ya simplificada entre dos participantes de un
/// evento: [fromId] le debe [amount] a [toId]. Es un modelo de solo
/// lectura calculado en el cliente (ver BalanceCalculator); no se persiste
/// en Firestore.
class DebtModel {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  const DebtModel({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });
}