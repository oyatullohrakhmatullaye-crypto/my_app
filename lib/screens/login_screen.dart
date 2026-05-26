import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../services/shop_service.dart';
import 'dashboard_screen.dart';

/// Oddiy kirish: ism (ixtiyoriy) + rol. Parol yo‘q — do‘kon ichi uchun mock.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  UserRole _role = UserRole.worker;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ShopService>().login(name: _nameCtrl.text, role: _role);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxta do‘koni — kirish')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Rolni tanlang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(value: UserRole.worker, label: Text('Ishchi'), icon: Icon(Icons.person)),
                  ButtonSegment(value: UserRole.admin, label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ism (ixtiyoriy)',
                  border: OutlineInputBorder(),
                  hintText: 'Masalan: Ali',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                child: const Text('Kirish', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
