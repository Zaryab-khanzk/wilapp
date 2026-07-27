import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/colors/app_colors.dart';
import '../core/services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _securityAnswerController =
      TextEditingController();

  static const List<String> _securityQuestions = [
    'What was the name of your first pet?',
    'What is your mother\'s maiden name?',
    'What was the name of your elementary school?',
    'In what city were you born?',
  ];

  String? _selectedSecurityQuestion = _securityQuestions.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifySecurityQuestion() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _securityAnswerController.text.trim().isEmpty ||
        _selectedSecurityQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email, security question, and answer.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String verifiedEmail = await AuthService().verifySecurityAnswer(
        email: _emailController.text.trim(),
        securityQuestion: _selectedSecurityQuestion!,
        securityAnswer: _securityAnswerController.text.trim(),
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: verifiedEmail),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF19191B),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3545), Color(0xFF1E2B37)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF23332A), Color(0xFF1B2822)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Forgot Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Answer your security question to reset your password.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Your Email',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.white70,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedSecurityQuestion,
                                dropdownColor: const Color(0xFF252528),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white70,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Security Question',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(
                                    Icons.security_outlined,
                                    color: Colors.white70,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                items: _securityQuestions
                                    .map(
                                      (q) => DropdownMenuItem<String>(
                                        value: q,
                                        child: Text(
                                          q,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(
                                    () => _selectedSecurityQuestion = val,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: TextField(
                                controller: _securityAnswerController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Security Answer',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(
                                    Icons.question_answer_outlined,
                                    color: Colors.white70,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleVerifySecurityQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'VERIFY',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
