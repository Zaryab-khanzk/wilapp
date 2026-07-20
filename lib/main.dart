import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'core/colors/app_colors.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
