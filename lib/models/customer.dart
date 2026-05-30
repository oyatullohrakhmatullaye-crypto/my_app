class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.type,
    required this.note,
    required this.debt,
    required this.creditLimit,
    required this.createdAt,
    this.debtDueDate,
    this.lastPaymentAt,
  });

  final String id;
  String name;
  String phone;
  String address;
  String type;
  String note;
  double debt;
  double creditLimit;
  DateTime createdAt;
  DateTime? debtDueDate;
  DateTime? lastPaymentAt;

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? type,
    String? note,
    double? debt,
    double? creditLimit,
    DateTime? debtDueDate,
    DateTime? lastPaymentAt,
    bool clearDebtDueDate = false,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
      note: note ?? this.note,
      debt: debt ?? this.debt,
      creditLimit: creditLimit ?? this.creditLimit,
      createdAt: createdAt,
      debtDueDate: clearDebtDueDate ? null : debtDueDate ?? this.debtDueDate,
      lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'type': type,
      'note': note,
      'debt': debt,
      'creditLimit': creditLimit,
      'createdAt': createdAt.toIso8601String(),
      'debtDueDate': debtDueDate?.toIso8601String(),
      'lastPaymentAt': lastPaymentAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      debt: (map['debt'] as num?)?.toDouble() ?? 0,
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      debtDueDate: DateTime.tryParse((map['debtDueDate'] ?? '').toString()),
      lastPaymentAt: DateTime.tryParse((map['lastPaymentAt'] ?? '').toString()),
    );
  }
}
