import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors/app_colors.dart';
import '../../core/widgets/app_loader.dart';

class UserDetailScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> userRef;

  const UserDetailScreen({super.key, required this.userRef});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dob;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _controllersLoaded = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fills the text controllers from the latest Firestore data. Only called
  // when NOT actively editing, so a live update from the stream never
  // overwrites text the admin is currently typing.
  void _loadControllers(Map<String, dynamic> data) {
    _firstNameController.text = data['firstName']?.toString() ?? '';
    _lastNameController.text = data['lastName']?.toString() ?? '';
    _phoneController.text = data['phone']?.toString() ?? '';
    _cnicController.text = data['cnic']?.toString() ?? '';
    _addressController.text = data['address']?.toString() ?? '';

    final rawDob = data['dob'];
    if (rawDob is String) {
      _dob = DateTime.tryParse(rawDob);
    } else if (rawDob is Timestamp) {
      _dob = rawDob.toDate();
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.userRef.update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'address': _addressController.text.trim(),
        if (_dob != null) 'dob': _dob!.toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save changes: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await widget.userRef.update({'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $status.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmAndUpdateStatus({
    required String status,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dropdownBackground,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppColors.errorLight),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus(status);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.8)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }

  Widget _buildReadOnlyChip(String label, String value, {Color? valueColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: const Text('User Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => setState(() => _isEditing = false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.userRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppLoader(color: Colors.white));
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text(
                'This user no longer exists.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!_controllersLoaded || !_isEditing) {
            _loadControllers(data);
            _controllersLoaded = true;
          }

          final role = (data['role']?.toString() ?? 'user').toLowerCase();
          final status = (data['status']?.toString() ?? 'pending')
              .toLowerCase();
          final email = data['email']?.toString() ?? '';
          final securityQuestion = data['securityQuestion']?.toString() ?? '';

          final statusColor = switch (status) {
            'approved' => AppColors.successLight,
            'rejected' => AppColors.errorLight,
            _ => AppColors.warning,
          };

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildReadOnlyChip('Email', email),
                  _buildReadOnlyChip('Role', role),
                  _buildReadOnlyChip('Status', status, valueColor: statusColor),
                  if (securityQuestion.isNotEmpty)
                    _buildReadOnlyChip('Security Question', securityQuestion),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: _isEditing,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('First Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: _isEditing,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Last Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cnicController,
                    enabled: _isEditing,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('CNIC'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    enabled: _isEditing,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Address'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isEditing ? _pickDob : null,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _fieldDecoration('Date of Birth'),
                      child: Text(
                        _dob != null
                            ? '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
                            : 'Not set',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSaving
                            ? const AppLoader(size: 16, color: Colors.white)
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Account Actions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus('rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorLight,
                              side: const BorderSide(
                                color: AppColors.errorLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successLight,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    )
                  else if (status == 'approved')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmAndUpdateStatus(
                          status: 'rejected',
                          title: 'Revoke access?',
                          message:
                              'This user will no longer be able to sign in until access is granted again.',
                          confirmLabel: 'Revoke',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorLight,
                          side: const BorderSide(color: AppColors.errorLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.block),
                        label: const Text('Revoke Access'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successLight,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Grant Access'),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
