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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'workerName': workerName,
      'at': at.toIso8601String(),
    };
  }

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    return SaleRecord(
      id: (map['id'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      workerName: (map['workerName'] ?? '').toString(),
      at: DateTime.tryParse((map['at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
