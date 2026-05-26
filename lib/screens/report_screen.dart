import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../services/pdf_report_service.dart';
import '../services/shop_service.dart';

/// Kunlik sotuvlar va PDF (admin uchun). 18:00 mantiq — mock yozuv.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final today = DateTime.now();
    final sales = shop.salesForDay(today);
    final total = shop.totalForDay(today);
    final byWorker = shop.workerTotalsForDay(today);
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: Text('Hisobot — ${df.format(today)}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bugungi jami', style: TextStyle(fontSize: 16)),
                  Text(
                    '${total.toStringAsFixed(0)} so‘m',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('Cheklar soni: ${sales.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Ishchilar bo‘yicha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...byWorker.entries.map(
            (e) => Card(
              child: ListTile(
                title: Text(e.key, style: const TextStyle(fontSize: 17)),
                trailing: Text('${e.value.toStringAsFixed(0)} so‘m', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          if (byWorker.isEmpty) const Text('Hozircha sotuv yo‘q'),
          const SizedBox(height: 16),
          const Text('Qoldiq', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...shop.products.map(
            (p) => ListTile(
              title: Text(p.name),
              subtitle: Text(p.size),
              trailing: Text('${p.quantity} dona', style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          if (admin) ...[
            Text(
              shop.isPastReportHour
                  ? 'Soat 18:00 dan keyin — PDF tayyorlash (reja bo‘yicha).'
                  : '18:00 gacha PDF rejalashtirilgan (mock). Hozir ham sinov uchun yaratish mumkin.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () async {
                final doc = await PdfReportService.buildDailyReport(
                  day: today,
                  allSales: shop.sales,
                  products: shop.products,
                  workerTotals: byWorker,
                  grandTotal: total,
                  footerNote: shop.isPastReportHour
                      ? 'Avtomatik hisobot vaqti: 18:00 (mock).'
                      : 'Sinov PDF — 18:00 dan keyin ishlab chiqarish rejasi.',
                );
                await Printing.layoutPdf(
                  onLayout: (format) async => doc.save(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF yuklash / chop etish', style: TextStyle(fontSize: 17)),
            ),
          ] else
            Text(
              'PDF yaratish faqat admin uchun.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
