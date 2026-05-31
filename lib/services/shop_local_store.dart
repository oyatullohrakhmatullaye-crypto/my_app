import 'package:hive_flutter/hive_flutter.dart';

import '../models/customer.dart';
import '../models/debt_payment.dart';
import '../models/defect_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';
import '../models/worker_profile.dart';

class ShopLocalStore {
  static const _boxName = 'shop_box';
  static const _kProducts = 'products';
  static const _kSales = 'sales';
  static const _kDefects = 'defects';
  static const _kCustomers = 'customers';
  static const _kDebtPayments = 'debtPayments';
  static const _kWorkers = 'workers';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Box<dynamic> get _box => Hive.box(_boxName);

  List<Product> loadProducts() {
    final raw = _box.get(_kProducts) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<SaleRecord> loadSales() {
    final raw = _box.get(_kSales) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => SaleRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<DefectRecord> loadDefects() {
    final raw = _box.get(_kDefects) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => DefectRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Customer> loadCustomers() {
    final raw = _box.get(_kCustomers) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => Customer.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<DebtPayment> loadDebtPayments() {
    final raw = _box.get(_kDebtPayments) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => DebtPayment.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<WorkerProfile> loadWorkers() {
    final raw = _box.get(_kWorkers) as List?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => WorkerProfile.fromMap(Map<String, dynamic>.from(e)))
        .where((e) => e.name.trim().isNotEmpty)
        .toList();
  }

  Future<void> saveProducts(List<Product> items) async {
    await _box.put(
        _kProducts, items.map((e) => e.toMap()).toList(growable: false));
  }

  Future<void> saveSales(List<SaleRecord> items) async {
    await _box.put(
        _kSales, items.map((e) => e.toMap()).toList(growable: false));
  }

  Future<void> saveDefects(List<DefectRecord> items) async {
    await _box.put(
        _kDefects, items.map((e) => e.toMap()).toList(growable: false));
  }

  Future<void> saveCustomers(List<Customer> items) async {
    await _box.put(
        _kCustomers, items.map((e) => e.toMap()).toList(growable: false));
  }

  Future<void> saveDebtPayments(List<DebtPayment> items) async {
    await _box.put(
        _kDebtPayments, items.map((e) => e.toMap()).toList(growable: false));
  }

  Future<void> saveWorkers(List<WorkerProfile> items) async {
    await _box.put(
        _kWorkers, items.map((e) => e.toMap()).toList(growable: false));
  }
}
