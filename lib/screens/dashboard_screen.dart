import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/shop_service.dart';
import 'defect_screen.dart';
import 'login_screen.dart';
import 'product_form_screen.dart';
import 'product_list_screen.dart';
import 'report_screen.dart';
import 'sales_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final u = shop.user;
    final colors = Theme.of(context).colorScheme;
    void openProducts() {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const ProductListScreen()),
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
          Row(
            children: [
              Expanded(
                child: _tapStatCard(
                  context,
                  label: 'Mahsulot',
                  value: '${shop.products.length}',
                  icon: Icons.inventory_2_outlined,
                  onTap: openProducts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  label: 'Bugun',
                  value: '${shop.salesForDay(DateTime.now()).length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  label: 'Brak',
                  value: '${shop.defects.length}',
                  icon: Icons.report_problem_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
}
