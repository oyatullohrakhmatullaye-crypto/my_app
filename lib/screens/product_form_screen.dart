import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/shop_service.dart';

/// Yangi mahsulot yoki mavjudini tahrirlash (faqat admin ochishi kerak).
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _type = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _size.text = p.size;
      _type.text = p.type;
      _price.text = p.price.toStringAsFixed(0);
      _qty.text = '${p.quantity}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _type.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _save() {
    final shop = context.read<ShopService>();
    if (!(shop.user?.isAdmin ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faqat admin')));
      return;
    }
    final price = double.tryParse(_price.text.replaceAll(' ', '')) ?? 0;
    final qty = int.tryParse(_qty.text) ?? 0;
    if (_name.text.trim().isEmpty || price <= 0 || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maydonlarni to‘ldiring')));
      return;
    }
    final existing = widget.product;
    if (existing != null) {
      shop.updateProduct(
        existing.copyWith(
          name: _name.text.trim(),
          size: _size.text.trim(),
          type: _type.text.trim(),
          price: price,
          quantity: qty,
        ),
      );
    } else {
      shop.addProduct(
        Product(
          id: 'id_${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          size: _size.text.trim(),
          type: _type.text.trim(),
          price: price,
          quantity: qty,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(edit ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nomi', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _size, decoration: const InputDecoration(labelText: 'O‘lcham (masalan 2x4)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _type, decoration: const InputDecoration(labelText: 'Turi', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Narxi (so‘m)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Zaxira (dona)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Saqlash', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
