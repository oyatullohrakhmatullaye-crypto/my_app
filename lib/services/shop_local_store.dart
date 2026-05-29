import 'package:hive_flutter/hive_flutter.dart';

import '../models/defect_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';

class ShopLocalStore {
  static const _boxName = 'shop_box';
  static const _kProducts = 'products';
  static const _kSales = 'sales';
  static const _kDefects = 'defects';

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
}
