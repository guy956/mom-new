import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../services/analytics_service.dart';
import '../widgets/admin_shared_widgets.dart';
import '../widgets/analytics_widgets.dart';

/// Enhanced Admin Overview Tab with Real-time Analytics Dashboard
class AdminOverviewTab extends StatefulWidget {
  final TabController tabController;
  final void Function(String tabId)? onNavigateToTab;
  const AdminOverviewTab({super.key, required this.tabController, this.onNavigateToTab});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  late AnalyticsService _analyticsService;
  TimeRange _selectedRange = TimeRange.last7Days();
  
  // Cached data
  Map<String, int> _userGrowthData = {};
  Map<String, int> _featureUsageData = {};
  Map<String, dynamic> _engagementData = {};
  Map<String, double> _revenueData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    _loadData();
  }

  @override
  void dispose() {
    _analyticsService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final growth = await _analyticsService.getUserGrowth(_selectedRange);
      final features = await _analyticsService.getFeatureUsage(_selectedRange);
      final engagement = await _analyticsService.getContentEngagement(_selectedRange);
      final revenue = await _analyticsService.getRevenueStats(_selectedRange);
      
      if (mounted) {
        setState(() {
          _userGrowthData = growth;
          _featureUsageData = features;
          _engagementData = engagement;
          _revenueData = revenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading analytics data: $e');
    }
  }

  void _onRangeChanged(TimeRange range) {
    setState(() => _selectedRange = range);
    _loadData();
  }

  String _buildCsvContent() {
    final buffer = StringBuffer();
    buffer.writeln('MOMIT Analytics Report - ${_selectedRange.label}');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('');

    // User growth data
    buffer.writeln('--- User Growth ---');
    buffer.writeln('Date,New Users');
    for (final entry in _userGrowthData.entries) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    buffer.writeln('Total New Users,${_userGrowthData.values.fold(0, (a, b) => a + b)}');
    buffer.writeln('');

    // Feature usage data
    buffer.writeln('--- Feature Usage ---');
    buffer.writeln('Feature,Usage Count');
    for (final entry in _featureUsageData.entries) {
      final name = AnalyticsService.featureNames[entry.key] ?? entry.key;
      buffer.writeln('$name,${entry.value}');
    }
    buffer.writeln('');

    // Engagement data
    if (_engagementData.isNotEmpty) {
      buffer.writeln('--- Content Engagement ---');
      buffer.writeln('Category,Metric,Value');
      for (final entry in _engagementData.entries) {
        if (entry.value is Map) {
          final map = entry.value as Map<String, dynamic>;
          for (final metric in map.entries) {
            buffer.writeln('${entry.key},${metric.key},${metric.value}');
          }
        } else {
          buffer.writeln('${entry.key},,${entry.value}');
        }
      }
      buffer.writeln('');
    }

    // Revenue data
    if (_revenueData.isNotEmpty) {
      buffer.writeln('--- Revenue ---');
      buffer.writeln('Metric,Value');
      for (final entry in _revenueData.entries) {
        buffer.writeln('${entry.key},${entry.value}');
      }
    }

    return buffer.toString();
  }

  Future<void> _exportToCsv() async {
    try {
      final csv = await _analyticsService.exportToCsv(
        dataType: 'analytics',
        range: _selectedRange,
      );

      final buffer = StringBuffer();
      buffer.write(_buildCsvContent());

      // Append the raw analytics CSV from the service
      if (csv.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('--- Raw Analytics Data ---');
        buffer.write(csv);
      }

      final fullCsv = buffer.toString();

      // Share the CSV data
      await SharePlus.instance.share(
        ShareParams(text: fullCsv, subject: 'MOMIT Analytics - ${_selectedRange.label}'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הנתונים יוצאו בהצלחה', style: TextStyle(fontFamily: 'Heebo'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בייצוא: $e', style: const TextStyle(fontFamily: 'Heebo'))),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    // Build a comprehensive text report (PDF library not available, so generate
    // a shareable text summary that can be pasted/printed)
    final report = StringBuffer();
    report.writeln('=== MOMIT Analytics Report ===');
    report.writeln('Period: ${_selectedRange.label}');
    report.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    report.writeln('');
    report.writeln('-- User Growth --');
    report.writeln('New users in period: ${_userGrowthData.values.fold(0, (a, b) => a + b)}');
    report.writeln('');
    report.writeln('-- Feature Usage --');
    for (final e in _featureUsageData.entries) {
      final name = AnalyticsService.featureNames[e.key] ?? e.key;
      report.writeln('  $name: ${e.value}');
    }
    report.writeln('');
    if (_engagementData.isNotEmpty) {
      report.writeln('-- Content Engagement --');
      for (final entry in _engagementData.entries) {
        if (entry.value is Map) {
          final map = entry.value as Map<String, dynamic>;
          report.writeln('  ${entry.key}: ${map.entries.map((m) => '${m.key}=${m.value}').join(', ')}');
        }
      }
      report.writeln('');
    }
    if (_revenueData.isNotEmpty) {
      report.writeln('-- Revenue --');
      for (final entry in _revenueData.entries) {
        report.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    final reportText = report.toString();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('דוח אנליטיקס', style: TextStyle(fontFamily: 'Heebo')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('תקופה: ${_selectedRange.label}', style: const TextStyle(fontFamily: 'Heebo')),
              const SizedBox(height: 16),
              const Text('נתוני משתמשים:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
              Text('צמיחה: ${_userGrowthData.values.fold(0, (a, b) => a + b)} משתמשים חדשים', style: const TextStyle(fontFamily: 'Heebo')),
              const SizedBox(height: 8),
              const Text('שימוש בתכונות:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
              ..._featureUsageData.entries.map((e) =>
                Text('${AnalyticsService.featureNames[e.key] ?? e.key}: ${e.value}', style: const TextStyle(fontFamily: 'Heebo'))),
              if (_engagementData.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('מעורבות תוכן:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
                ..._engagementData.entries.map((entry) {
                  if (entry.value is Map) {
                    final map = entry.value as Map<String, dynamic>;
                    return Text('${entry.key}: ${map.entries.map((m) => '${m.key}=${m.value}').join(', ')}', style: const TextStyle(fontFamily: 'Heebo'));
                  }
                  return Text('${entry.key}: ${entry.value}', style: const TextStyle(fontFamily: 'Heebo'));
                }),
              ],
              if (_revenueData.isNotEmpty && (_revenueData['total'] ?? 0.0) > 0) ...[
                const SizedBox(height: 8),
                const Text('הכנסות:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
                ..._revenueData.entries.map((e) =>
                  Text('${e.key}: ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Heebo'))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('הדוח הועתק ללוח', style: TextStyle(fontFamily: 'Heebo'))),
              );
            },
            child: const Text('העתק ללוח', style: TextStyle(fontFamily: 'Heebo')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await SharePlus.instance.share(
                ShareParams(text: reportText, subject: 'MOMIT Report - ${_selectedRange.label}'),
              );
            },
            child: const Text('שתף', style: TextStyle(fontFamily: 'Heebo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo')),
          ),
        ],
      ),
    );
  }

  void _showCustomDateRange() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedRange.start,
        end: _selectedRange.end,
      ),
    ).then((range) {
      if (range != null) {
        _onRangeChanged(TimeRange.custom(range.start, range.end));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Container(
      color: const Color(0xFFF9F5F4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Date Range Selector ──
            _buildHeader(),
            const SizedBox(height: 20),

            // ── Real-time Stats Row ──
            _buildRealTimeStats(fs),
            const SizedBox(height: 24),

            // ── Key Metrics Grid ──
            _buildKeyMetricsGrid(fs),
            const SizedBox(height: 24),

            // ── User Growth Chart ──
            AnalyticsWidgets.userGrowthChart(
              data: _userGrowthData,
              title: 'צמיחת משתמשים - ${_selectedRange.label}',
            ),
            const SizedBox(height: 24),

            // ── Charts Row: Feature Usage & Distribution ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnalyticsWidgets.featureUsageChart(
                    data: _featureUsageData,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserDistributionChart(fs),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Engagement & Revenue Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnalyticsWidgets.engagementMetricsCard(
                    engagement: _engagementData,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsWidgets.revenueChart(
                    revenue: _revenueData,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ──
            AdminWidgets.sectionTitle('פעולות מהירות', icon: Icons.flash_on_rounded),
            const SizedBox(height: 8),
            _buildQuickActions(),
            const SizedBox(height: 24),

            // ── Weekly Activity Bar Chart ──
            _buildWeeklyActivityChart(fs),
            const SizedBox(height: 24),

            // ── Recent Activity Feed ──
            StreamBuilder<List<UserAction>>(
              stream: _analyticsService.getRecentActions(limit: 10),
              builder: (context, snapshot) {
                return AnalyticsWidgets.activityFeed(
                  actions: snapshot.data ?? [],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Recent Registered Users ──
            AdminWidgets.sectionTitle('משתמשות חדשות', icon: Icons.person_add_rounded),
            const SizedBox(height: 8),
            _buildRecentUsers(fs),
            const SizedBox(height: 24),

            // ── Export Section ──
            _buildExportSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'דשבורד אנליטיקס',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF43363A),
          ),
        ),
        const Spacer(),
        AnalyticsWidgets.dateRangeSelector(
          currentRange: _selectedRange,
          onRangeChanged: _onRangeChanged,
          onCustomRange: _showCustomDateRange,
        ),
        const SizedBox(width: 12),
        AnalyticsWidgets.exportButtons(
          onExportCsv: _exportToCsv,
          onExportPdf: _exportToPdf,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // REAL-TIME STATS
  // ════════════════════════════════════════════════════════════════

  Widget _buildRealTimeStats(FirestoreService fs) {
    return ListenableBuilder(
      listenable: _analyticsService,
      builder: (context, _) {
        return StreamBuilder<int>(
          stream: _analyticsService.activeUsersNowStream,
          builder: (context, snapshot) {
            final activeNow = snapshot.data ?? 0;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD1C2D3), Color(0xFFDBC8B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.online_prediction,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$activeNow',
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'משתמשים פעילים עכשיו',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'לייב',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // KEY METRICS GRID
  // ════════════════════════════════════════════════════════════════

  Widget _buildKeyMetricsGrid(FirestoreService fs) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.usersStream,
      builder: (context, usersSnapshot) {
        final totalUsers = usersSnapshot.data?.length ?? 0;
        
        return StreamBuilder<int>(
          stream: _analyticsService.newUsersTodayStream,
          builder: (context, newUsersSnapshot) {
            final newUsersToday = newUsersSnapshot.data ?? 0;
            
            return GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                AnalyticsWidgets.statCard(
                  title: 'סה״כ משתמשות',
                  value: '$totalUsers',
                  icon: Icons.people_rounded,
                  color: const Color(0xFFD1C2D3),
                  trend: _calculateTrend(totalUsers, _userGrowthData),
                ),
                AnalyticsWidgets.statCard(
                  title: 'חדשות היום',
                  value: '$newUsersToday',
                  subtitle: 'השבוע: ${_userGrowthData.values.fold(0, (a, b) => a + b)}',
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFFB5C8B9),
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fs.postsStream,
                  builder: (_, snap) => AnalyticsWidgets.statCard(
                    title: 'פוסטים',
                    value: '${snap.data?.length ?? 0}',
                    icon: Icons.article_rounded,
                    color: const Color(0xFFC5CAE9),
                  ),
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fs.eventsStream,
                  builder: (_, snap) => AnalyticsWidgets.statCard(
                    title: 'אירועים',
                    value: '${snap.data?.length ?? 0}',
                    icon: Icons.event_rounded,
                    color: const Color(0xFFE8D5B7),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double? _calculateTrend(int current, Map<String, int> history) {
    if (history.isEmpty) return null;
    final previousTotal = current - history.values.fold(0, (a, b) => a + b);
    if (previousTotal <= 0) return null;
    return ((current - previousTotal) / previousTotal) * 100;
  }

  // ════════════════════════════════════════════════════════════════
  // USER DISTRIBUTION CHART
  // ════════════════════════════════════════════════════════════════

  Widget _buildUserDistributionChart(FirestoreService fs) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AdminWidgets.cardDecor(),
            child: const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final users = snapshot.data ?? [];
        final activeCount = users.where((u) => u['status'] == 'active').length;
        final pendingCount = users.where((u) => u['status'] == 'pending').length;
        final bannedCount = users.where((u) => u['status'] == 'banned').length;

        return AnalyticsWidgets.distributionPieChart(
          data: {
            'פעילות': activeCount,
            'ממתינות': pendingCount,
            'חסומות': bannedCount,
          },
          title: 'התפלגות משתמשות',
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ════════════════════════════════════════════════════════════════

  void _goToTab(String tabId) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabId);
    }
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        AdminWidgets.quickActionBtn(
          icon: Icons.school_rounded,
          label: 'הוסף מומחה',
          onTap: () => _goToTab('experts'),
        ),
        AdminWidgets.quickActionBtn(
          icon: Icons.event_rounded,
          label: 'צור אירוע',
          onTap: () => _goToTab('events'),
        ),
        AdminWidgets.quickActionBtn(
          icon: Icons.tips_and_updates_rounded,
          label: 'הוסף טיפ',
          onTap: () => _goToTab('content'),
        ),
        AdminWidgets.quickActionBtn(
          icon: Icons.flag_rounded,
          label: 'דיווחים',
          color: const Color(0xFFD4A3A3),
          onTap: () => _goToTab('reports'),
        ),
        AdminWidgets.quickActionBtn(
          icon: Icons.approval_rounded,
          label: 'אישורים',
          onTap: () => _goToTab('approvals'),
        ),
        AdminWidgets.quickActionBtn(
          icon: Icons.settings_rounded,
          label: 'הגדרות',
          onTap: () => _goToTab('config'),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WEEKLY ACTIVITY CHART
  // ════════════════════════════════════════════════════════════════

  Widget _buildWeeklyActivityChart(FirestoreService fs) {
    return StreamBuilder<List<dynamic>>(
      stream: fs.activityLogStream,
      builder: (context, snapshot) {
        final dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
        final dayCounts = List<double>.filled(7, 0);

        if (snapshot.hasData) {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          for (final log in snapshot.data!) {
            try {
              DateTime dt;
              final ts = log['createdAt'];
              if (ts == null) continue;
              if (ts is DateTime) {
                dt = ts;
              } else {
                dt = ts.toDate();
              }
              if (dt.isAfter(weekAgo)) {
                final dayIndex = dt.weekday % 7;
                dayCounts[dayIndex]++;
              }
            } catch (_) {}
          }
        }

        final maxVal = dayCounts.reduce((a, b) => a > b ? a : b);

        return Container(
          decoration: AdminWidgets.cardDecor(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'פעילות שבועית',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43363A),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal < 5 ? 5 : maxVal + 2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF43363A),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${dayCounts[groupIndex].toInt()} פעולות',
                            const TextStyle(
                              fontFamily: 'Heebo',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dayLabels.length) {
                              return const SizedBox();
                            }
                            return Text(
                              dayLabels[idx],
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) => BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(
                        toY: dayCounts[i],
                        color: const Color(0xFFD1C2D3),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      )],
                    )),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // RECENT USERS
  // ════════════════════════════════════════════════════════════════

  Widget _buildRecentUsers(FirestoreService fs) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.usersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AdminWidgets.emptyState('אין משתמשות חדשות');
        }

        final users = snapshot.data!.take(5).toList();

        return Container(
          decoration: AdminWidgets.cardDecor(),
          child: Column(
            children: users.map((user) {
              final name = (user['fullName'] ?? user['email'] ?? '').toString();
              final email = (user['email'] ?? '').toString();
              final status = user['status'] ?? 'active';
              final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFD1C2D3),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: AdminWidgets.statusChip(status),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // EXPORT SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminWidgets.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ייצוא נתונים',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF43363A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExportCard(
                  'ייצוא ל-CSV',
                  'הורדת נתונים בפורמט טבלאי',
                  Icons.table_chart_outlined,
                  const Color(0xFFD1C2D3),
                  _exportToCsv,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportCard(
                  'דוח PDF',
                  'דוח מסכם בפורמט PDF',
                  Icons.picture_as_pdf_outlined,
                  const Color(0xFFD4A3A3),
                  _exportToPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF43363A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
