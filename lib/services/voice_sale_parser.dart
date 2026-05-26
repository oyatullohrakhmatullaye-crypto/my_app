import '../models/product.dart';

/// Ovozdan kelgan matndan mahsulot va sonni topadi.
class ParsedVoiceSale {
  ParsedVoiceSale({
    required this.quantity,
    this.product,
    this.rawText = '',
    this.message = '',
  });

  final int quantity;
  final Product? product;
  final String rawText;
  final String message;
}

class VoiceSaleParser {
  static const _numberWords = <String, int>{
    'bir': 1,
    'bitta': 1,
    'ikki': 2,
    'ikkita': 2,
    'uch': 3,
    'uchta': 3,
    'to‘rt': 4,
    'to‘rtta': 4,
    "to'rt": 4,
    "to'rtta": 4,
    'tort': 4,
    'torta': 4,
    'besh': 5,
    'beshta': 5,
    'olti': 6,
    'oltita': 6,
    'yetti': 7,
    'yettita': 7,
    'sakkiz': 8,
    'sakkizta': 8,
    'to‘qqiz': 9,
    'to‘qqizta': 9,
    "to'qqiz": 9,
    "to'qqizta": 9,
    'toqiz': 9,
    'toqizta': 9,
    'o‘n': 10,
    "o'n": 10,
    'on': 10,
    'onta': 10,
    'yigirma': 20,
    'ottiz': 30,
    'qirq': 40,
    'ellik': 50,
    'oltmish': 60,
    'yetmish': 70,
    'sakson': 80,
    'to‘qson': 90,
    "to'qson": 90,
  };

  /// "5 dona 2x4 taxta sotildi", "beshta fanera", "ikki x tortdan 3 dona".
  static ParsedVoiceSale parse(String text, List<Product> products) {
    final lower = _normalize(text);
    if (lower.isEmpty) {
      return ParsedVoiceSale(
        quantity: 0,
        rawText: text,
        message: 'Matn bo‘sh',
      );
    }

    final qty = _quantityFrom(lower);

    Product? best;
    var bestScore = 0;
    for (final p in products) {
      final score = _scoreProduct(lower, p);
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }

    return ParsedVoiceSale(
      quantity: qty,
      product: bestScore > 0 ? best : null,
      rawText: text,
      message: bestScore > 0 && best != null
          ? 'Topildi: ${best.name} × $qty'
          : 'Mahsulot aniqlanmadi',
    );
  }

  static int _quantityFrom(String text) {
    final digitMatch = RegExp(r'\b(\d+)\s*(dona|ta)?\b').firstMatch(text);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!) ?? 1;
    }

    final tokens =
        text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    for (var i = 0; i < tokens.length; i++) {
      if (_looksLikeSizeNumber(tokens, i)) continue;
      final value = _numberValue(tokens[i]);
      if (value == null) continue;
      final next = i + 1 < tokens.length ? tokens[i + 1] : '';
      if (_hasCountMarker(tokens[i]) || next == 'dona') {
        return _combinedNumber(tokens, i);
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (_looksLikeSizeNumber(tokens, i)) continue;
      final one = _numberValue(tokens[i]);
      if (one == null) continue;
      return _combinedNumber(tokens, i);
    }
    return 1;
  }

  static int _scoreProduct(String text, Product p) {
    var score = 0;
    final name = _normalize(p.name);
    final type = _normalize(p.type);
    final size = _normalize(p.size);

    if (name.isNotEmpty && text.contains(name)) score += 6;
    if (type.isNotEmpty && text.contains(type)) score += 2;

    for (final token in name.split(RegExp(r'\s+'))) {
      if (token.length > 2 && text.contains(token)) score += 2;
    }

    for (final variant in _sizeVariants(size)) {
      if (variant.isNotEmpty && text.contains(variant)) score += 5;
    }

    if (text.contains('fanera') && name.contains('fanera')) score += 6;
    if (text.contains('taxta') && name.contains('taxta')) score += 2;

    return score;
  }

  static List<String> _sizeVariants(String size) {
    final compact = size.replaceAll(' ', '');
    final variants = <String>{size, compact};
    final parts =
        RegExp(r'(\d+)').allMatches(size).map((m) => m.group(1)!).toList();
    if (parts.length >= 2) {
      final a = parts[0];
      final b = parts[1];
      variants.add('$a x $b');
      variants.add('${a}x$b');
      variants.add('$a ga $b');
      variants.add('${_wordFor(a)} x ${_wordFor(b)}');
      variants.add('${_wordFor(a)} ga ${_wordFor(b)}');
    }
    return variants.toList();
  }

  static int? _numberValue(String token) {
    final cleaned = token
        .replaceAll(RegExp(r"[^a-z0-9‘’ʼ']"), '')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('ʼ', "'");
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned) ?? _numberWords[cleaned];
  }

  static int _combinedNumber(List<String> tokens, int index) {
    final one = _numberValue(tokens[index]) ?? 1;
    final next =
        index + 1 < tokens.length ? _numberValue(tokens[index + 1]) : null;
    if (next != null && one >= 10 && next < 10) return one + next;
    return one;
  }

  static bool _hasCountMarker(String token) {
    final normalized = token.replaceAll("'", '');
    return normalized.endsWith('ta');
  }

  static bool _looksLikeSizeNumber(List<String> tokens, int index) {
    final prev = index > 0 ? tokens[index - 1] : '';
    final next = index + 1 < tokens.length ? tokens[index + 1] : '';
    return prev == 'x' || prev == 'ga' || next == 'x' || next == 'ga';
  }

  static String _wordFor(String digit) {
    return switch (digit) {
      '1' => 'bir',
      '2' => 'ikki',
      '3' => 'uch',
      '4' => 'tort',
      '5' => 'besh',
      '6' => 'olti',
      '7' => 'yetti',
      '8' => 'sakkiz',
      '9' => 'toqiz',
      _ => digit,
    };
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('×', 'x')
        .replaceAll('х', 'x')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('ʼ', "'")
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
