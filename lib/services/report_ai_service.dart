import '../models/defect_record.dart';
import '../models/debt_payment.dart';
import '../models/product.dart';
import '../models/sale_record.dart';

enum ReportAdviceLevel { good, warning, danger, info }

class ReportAdvice {
  const ReportAdvice({
    required this.title,
    required this.body,
    required this.level,
  });

  final String title;
  final String body;
  final ReportAdviceLevel level;
}

class ProductSaleSummary {
  const ProductSaleSummary({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final int quantity;
  final double total;
}

class WorkerPerformance {
  const WorkerPerformance({
    required this.name,
    required this.total,
    required this.checks,
    required this.quantity,
    required this.averageCheck,
    required this.share,
    required this.rank,
  });

  final String name;
  final double total;
  final int checks;
  final int quantity;
  final double averageCheck;
  final double share;
  final int rank;
}

class DailyReportSummary {
  const DailyReportSummary({
    required this.sales,
    required this.defects,
    required this.products,
    required this.workerTotals,
    required this.workerPerformance,
    required this.totalRevenue,
    required this.cashRevenue,
    required this.debtRevenue,
    required this.debtPaymentsReceived,
    required this.cashInflow,
    required this.soldQuantity,
    required this.averageCheck,
    required this.grossProfit,
    required this.profitMargin,
    required this.salesMissingCost,
    required this.defectQuantity,
    required this.defectValue,
    required this.stockValue,
    required this.lowStockCount,
    required this.topProduct,
  });

  final List<SaleRecord> sales;
  final List<DefectRecord> defects;
  final List<Product> products;
  final Map<String, double> workerTotals;
  final List<WorkerPerformance> workerPerformance;
  final double totalRevenue;
  final double cashRevenue;
  final double debtRevenue;
  final double debtPaymentsReceived;
  final double cashInflow;
  final int soldQuantity;
  final double averageCheck;
  final double grossProfit;
  final double profitMargin;
  final int salesMissingCost;
  final int defectQuantity;
  final double defectValue;
  final double stockValue;
  final int lowStockCount;
  final ProductSaleSummary? topProduct;

  int get checkCount => sales.length;
  double get netRevenue => totalRevenue - defectValue;
}

class ReportAiService {
  static DailyReportSummary buildSummary({
    required DateTime day,
    required List<SaleRecord> allSales,
    required List<DefectRecord> allDefects,
    required List<Product> products,
    required Map<String, double> workerTotals,
    List<DebtPayment> allDebtPayments = const [],
  }) {
    final sales = allSales.where((s) => _sameDay(s.at, day)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final defects = allDefects.where((d) => _sameDay(d.at, day)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final debtPayments =
        allDebtPayments.where((p) => _sameDay(p.at, day)).toList();
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.total);
    final cashRevenue = sales
        .where((s) => !s.onDebt)
        .fold<double>(0, (sum, s) => sum + s.total);
    final debtRevenue =
        sales.where((s) => s.onDebt).fold<double>(0, (sum, s) => sum + s.total);
    final debtPaymentsReceived =
        debtPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final cashInflow = cashRevenue + debtPaymentsReceived;
    final grossProfit = sales.fold<double>(0, (sum, s) => sum + s.grossProfit);
    final salesMissingCost = sales.where((s) => !s.hasKnownCost).length;
    final soldQuantity = sales.fold<int>(0, (sum, s) => sum + s.quantity);
    final defectQuantity = defects.fold<int>(0, (sum, d) => sum + d.quantity);
    final stockValue =
        products.fold<double>(0, (sum, p) => sum + p.price * p.quantity);
    final lowStockCount = products.where((p) => p.quantity <= 10).length;
    final defectValue = defects.fold<double>(0, (sum, defect) {
      final price = _priceForProduct(products, defect.productId);
      return sum + price * defect.quantity;
    });

    final productMap = <String, _MutableProductSale>{};
    for (final sale in sales) {
      final current = productMap.putIfAbsent(
        sale.productName,
        () => _MutableProductSale(sale.productName),
      );
      current.quantity += sale.quantity;
      current.total += sale.total;
    }
    final productSales = productMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final topProduct = productSales.isEmpty
        ? null
        : ProductSaleSummary(
            name: productSales.first.name,
            quantity: productSales.first.quantity,
            total: productSales.first.total,
          );
    final workerPerformance = _buildWorkerPerformance(sales, totalRevenue);

    return DailyReportSummary(
      sales: sales,
      defects: defects,
      products: products,
      workerTotals: workerTotals,
      workerPerformance: workerPerformance,
      totalRevenue: totalRevenue,
      cashRevenue: cashRevenue,
      debtRevenue: debtRevenue,
      debtPaymentsReceived: debtPaymentsReceived,
      cashInflow: cashInflow,
      soldQuantity: soldQuantity,
      averageCheck: sales.isEmpty ? 0 : totalRevenue / sales.length,
      grossProfit: grossProfit,
      profitMargin: totalRevenue <= 0 ? 0 : (grossProfit / totalRevenue) * 100,
      salesMissingCost: salesMissingCost,
      defectQuantity: defectQuantity,
      defectValue: defectValue,
      stockValue: stockValue,
      lowStockCount: lowStockCount,
      topProduct: topProduct,
    );
  }

  static List<ReportAdvice> buildAdvice(DailyReportSummary summary) {
    final advice = <ReportAdvice>[];

    if (summary.sales.isEmpty) {
      advice.add(const ReportAdvice(
        title: 'Hali sotuv yo‘q',
        body:
            'Kun oxirida aniq hisobot chiqishi uchun har bir sotuvni darhol kiritib boring.',
        level: ReportAdviceLevel.info,
      ));
    } else {
      advice.add(ReportAdvice(
        title: 'Kunlik savdo qayd qilindi',
        body:
            'Bugun ${summary.checkCount} ta chek orqali ${summary.soldQuantity} dona mahsulot sotildi. Kassaga kirgan pulni alohida ko‘ring.',
        level: ReportAdviceLevel.good,
      ));
    }

    if (summary.debtRevenue > 0) {
      advice.add(ReportAdvice(
        title: 'Qarzga sotuv kassaga kirmaydi',
        body:
            'Bugun ${summary.debtRevenue.toStringAsFixed(0)} so‘m qarzga yozildi. Real kassa kirimi ${summary.cashInflow.toStringAsFixed(0)} so‘m.',
        level: ReportAdviceLevel.warning,
      ));
    } else if (summary.cashInflow > 0) {
      advice.add(ReportAdvice(
        title: 'Kassa kirimi ajratildi',
        body:
            'Bugun kassaga tushgan pul ${summary.cashInflow.toStringAsFixed(0)} so‘m: naqd sotuv va qarz to‘lovlari birga hisoblandi.',
        level: ReportAdviceLevel.good,
      ));
    }

    final topProduct = summary.topProduct;
    if (topProduct != null) {
      advice.add(ReportAdvice(
        title: 'Eng yuradigan mahsulot',
        body:
            '${topProduct.name} bugun ${topProduct.quantity} dona sotildi. Shu pozitsiya zaxirasini birinchi tekshiring.',
        level: ReportAdviceLevel.good,
      ));
    }

    if (summary.lowStockCount > 0) {
      advice.add(ReportAdvice(
        title: 'Zaxira xavfi bor',
        body:
            '${summary.lowStockCount} ta mahsulotda qoldiq 10 donadan kam. Ertangi savdo to‘xtab qolmasligi uchun to‘ldirish kerak.',
        level: ReportAdviceLevel.warning,
      ));
    } else {
      advice.add(const ReportAdvice(
        title: 'Zaxira yetarli',
        body: 'Hozircha mahsulotlar bo‘yicha kritik kamlik ko‘rinmayapti.',
        level: ReportAdviceLevel.good,
      ));
    }

    if (summary.salesMissingCost > 0) {
      advice.add(ReportAdvice(
        title: 'Foyda to‘liq ko‘rinmayapti',
        body:
            '${summary.salesMissingCost} ta sotuvda tan narx yo‘q. Mahsulotlarga tan narx kiritilsa, sof foyda va marja aniq chiqadi.',
        level: ReportAdviceLevel.warning,
      ));
    } else if (summary.grossProfit > 0) {
      advice.add(ReportAdvice(
        title: 'Foyda nazoratga tushdi',
        body:
            'Bugungi taxminiy yalpi foyda ${summary.grossProfit.toStringAsFixed(0)} so‘m, marja ${summary.profitMargin.toStringAsFixed(1)}%.',
        level: summary.profitMargin < 15
            ? ReportAdviceLevel.warning
            : ReportAdviceLevel.good,
      ));
    }

    if (summary.defectQuantity > 0) {
      advice.add(ReportAdvice(
        title: 'Brakni alohida tekshiring',
        body:
            'Bugun ${summary.defectQuantity} dona brak kiritildi. Taxminiy yo‘qotish: ${summary.defectValue.toStringAsFixed(0)} so‘m.',
        level: ReportAdviceLevel.danger,
      ));
    }

    if (summary.averageCheck > 0 && summary.averageCheck < 100000) {
      advice.add(ReportAdvice(
        title: 'O‘rtacha chek past',
        body:
            'O‘rtacha chek ${summary.averageCheck.toStringAsFixed(0)} so‘m. Sotuvda qo‘shimcha mahsulot tavsiya qilish foydali bo‘ladi.',
        level: ReportAdviceLevel.warning,
      ));
    }

    final workers = summary.workerPerformance;
    if (workers.length > 1) {
      final leader = workers.first;
      final last = workers.last;
      if (leader.share >= 0.7) {
        advice.add(ReportAdvice(
          title: 'Sotuv bir odamga bog‘lanib qolgan',
          body:
              '${leader.name} bugungi tushumning ${(leader.share * 100).round()}% qismini qildi. Qolgan sotuvchilarga ham aniq vazifa va mahsulot tavsiyasi bering.',
          level: ReportAdviceLevel.warning,
        ));
      } else {
        advice.add(ReportAdvice(
          title: 'Sotuvchilar balansi yaxshi',
          body:
              'Lider ${leader.name}, lekin tushum bir kishiga haddan tashqari bog‘lanmagan. Jamoa ritmini shu holatda ushlab turing.',
          level: ReportAdviceLevel.good,
        ));
      }

      if (last.checks <= 1 && last.total < leader.total * 0.35) {
        advice.add(ReportAdvice(
          title: 'Kuchsiz nuqtani ko‘taring',
          body:
              '${last.name}da chek kam. Unga eng yuradigan mahsulot va tayyor mijoz gaplashuv sxemasini bering.',
          level: ReportAdviceLevel.info,
        ));
      }
    } else if (workers.length == 1) {
      advice.add(ReportAdvice(
        title: 'Sotuv bitta xodimda',
        body:
            '${workers.first.name} bugun yagona sotuvchi sifatida ishlayapti. Navbat yoki ikkinchi sotuvchini qo‘shish zarur bo‘lsa, hoziroq ko‘rinadi.',
        level: ReportAdviceLevel.info,
      ));
    }

    return advice;
  }

  static List<WorkerPerformance> _buildWorkerPerformance(
    List<SaleRecord> sales,
    double totalRevenue,
  ) {
    final workerMap = <String, _MutableWorkerPerformance>{};
    for (final sale in sales) {
      final current = workerMap.putIfAbsent(
        sale.workerName,
        () => _MutableWorkerPerformance(sale.workerName),
      );
      current.checks += 1;
      current.quantity += sale.quantity;
      current.total += sale.total;
    }

    final rows = workerMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return [
      for (var i = 0; i < rows.length; i++)
        WorkerPerformance(
          name: rows[i].name,
          total: rows[i].total,
          checks: rows[i].checks,
          quantity: rows[i].quantity,
          averageCheck:
              rows[i].checks == 0 ? 0 : rows[i].total / rows[i].checks,
          share: totalRevenue <= 0 ? 0 : rows[i].total / totalRevenue,
          rank: i + 1,
        ),
    ];
  }

  static double _priceForProduct(List<Product> products, String id) {
    for (final product in products) {
      if (product.id == id) return product.price;
    }
    return 0;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MutableProductSale {
  _MutableProductSale(this.name);

  final String name;
  int quantity = 0;
  double total = 0;
}

class _MutableWorkerPerformance {
  _MutableWorkerPerformance(this.name);

  final String name;
  int checks = 0;
  int quantity = 0;
  double total = 0;
}
