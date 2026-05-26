/// Bitta sotuv yozuvi — hisobot va PDF uchun.
class SaleRecord {
  SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.workerName,
    required this.at,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String workerName;
  final DateTime at;

  double get total => quantity * unitPrice;
}
