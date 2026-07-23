import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/colors/app_colors.dart';
import '../core/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _securityAnswerController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Focus Nodes to track focus state for Phone and CNIC fields
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _cnicFocusNode = FocusNode();

  DateTime? _selectedDob;
  String? _selectedSecurityQuestion;
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  final List<String> _securityQuestions = [
    'What was the name of your first pet?',
    'What is your mother\'s maiden name?',
    'What was the name of your elementary school?',
    'In what city were you born?',
  ];

  @override
  void initState() {
    super.initState();
    // Rebuild UI when focus changes to swap hint text dynamically
    _phoneFocusNode.addListener(() => setState(() {}));
    _cnicFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _securityAnswerController.dispose();
    _dobController.dispose();

    _phoneFocusNode.dispose();
    _cnicFocusNode.dispose();
    super.dispose();
  }

  // Soft Glassmorphic Input Container Decoration
  BoxDecoration _fieldBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
    );
  }

  // Subtle Input Field Styling
  InputDecoration _inputDecoration(
    String hint, {
    IconData? icon,
    Widget? suffixIcon,
    Color? hintColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor ?? Colors.white54, fontSize: 14),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: Colors.white70, size: 20),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), height: 0.9),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth')),
      );
      return;
    }

    if (_selectedSecurityQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a security question')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
        address: _addressController.text.trim(),
        dob: _selectedDob!,
        securityQuestion: _selectedSecurityQuestion!,
        securityAnswer: _securityAnswerController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF19191B),
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Soft Light Ambient Background Glow (Top Right)
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                ),
              ),
            ),

            // Soft Light Ambient Background Glow (Bottom Left)
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38EF7D).withOpacity(0.06),
                ),
              ),
            ),

            // Glass Blur Layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.black.withOpacity(0.15)),
              ),
            ),

            // Main Registration Form
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // Subtitle Header
                        const Text(
                          'Join Wah Industries Limited',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fill in your details to create an account',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // First Name
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            decoration: _inputDecoration(
                              'First Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final RegExp nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                              if (!nameRegex.hasMatch(val.trim())) {
                                return 'Only letters and spaces allowed';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Last Name
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            decoration: _inputDecoration(
                              'Last Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final RegExp nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                              if (!nameRegex.hasMatch(val.trim())) {
                                return 'Only letters and spaces allowed';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (val) =>
                                val == null || !val.contains('@')
                                ? 'Invalid email address'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: _inputDecoration(
                              'Password',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _isPasswordObscured =
                                      !_isPasswordObscured,
                                ),
                              ),
                            ),
                            validator: (val) => val != null && val.length >= 6
                                ? null
                                : 'Min 6 characters required',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _isConfirmPasswordObscured,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: _inputDecoration(
                              'Confirm Password',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _isConfirmPasswordObscured =
                                      !_isConfirmPasswordObscured,
                                ),
                              ),
                            ),
                            validator: (val) => val == _passwordController.text
                                ? null
                                : 'Passwords do not match',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Phone Number Dynamic Field
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              _phoneFocusNode.hasFocus
                                  ? '03XXXXXXXXX'
                                  : 'Phone Number',
                              icon: Icons.phone_outlined,
                            ).copyWith(counterText: ''),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Required';
                              }
                              final RegExp phoneRegex = RegExp(r'^03\d{9}$');
                              if (!phoneRegex.hasMatch(val)) {
                                return 'Enter valid phone (e.g. 03001234567)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // CNIC Dynamic Field
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _cnicController,
                            focusNode: _cnicFocusNode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 15,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CnicInputFormatter(),
                            ],
                            decoration: _inputDecoration(
                              _cnicFocusNode.hasFocus
                                  ? 'XXXXX-YYYYYYY-Z'
                                  : 'CNIC / ID Number',
                              icon: Icons.badge_outlined,
                            ).copyWith(counterText: ''),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Required';
                              }
                              final RegExp cnicRegex = RegExp(
                                r'^\d{5}-\d{7}-\d{1}$',
                              );
                              if (!cnicRegex.hasMatch(val)) {
                                return 'Enter valid CNIC (12345-1234567-1)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Date of Birth
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _dobController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              DateInputFormatter(),
                            ],
                            decoration: _inputDecoration(
                              'Date of Birth',
                              icon: Icons.calendar_today_outlined,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.date_range,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDob ?? DateTime(2000),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    final day = picked.day.toString().padLeft(
                                      2,
                                      '0',
                                    );
                                    final month = picked.month
                                        .toString()
                                        .padLeft(2, '0');
                                    _dobController.text =
                                        '$day/$month/${picked.year}';
                                    setState(() => _selectedDob = picked);
                                  }
                                },
                              ),
                            ).copyWith(hintText: 'DD/MM/YYYY', counterText: ''),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }

                              final RegExp dateRegex = RegExp(
                                r'^\d{2}/\d{2}/\d{4}$',
                              );
                              if (!dateRegex.hasMatch(val)) {
                                return 'Enter valid date (DD/MM/YYYY)';
                              }

                              final parts = val.split('/');
                              final day = int.tryParse(parts[0]);
                              final month = int.tryParse(parts[1]);
                              final year = int.tryParse(parts[2]);

                              if (day == null ||
                                  month == null ||
                                  year == null) {
                                return 'Invalid Date';
                              }
                              if (month < 1 || month > 12) {
                                return 'Invalid Month (01-12)';
                              }
                              if (day < 1 || day > 31) {
                                return 'Invalid Day (01-31)';
                              }

                              try {
                                final parsedDate = DateTime(year, month, day);

                                if (parsedDate.isAfter(DateTime.now())) {
                                  return 'Date cannot be in future';
                                }
                                if (year < 1920) {
                                  return 'Enter realistic year';
                                }

                                _selectedDob = parsedDate;
                              } catch (_) {
                                return 'Invalid Date';
                              }

                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Security Question Dropdown
                        Container(
                          padding: const EdgeInsets.only(right: 12.0),
                          decoration: _fieldBoxDecoration(),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedSecurityQuestion,
                            dropdownColor: const Color(0xFF232326),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            hint: const Text(
                              'Security Question',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            decoration: _inputDecoration(
                              '',
                              icon: Icons.security_outlined,
                            ),
                            items: _securityQuestions.map((String q) {
                              return DropdownMenuItem<String>(
                                value: q,
                                child: Text(
                                  q,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSecurityQuestion = val),
                            validator: (val) =>
                                val == null ? 'Please select a question' : null,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Security Answer
                        Container(
                          decoration: _fieldBoxDecoration(),
                          child: TextFormField(
                            controller: _securityAnswerController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: _inputDecoration(
                              'Security Answer',
                              icon: Icons.question_answer_outlined,
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Register Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'REGISTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 13) {
      digitsOnly = digitsOnly.substring(0, 13);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 5 || i == 12) {
        buffer.write('-');
      }
      buffer.write(digitsOnly[i]);
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
