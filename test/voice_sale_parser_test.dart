import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/product.dart';
import 'package:my_app/services/voice_sale_parser.dart';

void main() {
  final products = [
    Product(
      id: 'p1',
      name: '2x4 taxta',
      size: '2x4',
      type: 'Quruq',
      price: 45000,
      quantity: 120,
    ),
    Product(
      id: 'p2',
      name: 'Fanera 18mm',
      size: '1.22x2.44',
      type: 'Fanera',
      price: 180000,
      quantity: 40,
    ),
  ];

  test('parses digit quantity and size', () {
    final parsed = VoiceSaleParser.parse('5 dona 2x4 taxta sotildi', products);

    expect(parsed.quantity, 5);
    expect(parsed.product?.id, 'p1');
  });

  test('parses Uzbek quantity words', () {
    final parsed = VoiceSaleParser.parse('beshta 2x4 taxta sotildi', products);

    expect(parsed.quantity, 5);
    expect(parsed.product?.id, 'p1');
  });

  test('parses spoken size variants', () {
    final parsed =
        VoiceSaleParser.parse('ikki x tort taxtadan uchta', products);

    expect(parsed.quantity, 3);
    expect(parsed.product?.id, 'p1');
  });

  test('parses product name with tens', () {
    final parsed = VoiceSaleParser.parse('fanera o‘n dona sotildi', products);

    expect(parsed.quantity, 10);
    expect(parsed.product?.id, 'p2');
  });
}
