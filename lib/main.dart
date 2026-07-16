import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const WilApp());
}

class WilApp extends StatelessWidget {
  const WilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wah Industries Limited',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
