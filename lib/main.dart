import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/product_provider.dart';

void main() {
  runApp(const ShebaBarApp());
}

class ShebaBarApp extends StatelessWidget {
  const ShebaBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const App(),
    );
  }
}
