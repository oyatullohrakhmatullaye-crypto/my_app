import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/worker_profile.dart';
import '../services/report_ai_service.dart';
import '../services/shop_service.dart';
import '../utils/money_input.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
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
    final today = DateTime.now();
    final summary = ReportAiService.buildSummary(
      day: today,
      allSales: shop.sales,
      allDefects: shop.defects,
      products: shop.products,
      workerTotals: shop.workerTotalsForDay(today),
    );
    final performanceByName = {
      for (final item in summary.workerPerformance)
        item.name.trim().toLowerCase(): item
    };
    final workers = _filtered(shop.workers);
    final activeCount = shop.workers.where((e) => e.active).length;
    final sellingCount = summary.workerPerformance.length;
    final targetDone = shop.workers.where((worker) {
      if (worker.dailyTarget <= 0) return false;
      final perf = performanceByName[worker.name.trim().toLowerCase()];
      return (perf?.total ?? 0) >= worker.dailyTarget;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ishchilar'),
        actions: [
          IconButton(
            tooltip: 'Ishchi qo‘shish',
            onPressed: () => _showWorkerSheet(context),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWorkerSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ishchi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _summary(context,
              total: summary.totalRevenue,
              active: activeCount,
              selling: sellingCount,
              targetDone: targetDone),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showWorkerSheet(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Ishchi qo‘shish'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Ishchi qidirish',
              hintText: 'Ism, telefon yoki lavozim',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (shop.workers.isEmpty)
            _emptyState(context)
          else if (workers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Mos ishchi topilmadi')),
            )
          else
            for (final worker in workers)
              _workerCard(
                context,
                worker,
                performanceByName[worker.name.trim().toLowerCase()],
              ),
        ],
      ),
    );
  }

  List<WorkerProfile> _filtered(List<WorkerProfile> workers) {
    final q = _query.text.trim().toLowerCase();
    return workers.where((worker) {
      final haystack =
          '${worker.name} ${worker.phone} ${worker.roleTitle}'.toLowerCase();
      return q.isEmpty || haystack.contains(q);
    }).toList();
  }

  Widget _summary(
    BuildContext context, {
    required double total,
    required int active,
    required int selling,
    required int targetDone,
  }) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
      childAspectRatio: MediaQuery.sizeOf(context).width > 720 ? 1.55 : 2.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metric(context, Icons.payments_outlined, _moneyText(total),
            'Bugungi tushum', const Color(0xFF2F7D55)),
        _metric(context, Icons.groups_outlined, '$active', 'Faol ishchi',
            Theme.of(context).colorScheme.primary),
        _metric(context, Icons.point_of_sale, '$selling', 'Bugun sotdi',
            const Color(0xFF315A8C)),
        _metric(context, Icons.flag_outlined, '$targetDone', 'Targetga yetdi',
            const Color(0xFFB15D1F)),
      ],
    );
  }

  Widget _metric(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
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

  Widget _workerCard(
    BuildContext context,
    WorkerProfile worker,
    WorkerPerformance? performance,
  ) {
    final colors = Theme.of(context).colorScheme;
    final total = performance?.total ?? 0;
    final progress = worker.dailyTarget <= 0
        ? 0.0
        : (total / worker.dailyTarget).clamp(0, 1).toDouble();
    final statusColor =
        worker.active ? const Color(0xFF2F7D55) : colors.outline;

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
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_outline, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(
                        '${worker.roleTitle} · ${worker.active ? 'Faol' : 'To‘xtatilgan'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.outline),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Tahrirlash',
                  onPressed: () => _showWorkerSheet(context, worker: worker),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, Icons.phone_outlined,
                    worker.phone.isEmpty ? 'Telefon yo‘q' : worker.phone),
                _chip(context, Icons.receipt_long_outlined,
                    '${performance?.checks ?? 0} chek'),
                _chip(context, Icons.inventory_2_outlined,
                    '${performance?.quantity ?? 0} dona'),
                _chip(context, Icons.trending_up,
                    'O‘rtacha: ${_moneyText(performance?.averageCheck ?? 0)}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bugun: ${_moneyText(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  worker.dailyTarget <= 0
                      ? 'Target yo‘q'
                      : 'Target: ${_moneyText(worker.dailyTarget)}',
                  style: TextStyle(color: colors.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            if (worker.note.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(worker.note, style: TextStyle(color: colors.outline)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _showWorkerSheet(BuildContext context,
      {WorkerProfile? worker}) async {
    final nameCtrl = TextEditingController(text: worker?.name ?? '');
    final phoneCtrl = TextEditingController(text: worker?.phone ?? '');
    final roleCtrl =
        TextEditingController(text: worker?.roleTitle ?? 'Sotuvchi');
    final targetCtrl = TextEditingController(
        text: worker == null || worker.dailyTarget <= 0
            ? ''
            : worker.dailyTarget.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: worker?.note ?? '');
    var active = worker?.active ?? true;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void save() {
              final service = sheetContext.read<ShopService>();
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ishchi ismini kiriting')),
                );
                return;
              }
              final target = parseMoneyInput(targetCtrl.text);
              if (worker == null) {
                service.addWorker(WorkerProfile(
                  id: 'worker_${DateTime.now().microsecondsSinceEpoch}',
                  name: name,
                  phone: phoneCtrl.text.trim(),
                  roleTitle: roleCtrl.text.trim().isEmpty
                      ? 'Sotuvchi'
                      : roleCtrl.text.trim(),
                  dailyTarget: target,
                  active: active,
                  note: noteCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
              } else {
                service.updateWorker(worker.copyWith(
                  name: name,
                  phone: phoneCtrl.text.trim(),
                  roleTitle: roleCtrl.text.trim().isEmpty
                      ? 'Sotuvchi'
                      : roleCtrl.text.trim(),
                  dailyTarget: target,
                  active: active,
                  note: noteCtrl.text.trim(),
                ));
              }
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(worker == null
                        ? 'Ishchi qo‘shildi'
                        : 'Ishchi yangilandi')),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                      worker == null
                          ? 'Ishchi qo‘shish'
                          : 'Ishchini tahrirlash',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ism',
                      hintText: 'Masalan: Ali',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      hintText: '+998 90 123 45 67',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lavozim',
                      hintText: 'Sotuvchi, kassir, omborchi...',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kunlik target',
                      hintText: '1 mln yoki 1 000 000 so‘m',
                      suffixText: 'so‘m',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: active,
                    onChanged: (value) => setSheetState(() => active = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Faol ishchi'),
                    subtitle: const Text(
                        'O‘chirilsa ro‘yxatda to‘xtatilgan bo‘lib turadi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Izoh',
                      hintText: 'Masalan: ertalabki smena, yangi ishchi...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.save_outlined),
                    label:
                        Text(worker == null ? 'Ishchini saqlash' : 'Saqlash'),
                  ),
                  if (worker != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        sheetContext
                            .read<ShopService>()
                            .deleteWorker(worker.id);
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Ishchi ro‘yxatdan olindi')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Ro‘yxatdan olish'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    } finally {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      roleCtrl.dispose();
      targetCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  Widget _emptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.groups_outlined,
                color: Theme.of(context).colorScheme.primary, size: 46),
            const SizedBox(height: 10),
            const Text('Ishchilar ro‘yxati bo‘sh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Ishchi qo‘shilgandan keyin boshliq uning targeti va bugungi sotuvini shu yerda ko‘radi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showWorkerSheet(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ishchi qo‘shish'),
            ),
          ],
        ),
      ),
    );
  }

  String _moneyText(double value) {
    return '${_money.format(value.round())} so‘m';
  }
}
