import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../services/shop_service.dart';
import 'customer_form_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final _query = TextEditingController();
  final _money = NumberFormat.decimalPattern();
  final _date = DateFormat('dd.MM.yyyy');

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final debtors = _filtered(shop.debtorCustomers);
    final overdue = shop.debtorCustomers.where(_isOverdue).length;
    final dueSoon = shop.debtorCustomers.where(_isDueSoon).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Qarzdorlik')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _summary(context,
              totalDebt: shop.totalDebt,
              debtorCount: shop.debtorCustomers.length,
              overdue: overdue,
              dueSoon: dueSoon),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Qarzdor qidirish',
              hintText: 'Ism, telefon yoki manzil',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (shop.debtorCustomers.isEmpty)
            _emptyState(context)
          else if (debtors.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Mos qarzdor topilmadi')),
            )
          else
            for (final customer in debtors)
              _debtorCard(context, shop, customer),
        ],
      ),
    );
  }

  List<Customer> _filtered(List<Customer> customers) {
    final q = _query.text.trim().toLowerCase();
    return customers.where((c) {
      final haystack = '${c.name} ${c.phone} ${c.address}'.toLowerCase();
      return q.isEmpty || haystack.contains(q);
    }).toList();
  }

  Widget _summary(
    BuildContext context, {
    required double totalDebt,
    required int debtorCount,
    required int overdue,
    required int dueSoon,
  }) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
      childAspectRatio: MediaQuery.sizeOf(context).width > 720 ? 1.65 : 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metric(context, Icons.account_balance_wallet_outlined,
            _moneyText(totalDebt), 'Jami qarz', const Color(0xFF7A4A35)),
        _metric(context, Icons.groups_outlined, '$debtorCount', 'Qarzdor',
            Theme.of(context).colorScheme.primary),
        _metric(context, Icons.warning_amber_outlined, '$overdue', 'O‘tgan',
            const Color(0xFFB3261E)),
        _metric(context, Icons.event_available_outlined, '$dueSoon', 'Yaqin',
            const Color(0xFFB15D1F)),
      ],
    );
  }

  Widget _metric(BuildContext context, IconData icon, String value,
      String label, Color c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _debtorCard(BuildContext context, ShopService shop, Customer c) {
    final status = _status(c);
    final payments = shop.paymentsForCustomer(c.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: status.color.withValues(alpha: 0.12),
                  child: Icon(status.icon, color: status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        c.phone.isEmpty ? 'Telefon kiritilmagan' : c.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Text(_moneyText(c.debt),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, status.icon, status.label, color: status.color),
                _chip(
                  context,
                  Icons.event_outlined,
                  c.debtDueDate == null
                      ? 'Qaytarish kuni yo‘q'
                      : _date.format(c.debtDueDate!),
                  color: status.color,
                ),
                if (c.lastPaymentAt != null)
                  _chip(context, Icons.payments_outlined,
                      'Oxirgi to‘lov: ${_date.format(c.lastPaymentAt!)}'),
                if (payments.isNotEmpty)
                  _chip(context, Icons.receipt_long_outlined,
                      '${payments.length} to‘lov'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showPaymentDialog(context, c),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('To‘lov'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Qarz sanasini tahrirlash',
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => CustomerFormScreen(customer: c)),
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text,
      {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(
      BuildContext context, Customer customer) async {
    final amountCtrl =
        TextEditingController(text: customer.debt.toStringAsFixed(0));
    final noteCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${customer.name} to‘lovi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'To‘lov summasi',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Izoh',
                  hintText: 'Naqd, karta, qisman to‘lov...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bekor')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Saqlash')),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        final amount = double.tryParse(
                amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.')) ??
            0;
        final err = context.read<ShopService>().addDebtPayment(
              customerId: customer.id,
              amount: amount,
              note: noteCtrl.text.trim(),
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'To‘lov qabul qilindi')),
        );
      }
    } finally {
      amountCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  Widget _emptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                color: const Color(0xFF2F7D55), size: 46),
            const SizedBox(height: 10),
            const Text('Qarzdorlik yo‘q',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Qarzga sotuv yoki klient kartasiga qarz qo‘shilganda bu yerda chiqadi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  _DebtStatus _status(Customer c) {
    final due = c.debtDueDate;
    if (due == null) {
      return const _DebtStatus(
          'Sana yo‘q', Icons.help_outline, Color(0xFF315A8C));
    }
    final today = DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day);
    final nowDay = DateTime(today.year, today.month, today.day);
    final diff = dueDay.difference(nowDay).inDays;
    if (diff < 0) {
      return _DebtStatus('${diff.abs()} kun o‘tgan',
          Icons.warning_amber_outlined, const Color(0xFFB3261E));
    }
    if (diff <= 3) {
      return _DebtStatus('$diff kun qoldi', Icons.event_available_outlined,
          const Color(0xFFB15D1F));
    }
    return _DebtStatus(
        '$diff kun qoldi', Icons.check_circle_outline, const Color(0xFF2F7D55));
  }

  bool _isOverdue(Customer c) {
    final due = c.debtDueDate;
    if (due == null) return false;
    final today = DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isDueSoon(Customer c) {
    final due = c.debtDueDate;
    if (due == null || _isOverdue(c)) return false;
    final today = DateTime.now();
    final diff = DateTime(due.year, due.month, due.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return diff <= 3;
  }

  String _moneyText(double value) {
    return '${_money.format(value.round())} so‘m';
  }
}

class _DebtStatus {
  const _DebtStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
