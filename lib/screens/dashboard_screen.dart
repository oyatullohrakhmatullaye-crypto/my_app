import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/shop_service.dart';
import 'defect_screen.dart';
import 'login_screen.dart';
import 'product_list_screen.dart';
import 'product_form_screen.dart';
import 'report_screen.dart';
import 'sales_screen.dart';

/// Admin va ishchi uchun turli tugmalar — katta bosilish maydoni.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final u = shop.user;
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
        title: Text(u.isAdmin ? 'Boshqaruv paneli' : 'Ishchi paneli'),
        actions: [
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
        padding: const EdgeInsets.all(16),
        children: [
          Text('Salom, ${u.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            u.isAdmin ? 'Administrator rejimi' : 'Sotuv rejimi',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _bigNav(
            context,
            label: 'Sotish',
            icon: Icons.point_of_sale,
            color: Colors.green.shade700,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const SalesScreen()),
            ),
          ),
          _bigNav(
            context,
            label: 'Mahsulotlar',
            icon: Icons.inventory_2_outlined,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProductListScreen()),
            ),
          ),
          _bigNav(
            context,
            label: 'Brak',
            icon: Icons.report_problem_outlined,
            color: Colors.orange.shade800,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const DefectScreen()),
            ),
          ),
          _bigNav(
            context,
            label: 'Bugungi hisobot',
            icon: Icons.analytics_outlined,
            color: Colors.indigo.shade700,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const ReportScreen()),
            ),
          ),
          if (u.isAdmin)
            _bigNav(
              context,
              label: 'Yangi mahsulot',
              icon: Icons.add_box_outlined,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bigNav(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(icon, size: 32, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
