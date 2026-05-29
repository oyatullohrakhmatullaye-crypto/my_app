/// Brak: ishchi belgilaydi, admin zaxiraga qaytarishi mumkin.
class DefectRecord {
  DefectRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.workerName,
    required this.at,
    this.note,
    this.recovered = false,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final String workerName;
  final DateTime at;
  String? note;
  bool recovered;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'workerName': workerName,
      'at': at.toIso8601String(),
      'note': note,
      'recovered': recovered,
    };
  }

  factory DefectRecord.fromMap(Map<String, dynamic> map) {
    return DefectRecord(
      id: (map['id'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      workerName: (map['workerName'] ?? '').toString(),
      at: DateTime.tryParse((map['at'] ?? '').toString()) ?? DateTime.now(),
      note: map['note']?.toString(),
      recovered: map['recovered'] == true,
    );
  }
}
