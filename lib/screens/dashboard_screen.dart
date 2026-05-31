import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/report_ai_service.dart';
import '../services/shop_service.dart';
import 'customer_list_screen.dart';
import 'defect_screen.dart';
import 'debt_list_screen.dart';
import 'login_screen.dart';
import 'product_form_screen.dart';
import 'product_list_screen.dart';
import 'report_screen.dart';
import 'sales_screen.dart';
import 'worker_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final u = shop.user;
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final dailySummary = ReportAiService.buildSummary(
      day: today,
      allSales: shop.sales,
      allDefects: shop.defects,
      products: shop.products,
      workerTotals: shop.workerTotalsForDay(today),
    );
    void openProducts() {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const ProductListScreen()),
      );
    }

    void openCustomers() {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const CustomerListScreen()),
      );
    }

    void openDebts() {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const DebtListScreen()),
      );
    }

    void openWorkers() {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const WorkerListScreen()),
      );
    }

    if (u == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxta do‘koni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Mahsulotlar',
            onPressed: openProducts,
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Klientlar',
            onPressed: openCustomers,
          ),
          if (u.isAdmin)
            IconButton(
              icon: const Icon(Icons.badge_outlined),
              tooltip: 'Ishchilar',
              onPressed: openWorkers,
            ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Qarzdorlik',
            onPressed: openDebts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Chiqish',
            onPressed: () {
              shop.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, ${u.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  u.isAdmin ? 'Administrator paneli' : 'Ishchi sotuv paneli',
                  style:
                      const TextStyle(color: Color(0xFFFFEDE2), fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            childAspectRatio:
                MediaQuery.sizeOf(context).width > 720 ? 1.65 : 2.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _tapStatCard(
                context,
                label: 'Mahsulot',
                value: '${shop.products.length}',
                icon: Icons.inventory_2_outlined,
                onTap: openProducts,
              ),
              _tapStatCard(
                context,
                label: 'Klient',
                value: '${shop.customers.length}',
                icon: Icons.groups_outlined,
                onTap: openCustomers,
              ),
              if (u.isAdmin)
                _tapStatCard(
                  context,
                  label: 'Ishchi',
                  value: '${shop.workers.length}',
                  icon: Icons.badge_outlined,
                  onTap: openWorkers,
                ),
              _tapStatCard(
                context,
                label: 'Qarz',
                value: _moneyShort(shop.totalDebt),
                icon: Icons.account_balance_wallet_outlined,
                onTap: openDebts,
              ),
              _statCard(
                context,
                label: 'Bugun',
                value: '${dailySummary.checkCount}',
                icon: Icons.receipt_long_outlined,
              ),
              _statCard(
                context,
                label: 'Brak',
                value: '${shop.defects.length}',
                icon: Icons.report_problem_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (u.isAdmin) ...[
            _sellerKpiPanel(context, dailySummary),
            const SizedBox(height: 18),
          ],
          Text(
            'Tezkor amallar',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _quickActionButton(
                context,
                label: 'Sotish',
                icon: Icons.point_of_sale,
                color: const Color(0xFF2F7D55),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SalesScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _quickActionButton(
                context,
                label: 'Mahsulotlar',
                icon: Icons.inventory_2_outlined,
                color: colors.primary,
                onTap: openProducts,
              ),
              const SizedBox(height: 10),
              _quickActionButton(
                context,
                label: 'Klientlar',
                icon: Icons.groups_outlined,
                color: const Color(0xFF6A4C93),
                onTap: openCustomers,
              ),
              if (u.isAdmin) ...[
                const SizedBox(height: 10),
                _quickActionButton(
                  context,
                  label: 'Ishchilar',
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF315A8C),
                  onTap: openWorkers,
                ),
              ],
              const SizedBox(height: 10),
              _quickActionButton(
                context,
                label: 'Qarzdorlik',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFB15D1F),
                onTap: openDebts,
              ),
              const SizedBox(height: 10),
              _quickActionButton(
                context,
                label: 'Brak',
                icon: Icons.report_problem_outlined,
                color: const Color(0xFFB15D1F),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const DefectScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _quickActionButton(
                context,
                label: 'Hisobot',
                icon: Icons.analytics_outlined,
                color: const Color(0xFF315A8C),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ReportScreen()),
                ),
              ),
              if (u.isAdmin) ...[
                const SizedBox(height: 10),
                _quickActionButton(
                  context,
                  label: 'Yangi mahsulot',
                  icon: Icons.add_box_outlined,
                  color: const Color(0xFF6A4C93),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const ProductFormScreen()),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _sellerKpiPanel(BuildContext context, DailyReportSummary summary) {
    final colors = Theme.of(context).colorScheme;
    final workers = summary.workerPerformance;
    final insight = _sellerInsight(summary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_outlined, color: colors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sotuvchilar KPI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _money(summary.totalRevenue),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bugungi sotuvlar: ${summary.checkCount} chek · ${summary.soldQuantity} dona',
              style: TextStyle(color: colors.outline),
            ),
            const SizedBox(height: 12),
            _sellerInsightBox(context, insight),
            const SizedBox(height: 12),
            if (workers.isEmpty)
              Text(
                'Hali sotuvchi bo‘yicha sotuv yo‘q. Har bir ishchi o‘z ismi bilan kirib sotuv qilsa, boshliq bu yerda natijani ko‘radi.',
                style: TextStyle(color: colors.outline),
              )
            else
              Column(
                children: [
                  for (final worker in workers.take(5))
                    _sellerKpiRow(context, worker, workers.first.total),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _sellerKpiRow(
    BuildContext context,
    WorkerPerformance worker,
    double topTotal,
  ) {
    final colors = Theme.of(context).colorScheme;
    final progress =
        topTotal <= 0 ? 0.0 : (worker.total / topTotal).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: Text(
                  '${worker.rank}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      '${worker.checks} chek · ${worker.quantity} dona · o‘rtacha ${_money(worker.averageCheck)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(worker.total),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('${(worker.share * 100).round()}%',
                      style: TextStyle(color: colors.outline, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerInsightBox(BuildContext context, _SellerInsight insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: insight.color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        color: insight.color, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(insight.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _SellerInsight _sellerInsight(DailyReportSummary summary) {
    final workers = summary.workerPerformance;
    if (workers.isEmpty) {
      return const _SellerInsight(
        title: 'AI KPI kutyapti',
        body:
            'Birinchi sotuv kiritilishi bilan sotuvchi reytingi va boshqaruv signali shu yerda chiqadi.',
        icon: Icons.auto_awesome,
        color: Color(0xFF315A8C),
      );
    }
    final leader = workers.first;
    if (workers.length == 1) {
      return _SellerInsight(
        title: '${leader.name} yakka sotuvda',
        body:
            'Bugun barcha tushum bitta sotuvchida. Ikkinchi sotuvchi ishga tushsa, taqqoslash va vazifa berish osonlashadi.',
        icon: Icons.insights_outlined,
        color: const Color(0xFF315A8C),
      );
    }
    if (leader.share >= 0.7) {
      return _SellerInsight(
        title: 'Sotuv liderga juda bog‘langan',
        body:
            '${leader.name} tushumning ${(leader.share * 100).round()}% qismini qildi. Qolgan sotuvchilarga eng yuradigan mahsulot bo‘yicha aniq vazifa bering.',
        icon: Icons.warning_amber_outlined,
        color: const Color(0xFFB15D1F),
      );
    }
    return _SellerInsight(
      title: 'Jamoa ritmi sog‘lom',
      body:
          'Lider ${leader.name}, ammo tushum jamoa bo‘yicha bo‘linyapti. Shu balansni ushlab, pastdagi sotuvchiga kichik kunlik target bering.',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF2F7D55),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tapStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: _statCard(
          context,
          label: label,
          value: value,
          icon: icon,
        ),
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: const Color(0xFF211A16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: Color(0xFFE8DED5)),
        ),
      ),
    );
  }

  String _moneyShort(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} mln';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)} ming';
    return value.toStringAsFixed(0);
  }

  String _money(double value) {
    final text = NumberFormat.decimalPattern().format(value.round());
    return '$text so‘m';
  }
}

class _SellerInsight {
  const _SellerInsight({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}
