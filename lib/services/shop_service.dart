import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/defect_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';
import '../models/user_role.dart';
import 'voice_sale_parser.dart';

/// Barcha mahsulotlar, sotuvlar va brak — xotirada (mock).
/// Keyinroq Hive/SQLite ga o‘tkazish oson.
class ShopService extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;

  final List<Product> _products = [];
  final List<SaleRecord> _sales = [];
  final List<DefectRecord> _defects = [];

  List<Product> get products => List.unmodifiable(_products);
  List<SaleRecord> get sales => List.unmodifiable(_sales);
  List<DefectRecord> get defects => List.unmodifiable(_defects);

  ShopService() {
    _seedProducts();
  }

  void _seedProducts() {
    _products.addAll([
      Product(
        id: _genId(),
        name: '2x4 taxta',
        size: '2x4',
        type: 'Quruq',
        price: 45000,
        quantity: 120,
      ),
      Product(
        id: _genId(),
        name: '2x6 taxta',
        size: '2x6',
        type: 'Quruq',
        price: 62000,
        quantity: 80,
      ),
      Product(
        id: _genId(),
        name: 'Fanera 18mm',
        size: '1.22x2.44',
        type: 'Fanera',
        price: 180000,
        quantity: 40,
      ),
    ]);
  }

  int _idSeq = 0;

  String _genId() => 'id_${DateTime.now().microsecondsSinceEpoch}_${++_idSeq}';

  /// Oddiy kirish: ism + rol (parol shart emas — demo).
  void login({required String name, required UserRole role}) {
    _user = AppUser(name: name.trim().isEmpty ? (role == UserRole.admin ? 'Admin' : 'Ishchi') : name.trim(), role: role);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void addProduct(Product p) {
    _products.add(p);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final i = _products.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      _products[i] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Product? productById(String id) {
    try {
      return _products.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tez sotuv: zaxiradan ayirib, yozuv qo‘shadi.
  String? sell({
    required String productId,
    required int quantity,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    final p = productById(productId);
    if (p == null) return 'Mahsulot topilmadi';
    if (quantity < 1) return 'Soni noto‘g‘ri';
    if (p.quantity < quantity) return 'Zaxira yetarli emas (${p.quantity} dona)';

    p.quantity -= quantity;
    _sales.add(SaleRecord(
      id: _genId(),
      productId: p.id,
      productName: p.name,
      quantity: quantity,
      unitPrice: p.price,
      workerName: u.name,
      at: DateTime.now(),
    ));
    notifyListeners();
    return null;
  }

  /// Ovoz matni → parser → sotuv.
  String? sellFromVoiceText(String text) {
    final parsed = VoiceSaleParser.parse(text, _products);
    if (parsed.product == null) return parsed.message;
    return sell(productId: parsed.product!.id, quantity: parsed.quantity);
  }

  /// Ishchi brakni belgilaydi (zaxiradan kamayadi yoki alohida hisob — bu yerda zaxiradan ayiramiz).
  String? reportDefect({
    required String productId,
    required int quantity,
    String? note,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    final p = productById(productId);
    if (p == null) return 'Mahsulot topilmadi';
    if (quantity < 1) return 'Soni noto‘g‘ri';
    if (p.quantity < quantity) return 'Zaxira yetarli emas';

    p.quantity -= quantity;
    _defects.add(DefectRecord(
      id: _genId(),
      productId: p.id,
      productName: p.name,
      quantity: quantity,
      workerName: u.name,
      at: DateTime.now(),
      note: note,
    ));
    notifyListeners();
    return null;
  }

  /// Admin brakni yana sotiladigan zaxiraga qaytaradi.
  String? recoverDefect(String defectId) {
    final u = _user;
    if (u == null || !u.isAdmin) return 'Faqat admin';

    DefectRecord? d;
    for (final x in _defects) {
      if (x.id == defectId) {
        d = x;
        break;
      }
    }
    if (d == null) return 'Yozuv topilmadi';
    if (d.recovered) return 'Allaqachon qaytarilgan';

    final p = productById(d.productId);
    if (p == null) return 'Mahsulot o‘chirilgan';

    d.recovered = true;
    p.quantity += d.quantity;
    notifyListeners();
    return null;
  }

  // --- Hisobotlar ---

  List<SaleRecord> salesForDay(DateTime day) {
    return _sales
        .where((s) => s.at.year == day.year && s.at.month == day.month && s.at.day == day.day)
        .toList();
  }

  double totalForDay(DateTime day) {
    return salesForDay(day).fold<double>(0, (a, s) => a + s.total);
  }

  Map<String, double> workerTotalsForDay(DateTime day) {
    final map = <String, double>{};
    for (final s in salesForDay(day)) {
      map[s.workerName] = (map[s.workerName] ?? 0) + s.total;
    }
    return map;
  }

  /// 18:00 da avtomatik PDF — haqiqiy ilovada Workmanager/background ishlatiladi.
  /// Bu yerda faqat "soat 18:00 bo‘lganda tayyor" degan tekshiruv (mock).
  bool get isPastReportHour {
    final now = DateTime.now();
    return now.hour >= 18;
  }
}
