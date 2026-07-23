import 'package:flutter/material.dart';
import '../core/colors/app_colors.dart';
import '../core/services/auth_service.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

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
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  decoration: _inputDecoration(
                    'First Name',
                    icon: Icons.person,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Required';
                    }
                    // Ensures no numbers or special characters pass through
                    final RegExp nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                    if (!nameRegex.hasMatch(val.trim())) {
                      return 'Only letters and spaces are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration(
                    'Last Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', icon: Icons.email),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Invalid email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _inputDecoration(
                    'Password',
                    icon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordObscured = !_isPasswordObscured,
                      ),
                    ),
                  ),
                  validator: (val) => val != null && val.length >= 6
                      ? null
                      : 'Min 6 characters',
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: _inputDecoration(
                    'Confirm Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength:
                      11, // Restricts user input to a maximum of 11 digits
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Restricts input to numbers only
                  ],

                  decoration:
                      _inputDecoration(
                        'Phone Number',
                        icon: Icons.phone,
                      ).copyWith(
                        hintText: '03XXXXXXXXX', // Placeholder format
                        counterText:
                            '', // Hides the "0/11" character counter below the field
                      ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Required';
                    }
                    // Ensures it starts with 03 and is exactly 11 digits long
                    final RegExp phoneRegex = RegExp(r'^03\d{9}$');
                    if (!phoneRegex.hasMatch(val)) {
                      return 'Enter a valid phone number (e.g., 03001234567)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // CNIC
                TextFormField(
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  maxLength: 15, // 13 digits + 2 hyphens
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CnicInputFormatter(),
                  ],
                  decoration:
                      _inputDecoration(
                        'CNIC / ID Number',
                        icon: Icons.badge,
                      ).copyWith(
                        hintText: 'XXXXX-YYYYYYY-Z',
                        counterText:
                            '', // Hides the default character counter text below the field
                      ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Required';
                    }
                    // Validates exact format: 5 digits - 7 digits - 1 digit
                    final RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
                    if (!cnicRegex.hasMatch(val)) {
                      return 'Enter a valid CNIC (e.g., 12345-1234567-1)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Date of Birth Picker
                ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDob == null
                        ? 'Select Date of Birth'
                        : 'DOB: ${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                  ),
                  onTap: _selectDateOfBirth,
                ),
                const SizedBox(height: 16),

                // Security Question Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true, // <--- FIX: Prevents horizontal overflow
                  value: _selectedSecurityQuestion,
                  decoration: _inputDecoration(
                    'Security Question',
                    icon: Icons.security,
                  ),
                  items: _securityQuestions.map((String q) {
                    return DropdownMenuItem<String>(
                      value: q,
                      child: Text(
                        q,
                        overflow: TextOverflow
                            .ellipsis, // <--- Truncates long text gracefully with '...' if needed
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedSecurityQuestion = val),
                  validator: (val) =>
                      val == null ? 'Please select a question' : null,
                ),
                const SizedBox(height: 16),
                // Security Answer
                TextFormField(
                  controller: _securityAnswerController,
                  decoration: _inputDecoration(
                    'Security Answer',
                    icon: Icons.question_answer,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 30),

                // Register Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                            'REGISTER',
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
