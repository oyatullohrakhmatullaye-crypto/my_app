import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/customer.dart';
import 'package:my_app/models/product.dart';
import 'package:my_app/models/user_role.dart';
import 'package:my_app/models/debt_payment.dart';
import 'package:my_app/models/defect_record.dart';
import 'package:my_app/models/sale_record.dart';
import 'package:my_app/models/worker_profile.dart';
import 'package:my_app/services/shop_local_store.dart';
import 'package:my_app/services/shop_service.dart';

void main() {
  group('ShopService business safeguards', () {
    test('blocks debt sale when customer credit limit would be exceeded', () {
      final service = ShopService(localStore: _MemoryStore());
      service.login(name: 'Admin', role: UserRole.admin);
      service.addProduct(Product(
        id: 'p1',
        name: '2x4 taxta',
        size: '2x4',
        type: 'Quruq',
        price: 300000,
        costPrice: 240000,
        quantity: 5,
      ));
      service.addCustomer(Customer(
        id: 'c1',
        name: 'Ali',
        phone: '',
        address: 'Toshkent',
        type: 'Doimiy',
        note: '',
        debt: 800000,
        creditLimit: 1000000,
        createdAt: DateTime(2026, 5, 30),
      ));

      final err = service.sell(
        productId: 'p1',
        quantity: 1,
        customerId: 'c1',
        addToDebt: true,
      );

      expect(err, contains('Qarz limiti'));
      expect(service.productById('p1')!.quantity, 5);
      expect(service.customerById('c1')!.debt, 800000);
      expect(service.sales, isEmpty);
    });

    test('does not delete a customer with active debt', () {
      final service = ShopService(localStore: _MemoryStore());
      service.login(name: 'Admin', role: UserRole.admin);
      service.addCustomer(Customer(
        id: 'c1',
        name: 'Ali',
        phone: '',
        address: 'Toshkent',
        type: 'Doimiy',
        note: '',
        debt: 100000,
        creditLimit: 500000,
        createdAt: DateTime(2026, 5, 30),
      ));

      final err = service.deleteCustomer('c1');

      expect(err, contains('Qarzi bor'));
      expect(service.customerById('c1'), isNotNull);
    });

    test('undoes the latest debt sale and restores stock and debt', () {
      final service = ShopService(localStore: _MemoryStore());
      service.login(name: 'Admin', role: UserRole.admin);
      service.addProduct(Product(
        id: 'p1',
        name: '2x4 taxta',
        size: '2x4',
        type: 'Quruq',
        price: 100000,
        costPrice: 80000,
        quantity: 5,
      ));
      service.addCustomer(Customer(
        id: 'c1',
        name: 'Ali',
        phone: '',
        address: 'Toshkent',
        type: 'Doimiy',
        note: '',
        debt: 200000,
        creditLimit: 1000000,
        createdAt: DateTime(2026, 5, 30),
      ));

      final sellErr = service.sell(
        productId: 'p1',
        quantity: 2,
        customerId: 'c1',
        addToDebt: true,
      );
      expect(sellErr, isNull);
      expect(service.productById('p1')!.quantity, 3);
      expect(service.customerById('c1')!.debt, 400000);
      expect(service.sales, hasLength(1));

      final undoErr = service.undoLastSale();

      expect(undoErr, isNull);
      expect(service.productById('p1')!.quantity, 5);
      expect(service.customerById('c1')!.debt, 200000);
      expect(service.sales, isEmpty);
    });
  });
}

class _MemoryStore extends ShopLocalStore {
  @override
  Future<void> init() async {}

  @override
  List<Product> loadProducts() => [];

  @override
  List<SaleRecord> loadSales() => [];

  @override
  List<DefectRecord> loadDefects() => [];

  @override
  List<Customer> loadCustomers() => [];

  @override
  List<DebtPayment> loadDebtPayments() => [];

  @override
  List<WorkerProfile> loadWorkers() => [];

  @override
  Future<void> saveProducts(List<Product> items) async {}

  @override
  Future<void> saveSales(List<SaleRecord> items) async {}

  @override
  Future<void> saveDefects(List<DefectRecord> items) async {}

  @override
  Future<void> saveCustomers(List<Customer> items) async {}

  @override
  Future<void> saveDebtPayments(List<DebtPayment> items) async {}

  @override
  Future<void> saveWorkers(List<WorkerProfile> items) async {}
}
