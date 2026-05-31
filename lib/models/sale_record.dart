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
    this.unitCost = 0,
    this.customerId,
    this.customerName,
    this.onDebt = false,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final String workerName;
  final DateTime at;
  final String? customerId;
  final String? customerName;
  final bool onDebt;

  double get total => quantity * unitPrice;
  double get grossProfit =>
      unitCost <= 0 ? 0 : quantity * (unitPrice - unitCost);
  bool get hasKnownCost => unitCost > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'workerName': workerName,
      'at': at.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'onDebt': onDebt,
    };
  }

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    return SaleRecord(
      id: (map['id'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0,
      workerName: (map['workerName'] ?? '').toString(),
      at: DateTime.tryParse((map['at'] ?? '').toString()) ?? DateTime.now(),
      customerId: map['customerId']?.toString(),
      customerName: map['customerName']?.toString(),
      onDebt: map['onDebt'] == true,
    );
  }
}
