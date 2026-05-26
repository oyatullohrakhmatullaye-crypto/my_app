import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/shop_service.dart';

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
    final err = context.read<ShopService>().sellFromVoiceText(text);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sotish'),
        actions: [
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
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onPressed: () {
                      final err = shop.sell(productId: p.id, quantity: q);
                      if (err != null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${p.name} · $q dona sotildi')),
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
