import '../models/product.dart';

/// Ovozdan kelgan matnni soddalashtirilgan qoida bilan tahlil qiladi.
/// Haqiqiy STT o‘rniga server yoki speech_to_text ulash mumkin.
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
  /// "5 dona 2x4 taxta sotildi" kabi qatorlardan son va mahsulotni topish.
  static ParsedVoiceSale parse(String text, List<Product> products) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) {
      return ParsedVoiceSale(
        quantity: 0,
        rawText: text,
        message: 'Matn bo‘sh',
      );
    }

    // Birinchi raqam — odatda "dona" yoki mahsulot oldida.
    final qtyMatch = RegExp(r'(\d+)\s*dona').firstMatch(lower) ??
        RegExp(r'^(\d+)\b').firstMatch(lower);
    final qty = qtyMatch != null ? int.tryParse(qtyMatch.group(1)!) ?? 1 : 1;

    Product? best;
    var bestScore = 0;
    for (final p in products) {
      var score = 0;
      final nameL = p.name.toLowerCase();
      final sizeNorm = p.size.toLowerCase().replaceAll(' ', '').replaceAll('x', 'x');
      if (lower.contains(nameL)) score += 3;
      if (sizeNorm.isNotEmpty && lower.contains(sizeNorm)) score += 2;
      // "2x4" va "2 x 4" variantlari
      final loose = p.size.toLowerCase().replaceAll(' ', '');
      if (loose.isNotEmpty && lower.contains(loose)) score += 2;
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }

    if (best == null && products.isNotEmpty) {
      best = products.first;
    }

    return ParsedVoiceSale(
      quantity: qty,
      product: best,
      rawText: text,
      message: best != null
          ? 'Topildi: ${best.name} × $qty'
          : 'Mahsulot aniqlanmadi',
    );
  }
}
