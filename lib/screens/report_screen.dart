import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../services/pdf_report_service.dart';
import '../services/report_ai_service.dart';
import '../services/shop_service.dart';

/// Kunlik sotuv, brak, qoldiq va aqlli maslahatlar paneli.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final today = DateTime.now();
    final summary = ReportAiService.buildSummary(
      day: today,
      allSales: shop.sales,
      allDefects: shop.defects,
      products: shop.products,
      workerTotals: shop.workerTotalsForDay(today),
    );
    final advice = ReportAiService.buildAdvice(summary);
    final dateFmt = DateFormat('dd.MM.yyyy');
    final timeFmt = DateFormat('HH:mm');
    final finalMode = shop.isPastReportHour;

    return Scaffold(
      appBar: AppBar(title: const Text('Bugungi hisobot')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _closingBanner(
            context,
            date: dateFmt.format(today),
            time: timeFmt.format(today),
            finalMode: finalMode,
          ),
          const SizedBox(height: 14),
          _metricsGrid(context, summary),
          const SizedBox(height: 14),
          _aiAdviceCard(context, advice),
          const SizedBox(height: 14),
          _topProductCard(context, summary),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Ishchilar bo‘yicha'),
          const SizedBox(height: 8),
          _workerTotals(context, summary),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Qoldiq nazorati'),
          const SizedBox(height: 8),
          _stockList(context, summary),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Oxirgi sotuvlar'),
          const SizedBox(height: 8),
          _salesList(context, summary),
          const SizedBox(height: 24),
          if (admin)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              onPressed: () async {
                final doc = await PdfReportService.buildDailyReport(
                  day: today,
                  allSales: shop.sales,
                  products: shop.products,
                  workerTotals: summary.workerTotals,
                  grandTotal: summary.totalRevenue,
                  advice: advice,
                  footerNote: finalMode
                      ? 'Kechki yakuniy hisobot: 18:00 dan keyin.'
                      : 'Jonli hisobot: 18:00 dan keyin yakuniy raqam sifatida ishlating.',
                );
                await Printing.layoutPdf(
                  onLayout: (format) async => doc.save(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF hisobot'),
            )
          else
            Text(
              'PDF yaratish faqat admin uchun.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
        ],
      ),
    );
  }

  Widget _closingBanner(
    BuildContext context, {
    required String date,
    required String time,
    required bool finalMode,
  }) {
    final color = finalMode ? const Color(0xFF2F7D55) : const Color(0xFF315A8C);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(finalMode ? Icons.verified_outlined : Icons.query_stats,
              color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finalMode ? 'Kechki yakun' : 'Jonli hisobot',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$date · $time',
                  style: const TextStyle(color: Color(0xFFEAF4FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(BuildContext context, DailyReportSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final narrow = constraints.maxWidth < 420;
        return GridView.count(
          crossAxisCount: narrow
              ? 1
              : wide
                  ? 4
                  : 2,
          childAspectRatio: narrow
              ? 3.2
              : wide
                  ? 1.35
                  : 2.15,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _metricCard(
              context,
              icon: Icons.payments_outlined,
              label: 'Tushum',
              value: _money(summary.totalRevenue),
              color: const Color(0xFF2F7D55),
            ),
            _metricCard(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Sotildi',
              value: '${summary.soldQuantity} dona',
              color: Theme.of(context).colorScheme.primary,
            ),
            _metricCard(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'O‘rtacha chek',
              value: _money(summary.averageCheck),
              color: const Color(0xFF315A8C),
            ),
            _metricCard(
              context,
              icon: Icons.report_problem_outlined,
              label: 'Brak',
              value: '${summary.defectQuantity} dona',
              color: const Color(0xFFB3261E),
            ),
            _metricCard(
              context,
              icon: Icons.savings_outlined,
              label: 'Sof natija',
              value: _money(summary.netRevenue),
              color: const Color(0xFF6A4C93),
            ),
            _metricCard(
              context,
              icon: Icons.warehouse_outlined,
              label: 'Qoldiq qiymati',
              value: _money(summary.stockValue),
              color: const Color(0xFF7A4A35),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiAdviceCard(BuildContext context, List<ReportAdvice> advice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI maslahat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in advice) _adviceTile(context, item),
          ],
        ),
      ),
    );
  }

  Widget _adviceTile(BuildContext context, ReportAdvice advice) {
    final color = _adviceColor(context, advice.level);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advice.title,
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(advice.body),
        ],
      ),
    );
  }

  Widget _topProductCard(BuildContext context, DailyReportSummary summary) {
    final top = summary.topProduct;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.trending_up),
        title: Text(top == null ? 'Eng yuradigan mahsulot yo‘q' : top.name),
        subtitle: Text(
          top == null
              ? 'Sotuv kiritilganda bu yerda lider mahsulot chiqadi.'
              : '${top.quantity} dona · ${_money(top.total)}',
        ),
        trailing: Text('${summary.lowStockCount} kam'),
      ),
    );
  }

  Widget _workerTotals(BuildContext context, DailyReportSummary summary) {
    if (summary.workerTotals.isEmpty) {
      return _emptyText(context, 'Hozircha ishchi bo‘yicha sotuv yo‘q.');
    }
    final entries = summary.workerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final entry in entries)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(entry.key),
              trailing: Text(
                _money(entry.value),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stockList(BuildContext context, DailyReportSummary summary) {
    final products = summary.products.toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    if (products.isEmpty) return _emptyText(context, 'Mahsulot yo‘q.');
    return Column(
      children: [
        for (final product in products)
          Card(
            child: ListTile(
              leading: Icon(
                product.quantity <= 10
                    ? Icons.warning_amber_outlined
                    : Icons.inventory_2_outlined,
                color: product.quantity <= 10
                    ? const Color(0xFFB15D1F)
                    : const Color(0xFF2F7D55),
              ),
              title: Text(product.name),
              subtitle: Text('${product.size} · ${product.type}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${product.quantity} dona',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(_money(product.price * product.quantity),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _salesList(BuildContext context, DailyReportSummary summary) {
    if (summary.sales.isEmpty) {
      return _emptyText(context, 'Bugun sotuv kiritilmagan.');
    }
    final timeFmt = DateFormat('HH:mm');
    return Column(
      children: [
        for (final sale in summary.sales.take(6))
          Card(
            child: ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: Text(sale.productName),
              subtitle:
                  Text('${timeFmt.format(sale.at)} · ${sale.quantity} dona'),
              trailing: Text(
                _money(sale.total),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w900),
    );
  }

  Widget _emptyText(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }

  Color _adviceColor(BuildContext context, ReportAdviceLevel level) {
    return switch (level) {
      ReportAdviceLevel.good => const Color(0xFF2F7D55),
      ReportAdviceLevel.warning => const Color(0xFFB15D1F),
      ReportAdviceLevel.danger => const Color(0xFFB3261E),
      ReportAdviceLevel.info => const Color(0xFF315A8C),
    };
  }

  String _money(double value) {
    final rounded = value.round();
    final text = NumberFormat.decimalPattern().format(rounded);
    return '$text so‘m';
  }
}
