/// Taxta mahsuloti: nomi, o‘lchami, turi, narxi va zaxira.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.price,
    required this.quantity,
  });

  final String id;
  String name;
  String size;
  String type;
  double price;
  int quantity;

  Product copyWith({
    String? name,
    String? size,
    String? type,
    double? price,
    int? quantity,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
