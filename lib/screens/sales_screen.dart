import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/product.dart';
import '../services/shop_service.dart';
import 'debt_list_screen.dart';

/// Tez sotuv: mahsulot + soni + bir tugma. Ovoz orqali sotuv ham bor.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Map<String, int> _qty = {};
  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<bool> _speechBusySignal = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _voiceUnavailableSignal =
      ValueNotifier<bool>(false);
  final ValueNotifier<String> _voiceTextSignal = ValueNotifier<String>('');
  final ValueNotifier<String> _voiceStatusSignal =
      ValueNotifier<String>('Tugmani bosing, keyin gapiring.');

  bool _speechReady = false;
  String _voiceText = '';
  String? _selectedCustomerId;
  DateTime? _debtDueDate;

  @override
  void dispose() {
    _speech.stop();
    _speechBusySignal.dispose();
    _voiceUnavailableSignal.dispose();
    _voiceTextSignal.dispose();
    _voiceStatusSignal.dispose();
    super.dispose();
  }

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

  Future<void> _ensureSpeechReady() async {
    if (_speechReady) return;
    _voiceStatusSignal.value = 'Mikrofon ruxsati so‘ralyapti...';
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final listening = status == 'listening';
        _speechBusySignal.value = listening;
        if (listening) {
          _voiceStatusSignal.value = 'Eshityapti. Hozir gapiring.';
        } else if (status == 'done' || status == 'notListening') {
          _voiceStatusSignal.value =
              'To‘xtadi. Matn tushgan bo‘lsa, sotish mumkin.';
        }
      },
      onError: (error) {
        if (!mounted) return;
        _speechBusySignal.value = false;
        _voiceStatusSignal.value = 'Mikrofon xatosi: ${error.errorMsg}';
      },
    );
  }

  Future<void> _startListening(TextEditingController ctrl) async {
    _voiceUnavailableSignal.value = false;
    try {
      await _ensureSpeechReady();
    } catch (e) {
      _speechBusySignal.value = false;
      _voiceUnavailableSignal.value = true;
      _voiceStatusSignal.value = _friendlySpeechError(e);
      return;
    }

    if (!_speechReady || !_speech.isAvailable) {
      if (!mounted) return;
      _voiceStatusSignal.value =
          'Bu brauzer yoki qurilma mikrofonni qo‘llamayapti.';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Mikrofon ruxsati berilmadi yoki qurilma qo‘llamaydi')),
      );
      return;
    }

    _speechBusySignal.value = true;
    _voiceStatusSignal.value = 'Eshityapti. Hozir gapiring.';
    final localeId = await _bestLocaleId();
    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
        ),
        onResult: (SpeechRecognitionResult result) {
          ctrl.text = result.recognizedWords;
          ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
          if (mounted) setState(() => _voiceText = result.recognizedWords);
          _voiceTextSignal.value = result.recognizedWords;
          if (result.recognizedWords.trim().isNotEmpty) {
            _voiceStatusSignal.value = result.finalResult
                ? 'Matn tayyor. Sotish tugmasini bosing.'
                : 'Eshityapti, matn tushyapti...';
          }
        },
      );
    } catch (e) {
      _speechBusySignal.value = false;
      _voiceUnavailableSignal.value = true;
      _voiceStatusSignal.value = _friendlySpeechError(e);
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _speechBusySignal.value = false;
    _voiceStatusSignal.value = 'To‘xtadi. Matn tushgan bo‘lsa, sotish mumkin.';
  }

  Future<String?> _bestLocaleId() async {
    try {
      final locales = await _speech.locales();
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase();
        if (id == 'uz_uz' || id.startsWith('uz')) return locale.localeId;
      }
      final system = await _speech.systemLocale();
      return system?.localeId;
    } catch (_) {
      return null;
    }
  }

  String _friendlySpeechError(Object error) {
    final raw = error.toString();
    if (raw.contains('MissingPluginException')) {
      return 'Bu web preview’da mikrofon ulanmagan. Hozir matnni qo‘lda kiriting yoki Chrome/telefon buildda sinang.';
    }
    if (raw.toLowerCase().contains('permission')) {
      return 'Mikrofon ruxsati berilmadi. Brauzer sozlamasidan mikrofonni yoqing.';
    }
    return 'Mikrofon ishga tushmadi. Matnni qo‘lda kiriting yoki qayta urinib ko‘ring.';
  }

  Future<void> _sellFromVoice(String text) async {
    final err = context.read<ShopService>().sellFromVoiceText(text,
        customerId: _selectedCustomerId, addToDebt: false, debtDueDate: null);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ovozdan sotildi: $text')),
      );
    }
  }

  Future<void> _openVoiceDialog() async {
    final ctrl = TextEditingController(text: _voiceText);
    _voiceTextSignal.value = _voiceText;
    _voiceUnavailableSignal.value = false;
    _voiceStatusSignal.value = 'Tugmani bosing, keyin gapiring.';
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> listen() async {
              await _startListening(ctrl);
              setDialogState(() {});
            }

            Future<void> stop() async {
              await _stopListening();
              setDialogState(() {});
            }

            return AlertDialog(
              title: const Text('Ovoz orqali sotish'),
              content: ValueListenableBuilder<bool>(
                valueListenable: _speechBusySignal,
                builder: (context, listening, _) {
                  final activeColor = listening
                      ? const Color(0xFF1F8F5F)
                      : Theme.of(context).colorScheme.primary;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: listening
                              ? const Color(0xFFE7F6EE)
                              : const Color(0xFFF5EEE9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: activeColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              listening ? Icons.hearing : Icons.mic_none,
                              color: activeColor,
                              size: 44,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              listening ? 'ESHITYAPTI' : 'MIKROFON TAYYOR',
                              style: TextStyle(
                                color: activeColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listening
                                  ? 'Gapiring: “beshta 2x4 taxta sotildi”.'
                                  : 'Bosilganda yashil bo‘lsa, app gapni eshityapti.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<String>(
                        valueListenable: _voiceStatusSignal,
                        builder: (context, status, _) {
                          final isError = status.contains('xatosi') ||
                              status.contains('qo‘llamayapti') ||
                              status.contains('tushmadi') ||
                              status.contains('ulanmagan') ||
                              status.contains('ruxsati berilmadi');
                          return Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isError
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<bool>(
                        valueListenable: _voiceUnavailableSignal,
                        builder: (context, unavailable, _) {
                          return FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: unavailable
                                  ? Colors.grey.shade700
                                  : activeColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: unavailable
                                ? null
                                : listening
                                    ? stop
                                    : listen,
                            icon: Icon(unavailable
                                ? Icons.mic_off_outlined
                                : listening
                                    ? Icons.stop
                                    : Icons.mic),
                            label: Text(unavailable
                                ? 'Mikrofon mavjud emas'
                                : listening
                                    ? 'To‘xtatish'
                                    : 'Gapirishni boshlash'),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<String>(
                        valueListenable: _voiceTextSignal,
                        builder: (context, value, _) {
                          return TextField(
                            controller: ctrl,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Tushgan matn yoki qo‘lda yozish',
                              hintText: 'beshta 2x4 taxta sotildi',
                              prefixIcon:
                                  Icon(Icons.record_voice_over_outlined),
                            ),
                            onChanged: (v) {
                              _voiceText = v;
                              _voiceTextSignal.value = v;
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Bekor'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Sotish'),
                ),
              ],
            );
          },
        ),
      );
      await _stopListening();
      if (ok == true && mounted) {
        _voiceText = ctrl.text.trim();
        await _sellFromVoice(_voiceText);
      }
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopService>();
    final products = shop.products;
    final customers = shop.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sotish'),
        actions: [
          if (shop.latestSale != null)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Oxirgi sotuvni bekor qilish',
              onPressed: () => _undoLastSale(shop),
            ),
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Ovoz orqali sotish',
            onPressed: _openVoiceDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVoiceDialog,
        icon: const Icon(Icons.mic),
        label: const Text('Ovoz bilan sotish'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Klient',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Klient tanlanmagan'),
                  ),
                  for (final customer in customers)
                    DropdownMenuItem<String?>(
                      value: customer.id,
                      child: Text(customer.name),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _selectedCustomerId = v;
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final p in products) _productSaleCard(context, shop, p),
        ],
      ),
    );
  }

  Widget _productSaleCard(BuildContext context, ShopService shop, Product p) {
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
            Text(p.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
                '${p.size} · ${p.price.toStringAsFixed(0)} so‘m · zaxira: $maxS'),
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
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600),
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
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: () => _confirmSale(shop, p, q),
              child: const Text('SOTISH', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSale(
    ShopService shop,
    Product product,
    int quantity,
  ) async {
    final decision = await _showPaymentSheet(context, shop, product, quantity);
    if (!mounted || decision == null) return;

    if (decision.openDebtsOnly) {
      _openDebts();
      return;
    }

    final onDebt = decision.choice == _PaymentChoice.debt;
    final customerId = onDebt ? decision.customerId : _selectedCustomerId;
    final err = shop.sell(
      productId: product.id,
      quantity: quantity,
      customerId: customerId,
      addToDebt: onDebt,
      debtDueDate: onDebt ? decision.dueDate : null,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final customer = shop.customerById(customerId);
    final saleId = shop.latestSale?.id;
    final who = customer == null ? '' : ' · ${customer.name}';
    final paymentText = onDebt ? ' · nasiya' : ' · naqd';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${product.name} · $quantity dona sotildi$who$paymentText'),
        action: saleId == null
            ? null
            : SnackBarAction(
                label: 'Bekor',
                onPressed: () => _undoSale(shop, saleId),
              ),
      ),
    );
    setState(() {
      _qty[product.id] = 1;
      if (onDebt) {
        _selectedCustomerId = customerId;
        _debtDueDate = decision.dueDate;
      }
    });
    if (onDebt) _openDebts();
  }

  void _undoLastSale(ShopService shop) {
    final saleId = shop.latestSale?.id;
    if (saleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bekor qilinadigan sotuv yo‘q')),
      );
      return;
    }
    _undoSale(shop, saleId);
  }

  void _undoSale(ShopService shop, String saleId) {
    final err = shop.undoSale(saleId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Sotuv bekor qilindi')),
    );
  }

  Future<_SaleDecision?> _showPaymentSheet(
    BuildContext context,
    ShopService shop,
    Product product,
    int quantity,
  ) {
    var choice = _PaymentChoice.cash;
    var selectedCustomerId = _selectedCustomerId;
    var dueDate = _debtDueDate ?? DateTime.now().add(const Duration(days: 7));
    final dateFmt = DateFormat('dd.MM.yyyy');

    return showModalBottomSheet<_SaleDecision>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickDueDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: dueDate,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 3),
            );
            if (picked != null) setSheetState(() => dueDate = picked);
          }

          final debtMode = choice == _PaymentChoice.debt;
          final effectiveCustomerId =
              _validCustomerId(shop, selectedCustomerId) ??
                  (shop.customers.isEmpty ? null : shop.customers.first.id);
          final canDebtSell = !debtMode || effectiveCustomerId != null;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('To‘lov turi',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  '${product.name} · $quantity dona · ${(product.price * quantity).toStringAsFixed(0)} so‘m',
                  style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.outline),
                ),
                const SizedBox(height: 14),
                SegmentedButton<_PaymentChoice>(
                  segments: const [
                    ButtonSegment(
                      value: _PaymentChoice.cash,
                      icon: Icon(Icons.point_of_sale),
                      label: Text('Naqd'),
                    ),
                    ButtonSegment(
                      value: _PaymentChoice.debt,
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: Text('Nasiya'),
                    ),
                  ],
                  selected: {choice},
                  onSelectionChanged: (value) => setSheetState(() {
                    choice = value.first;
                    if (choice == _PaymentChoice.debt &&
                        selectedCustomerId == null &&
                        shop.customers.isNotEmpty) {
                      selectedCustomerId = shop.customers.first.id;
                    }
                  }),
                ),
                const SizedBox(height: 14),
                if (debtMode) ...[
                  if (shop.customers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nasiya uchun klient kerak',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              'Avval qarzdor yoki klient qo‘shing, keyin nasiya sotuvni bog‘laymiz.',
                              style: TextStyle(
                                  color: Theme.of(sheetContext)
                                      .colorScheme
                                      .outline),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(
                                sheetContext,
                                const _SaleDecision.openDebts(),
                              ),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Qarzdorlikka o‘tish'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: effectiveCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Qarzdor klient',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        for (final customer in shop.customers)
                          DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => selectedCustomerId = value),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: pickDueDate,
                      icon: const Icon(Icons.event_available_outlined),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child:
                            Text('Qaytarish kuni: ${dateFmt.format(dueDate)}'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nasiya saqlangach, qarzdorlik ro‘yxati avtomatik ochiladi.',
                      style: TextStyle(
                          color: Theme.of(sheetContext).colorScheme.outline),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: canDebtSell
                      ? () => Navigator.pop(
                            sheetContext,
                            _SaleDecision(
                              choice: choice,
                              customerId: effectiveCustomerId,
                              dueDate: dueDate,
                            ),
                          )
                      : null,
                  icon: Icon(debtMode
                      ? Icons.account_balance_wallet_outlined
                      : Icons.point_of_sale),
                  label: Text(debtMode ? 'Nasiya qilib sotish' : 'Naqd sotish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDebts() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const DebtListScreen()),
    );
  }

  String? _validCustomerId(ShopService shop, String? customerId) {
    if (customerId == null) return null;
    for (final customer in shop.customers) {
      if (customer.id == customerId) return customerId;
    }
    return null;
  }
}

enum _PaymentChoice { cash, debt }

class _SaleDecision {
  const _SaleDecision({
    required this.choice,
    this.customerId,
    this.dueDate,
  }) : openDebtsOnly = false;

  const _SaleDecision.openDebts()
      : choice = _PaymentChoice.debt,
        customerId = null,
        dueDate = null,
        openDebtsOnly = true;

  final _PaymentChoice choice;
  final String? customerId;
  final DateTime? dueDate;
  final bool openDebtsOnly;
}
