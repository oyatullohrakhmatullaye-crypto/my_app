/// Taxta mahsuloti: nomi, o‘lchami, turi, sotuv/tan narxi va zaxira.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.price,
    required this.quantity,
    this.costPrice = 0,
  });

  final String id;
  String name;
  String size;
  String type;
  double price;
  double costPrice;
  int quantity;

  double get profitPerUnit => costPrice <= 0 ? 0 : price - costPrice;
  double get marginPercent =>
      price <= 0 || costPrice <= 0 ? 0 : ((price - costPrice) / price) * 100;

  Product copyWith({
    String? name,
    String? size,
    String? type,
    double? price,
    double? costPrice,
    int? quantity,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'type': type,
      'price': price,
      'costPrice': costPrice,
      'quantity': quantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      size: (map['size'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
