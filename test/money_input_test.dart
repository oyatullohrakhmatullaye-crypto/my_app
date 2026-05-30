import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/money_input.dart';

void main() {
  group('parseMoneyInput', () {
    test('accepts plain digits', () {
      expect(parseMoneyInput('500000'), 500000);
    });

    test('accepts currency suffix and spaces', () {
      expect(parseMoneyInput('500 000 so‘m'), 500000);
      expect(parseMoneyInput("500 000 so'm"), 500000);
    });

    test('accepts thousand separators', () {
      expect(parseMoneyInput('500,000 sum'), 500000);
      expect(parseMoneyInput('500.000 som'), 500000);
    });

    test('accepts common shorthand', () {
      expect(parseMoneyInput('500 ming'), 500000);
      expect(parseMoneyInput('1.5 mln'), 1500000);
      expect(parseMoneyInput('1,5 milyon so‘m'), 1500000);
    });
  });
}
