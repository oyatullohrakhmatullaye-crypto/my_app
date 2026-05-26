import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/shop_service.dart';

/// Tez sotuv: mahsulot + soni + bir tugma. Ovoz — matn sifatida sinov.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Map<String, int> _qty = {};

  int _qFor(String id, int maxStock) {
    final v = _qty[id] ?? 1;
    return v.clamp(1, maxStock > 0 ? maxStock : 1);
  }

  void _setQ(String id, int maxStock, int delta) {
    setState(() {
      final cur = _qty[id] ?? 1;
      final next = (cur + delta).clamp(1, maxStock > 0 ? maxStock : 1);
      _qty[id] = next;
    });
  }

  Future<void> _openVoiceDialog() async {
    final ctrl = TextEditingController(text: '5 dona 2x4 taxta sotildi');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ovoz (sinov)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Haqiqiy ovozdan matnga keyinroq speech_to_text ulash mumkin. Hozir matnni tahrirlang.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masalan: 5 dona 2x4 taxta sotildi',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sotish')),
          ],
        ),
      );
      if (ok == true && mounted) {
        final err = context.read<ShopService>().sellFromVoiceText(ctrl.text);
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sotildi')));
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final products = shop.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sotish'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Ovoz (sinov)',
            onPressed: _openVoiceDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVoiceDialog,
        icon: const Icon(Icons.mic),
        label: const Text('Ovoz'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final maxS = p.quantity;
          final q = _qFor(p.id, maxS);
          if (maxS == 0) {
            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: const Text('Zaxira tugagan'),
              ),
            );
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${p.size} · ${p.price.toStringAsFixed(0)} so‘m · zaxira: $maxS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: q > 1 ? () => _setQ(p.id, maxS, -1) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Text(
                          '$q dona',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: q < maxS ? () => _setQ(p.id, maxS, 1) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () {
                      final err = shop.sell(productId: p.id, quantity: q);
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.name} · $q dona sotildi')),
                        );
                        setState(() => _qty[p.id] = 1);
                      }
                    },
                    child: const Text('SOTISH', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
