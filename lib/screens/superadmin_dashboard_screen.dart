import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/colors/app_colors.dart';
import '../core/services/auth_service.dart';
import 'login_screen.dart';
import 'user_detail_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUserStatus(_DashboardUser user, String status) async {
    try {
      await user.reference.update({'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName} updated to $status.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  bool _matchesSearch(_DashboardUser user) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    return user.displayName.toLowerCase().contains(_searchQuery) ||
        user.email.toLowerCase().contains(_searchQuery) ||
        user.role.toLowerCase().contains(_searchQuery) ||
        user.status.toLowerCase().contains(_searchQuery);
  }

  bool _matchesFilters(_DashboardUser user) {
    final roleMatches = _roleFilter == 'all' || user.role == _roleFilter;
    final statusMatches =
        _statusFilter == 'all' || user.status == _statusFilter;
    return roleMatches && statusMatches;
  }

  List<_DashboardUser> _buildAllUsers(
    QuerySnapshot<Map<String, dynamic>> data,
  ) {
    final users = data.docs.map(_DashboardUser.fromDoc).toList();

    users.sort((left, right) => left.displayName.compareTo(right.displayName));
    return users;
  }

  List<_DashboardUser> _buildVisibleUsers(List<_DashboardUser> users) {
    return users.where(_matchesSearch).where(_matchesFilters).toList();
  }

  // Pending approvals are now ordered by when the request was submitted
  // (oldest first), instead of relying on the alphabetical order inherited
  // from `_buildAllUsers`. Users without a `createdAt` timestamp are pushed
  // to the end rather than breaking the sort.
  List<_DashboardUser> _buildPendingUsers(List<_DashboardUser> users) {
    final pending = users
        .where((user) => user.status == 'pending')
        .where(_matchesSearch)
        .toList();

    pending.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return pending;
  }

  void _openUserDetail(_DashboardUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userRef: user.reference),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glowPurple.withOpacity(0.16),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glowCyan.withOpacity(0.12),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(color: Colors.black.withOpacity(0.32)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search by name, email, role, or status',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _roleFilter,
            dropdownColor: AppColors.dropdownBackground,
            decoration: _dropdownDecoration('Role'),
            iconEnabledColor: Colors.white70,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Roles')),
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'superadmin', child: Text('SuperAdmin')),
            ],
            onChanged: (value) {
              setState(() {
                _roleFilter = value ?? 'all';
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            dropdownColor: AppColors.dropdownBackground,
            decoration: _dropdownDecoration('Status'),
            iconEnabledColor: Colors.white70,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value ?? 'all';
              });
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.8)),
      ),
    );
  }

  // Builds the action row shown at the bottom of a user card. The available
  // actions depend on the user's current status:
  //  - pending  -> Reject / Approve
  //  - approved -> Revoke Access (blocks sign-in going forward)
  //  - rejected -> Grant Access (re-approves the user)
  // NOTE: this only updates the `status` field in Firestore. For this to
  // actually stop a revoked user from signing in, your auth flow (e.g.
  // AuthService / LoginScreen) must check this field on sign-in and refuse
  // access unless status == 'approved'.
  Widget _buildActionRow(_DashboardUser user) {
    switch (user.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateUserStatus(user, 'rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorLight,
                  side: const BorderSide(color: AppColors.errorLight),
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
                onPressed: () => _updateUserStatus(user, 'approved'),
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
        );
      case 'approved':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndUpdateStatus(
              user,
              newStatus: 'rejected',
              title: 'Revoke access?',
              message:
                  '${user.displayName} will no longer be able to sign in until access is granted again.',
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
        );
      case 'rejected':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateUserStatus(user, 'approved'),
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
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmAndUpdateStatus(
    _DashboardUser user, {
    required String newStatus,
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
      await _updateUserStatus(user, newStatus);
    }
  }

  Widget _buildUserCard(_DashboardUser user) {
    final statusColor = switch (user.status) {
      'approved' => AppColors.successLight,
      'rejected' => AppColors.errorLight,
      _ => AppColors.warning,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openUserDetail(user),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.55),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Role', value: user.role),
                  _InfoChip(
                    label: 'Status',
                    value: user.status,
                    valueColor: statusColor,
                  ),
                  if (user.phone.isNotEmpty)
                    _InfoChip(label: 'Phone', value: user.phone),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionRow(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'SuperAdmin Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Review accounts and manage approvals',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  // Wrapping the rest of the body in Expanded means it always
                  // takes exactly the remaining vertical space, so nothing
                  // gets pushed past the bottom of the screen no matter the
                  // device size or amount of content.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestore.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          final allUsers = snapshot.hasData
                              ? _buildAllUsers(snapshot.data!)
                              : <_DashboardUser>[];
                          final visibleUsers = _buildVisibleUsers(allUsers);
                          final pendingUsers = _buildPendingUsers(allUsers);

                          return Column(
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 12),
                              _buildFilterRow(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatCard(
                                    'Pending',
                                    pendingUsers.length.toString(),
                                    AppColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                    'Visible Users',
                                    visibleUsers.length.toString(),
                                    AppColors.successLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const TabBar(
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white54,
                                indicatorColor: AppColors.successLight,
                                tabs: [
                                  Tab(text: 'Pending Approvals'),
                                  Tab(text: 'All Users'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Was a SizedBox with a hardcoded
                              // MediaQuery-based height before, which could
                              // overflow. Expanded now fills exactly what's
                              // left, guaranteed no overflow.
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : pendingUsers.isEmpty
                                        ? _buildEmptyState(
                                            'No pending approvals right now.',
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            itemCount: pendingUsers.length,
                                            itemBuilder: (context, index) {
                                              return _buildUserCard(
                                                pendingUsers[index],
                                              );
                                            },
                                          ),
                                    snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : visibleUsers.isEmpty
                                        ? _buildEmptyState(
                                            'No users match the current filters.',
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            itemCount: visibleUsers.length,
                                            itemBuilder: (context, index) {
                                              return _buildUserCard(
                                                visibleUsers[index],
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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

class _DashboardUser {
  final DocumentReference<Map<String, dynamic>> reference;
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final DateTime? createdAt;

  const _DashboardUser({
    required this.reference,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory _DashboardUser.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return _DashboardUser(
      reference: doc.reference,
      uid: data['uid']?.toString() ?? doc.id,
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      role: (data['role']?.toString() ?? 'user').toLowerCase(),
      status: (data['status']?.toString() ?? 'pending').toLowerCase(),
      createdAt: createdAt,
    );
  }

  String get displayName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) {
      return combined;
    }
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return uid;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName.characters.first}${lastName.characters.first}'
          .toUpperCase();
    }
    if (displayName.isNotEmpty) {
      return displayName.characters.first.toUpperCase();
    }
    return '?';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
