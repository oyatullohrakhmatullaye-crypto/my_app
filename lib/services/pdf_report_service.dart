import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/product.dart';
import '../models/sale_record.dart';

/// Kunlik hisobot PDF — chop etish yoki ulashish uchun.
class PdfReportService {
  static final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

  static Future<pw.Document> buildDailyReport({
    required DateTime day,
    required List<SaleRecord> allSales,
    required List<Product> products,
    required Map<String, double> workerTotals,
    required double grandTotal,
    String footerNote = '',
  }) async {
    final doc = pw.Document();
    final daySales =
        allSales.where((s) => _sameDay(s.at, day)).toList()..sort((a, b) => a.at.compareTo(b.at));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Kunlik sotuv hisoboti — ${DateFormat('dd.MM.yyyy').format(day)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Jami sotuv: ${grandTotal.toStringAsFixed(0)} so‘m',
              style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Text('Ishchilar bo‘yicha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: const ['Ishchi', 'Jami (so‘m)'],
            data: workerTotals.entries
                .map((e) => [e.key, e.value.toStringAsFixed(0)])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Sotuvlar ro‘yxati', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: const ['Vaqt', 'Mahsulot', 'Soni', 'Summa'],
            data: daySales
                .map((s) => [
                      _dateFmt.format(s.at),
                      s.productName,
                      '${s.quantity}',
                      s.total.toStringAsFixed(0),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Qoldiq', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: const ['Mahsulot', 'O‘lcham', 'Qoldiq (dona)'],
            data: products
                .map((p) => [p.name, p.size, '${p.quantity}'])
                .toList(),
          ),
          if (footerNote.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(footerNote, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
    return doc;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
