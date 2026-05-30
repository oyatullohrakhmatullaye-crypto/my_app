double parseMoneyInput(String value) {
  final text = value
      .toLowerCase()
      .replaceAll('\u00a0', ' ')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .trim();
  if (text.isEmpty) return 0;

  final multiplier = _moneyMultiplier(text);
  if (multiplier > 1) {
    final numberMatch = RegExp(
      r'[0-9]+(?:[ \.,][0-9]{3})*(?:[\.,][0-9]+)?|[0-9]+(?:[\.,][0-9]+)?',
    ).firstMatch(text);
    if (numberMatch == null) return 0;
    return _parseFlexibleNumber(numberMatch.group(0)!, allowDecimal: true) *
        multiplier;
  }

  return _parseFlexibleNumber(text, allowDecimal: false);
}

double _moneyMultiplier(String text) {
  if (RegExp(r'\b(mln|million|milyon)\b').hasMatch(text)) return 1000000;
  if (RegExp(r'\bming\b').hasMatch(text)) return 1000;
  return 1;
}

double _parseFlexibleNumber(String raw, {required bool allowDecimal}) {
  final text = raw.replaceAll(RegExp(r'[^0-9,\.\s]'), ' ').trim();
  if (text.isEmpty) return 0;

  if (RegExp(r'^[0-9]{1,3}([ ,\.][0-9]{3})+$').hasMatch(text)) {
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  if (allowDecimal) {
    final compact = text.replaceAll(' ', '').replaceAll(',', '.');
    if (RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(compact)) {
      return double.tryParse(compact) ?? 0;
    }
  }

  return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
