class DebtPayment {
  DebtPayment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.at,
    required this.workerName,
    this.note,
  });

  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime at;
  final String workerName;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'at': at.toIso8601String(),
      'workerName': workerName,
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: (map['id'] ?? '').toString(),
      customerId: (map['customerId'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      at: DateTime.tryParse((map['at'] ?? '').toString()) ?? DateTime.now(),
      workerName: (map['workerName'] ?? '').toString(),
      note: map['note']?.toString(),
    );
  }
}
