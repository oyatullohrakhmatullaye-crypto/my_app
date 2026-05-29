import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'services/shop_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final shopService = ShopService();
  await shopService.init();
  runApp(TaxtaApp(shopService: shopService));
}

/// Taxta do‘koni boshqaruvi — Provider orqali bitta ShopService.
class TaxtaApp extends StatelessWidget {
  const TaxtaApp({super.key, this.shopService});

  final ShopService? shopService;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7A4A35);
    return ChangeNotifierProvider<ShopService>(
      create: (_) => shopService ?? ShopService(),
      child: MaterialApp(
        title: 'Taxta do‘koni',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          scaffoldBackgroundColor: const Color(0xFFF7F3EE),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFFF7F3EE),
            foregroundColor: Color(0xFF211A16),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE8DED5)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD6C5B8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD6C5B8)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              textStyle: const TextStyle(fontSize: 17),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
