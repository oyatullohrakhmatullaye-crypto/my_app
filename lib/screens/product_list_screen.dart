import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/shop_service.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _query = TextEditingController();
  String _typeFilter = 'Barchasi';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final products = shop.products;
    final types = [
      'Barchasi',
      ...products.map((p) => p.type).where((t) => t.trim().isNotEmpty).toSet()
    ];
    final filtered = _filtered(products);
    final stockValue =
        products.fold<double>(0, (sum, p) => sum + p.price * p.quantity);
    final lowStock = products.where((p) => p.quantity <= 10).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahsulotlar'),
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Yangi mahsulot',
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ProductFormScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ProductFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Qo‘shish'),
            )
          : null,
      body: products.isEmpty
          ? _emptyState(context, admin)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                _summary(products.length, lowStock, stockValue),
                const SizedBox(height: 14),
                TextField(
                  controller: _query,
                  decoration: const InputDecoration(
                    labelText: 'Qidirish',
                    hintText: 'Nomi, o‘lchami yoki turi',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in types)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: _typeFilter == type,
                            onSelected: (_) =>
                                setState(() => _typeFilter = type),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('Mos mahsulot topilmadi')),
                  )
                else
                  for (final product in filtered)
                    _productCard(context, product, admin),
              ],
            ),
    );
  }

  List<Product> _filtered(List<Product> products) {
    final q = _query.text.trim().toLowerCase();
    return products.where((p) {
      final matchesType = _typeFilter == 'Barchasi' || p.type == _typeFilter;
      final haystack = '${p.name} ${p.size} ${p.type}'.toLowerCase();
      final matchesQuery = q.isEmpty || haystack.contains(q);
      return matchesType && matchesQuery;
    }).toList()
      ..sort((a, b) {
        final stockCompare = _stockRank(a).compareTo(_stockRank(b));
        if (stockCompare != 0) return stockCompare;
        return a.name.compareTo(b.name);
      });
  }

  int _stockRank(Product p) {
    if (p.quantity == 0) return 0;
    if (p.quantity <= 10) return 1;
    return 2;
  }

  Widget _summary(int count, int lowStock, double stockValue) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.inventory_2_outlined,
            label: 'Tur',
            value: '$count',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.warning_amber_outlined,
            label: 'Kam zaxira',
            value: '$lowStock',
            alert: lowStock > 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.payments_outlined,
            label: 'Qiymat',
            value: _moneyShort(stockValue),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    bool alert = false,
  }) {
    final color =
        alert ? const Color(0xFFB15D1F) : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, Product p, bool admin) {
    final status = _stockStatus(p);
    final total = p.price * p.quantity;
    final costValue = p.costPrice * p.quantity;
    final profitText = p.costPrice <= 0
        ? 'Tan narx yo‘q'
        : '${p.profitPerUnit.toStringAsFixed(0)} so‘m';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(Icons.straighten,
                              p.size.isEmpty ? 'O‘lcham yo‘q' : p.size),
                          _chip(Icons.category_outlined,
                              p.type.isEmpty ? 'Tur yo‘q' : p.type),
                          _chip(status.icon, status.label, color: status.color),
                        ],
                      ),
                    ],
                  ),
                ),
                if (admin) _adminMenu(context, p),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child:
                        _detail('Narx', '${p.price.toStringAsFixed(0)} so‘m')),
                Expanded(
                    child: _detail(
                        'Tan narx',
                        p.costPrice <= 0
                            ? 'Yo‘q'
                            : '${p.costPrice.toStringAsFixed(0)} so‘m')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _detail('Foyda/dona', profitText)),
                Expanded(child: _detail('Zaxira', '${p.quantity} dona')),
                Expanded(
                    child: _detail(p.costPrice <= 0 ? 'Jami' : 'Tan qiymat',
                        '${(p.costPrice <= 0 ? total : costValue).toStringAsFixed(0)} so‘m')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _adminMenu(BuildContext context, Product p) {
    return PopupMenuButton<String>(
      tooltip: 'Amallar',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
                builder: (_) => ProductFormScreen(product: p)),
          );
          return;
        }
        if (value == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Mahsulotni o‘chirish'),
              content: Text(
                  '${p.name} ro‘yxatdan o‘chiriladi. Bu amal sotuv tarixini o‘chirmaydi.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Bekor')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('O‘chirish')),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            context.read<ShopService>().deleteProduct(p.id);
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
            value: 'edit',
            child: ListTile(
                leading: Icon(Icons.edit_outlined), title: Text('Tahrirlash'))),
        PopupMenuItem(
            value: 'delete',
            child: ListTile(
                leading: Icon(Icons.delete_outline), title: Text('O‘chirish'))),
      ],
    );
  }

  Widget _emptyState(BuildContext context, bool admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Mahsulot yo‘q',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              admin
                  ? 'Birinchi mahsulotni qo‘shing.'
                  : 'Admin mahsulot qo‘shgandan keyin ro‘yxat ko‘rinadi.',
              textAlign: TextAlign.center,
            ),
            if (admin) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const ProductFormScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Mahsulot qo‘shish'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StockStatus _stockStatus(Product p) {
    if (p.quantity == 0) {
      return const _StockStatus(
          'Tugagan', Icons.remove_shopping_cart_outlined, Color(0xFFB3261E));
    }
    if (p.quantity <= 10) {
      return const _StockStatus(
          'Kam zaxira', Icons.warning_amber_outlined, Color(0xFFB15D1F));
    }
    return const _StockStatus(
        'Yetarli', Icons.check_circle_outline, Color(0xFF2F7D55));
  }

  String _moneyShort(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} mln';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)} ming';
    return value.toStringAsFixed(0);
  }
}

class _StockStatus {
  const _StockStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
