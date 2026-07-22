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
    "First pet's name",
    "Mother's maiden name",
    'City where you were born',
  ];

  String? _selectedSecurityQuestion = _securityQuestions.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _handlePasswordReset() async {
    if (_emailController.text.isEmpty ||
        _securityAnswerController.text.isEmpty ||
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
        email: _emailController.text,
        securityQuestion: _selectedSecurityQuestion!,
        securityAnswer: _securityAnswerController.text,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: verifiedEmail),
          ),
        );
      }
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Verify Security Question',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer your security question to receive a password reset link.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 30),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedSecurityQuestion,
                decoration: const InputDecoration(
                  labelText: 'Security Question',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: _securityQuestions
                    .map(
                      (question) => DropdownMenuItem<String>(
                        value: question,
                        child: Text(question),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSecurityQuestion = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Security Answer
              TextField(
                controller: _securityAnswerController,
                decoration: const InputDecoration(
                  labelText: 'Security Answer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.question_answer_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 30),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'VERIFY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
