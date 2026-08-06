import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/colors/app_colors.dart';
import '../../core/services/presence_service.dart';
import '../../core/widgets/app_loader.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Charts & Analytics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search charts (e.g. gender, status, online)',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                ),
                                onPressed: () => _searchController.clear(),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: AppLoader(color: Colors.white),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      final genderCounts = <String, int>{};
                      final statusCounts = <String, int>{};
                      int onlineCount = 0;
                      int offlineCount = 0;

                      for (final doc in docs) {
                        final data = doc.data();

                        final sex = (data['sex']?.toString() ?? 'unspecified')
                            .toLowerCase();
                        genderCounts[sex] = (genderCounts[sex] ?? 0) + 1;

                        final status = (data['status']?.toString() ?? 'pending')
                            .toLowerCase();
                        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

                        DateTime? lastActive;
                        final rawLastActive = data['lastActive'];
                        if (rawLastActive is Timestamp) {
                          lastActive = rawLastActive.toDate();
                        }

                        final isOnlineFromDb = data['isOnline'] == true;

                        final isOnline =
                            isOnlineFromDb &&
                            lastActive != null &&
                            DateTime.now().difference(lastActive) <
                                PresenceService.onlineThreshold;

                        if (isOnline) {
                          onlineCount++;
                        } else {
                          offlineCount++;
                        }
                      }

                      final allCharts = <_ChartCard>[
                        _ChartCard(
                          title: 'Gender Distribution',
                          sections: [
                            _Slice(
                              'Male',
                              genderCounts['male'] ?? 0,
                              AppColors.glowCyan,
                            ),
                            _Slice(
                              'Female',
                              genderCounts['female'] ?? 0,
                              AppColors.glowPink,
                            ),
                            if ((genderCounts['unspecified'] ?? 0) > 0)
                              _Slice(
                                'Unspecified',
                                genderCounts['unspecified'] ?? 0,
                                Colors.white38,
                              ),
                          ],
                        ),
                        _ChartCard(
                          title: 'Access Status',
                          sections: [
                            _Slice(
                              'Approved',
                              statusCounts['approved'] ?? 0,
                              AppColors.successLight,
                            ),
                            _Slice(
                              'Pending',
                              statusCounts['pending'] ?? 0,
                              AppColors.warning,
                            ),
                            _Slice(
                              'Rejected',
                              statusCounts['rejected'] ?? 0,
                              AppColors.errorLight,
                            ),
                          ],
                        ),
                        _ChartCard(
                          title: 'Online Presence',
                          sections: [
                            _Slice(
                              'Online',
                              onlineCount,
                              AppColors.successLight,
                            ),
                            _Slice('Offline', offlineCount, Colors.white38),
                          ],
                        ),
                      ];

                      final filteredCharts = _query.isEmpty
                          ? allCharts
                          : allCharts
                                .where(
                                  (card) =>
                                      card.title.toLowerCase().contains(_query),
                                )
                                .toList();

                      if (filteredCharts.isEmpty) {
                        return Center(
                          child: Text(
                            'No charts match "$_query".',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: filteredCharts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) => filteredCharts[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
              color: AppColors.glowPurple.withValues(alpha: 0.16),
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
              color: AppColors.glowCyan.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(color: Colors.black.withValues(alpha: 0.32)),
          ),
        ),
      ],
    );
  }
}

class _Slice {
  final String label;
  final int value;
  final Color color;

  const _Slice(this.label, this.value, this.color);
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<_Slice> sections;

  const _ChartCard({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final total = sections.fold<int>(0, (runningTotal, section) {
      return runningTotal + section.value;
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No data yet.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: sections
                            .where((s) => s.value > 0)
                            .map(
                              (s) => PieChartSectionData(
                                value: s.value.toDouble(),
                                color: s.color,
                                title: '${((s.value / total) * 100).round()}%',
                                radius: 54,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sections
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${s.label}: ${s.value}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
