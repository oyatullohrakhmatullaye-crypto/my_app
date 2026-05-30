import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../services/shop_service.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _debt = TextEditingController();
  final _limit = TextEditingController();
  String _type = 'Doimiy';

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _name.text = c.name;
      _phone.text = c.phone;
      _address.text = c.address;
      _note.text = c.note;
      _debt.text = c.debt.toStringAsFixed(0);
      _limit.text = c.creditLimit.toStringAsFixed(0);
      _type = c.type.isEmpty ? 'Doimiy' : c.type;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _debt.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final shop = context.read<ShopService>();
    final existing = widget.customer;
    final debt = _number(_debt.text);
    final limit = _number(_limit.text);

    if (existing == null) {
      shop.addCustomer(
        Customer(
          id: 'customer_${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          type: _type,
          note: _note.text.trim(),
          debt: debt,
          creditLimit: limit,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      shop.updateCustomer(
        existing.copyWith(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          type: _type,
          note: _note.text.trim(),
          debt: debt,
          creditLimit: limit,
        ),
      );
    }
    Navigator.pop(context);
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.customer != null;
    return Scaffold(
      appBar:
          AppBar(title: Text(edit ? 'Klientni tahrirlash' : 'Yangi klient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Ism yoki firma',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Klient nomini kiriting'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '+998 90 123 45 67',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Klient turi',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Doimiy', child: Text('Doimiy')),
                DropdownMenuItem(value: 'Usta', child: Text('Usta')),
                DropdownMenuItem(value: 'Diler', child: Text('Diler')),
                DropdownMenuItem(value: 'Oddiy', child: Text('Oddiy')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Doimiy'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Manzil',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _debt,
                    decoration: const InputDecoration(
                      labelText: 'Qarz',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _limit,
                    decoration: const InputDecoration(
                      labelText: 'Qarz limiti',
                      prefixIcon: Icon(Icons.speed_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Izoh',
                hintText: 'Masalan: 2x4 ko‘p oladi, yetkazib berish kerak',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(edit ? 'Saqlash' : 'Klient qo‘shish'),
            ),
          ],
        ),
      ),
    );
  }
}
