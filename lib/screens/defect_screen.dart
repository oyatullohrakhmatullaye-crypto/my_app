import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/shop_service.dart';

/// Ishchi brakni belgilaydi; admin zaxiraga qaytaradi.
class DefectScreen extends StatefulWidget {
  const DefectScreen({super.key});

  @override
  State<DefectScreen> createState() => _DefectScreenState();
}

class _DefectScreenState extends State<DefectScreen> {
  String? _selectedProductId;
  int _qty = 1;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Ro‘yxatdagi tanlov: foydalanuvchi tanlamagan bo‘lsa, birinchi mahsulot.
  Product? _effectiveProduct(List<Product> products) {
    if (products.isEmpty) return null;
    final id = _selectedProductId;
    if (id != null) {
      for (final p in products) {
        if (p.id == id) return p;
      }
    }
    return products.first;
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final products = shop.products;
    final selected = _effectiveProduct(products);

    return Scaffold(
      appBar: AppBar(title: const Text('Brak')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!admin) ...[
            const Text('Brakga berish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (products.isEmpty)
              const Text('Mahsulot yo‘q')
            else ...[
              DropdownButtonFormField<String>(
                value: selected?.id,
                decoration: const InputDecoration(labelText: 'Mahsulot', border: OutlineInputBorder()),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${p.quantity} dona)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedProductId = v;
                  _qty = 1;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Soni:', style: TextStyle(fontSize: 16)),
                  IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_qty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: selected != null && _qty < selected.quantity ? () => setState(() => _qty++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: selected == null
                    ? null
                    : () {
                        final err = shop.reportDefect(productId: selected.id, quantity: _qty, note: _note.text);
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brak qayd etildi')));
                          setState(() {
                            _qty = 1;
                            _note.clear();
                          });
                        }
                      },
                child: const Text('Brakga berish', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
          if (admin) ...[
            const Text('Brak ro‘yxati (admin)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...shop.defects.map((d) {
              return Card(
                child: ListTile(
                  title: Text('${d.productName} · ${d.quantity} dona'),
                  subtitle: Text('${d.workerName} · ${d.note ?? ""} ${d.recovered ? "· qaytarilgan" : ""}'),
                  trailing: d.recovered
                      ? const Chip(label: Text('Zaxirada'))
                      : FilledButton(
                          onPressed: () {
                            final err = shop.recoverDefect(d.id);
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                          child: const Text('Zaxiraga'),
                        ),
                ),
              );
            }),
            if (shop.defects.isEmpty) const Text('Brak yozuvlari yo‘q'),
          ],
        ],
      ),
    );
  }
}
