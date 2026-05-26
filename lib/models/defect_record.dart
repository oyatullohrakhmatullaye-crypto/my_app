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
}
