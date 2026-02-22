import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/models/tracking_models.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/tracking_service.dart';

/// מסך מעקב תינוק מקצועי עם CRUD מלא
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedChildIndex = 0;
  bool _showWeight = true; // growth chart toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Initialize tracking service scoped to the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppState>().currentUser?.id;
      final firestoreService = context.read<FirestoreService>();
      context.read<TrackingService>().init(userId: userId, firestoreService: firestoreService);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TrackingService get _service => context.read<TrackingService>();

  ChildProfile? get _selectedChild {
    final children = context.read<TrackingService>().children;
    if (children.isEmpty || _selectedChildIndex >= children.length) return null;
    return children[_selectedChildIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingService>(
      builder: (context, service, _) {
        if (!service.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildChildSelector(service)),
              SliverToBoxAdapter(child: _buildQuickStats(service)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(_buildTabBar()),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildGrowthTab(service),
                _buildSleepTab(service),
                _buildFeedingTab(service),
                _buildMilestonesTab(service),
                _buildHealthTab(service),
                _buildOtherTab(service),
              ],
            ),
          ),
          floatingActionButton: Semantics(
            label: 'הוספת רשומת מעקב חדשה',
            button: true,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.momGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2),
                  BoxShadow(color: AppColors.secondary.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10), spreadRadius: -4),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddRecordSheet();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                label: const Text('הוסף רשומה', style: TextStyle(fontFamily: 'Heebo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== HEADER =====
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.secondary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFBE8A93), Color(0xFFAD7D86)],
                  ).createShader(bounds),
                  child: const Text(
                    'מעקב התפתחות',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'עקבי אחר הצמיחה וההתפתחות של הילדים',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.momGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ===== CHILD SELECTOR =====
  Widget _buildChildSelector(TrackingService service) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: service.children.length + 1,
        itemBuilder: (context, index) {
          if (index == service.children.length) return _buildAddChildCard();
          return _buildChildCard(index, service.children[index]);
        },
      ),
    );
  }

  Widget _buildChildCard(int index, ChildProfile child) {
    final isSelected = _selectedChildIndex == index;
    final color = child.isBoy ? AppColors.info : AppColors.secondary;
    return Semantics(
      label: 'ילד: ${child.name}, גיל: ${child.ageDisplay}',
      button: true,
      selected: isSelected,
      hint: 'לחצי לבחירה, לחצה ממושכת לעריכה',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedChildIndex = index);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showEditChildDialog(child);
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        width: 106,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.border.withValues(alpha: 0.5), width: isSelected ? 2.5 : 1),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2),
          ] : AppColors.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(isSelected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(child.name[0], style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w800, fontSize: 15, color: color)),
              ),
            ),
            const SizedBox(height: 6),
            Text(child.name, style: TextStyle(fontFamily: 'Heebo', fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13, color: isSelected ? color : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(child.ageDisplay, style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: isSelected ? color.withValues(alpha: 0.7) : AppColors.textHint)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddChildCard() {
    return Semantics(
      label: 'הוספת ילד חדש',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showAddChildDialog();
        },
        child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(12),
        width: 90,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            const Text('הוסף ילד', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      ),
    );
  }

  // ===== QUICK STATS (computed from real data) =====
  Widget _buildQuickStats(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return const SizedBox.shrink();

    final sleepHours = service.getTodaySleepHours(child.id);
    final feedingCount = service.getTodayFeedingCount(child.id);
    final diaperCount = service.getTodayDiaperCount(child.id);
    final latestGrowth = service.getLatestGrowth(child.id);

    return Semantics(
      label: 'סיכום יומי: שינה ${sleepHours.toStringAsFixed(1)} שעות, ${feedingCount} האכלות, ${diaperCount} חיתולים',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.04)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('סיכום יומי', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                ),
                const Spacer(),
                Icon(Icons.today_rounded, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(DateFormat('dd.MM.yyyy').format(DateTime.now()), style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickStatItem(Icons.bedtime_rounded, 'שינה', '${sleepHours.toStringAsFixed(1)}h', AppColors.trackingSleep),
                const SizedBox(width: 8),
                _buildQuickStatItem(Icons.restaurant_rounded, 'האכלות', '$feedingCount', AppColors.trackingFeeding),
                const SizedBox(width: 8),
                _buildQuickStatItem(Icons.baby_changing_station_rounded, 'חיתולים', '$diaperCount', AppColors.trackingDiaper),
                const SizedBox(width: 8),
                _buildQuickStatItem(Icons.straighten_rounded, 'גובה', latestGrowth?.height != null ? '${latestGrowth!.height!.toStringAsFixed(0)}cm' : '-', AppColors.trackingGrowth),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ===== TAB BAR =====
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'צמיחה'),
          Tab(text: 'שינה'),
          Tab(text: 'האכלה'),
          Tab(text: 'אבני דרך'),
          Tab(text: 'בריאות'),
          Tab(text: 'אחר'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  GROWTH TAB
  // ══════════════════════════════════════════════════
  Widget _buildGrowthTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final records = service.getRecordsForChild(child.id, type: TrackingType.growth);
    records.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // chronological

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrowthChart(records, child),
          const SizedBox(height: 20),
          _buildSectionTitle('היסטוריית מדידות', records.length),
          const SizedBox(height: 12),
          ...records.reversed.take(10).map((r) => _buildRecordCard(r, service)),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<TrackingRecord> records, ChildProfile child) {
    final spots = <FlSpot>[];
    for (final r in records) {
      final monthsAge = r.dateTime.difference(child.birthDate).inDays / 30.0;
      final val = _showWeight ? r.weight : r.height;
      if (val != null) spots.add(FlSpot(monthsAge, val));
    }

    // WHO reference line (weight in kg for girls)
    final whoSpots = _showWeight
        ? const [FlSpot(0, 3.3), FlSpot(3, 5.6), FlSpot(6, 7.5), FlSpot(9, 8.9), FlSpot(12, 9.9), FlSpot(15, 10.7), FlSpot(18, 11.3), FlSpot(21, 11.8), FlSpot(24, 12.2)]
        : const [FlSpot(0, 49.0), FlSpot(3, 59.8), FlSpot(6, 65.7), FlSpot(9, 70.1), FlSpot(12, 74.0), FlSpot(15, 77.0), FlSpot(18, 80.0), FlSpot(21, 83.0), FlSpot(24, 85.0)];

    final maxY = _showWeight ? 16.0 : 100.0;
    final unit = _showWeight ? 'kg' : 'cm';
    final chartDescription = spots.isEmpty
        ? 'גרף גדילה - אין מדידות עדיין'
        : 'גרף גדילה - ${_showWeight ? "משקל" : "גובה"} של ${child.name}, ${spots.length} נקודות מדידה';

    return Semantics(
      label: chartDescription,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('גרף גדילה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w800, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    _buildChartToggle('משקל', _showWeight, () => setState(() => _showWeight = true)),
                    _buildChartToggle('גובה', !_showWeight, () => setState(() => _showWeight = false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(child: Text('אין מדידות עדיין', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _showWeight ? 4 : 20,
                        getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46, interval: _showWeight ? 4 : 20,
                          getTitlesWidget: (v, m) {
                            if (v == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text('${v.toInt()}$unit', style: const TextStyle(fontFamily: 'Heebo', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            );
                          })),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 6,
                          getTitlesWidget: (v, m) {
                            if (v == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('${v.toInt()}m', style: const TextStyle(fontFamily: 'Heebo', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            );
                          })),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0, maxX: (child.ageInMonths + 3).toDouble(), minY: 0, maxY: maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit',
                            const TextStyle(fontFamily: 'Heebo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          )).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(spots: whoSpots, isCurved: true, color: AppColors.textHint.withValues(alpha: 0.5), barWidth: 2, dotData: const FlDotData(show: false), dashArray: [5, 5]),
                        LineChartBarData(spots: spots, isCurved: true, gradient: AppColors.momGradient, barWidth: 3,
                          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white)),
                          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.0)]))),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend(AppColors.primary, '${_showWeight ? "משקל" : "גובה"} ${child.name}'),
              const SizedBox(width: 24),
              _buildChartLegend(AppColors.textHint, 'ממוצע WHO'),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildChartToggle(String label, bool isSelected, VoidCallback onTap) {
    return Semantics(
      label: 'הצג גרף $label',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }

  // ══════════════════════════════════════════════════
  //  SLEEP TAB
  // ══════════════════════════════════════════════════
  Widget _buildSleepTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final allSleep = service.getRecordsForChild(child.id, type: TrackingType.sleep);
    final todaySleep = service.getTodayRecords(child.id, type: TrackingType.sleep);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSleepChart(service, child),
          const SizedBox(height: 20),
          _buildSectionTitle('יומן שינה - היום', todaySleep.length),
          const SizedBox(height: 12),
          if (todaySleep.isEmpty) _emptyState('אין רשומות שינה היום'),
          ...todaySleep.map((r) => _buildRecordCard(r, service)),
          if (allSleep.length > todaySleep.length) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('ימים קודמים', allSleep.length - todaySleep.length),
            const SizedBox(height: 12),
            ...allSleep.where((r) => !todaySleep.contains(r)).take(10).map((r) => _buildRecordCard(r, service)),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepChart(TrackingService service, ChildProfile child) {
    final now = DateTime.now();
    final dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
    final barGroups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayRecords = service.getRecordsForChild(child.id, type: TrackingType.sleep)
          .where((r) => r.dateTime.isAfter(dayStart) && r.dateTime.isBefore(dayEnd)).toList();

      double nightHours = 0, napHours = 0;
      for (final r in dayRecords) {
        if (r.sleepType == SleepSubType.nightSleep) {
          nightHours += r.sleepDurationHours;
        } else {
          napHours += r.sleepDurationHours;
        }
      }
      barGroups.add(BarChartGroupData(x: 6 - i, barRods: [
        BarChartRodData(toY: nightHours + napHours, width: 20,
          rodStackItems: [
            BarChartRodStackItem(0, nightHours, AppColors.info),
            BarChartRodStackItem(nightHours, nightHours + napHours, AppColors.accent),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ]));
    }

    return Semantics(
      label: 'גרף שעות שינה לשבוע האחרון של ${child.name}',
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('שעות שינה - שבוע אחרון', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround, maxY: 14,
              barTouchData: BarTouchData(enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)}h',
                      const TextStyle(fontFamily: 'Heebo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 4,
                  getTitlesWidget: (v, m) {
                    if (v == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('${v.toInt()}h', style: const TextStyle(fontFamily: 'Heebo', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    );
                  })),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, m) {
                    final day = now.subtract(Duration(days: 6 - v.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dayLabels[day.weekday % 7], style: const TextStyle(fontFamily: 'Heebo', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    );
                  })),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 4, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
              barGroups: barGroups,
            )),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend(AppColors.info, 'שינת לילה'),
              const SizedBox(width: 24),
              _buildChartLegend(AppColors.accent, 'תנומות'),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  FEEDING TAB
  // ══════════════════════════════════════════════════
  Widget _buildFeedingTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final todayFeedings = service.getTodayRecords(child.id, type: TrackingType.feeding);
    final allFeedings = service.getRecordsForChild(child.id, type: TrackingType.feeding);

    // Count by type
    final typeCounts = <FeedingSubType, int>{};
    for (final r in todayFeedings) {
      final ft = r.feedingType ?? FeedingSubType.bottle;
      typeCounts[ft] = (typeCounts[ft] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedingSummaryCard(typeCounts, todayFeedings),
          const SizedBox(height: 20),
          _buildSectionTitle('יומן האכלה - היום', todayFeedings.length),
          const SizedBox(height: 12),
          if (todayFeedings.isEmpty) _emptyState('אין רשומות האכלה היום'),
          ...todayFeedings.map((r) => _buildRecordCard(r, service)),
          if (allFeedings.length > todayFeedings.length) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('ימים קודמים', allFeedings.length - todayFeedings.length),
            const SizedBox(height: 12),
            ...allFeedings.where((r) => !todayFeedings.contains(r)).take(10).map((r) => _buildRecordCard(r, service)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedingSummaryCard(Map<FeedingSubType, int> counts, List<TrackingRecord> todayFeedings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('סיכום האכלה - היום', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: FeedingSubType.values.map((ft) {
              final count = counts[ft] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return _buildFeedingStat(TrackingHelpers.feedingTypeEmoji(ft), TrackingHelpers.feedingTypeLabel(ft), '$count פעמים', TrackingHelpers.typeColor(TrackingType.feeding));
            }).toList(),
          ),
          if (counts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('אין האכלות היום', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint))),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedingStat(String emoji, String label, String count, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13)),
          Text(count, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  MILESTONES TAB
  // ══════════════════════════════════════════════════
  Widget _buildMilestonesTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final milestones = service.getRecordsForChild(child.id, type: TrackingType.milestone);

    // Compute progress per category
    final catCounts = <MilestoneCategory, int>{};
    final catAchieved = <MilestoneCategory, int>{};
    for (final r in milestones) {
      final cat = r.milestoneCategory ?? MilestoneCategory.grossMotor;
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
      if (r.milestoneStatus == MilestoneStatus.achieved) {
        catAchieved[cat] = (catAchieved[cat] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('התקדמות כללית', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                ...MilestoneCategory.values.map((cat) {
                  final total = catCounts[cat] ?? 0;
                  final achieved = catAchieved[cat] ?? 0;
                  final progress = total > 0 ? achieved / total : 0.0;
                  return _buildProgressBar(TrackingHelpers.milestoneCategoryLabel(cat), progress, TrackingHelpers.typeColor(TrackingType.milestone));
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('אבני דרך', milestones.length),
          const SizedBox(height: 12),
          if (milestones.isEmpty) _emptyState('אין אבני דרך'),
          ...milestones.map((r) => _buildRecordCard(r, service)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  HEALTH TAB
  // ══════════════════════════════════════════════════
  Widget _buildHealthTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final healthRecords = service.getRecordsForChild(child.id, type: TrackingType.health);

    // Separate vaccines from other health
    final vaccines = healthRecords.where((r) => r.healthType == 'vaccine').toList();
    final others = healthRecords.where((r) => r.healthType != 'vaccine').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vaccines.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('לוח חיסונים', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Icon(Icons.notifications, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text('תזכורת פעילה', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.accent)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...vaccines.map((r) => _buildRecordCard(r, service)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionTitle('היסטוריה רפואית', others.length),
          const SizedBox(height: 12),
          if (others.isEmpty) _emptyState('אין רשומות בריאות'),
          ...others.map((r) => _buildRecordCard(r, service)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  OTHER TAB
  // ══════════════════════════════════════════════════
  Widget _buildOtherTab(TrackingService service) {
    final child = _selectedChild;
    if (child == null) return _emptyChild();
    final otherRecords = service.getRecordsForChild(child.id, type: TrackingType.other);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1C2D3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('✍️', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('רשומות מותאמות אישית', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('${otherRecords.length} רשומות', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (otherRecords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // Show unique categories
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getOtherCategories(otherRecords).map((cat) {
                      final count = otherRecords.where((r) => r.customType == cat).length;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1C2D3).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD1C2D3).withValues(alpha: 0.2)),
                        ),
                        child: Text('$cat ($count)', style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Color(0xFFD1C2D3), fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('כל הרשומות', otherRecords.length),
          const SizedBox(height: 12),
          if (otherRecords.isEmpty)
            _emptyState('אין רשומות מותאמות אישית עדיין\nהוסיפי רשומה חדשה עם הכפתור למטה')
          else
            ...otherRecords.map((r) => _buildRecordCard(r, service)),
        ],
      ),
    );
  }

  List<String> _getOtherCategories(List<TrackingRecord> records) {
    final cats = <String>{};
    for (final r in records) {
      if (r.customType != null && r.customType!.isNotEmpty) {
        cats.add(r.customType!);
      }
    }
    return cats.toList();
  }

  // ══════════════════════════════════════════════════
  //  UNIVERSAL RECORD CARD (with edit/delete)
  // ══════════════════════════════════════════════════
  Widget _buildRecordCard(TrackingRecord record, TrackingService service) {
    final color = TrackingHelpers.typeColor(record.type);
    final dateStr = _formatDate(record.dateTime);
    final timeStr = DateFormat('HH:mm').format(record.dateTime);
    final typeLabel = TrackingHelpers.typeLabel(record.type);

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.error.withValues(alpha: 0.8), AppColors.error]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDelete(context, record, service);
      },
      child: Semantics(
        label: 'רשומת $typeLabel מתאריך $dateStr בשעה $timeStr',
        button: true,
        hint: 'לחצי לעריכה, גררי לשמאל למחיקה',
        child: GestureDetector(
          onTap: () => _showEditRecordSheet(record),
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border(right: BorderSide(color: color, width: 3.5)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Text(TrackingHelpers.typeEmoji(record.type), style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildRecordContent(record)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(dateStr, style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.textHint)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _showEditRecordSheet(record),
                        child: Icon(Icons.edit, size: 16, color: AppColors.info.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, record, service),
                        child: Icon(Icons.delete_outline, size: 16, color: AppColors.error.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildRecordContent(TrackingRecord record) {
    switch (record.type) {
      case TrackingType.growth:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('מדידה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              [
                if (record.weight != null) '${record.weight!.toStringAsFixed(1)} ק"ג',
                if (record.height != null) '${record.height!.toStringAsFixed(0)} ס"מ',
                if (record.headCircumference != null) 'ר: ${record.headCircumference!.toStringAsFixed(1)} ס"מ',
              ].join(' | '),
              style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary),
            ),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        );
      case TrackingType.sleep:
        final dur = record.sleepDurationHours;
        final durStr = dur >= 1 ? '${dur.toStringAsFixed(1)} שעות' : '${(dur * 60).toInt()} דקות';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TrackingHelpers.sleepTypeLabel(record.sleepType ?? SleepSubType.nap), style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            Text(durStr, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.info, fontWeight: FontWeight.bold)),
            if (record.sleepEnd != null) Text('${DateFormat('HH:mm').format(record.dateTime)} - ${DateFormat('HH:mm').format(record.sleepEnd!)}', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textSecondary)),
          ],
        );
      case TrackingType.feeding:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TrackingHelpers.feedingTypeLabel(record.feedingType ?? FeedingSubType.bottle), style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              [
                if (record.foodDetails != null) record.foodDetails!,
                if (record.amountMl != null) '${record.amountMl!.toStringAsFixed(0)} מ"ל',
                if (record.durationMinutes != null) '${record.durationMinutes} דק׳',
                if (record.breastSide != null) record.breastSide!,
              ].join(' | '),
              style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary),
            ),
            if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        );
      case TrackingType.diaper:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('חיתול', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            Text(TrackingHelpers.diaperTypeLabel(record.diaperType ?? DiaperSubType.wet), style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
            if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        );
      case TrackingType.milestone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.milestoneName ?? 'אבן דרך', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Text(TrackingHelpers.milestoneCategoryLabel(record.milestoneCategory ?? MilestoneCategory.grossMotor), style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Text(TrackingHelpers.milestoneStatusLabel(record.milestoneStatus ?? MilestoneStatus.expected), style: const TextStyle(fontFamily: 'Heebo', fontSize: 12)),
            ]),
            if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        );
      case TrackingType.health:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TrackingHelpers.healthTypeLabel(record.healthType), style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            if (record.healthDetails != null) Text(record.healthDetails!, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
            if (record.temperature != null) Text('${record.temperature}°C', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
            if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        );
      case TrackingType.other:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.customType ?? 'אחר', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
            if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
          ],
        );
    }
  }

  // ══════════════════════════════════════════════════
  //  ADD RECORD SHEET
  // ══════════════════════════════════════════════════
  void _showAddRecordSheet() {
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('נא להוסיף ילד תחילה', style: TextStyle(fontFamily: 'Heebo'))));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            _sheetHandle(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('הוסף רשומה חדשה', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: TrackingType.values.map((type) {
                  return _buildAddTypeOption(type);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTypeOption(TrackingType type) {
    final color = TrackingHelpers.typeColor(type);
    final label = TrackingHelpers.typeLabel(type);
    return Semantics(
      label: 'הוספת רשומת $label',
      button: true,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          _showRecordFormSheet(type, null);
        },
        child: Container(
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(TrackingHelpers.typeEmoji(type), style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  EDIT RECORD SHEET
  // ══════════════════════════════════════════════════
  void _showEditRecordSheet(TrackingRecord record) {
    _showRecordFormSheet(record.type, record);
  }

  // ══════════════════════════════════════════════════
  //  RECORD FORM (Add / Edit) - MEGA SHEET
  // ══════════════════════════════════════════════════
  void _showRecordFormSheet(TrackingType type, TrackingRecord? existing) {
    if (_selectedChild == null) return;
    final isEdit = existing != null;
    final color = TrackingHelpers.typeColor(type);
    final child = _selectedChild!;

    // Controllers
    final notesController = TextEditingController(text: existing?.notes ?? '');
    DateTime selectedDate = existing?.dateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    // Type-specific state
    final weightController = TextEditingController(text: existing?.weight?.toString() ?? '');
    final heightController = TextEditingController(text: existing?.height?.toString() ?? '');
    final headController = TextEditingController(text: existing?.headCircumference?.toString() ?? '');

    SleepSubType selectedSleepType = existing?.sleepType ?? SleepSubType.nightSleep;
    DateTime? sleepEnd = existing?.sleepEnd;
    TimeOfDay? sleepEndTime = sleepEnd != null ? TimeOfDay.fromDateTime(sleepEnd) : null;

    FeedingSubType selectedFeedingType = existing?.feedingType ?? FeedingSubType.breastfeeding;
    final amountController = TextEditingController(text: existing?.amountMl?.toString() ?? '');
    final durationController = TextEditingController(text: existing?.durationMinutes?.toString() ?? '');
    final foodDetailsController = TextEditingController(text: existing?.foodDetails ?? '');
    final breastSideController = TextEditingController(text: existing?.breastSide ?? '');

    DiaperSubType selectedDiaperType = existing?.diaperType ?? DiaperSubType.wet;

    final milestoneNameController = TextEditingController(text: existing?.milestoneName ?? '');
    MilestoneCategory selectedMilestoneCat = existing?.milestoneCategory ?? MilestoneCategory.grossMotor;
    MilestoneStatus selectedMilestoneStatus = existing?.milestoneStatus ?? MilestoneStatus.achieved;

    String selectedHealthType = existing?.healthType ?? 'doctor_visit';
    final healthDetailsController = TextEditingController(text: existing?.healthDetails ?? '');
    final tempController = TextEditingController(text: existing?.temperature?.toString() ?? '');

    final customTypeController = TextEditingController(text: existing?.customType ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                          child: Text(TrackingHelpers.typeEmoji(type), style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Text('${isEdit ? "עריכת" : "הוספת"} ${TrackingHelpers.typeLabel(type)}', style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (isEdit)
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            tooltip: 'מחק',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDelete(context, existing, _service);
                            },
                          ),
                      ],
                    ),
                  ),
                  // Form content (scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & Time picker
                          _buildDateTimePicker(selectedDate, selectedTime, (date, time) {
                            setSheetState(() {
                              selectedDate = date;
                              selectedTime = time;
                            });
                          }),
                          const SizedBox(height: 16),

                          // Type-specific fields
                          if (type == TrackingType.growth) ...[
                            _buildFormField('משקל (ק"ג)', weightController, TextInputType.number, icon: Icons.monitor_weight),
                            _buildFormField('גובה (ס"מ)', heightController, TextInputType.number, icon: Icons.height),
                            _buildFormField('היקף ראש (ס"מ)', headController, TextInputType.number, icon: Icons.circle_outlined),
                          ],

                          if (type == TrackingType.sleep) ...[
                            _buildSegmentedSelector<SleepSubType>(
                              'סוג שינה',
                              SleepSubType.values,
                              selectedSleepType,
                              (v) => setSheetState(() => selectedSleepType = v),
                              (v) => TrackingHelpers.sleepTypeLabel(v),
                            ),
                            const SizedBox(height: 12),
                            _buildTimePicker('שעת סיום', sleepEndTime, (t) => setSheetState(() => sleepEndTime = t)),
                          ],

                          if (type == TrackingType.feeding) ...[
                            _buildSegmentedSelector<FeedingSubType>(
                              'סוג האכלה',
                              FeedingSubType.values,
                              selectedFeedingType,
                              (v) => setSheetState(() => selectedFeedingType = v),
                              (v) => TrackingHelpers.feedingTypeLabel(v),
                            ),
                            const SizedBox(height: 12),
                            if (selectedFeedingType == FeedingSubType.bottle || selectedFeedingType == FeedingSubType.water)
                              _buildFormField('כמות (מ"ל)', amountController, TextInputType.number, icon: Icons.water_drop),
                            if (selectedFeedingType == FeedingSubType.breastfeeding) ...[
                              _buildFormField('משך (דקות)', durationController, TextInputType.number, icon: Icons.timer),
                              _buildFormField('צד (שמאל/ימין/שניהם)', breastSideController, TextInputType.text, icon: Icons.compare_arrows),
                            ],
                            if (selectedFeedingType == FeedingSubType.solid || selectedFeedingType == FeedingSubType.snack)
                              _buildFormField('מה אכל/ה?', foodDetailsController, TextInputType.text, icon: Icons.restaurant),
                          ],

                          if (type == TrackingType.diaper) ...[
                            _buildSegmentedSelector<DiaperSubType>(
                              'סוג חיתול',
                              DiaperSubType.values,
                              selectedDiaperType,
                              (v) => setSheetState(() => selectedDiaperType = v),
                              (v) => TrackingHelpers.diaperTypeLabel(v),
                            ),
                          ],

                          if (type == TrackingType.milestone) ...[
                            _buildFormField('שם אבן הדרך', milestoneNameController, TextInputType.text, icon: Icons.flag),
                            const SizedBox(height: 12),
                            _buildSegmentedSelector<MilestoneCategory>(
                              'קטגוריה',
                              MilestoneCategory.values,
                              selectedMilestoneCat,
                              (v) => setSheetState(() => selectedMilestoneCat = v),
                              (v) => TrackingHelpers.milestoneCategoryLabel(v),
                            ),
                            const SizedBox(height: 12),
                            _buildSegmentedSelector<MilestoneStatus>(
                              'סטטוס',
                              MilestoneStatus.values,
                              selectedMilestoneStatus,
                              (v) => setSheetState(() => selectedMilestoneStatus = v),
                              (v) => TrackingHelpers.milestoneStatusLabel(v),
                            ),
                          ],

                          if (type == TrackingType.health) ...[
                            _buildSegmentedSelector<String>(
                              'סוג',
                              ['doctor_visit', 'fever', 'allergy', 'vaccine', 'medication', 'injury'],
                              selectedHealthType,
                              (v) => setSheetState(() => selectedHealthType = v),
                              (v) => TrackingHelpers.healthTypeLabel(v),
                            ),
                            const SizedBox(height: 12),
                            _buildFormField('פרטים', healthDetailsController, TextInputType.text, icon: Icons.notes),
                            if (selectedHealthType == 'fever')
                              _buildFormField('חום (°C)', tempController, TextInputType.number, icon: Icons.thermostat),
                          ],

                          if (type == TrackingType.other) ...[
                            _buildFormField('סוג (לדוגמה: רחצה, טיול...)', customTypeController, TextInputType.text, icon: Icons.category),
                          ],

                          const SizedBox(height: 12),
                          // Notes field
                          _buildFormField('הערות (אופציונלי)', notesController, TextInputType.multiline, icon: Icons.note, maxLines: 3),
                          const SizedBox(height: 20),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                                final data = <String, dynamic>{};

                                switch (type) {
                                  case TrackingType.growth:
                                    if (weightController.text.isNotEmpty) data['weight'] = double.tryParse(weightController.text);
                                    if (heightController.text.isNotEmpty) data['height'] = double.tryParse(heightController.text);
                                    if (headController.text.isNotEmpty) data['headCircumference'] = double.tryParse(headController.text);
                                  case TrackingType.sleep:
                                    data['sleepType'] = selectedSleepType.name;
                                    if (sleepEndTime != null) {
                                      data['sleepEnd'] = DateTime(dt.year, dt.month, dt.day, sleepEndTime!.hour, sleepEndTime!.minute).toIso8601String();
                                    }
                                  case TrackingType.feeding:
                                    data['feedingType'] = selectedFeedingType.name;
                                    if (amountController.text.isNotEmpty) data['amountMl'] = double.tryParse(amountController.text);
                                    if (durationController.text.isNotEmpty) data['durationMinutes'] = int.tryParse(durationController.text);
                                    if (foodDetailsController.text.isNotEmpty) data['foodDetails'] = foodDetailsController.text;
                                    if (breastSideController.text.isNotEmpty) data['breastSide'] = breastSideController.text;
                                  case TrackingType.diaper:
                                    data['diaperType'] = selectedDiaperType.name;
                                  case TrackingType.milestone:
                                    data['milestoneName'] = milestoneNameController.text;
                                    data['milestoneCategory'] = selectedMilestoneCat.name;
                                    data['milestoneStatus'] = selectedMilestoneStatus.name;
                                  case TrackingType.health:
                                    data['healthType'] = selectedHealthType;
                                    if (healthDetailsController.text.isNotEmpty) data['healthDetails'] = healthDetailsController.text;
                                    if (tempController.text.isNotEmpty) data['temperature'] = double.tryParse(tempController.text);
                                  case TrackingType.other:
                                    if (customTypeController.text.isNotEmpty) data['customType'] = customTypeController.text;
                                }

                                final record = TrackingRecord(
                                  id: existing?.id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
                                  childId: child.id,
                                  type: type,
                                  dateTime: dt,
                                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                                  data: data,
                                );

                                if (isEdit) {
                                  _service.updateRecord(record);
                                } else {
                                  _service.addRecord(record);
                                }

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${TrackingHelpers.typeEmoji(type)} ${isEdit ? "עודכן" : "נוסף"} בהצלחה!', style: const TextStyle(fontFamily: 'Heebo')),
                                  backgroundColor: color,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text(isEdit ? 'עדכן' : 'שמור', style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  FORM HELPERS
  // ══════════════════════════════════════════════════

  Widget _buildFormField(String label, TextEditingController controller, TextInputType type, {IconData? icon, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        textDirection: TextDirection.rtl,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Heebo'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textHint) : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(DateTime date, TimeOfDay time, Function(DateTime, TimeOfDay) onChanged) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                locale: const Locale('he'));
              if (picked != null) onChanged(picked, time);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd.MM.yyyy').format(date), style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _showCupertinoTimePicker(time, (picked) => onChanged(date, picked)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () => _showCupertinoTimePicker(time ?? TimeOfDay.now(), onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: time != null ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              time != null ? '$label: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '$label (לחצי לבחור)',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: time != null ? AppColors.textPrimary : AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium iOS-style CupertinoTimerPicker for selecting time
  void _showCupertinoTimePicker(TimeOfDay initialTime, Function(TimeOfDay) onChanged) {
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) => Container(
          height: 360,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5F4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // iOS-style toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5F4),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('ביטול', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onChanged(TimeOfDay(hour: selectedHour, minute: selectedMinute));
                        Navigator.pop(ctx);
                      },
                      child: const Text('אישור', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              // CupertinoPicker wheels
              Expanded(
                child: Row(
                  children: [
                    // Hours column (appears on right in RTL)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: selectedHour),
                        itemExtent: 42,
                        magnification: 1.15,
                        squeeze: 1.1,
                        useMagnifier: true,
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
                            ),
                          ),
                        ),
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          selectedHour = index;
                          setPickerState(() {});
                        },
                        children: List.generate(24, (index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                        )),
                      ),
                    ),
                    // Colon separator
                    const SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ),
                    ),
                    // Minutes column (appears on left in RTL)
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: selectedMinute),
                        itemExtent: 42,
                        magnification: 1.15,
                        squeeze: 1.1,
                        useMagnifier: true,
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
                            ),
                          ),
                        ),
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          selectedMinute = index;
                          setPickerState(() {});
                        },
                        children: List.generate(60, (index) => Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedSelector<T>(String label, List<T> options, T selected, Function(T) onChanged, String Function(T) labelFn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSel = opt == selected;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                ),
                child: Text(labelFn(opt), style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSel ? Colors.white : AppColors.textSecondary, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  //  ADD / EDIT CHILD DIALOG
  // ══════════════════════════════════════════════════
  void _showAddChildDialog() {
    _showChildFormDialog(null);
  }

  void _showEditChildDialog(ChildProfile child) {
    _showChildFormDialog(child);
  }

  void _showChildFormDialog(ChildProfile? existing) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    DateTime birthDate = existing?.birthDate ?? DateTime.now();
    String gender = existing?.gender ?? 'female';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEdit ? 'עריכת ילד' : 'הוסף ילד', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(labelText: 'שם הילד', labelStyle: const TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: birthDate, firstDate: DateTime(2018), lastDate: DateTime.now(), locale: const Locale('he'));
                    if (picked != null) setDState(() => birthDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(birthDate), style: const TextStyle(fontFamily: 'Heebo')),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _genderOption('בן', 'male', gender == 'male', () => setDState(() => gender = 'male')),
                    const SizedBox(width: 16),
                    _genderOption('בת', 'female', gender == 'female', () => setDState(() => gender = 'female')),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
              if (isEdit)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _service.deleteChild(existing.id);
                    try {
                      context.read<AppState>().removeChild(existing.id);
                    } catch (e) { debugPrint('[Tracking] Failed to remove child from AppState: $e'); }
                    if (_selectedChildIndex >= _service.children.length && _selectedChildIndex > 0) {
                      setState(() => _selectedChildIndex = _service.children.length - 1);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הילד נמחק', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
                  },
                  child: const Text('מחק', style: TextStyle(fontFamily: 'Heebo', color: AppColors.error)),
                ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final childData = ChildProfile(
                    id: existing?.id ?? 'child_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    birthDate: birthDate,
                    gender: gender,
                  );
                  if (isEdit) {
                    _service.updateChild(childData);
                  } else {
                    _service.addChild(childData);
                    setState(() => _selectedChildIndex = _service.children.length - 1);
                  }
                  // Sync to profile (AppState)
                  try {
                    final appState = context.read<AppState>();
                    final childModel = _service.childProfileToModel(childData);
                    if (isEdit) {
                      appState.updateChild(childModel);
                    } else {
                      appState.addChild(childModel);
                    }
                  } catch (e) { debugPrint('[Tracking] Failed to sync child to AppState: $e'); }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${isEdit ? "עודכן" : "נוסף"} בהצלחה! 🎉', style: const TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: AppColors.success,
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(isEdit ? 'עדכן' : 'הוסף', style: const TextStyle(fontFamily: 'Heebo', color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _genderOption(String label, String value, bool isSelected, VoidCallback onTap) {
    final color = value == 'male' ? AppColors.info : AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Heebo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : AppColors.textSecondary)),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════

  Future<bool?> _confirmDelete(BuildContext ctx, TrackingRecord record, TrackingService service) async {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('מחיקת רשומה', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        content: const Text('האם למחוק רשומה זו?', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Heebo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
          ElevatedButton(
            onPressed: () {
              service.deleteRecord(record.id);
              Navigator.pop(c, true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('הרשומה נמחקה', style: TextStyle(fontFamily: 'Heebo')),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('מחק', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dt.year, dt.month, dt.day);
    if (dateDay == today) return 'היום';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'אתמול';
    final diff = today.difference(dateDay).inDays;
    if (diff < 7) return 'לפני $diff ימים';
    if (diff < 30) return 'לפני ${diff ~/ 7} שבועות';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Widget _sheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _emptyChild() {
    return Center(child: Text('נא לבחור ילד', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: AppColors.textHint)));
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint)),
        ],
      ),
    );
  }
}

// Sliver delegate for tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => tabBar;
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
