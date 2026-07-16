import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/gunnmorelogo.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 30),
            const Text(
              'Wah Industries Limited',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Employee Management System',
              style: TextStyle(fontSize: 16, color: Colors.yellowAccent),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.yellowAccent,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
