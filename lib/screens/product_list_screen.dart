import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/shop_service.dart';
import 'product_form_screen.dart';

/// Barcha mahsulotlar ro‘yxati; admin tahrirlashi/o‘chirishi mumkin.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final items = shop.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Mahsulotlar')),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Qo‘shish'),
            )
          : null,
      body: items.isEmpty
          ? const Center(child: Text('Hozircha mahsulot yo‘q'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = items[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.size} · ${p.type} · ${p.price.toStringAsFixed(0)} so‘m\nZaxira: ${p.quantity} dona'),
                    isThreeLine: true,
                    trailing: admin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProductFormScreen(product: p),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('O‘chirish?'),
                                      content: Text('${p.name} o‘chiriladi.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha')),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    shop.deleteProduct(p.id);
                                  }
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
