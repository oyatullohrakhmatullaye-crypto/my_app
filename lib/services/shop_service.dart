import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/customer.dart';
import '../models/debt_payment.dart';
import '../models/defect_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';
import '../models/user_role.dart';
import '../models/worker_profile.dart';
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
  final List<DebtPayment> _debtPayments = [];
  final List<WorkerProfile> _workers = [];

  List<Product> get products => List.unmodifiable(_products);
  List<SaleRecord> get sales => List.unmodifiable(_sales);
  List<DefectRecord> get defects => List.unmodifiable(_defects);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<DebtPayment> get debtPayments => List.unmodifiable(_debtPayments);
  List<WorkerProfile> get workers => List.unmodifiable(_workers);

  bool _isReady = false;
  bool get isReady => _isReady;

  int _idSeq = 0;

  Future<void> init() async {
    await _localStore.init();

    final storedProducts = _localStore.loadProducts();
    final storedSales = _localStore.loadSales();
    final storedDefects = _localStore.loadDefects();
    final storedCustomers = _localStore.loadCustomers();
    final storedDebtPayments = _localStore.loadDebtPayments();
    final storedWorkers = _localStore.loadWorkers();

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
    _debtPayments
      ..clear()
      ..addAll(storedDebtPayments);
    _workers
      ..clear()
      ..addAll(storedWorkers);
    _syncWorkersFromSales();

    _isReady = true;
    notifyListeners();

    if (storedProducts.isEmpty) {
      await _persistProducts();
    }
    if (storedWorkers.isEmpty && _workers.isNotEmpty) {
      await _persistWorkers();
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
  Future<void> _persistDebtPayments() =>
      _localStore.saveDebtPayments(_debtPayments);
  Future<void> _persistWorkers() => _localStore.saveWorkers(_workers);

  void login({required String name, required UserRole role}) {
    _user = AppUser(
      name: name.trim().isEmpty
          ? (role == UserRole.admin ? 'Admin' : 'Ishchi')
          : name.trim(),
      role: role,
    );
    if (role == UserRole.worker) {
      _ensureWorkerProfile(_user!.name);
    }
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
    _debtPayments.removeWhere((e) => e.customerId == id);
    notifyListeners();
    unawaited(_persistCustomers());
    unawaited(_persistDebtPayments());
  }

  void addWorker(WorkerProfile worker) {
    final cleanName = worker.name.trim();
    if (cleanName.isEmpty) return;
    final existing = workerByName(cleanName);
    if (existing != null) {
      updateWorker(existing.copyWith(
        phone: worker.phone,
        roleTitle: worker.roleTitle,
        dailyTarget: worker.dailyTarget,
        active: worker.active,
        note: worker.note,
      ));
      return;
    }
    _workers.add(worker);
    _sortWorkers();
    notifyListeners();
    if (_isReady) unawaited(_persistWorkers());
  }

  void updateWorker(WorkerProfile updated) {
    final i = _workers.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      _workers[i] = updated;
      _sortWorkers();
      notifyListeners();
      if (_isReady) unawaited(_persistWorkers());
    }
  }

  void deleteWorker(String id) {
    _workers.removeWhere((e) => e.id == id);
    notifyListeners();
    if (_isReady) unawaited(_persistWorkers());
  }

  Customer? customerById(String? id) {
    if (id == null) return null;
    try {
      return _customers.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  WorkerProfile? workerByName(String name) {
    final normalized = _normName(name);
    for (final worker in _workers) {
      if (_normName(worker.name) == normalized) return worker;
    }
    return null;
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
    bool addToDebt = false,
    DateTime? debtDueDate,
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
    if (addToDebt && customer == null) {
      return 'Qarzga yozish uchun klient tanlang';
    }

    p.quantity -= quantity;
    final saleTotal = p.price * quantity;
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
    if (addToDebt && customer != null) {
      customer.debt += saleTotal;
      if (debtDueDate != null) {
        customer.debtDueDate = debtDueDate;
      } else {
        customer.debtDueDate ??= DateTime.now().add(const Duration(days: 7));
      }
    }
    notifyListeners();
    unawaited(_persistProducts());
    unawaited(_persistSales());
    if (addToDebt) unawaited(_persistCustomers());
    return null;
  }

  String? sellFromVoiceText(String text,
      {String? customerId, bool addToDebt = false, DateTime? debtDueDate}) {
    final parsed = VoiceSaleParser.parse(text, _products);
    if (parsed.product == null) return parsed.message;
    return sell(
      productId: parsed.product!.id,
      quantity: parsed.quantity,
      customerId: customerId,
      addToDebt: addToDebt,
      debtDueDate: debtDueDate,
    );
  }

  String? addDebtPayment({
    required String customerId,
    required double amount,
    String? note,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    final customer = customerById(customerId);
    if (customer == null) return 'Klient topilmadi';
    if (amount <= 0) return 'To‘lov summasi noto‘g‘ri';
    if (customer.debt <= 0) return 'Bu klientda qarz yo‘q';

    final paid = amount > customer.debt ? customer.debt : amount;
    customer.debt -= paid;
    customer.lastPaymentAt = DateTime.now();
    if (customer.debt <= 0) {
      customer.debt = 0;
      customer.debtDueDate = null;
    }
    _debtPayments.add(DebtPayment(
      id: _genId(),
      customerId: customer.id,
      customerName: customer.name,
      amount: paid,
      at: DateTime.now(),
      workerName: u.name,
      note: note,
    ));
    notifyListeners();
    unawaited(_persistCustomers());
    unawaited(_persistDebtPayments());
    return null;
  }

  String? addDebtToCustomer({
    required String customerId,
    required double amount,
    required DateTime dueDate,
    String? address,
    String? note,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    final customer = customerById(customerId);
    if (customer == null) return 'Klient topilmadi';
    if (amount <= 0) return 'Qarz summasi noto‘g‘ri';

    customer.debt += amount;
    customer.debtDueDate = dueDate;
    final cleanAddress = address?.trim();
    if (cleanAddress != null && cleanAddress.isNotEmpty) {
      customer.address = cleanAddress;
    }
    final cleanNote = note?.trim();
    if (cleanNote != null && cleanNote.isNotEmpty) {
      customer.note = customer.note.trim().isEmpty
          ? cleanNote
          : '${customer.note.trim()}\nQarz: $cleanNote';
    }
    notifyListeners();
    unawaited(_persistCustomers());
    return null;
  }

  String? createDebtor({
    required String name,
    required String phone,
    required String address,
    required double amount,
    required DateTime dueDate,
    String? note,
  }) {
    final u = _user;
    if (u == null) return 'Avval tizimga kiring';
    if (name.trim().isEmpty) return 'Klient nomini kiriting';
    if (address.trim().isEmpty) return 'Manzilni kiriting';
    if (amount <= 0) return 'Qarz summasi noto‘g‘ri';

    final customer = Customer(
      id: _genId(),
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      type: 'Qarzdor',
      note: note?.trim() ?? '',
      debt: amount,
      creditLimit: 0,
      createdAt: DateTime.now(),
      debtDueDate: dueDate,
    );
    _customers.add(customer);
    notifyListeners();
    unawaited(_persistCustomers());
    return null;
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

  List<DebtPayment> paymentsForCustomer(String customerId) {
    return _debtPayments.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  List<Customer> get debtorCustomers {
    return _customers.where((c) => c.debt > 0).toList()
      ..sort((a, b) {
        final ad = a.debtDueDate;
        final bd = b.debtDueDate;
        if (ad == null && bd == null) return b.debt.compareTo(a.debt);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
  }

  double get totalDebt {
    return _customers.fold<double>(0, (sum, c) => sum + c.debt);
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

  void _ensureWorkerProfile(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || workerByName(cleanName) != null) return;
    _workers.add(WorkerProfile(
      id: _genId(),
      name: cleanName,
      phone: '',
      roleTitle: 'Sotuvchi',
      dailyTarget: 0,
      active: true,
      note: '',
      createdAt: DateTime.now(),
    ));
    _sortWorkers();
    if (_isReady) unawaited(_persistWorkers());
  }

  void _syncWorkersFromSales() {
    var changed = false;
    for (final sale in _sales) {
      final workerName = sale.workerName.trim();
      if (workerName.isEmpty || workerByName(workerName) != null) continue;
      _workers.add(WorkerProfile(
        id: _genId(),
        name: workerName,
        phone: '',
        roleTitle: 'Sotuvchi',
        dailyTarget: 0,
        active: true,
        note: 'Sotuv tarixidan qo‘shildi',
        createdAt: sale.at,
      ));
      changed = true;
    }
    if (changed) _sortWorkers();
  }

  void _sortWorkers() {
    _workers.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  String _normName(String value) => value.trim().toLowerCase();

  bool get isPastReportHour {
    final now = DateTime.now();
    return now.hour >= 18;
  }
}
