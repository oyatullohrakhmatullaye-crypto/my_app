import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'services/shop_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaxtaApp());
}

/// Taxta do‘koni boshqaruvi — Provider orqali bitta ShopService.
class TaxtaApp extends StatelessWidget {
  const TaxtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShopService>(
      create: (_) => ShopService(),
      child: MaterialApp(
        title: 'Taxta do‘koni',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
          useMaterial3: true,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              textStyle: const TextStyle(fontSize: 17),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
