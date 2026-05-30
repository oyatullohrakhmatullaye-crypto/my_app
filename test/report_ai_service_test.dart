import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/defect_record.dart';
import 'package:my_app/models/product.dart';
import 'package:my_app/models/sale_record.dart';
import 'package:my_app/services/report_ai_service.dart';

void main() {
  test('buildSummary ranks workers by revenue with KPI details', () {
    final day = DateTime(2026, 5, 30, 10);
    final summary = ReportAiService.buildSummary(
      day: day,
      allSales: [
        SaleRecord(
          id: 's1',
          productId: 'p1',
          productName: '2x4',
          quantity: 2,
          unitPrice: 50000,
          workerName: 'Ali',
          at: day,
        ),
        SaleRecord(
          id: 's2',
          productId: 'p2',
          productName: '2x6',
          quantity: 1,
          unitPrice: 200000,
          workerName: 'Vali',
          at: day,
        ),
        SaleRecord(
          id: 's3',
          productId: 'p1',
          productName: '2x4',
          quantity: 1,
          unitPrice: 50000,
          workerName: 'Ali',
          at: day,
        ),
      ],
      allDefects: <DefectRecord>[],
      products: <Product>[],
      workerTotals: const {},
    );

    expect(summary.workerPerformance, hasLength(2));
    expect(summary.workerPerformance.first.name, 'Vali');
    expect(summary.workerPerformance.first.rank, 1);
    expect(summary.workerPerformance.first.total, 200000);
    expect(summary.workerPerformance.first.checks, 1);
    expect(summary.workerPerformance.last.name, 'Ali');
    expect(summary.workerPerformance.last.checks, 2);
    expect(summary.workerPerformance.last.quantity, 3);
  });
}
