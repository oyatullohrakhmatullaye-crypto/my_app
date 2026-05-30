import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/shop_service.dart';
import '../utils/money_input.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _type = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();

  static const _typePresets = ['Quruq', 'Ho‘l', 'Fanera', 'Brus', 'Reyka'];
  static const _sizePresets = ['2x4', '2x6', '1.22x2.44', '50x50', '25x50'];

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Faqat admin')));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = _parseMoney(_price.text);
    final qty = int.parse(_digitsOnly(_qty.text));
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
      appBar: AppBar(
          title: Text(edit ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      edit ? 'Mahsulot ma’lumotlari' : 'Yangi mahsulot',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nomi',
                        hintText: 'Masalan: 2x4 taxta',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Mahsulot nomini kiriting'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _size,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'O‘lcham',
                        hintText: 'Masalan: 2x4',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'O‘lchamni kiriting'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _presetChips(_sizePresets, _size),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _type,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Turi',
                        hintText: 'Masalan: Quruq',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Turini kiriting' : null,
                    ),
                    const SizedBox(height: 8),
                    _presetChips(_typePresets, _type),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Narxi',
                        hintText: '45000 yoki 45 000 so‘m',
                        suffixText: 'so‘m',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (v) {
                        final price = _parseMoney(v ?? '');
                        if (price <= 0) {
                          return 'Narx 0 dan katta bo‘lishi kerak';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Zaxira',
                        suffixText: 'dona',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                      validator: (v) {
                        final digits = _digitsOnly(v ?? '');
                        if (digits.isEmpty) {
                          return 'Zaxira sonini kiriting';
                        }
                        if (int.parse(digits) < 0) {
                          return 'Zaxira manfiy bo‘lmaydi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label:
                  Text(edit ? 'O‘zgarishlarni saqlash' : 'Mahsulotni qo‘shish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChips(List<String> presets, TextEditingController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in presets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(preset),
                onPressed: () => setState(() => controller.text = preset),
              ),
            ),
        ],
      ),
    );
  }

  double _parseMoney(String value) {
    return parseMoneyInput(value);
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
