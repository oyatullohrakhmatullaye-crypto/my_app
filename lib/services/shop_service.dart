import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/customer.dart';
import '../models/defect_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';
import '../models/user_role.dart';
import 'shop_local_store.dart';
import 'voice_sale_parser.dart';

class ShopService extends ChangeNotifier {
  ShopService({ShopLocalStore? localStore})
      : _localStore = localStore ?? ShopLocalStore();

  final ShopLocalStore _localStore;

  AppUser? _user;
  AppUser? get user => _user;

  final List<Product> _products = [];
  final List<SaleRecord> _sales = [];
  final List<DefectRecord> _defects = [];
  final List<Customer> _customers = [];

  List<Product> get products => List.unmodifiable(_products);
  List<SaleRecord> get sales => List.unmodifiable(_sales);
  List<DefectRecord> get defects => List.unmodifiable(_defects);
  List<Customer> get customers => List.unmodifiable(_customers);

  bool _isReady = false;
  bool get isReady => _isReady;

  int _idSeq = 0;

  Future<void> init() async {
    await _localStore.init();

    final storedProducts = _localStore.loadProducts();
    final storedSales = _localStore.loadSales();
    final storedDefects = _localStore.loadDefects();
    final storedCustomers = _localStore.loadCustomers();

    _products
      ..clear()
      ..addAll(storedProducts.isNotEmpty ? storedProducts : _defaultProducts());
    _sales
      ..clear()
      ..addAll(storedSales);
    _defects
      ..clear()
      ..addAll(storedDefects);
    _customers
      ..clear()
      ..addAll(storedCustomers);

    _isReady = true;
    notifyListeners();

    if (storedProducts.isEmpty) {
      await _persistProducts();
    }
  }

  List<Product> _defaultProducts() {
    return [
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
    ];
  }

  String _genId() => 'id_${DateTime.now().microsecondsSinceEpoch}_${++_idSeq}';

  Future<void> _persistProducts() => _localStore.saveProducts(_products);
  Future<void> _persistSales() => _localStore.saveSales(_sales);
  Future<void> _persistDefects() => _localStore.saveDefects(_defects);
  Future<void> _persistCustomers() => _localStore.saveCustomers(_customers);

  void login({required String name, required UserRole role}) {
    _user = AppUser(
      name: name.trim().isEmpty
          ? (role == UserRole.admin ? 'Admin' : 'Ishchi')
          : name.trim(),
      role: role,
    );
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void addProduct(Product p) {
    _products.add(p);
    notifyListeners();
    unawaited(_persistProducts());
  }

  void updateProduct(Product updated) {
    final i = _products.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      _products[i] = updated;
      notifyListeners();
      unawaited(_persistProducts());
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((e) => e.id == id);
    notifyListeners();
    unawaited(_persistProducts());
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
    unawaited(_persistCustomers());
  }

  void updateCustomer(Customer updated) {
    final i = _customers.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      _customers[i] = updated;
      notifyListeners();
      unawaited(_persistCustomers());
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((e) => e.id == id);
    notifyListeners();
    unawaited(_persistCustomers());
  }

  Customer? customerById(String? id) {
    if (id == null) return null;
    try {
      return _customers.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? productById(String id) {
    try {
      return _products.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  String? sell({
    required String productId,
    required int quantity,
    String? customerId,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    final p = productById(productId);
    if (p == null) return 'Mahsulot topilmadi';
    if (quantity < 1) return 'Soni noto‘g‘ri';
    if (p.quantity < quantity) {
      return 'Zaxira yetarli emas (${p.quantity} dona)';
    }
    final customer = customerById(customerId);

    p.quantity -= quantity;
    _sales.add(SaleRecord(
      id: _genId(),
      productId: p.id,
      productName: p.name,
      quantity: quantity,
      unitPrice: p.price,
      workerName: u.name,
      at: DateTime.now(),
      customerId: customer?.id,
      customerName: customer?.name,
    ));
    notifyListeners();
    unawaited(_persistProducts());
    unawaited(_persistSales());
    return null;
  }

  String? sellFromVoiceText(String text, {String? customerId}) {
    final parsed = VoiceSaleParser.parse(text, _products);
    if (parsed.product == null) return parsed.message;
    return sell(
      productId: parsed.product!.id,
      quantity: parsed.quantity,
      customerId: customerId,
    );
  }

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
    unawaited(_persistProducts());
    unawaited(_persistDefects());
    return null;
  }

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
    unawaited(_persistProducts());
    unawaited(_persistDefects());
    return null;
  }

  List<SaleRecord> salesForDay(DateTime day) {
    return _sales
        .where((s) =>
            s.at.year == day.year &&
            s.at.month == day.month &&
            s.at.day == day.day)
        .toList();
  }

  List<SaleRecord> salesForCustomer(String customerId) {
    return _sales.where((s) => s.customerId == customerId).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  double totalForCustomer(String customerId) {
    return salesForCustomer(customerId).fold<double>(0, (a, s) => a + s.total);
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

  bool get isPastReportHour {
    final now = DateTime.now();
    return now.hour >= 18;
  }
}
