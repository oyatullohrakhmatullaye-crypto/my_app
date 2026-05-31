enum DebtRiskLevel { low, watch, high, critical }

class DebtRiskInfo {
  const DebtRiskInfo({
    required this.level,
    required this.score,
    required this.label,
    required this.headline,
    required this.action,
    required this.overdueDays,
    required this.daysUntilDue,
    required this.needsDueDate,
  });

  final DebtRiskLevel level;
  final int score;
  final String label;
  final String headline;
  final String action;
  final int overdueDays;
  final int daysUntilDue;
  final bool needsDueDate;

  bool get isRisky =>
      level == DebtRiskLevel.high || level == DebtRiskLevel.critical;
}

DebtRiskInfo calculateDebtRisk({
  required double debt,
  DateTime? dueDate,
  DateTime? lastPaymentAt,
  DateTime? today,
}) {
  final now = _dayOnly(today ?? DateTime.now());
  final due = dueDate == null ? null : _dayOnly(dueDate);
  final payment = lastPaymentAt == null ? null : _dayOnly(lastPaymentAt);

  var score = debt > 0 ? 10 : 0;
  var overdueDays = 0;
  var daysUntilDue = 9999;
  var headline = 'Reja bo‘yicha';
  var action = 'Reja bo‘yicha kuzatib boring.';

  if (due == null) {
    score += 35;
    headline = 'Qaytarish kuni yo‘q';
    action = 'Bugun qaytarish kunini va qisman to‘lov rejasini kelishing.';
  } else {
    daysUntilDue = due.difference(now).inDays;
    if (daysUntilDue < 0) {
      overdueDays = daysUntilDue.abs();
      score += overdueDays >= 30
          ? 60
          : overdueDays >= 14
              ? 50
              : overdueDays >= 7
                  ? 40
                  : 30;
      headline = '$overdueDays kun kechikkan';
      action = overdueDays >= 14
          ? 'Bugun qo‘ng‘iroq qilib qisman to‘lov oling va yangi sana belgilang.'
          : 'Bugun eslatma yuboring, to‘lov vaqtini aniq yozib oling.';
    } else if (daysUntilDue == 0) {
      score += 25;
      headline = 'Bugun qaytarish kuni';
      action = 'Bugun to‘lovni eslatib, naqd yoki karta kanalini kelishing.';
    } else if (daysUntilDue <= 3) {
      score += 18;
      headline = '$daysUntilDue kun qoldi';
      action = 'Oldindan eslatma bering, mijoz to‘lovga tayyor bo‘lsin.';
    } else if (daysUntilDue <= 7) {
      score += 10;
      headline = '$daysUntilDue kun qoldi';
      action = 'Hafta ichida nazorat xabarini yuboring.';
    } else {
      score += 3;
      headline = '$daysUntilDue kun qoldi';
    }
  }

  if (debt >= 10000000) {
    score += 22;
  } else if (debt >= 5000000) {
    score += 17;
  } else if (debt >= 1000000) {
    score += 10;
  } else if (debt >= 500000) {
    score += 6;
  }

  if (payment == null) {
    score += debt > 0 ? 8 : 0;
  } else {
    final daysSincePayment = now.difference(payment).inDays;
    if (daysSincePayment >= 30) {
      score += 12;
    } else if (daysSincePayment >= 14) {
      score += 8;
    }
  }

  final clamped = score.clamp(0, 100).round();
  final level = _levelForScore(clamped);

  if (level == DebtRiskLevel.critical && overdueDays >= 14) {
    action =
        'Bugun undiring: qisman to‘lov oling yoki qarzni muzlatib qo‘ying.';
  } else if (level == DebtRiskLevel.high &&
      debt >= 5000000 &&
      overdueDays == 0) {
    action = 'Yangi qarzga savdoni to‘xtatib, avval qisman to‘lov oling.';
  }

  return DebtRiskInfo(
    level: level,
    score: clamped,
    label: _labelForLevel(level),
    headline: headline,
    action: action,
    overdueDays: overdueDays,
    daysUntilDue: daysUntilDue,
    needsDueDate: due == null,
  );
}

DebtRiskLevel _levelForScore(int score) {
  if (score >= 80) return DebtRiskLevel.critical;
  if (score >= 60) return DebtRiskLevel.high;
  if (score >= 35) return DebtRiskLevel.watch;
  return DebtRiskLevel.low;
}

String _labelForLevel(DebtRiskLevel level) {
  return switch (level) {
    DebtRiskLevel.critical => 'Kritik',
    DebtRiskLevel.high => 'Yuqori',
    DebtRiskLevel.watch => 'Nazorat',
    DebtRiskLevel.low => 'Tinch',
  };
}

DateTime _dayOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
