import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/debt_risk.dart';

void main() {
  group('calculateDebtRisk', () {
    final today = DateTime(2026, 5, 30);

    test('marks long overdue large debts as critical', () {
      final risk = calculateDebtRisk(
        debt: 6000000,
        dueDate: DateTime(2026, 5, 10),
        today: today,
      );

      expect(risk.level, DebtRiskLevel.critical);
      expect(risk.overdueDays, 20);
      expect(risk.isRisky, isTrue);
    });

    test('treats missing due date as a control risk', () {
      final risk = calculateDebtRisk(
        debt: 800000,
        today: today,
      );

      expect(risk.level, DebtRiskLevel.watch);
      expect(risk.needsDueDate, isTrue);
      expect(risk.headline, 'Qaytarish kuni yo‘q');
    });

    test('keeps far future small debts low risk', () {
      final risk = calculateDebtRisk(
        debt: 200000,
        dueDate: DateTime(2026, 6, 20),
        lastPaymentAt: DateTime(2026, 5, 29),
        today: today,
      );

      expect(risk.level, DebtRiskLevel.low);
      expect(risk.isRisky, isFalse);
    });
  });
}
