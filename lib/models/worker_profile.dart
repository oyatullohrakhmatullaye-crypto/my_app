class WorkerProfile {
  WorkerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.roleTitle,
    required this.dailyTarget,
    required this.active,
    required this.note,
    required this.createdAt,
  });

  final String id;
  String name;
  String phone;
  String roleTitle;
  double dailyTarget;
  bool active;
  String note;
  final DateTime createdAt;

  WorkerProfile copyWith({
    String? name,
    String? phone,
    String? roleTitle,
    double? dailyTarget,
    bool? active,
    String? note,
  }) {
    return WorkerProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      roleTitle: roleTitle ?? this.roleTitle,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      active: active ?? this.active,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'roleTitle': roleTitle,
      'dailyTarget': dailyTarget,
      'active': active,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkerProfile.fromMap(Map<String, dynamic> map) {
    return WorkerProfile(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      roleTitle: (map['roleTitle'] ?? 'Sotuvchi').toString(),
      dailyTarget: (map['dailyTarget'] as num?)?.toDouble() ?? 0,
      active: map['active'] is bool ? map['active'] as bool : true,
      note: (map['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
