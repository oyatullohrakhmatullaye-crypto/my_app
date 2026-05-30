import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/sale_record.dart';
import '../services/shop_service.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _query = TextEditingController();
  final _money = NumberFormat.decimalPattern();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final customers = _filtered(shop.customers);
    final totalDebt = shop.customers.fold<double>(0, (sum, c) => sum + c.debt);
    final activeCustomers = shop.customers
        .where((c) => shop.salesForCustomer(c.id).isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klientlar'),
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Yangi klient',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => _openForm(context),
            ),
        ],
      ),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Qo‘shish'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _summary(context,
              count: shop.customers.length,
              active: activeCustomers,
              debt: totalDebt),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Klient qidirish',
              hintText: 'Ism, telefon yoki turi',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (shop.customers.isEmpty)
            _emptyState(context, admin)
          else if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Mos klient topilmadi')),
            )
          else
            for (final customer in customers) _customerCard(context, customer),
        ],
      ),
    );
  }

  List<Customer> _filtered(List<Customer> customers) {
    final q = _query.text.trim().toLowerCase();
    return customers.where((c) {
      final haystack =
          '${c.name} ${c.phone} ${c.type} ${c.address}'.toLowerCase();
      return q.isEmpty || haystack.contains(q);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Widget _summary(
    BuildContext context, {
    required int count,
    required int active,
    required double debt,
  }) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(context,
              icon: Icons.groups_outlined, value: '$count', label: 'Klient'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(context,
              icon: Icons.trending_up, value: '$active', label: 'Faol'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(context,
              icon: Icons.account_balance_wallet_outlined,
              value: _moneyText(debt),
              label: 'Qarz'),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context,
      {required IconData icon, required String value, required String label}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(BuildContext context, Customer customer) {
    final shop = context.watch<ShopService>();
    final admin = shop.user?.isAdmin ?? false;
    final sales = shop.salesForCustomer(customer.id);
    final total = sales.fold<double>(0, (sum, s) => sum + s.total);
    final last = sales.isEmpty ? null : sales.first.at;
    final danger =
        customer.creditLimit > 0 && customer.debt >= customer.creditLimit;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showProfile(context, customer),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    child: Icon(Icons.person_outline,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (customer.type.isNotEmpty) customer.type,
                            if (customer.phone.isNotEmpty) customer.phone,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  if (admin) _adminMenu(context, customer),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(context, Icons.payments_outlined,
                      'Jami: ${_moneyText(total)}'),
                  _chip(context, Icons.receipt_long_outlined,
                      '${sales.length} xarid'),
                  _chip(
                    context,
                    danger
                        ? Icons.warning_amber_outlined
                        : Icons.account_balance_wallet_outlined,
                    'Qarz: ${_moneyText(customer.debt)}',
                    color: danger ? const Color(0xFFB3261E) : null,
                  ),
                  _chip(
                    context,
                    Icons.history,
                    last == null
                        ? 'Hali xarid yo‘q'
                        : 'Oxirgi: ${DateFormat('dd.MM').format(last)}',
                  ),
                ],
              ),
            ],
          ),
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

  Widget _adminMenu(BuildContext context, Customer customer) {
    return PopupMenuButton<String>(
      tooltip: 'Amallar',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'edit') {
          _openForm(context, customer: customer);
          return;
        }
        if (value == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Klientni o‘chirish'),
              content: Text('${customer.name} klient bazasidan o‘chiriladi.'),
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
            context.read<ShopService>().deleteCustomer(customer.id);
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
              leading: Icon(Icons.edit_outlined), title: Text('Tahrirlash')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
              leading: Icon(Icons.delete_outline), title: Text('O‘chirish')),
        ),
      ],
    );
  }

  void _showProfile(BuildContext context, Customer customer) {
    final shop = context.read<ShopService>();
    final sales = shop.salesForCustomer(customer.id);
    final total = shop.totalForCustomer(customer.id);
    final advice = _customerAdvice(customer, sales, total);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(customer.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              [
                if (customer.phone.isNotEmpty) customer.phone,
                if (customer.address.isNotEmpty) customer.address,
              ].join(' · '),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _profileMetric(ctx, 'Jami', _moneyText(total))),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _profileMetric(ctx, 'Qarz', _moneyText(customer.debt))),
                const SizedBox(width: 8),
                Expanded(
                    child: _profileMetric(ctx, 'Xarid', '${sales.length}')),
              ],
            ),
            const SizedBox(height: 14),
            const Text('AI maslahat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final item in advice)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(item),
                ),
              ),
            const SizedBox(height: 10),
            const Text('Oxirgi xaridlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (sales.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Bu klientga hali sotuv bog‘lanmagan.'),
                ),
              )
            else
              for (final sale in sales.take(8)) _saleTile(sale),
          ],
        ),
      ),
    );
  }

  Widget _profileMetric(BuildContext context, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _saleTile(SaleRecord sale) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.point_of_sale),
        title: Text(sale.productName),
        subtitle: Text(
            '${DateFormat('dd.MM.yyyy HH:mm').format(sale.at)} · ${sale.quantity} dona'),
        trailing: Text(_moneyText(sale.total),
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  List<String> _customerAdvice(
      Customer customer, List<SaleRecord> sales, double total) {
    final advice = <String>[];
    if (sales.isEmpty) {
      advice
          .add('Klient yangi: birinchi xaridga kichik chegirma taklif qiling.');
    } else {
      final last = sales.first.at;
      final days = DateTime.now().difference(last).inDays;
      if (days >= 14) {
        advice.add(
            '$days kundan beri xarid qilmagan. Qo‘ng‘iroq qilish foydali.');
      } else {
        advice.add(
            'Faol klient. Xarid odatini ushlab turish uchun aloqa qiling.');
      }
    }
    if (customer.creditLimit > 0 && customer.debt >= customer.creditLimit) {
      advice.add(
          'Qarz limiti to‘lgan. Yangi qarzga sotishdan oldin to‘lov oling.');
    } else if (customer.debt > 0) {
      advice.add('Qarz bor. Keyingi sotuvda to‘lovni eslatish kerak.');
    }
    if (total > 1000000) {
      advice.add('Katta klient. Alohida narx yoki diler sharti berish mumkin.');
    }
    return advice;
  }

  Widget _emptyState(BuildContext context, bool admin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.groups_outlined,
                color: Theme.of(context).colorScheme.primary, size: 42),
            const SizedBox(height: 10),
            const Text('Klient bazasi bo‘sh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              admin
                  ? 'Birinchi klientni qo‘shing va sotuvlarda tanlab boring.'
                  : 'Admin klient qo‘shgandan keyin ro‘yxat chiqadi.',
              textAlign: TextAlign.center,
            ),
            if (admin) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Klient qo‘shish'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Customer? customer}) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
  }

  String _moneyText(double value) {
    return '${_money.format(value.round())} so‘m';
  }
}
