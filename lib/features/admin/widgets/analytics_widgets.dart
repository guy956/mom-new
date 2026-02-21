import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mom_connect/services/analytics_service.dart' show UserAction, AnalyticsService, TimeRange;

/// Analytics widgets for the admin dashboard
class AnalyticsWidgets {
  AnalyticsWidgets._();

  static const _heebo = TextStyle(fontFamily: 'Heebo');
  static const Color kPrimary = Color(0xFFD1C2D3);
  static const Color kSecondary = Color(0xFFDBC8B0);
  static const Color kAccent = Color(0xFFB5C8B9);
  static const Color kDark = Color(0xFF43363A);
  static const Color kWarning = Color(0xFFE8D5B7);

  // Chart colors palette
  static const List<Color> chartColors = [
    Color(0xFFD1C2D3), // Primary purple
    Color(0xFFDBC8B0), // Beige
    Color(0xFFB5C8B9), // Sage green
    Color(0xFFE8D5B7), // Peach
    Color(0xFFC5CAE9), // Light blue
    Color(0xFFD4A3A3), // Rose
    Color(0xFF9FA8DA), // Indigo
    Color(0xFF80CBC4), // Teal
  ];

  // ════════════════════════════════════════════════════════════════
  // STAT CARDS
  // ════════════════════════════════════════════════════════════════

  static Widget statCard({
    required String title,
    required String value,
    String? subtitle,
    IconData? icon,
    Color? color,
    double? trend,
    VoidCallback? onTap,
  }) {
    final c = color ?? kPrimary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon ?? Icons.analytics_outlined, color: c, size: 20),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trend >= 0 
                        ? const Color(0xFFE8F5E9) 
                        : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: trend >= 0 
                            ? const Color(0xFF2E7D32) 
                            : const Color(0xFFC62828),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: _heebo.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: trend >= 0 
                              ? const Color(0xFF2E7D32) 
                              : const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: _heebo.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: _heebo.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: _heebo.copyWith(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget activeUsersCard({required int count, int? previousCount}) {
    final trend = previousCount != null && previousCount > 0
      ? ((count - previousCount) / previousCount) * 100
      : null;

    return statCard(
      title: 'פעילים עכשיו',
      value: count.toString(),
      subtitle: 'ב-5 הדקות האחרונות',
      icon: Icons.people_alt_rounded,
      color: const Color(0xFFB5C8B9),
      trend: trend,
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LINE CHART - User Growth
  // ════════════════════════════════════════════════════════════════

  static Widget userGrowthChart({
    required Map<String, int> data,
    String title = 'צמיחת משתמשים',
    String? subtitle,
  }) {
    if (data.isEmpty) {
      return _emptyChart(title);
    }

    final sortedEntries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = <FlSpot>[];
    final maxValue = sortedEntries.map((e) => e.value).reduce(max);
    
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value.toDouble()));
    }

    return _chartContainer(
      title: title,
      subtitle: subtitle,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: max(1, maxValue / 4),
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: max(1, sortedEntries.length / 6).ceil().toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= sortedEntries.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatShortDate(sortedEntries[index].key),
                        style: _heebo.copyWith(fontSize: 10, color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: max(1, maxValue / 4),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: _heebo.copyWith(fontSize: 10, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (sortedEntries.length - 1).toDouble(),
            minY: 0,
            maxY: maxValue * 1.2,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: kPrimary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: kPrimary.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => kDark,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final date = sortedEntries[index].key;
                    return LineTooltipItem(
                      '${sortedEntries[index].value} משתמשים\n',
                      _heebo.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: _formatLongDate(date),
                          style: _heebo.copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BAR CHART - Feature Usage
  // ════════════════════════════════════════════════════════════════

  static Widget featureUsageChart({
    required Map<String, int> data,
    String title = 'פופולריות תכונות',
  }) {
    if (data.isEmpty) {
      return _emptyChart(title);
    }

    // Sort by value descending
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayEntries = sortedEntries.take(8).toList();
    final maxValue = displayEntries.first.value;

    return _chartContainer(
      title: title,
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => kDark,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final feature = displayEntries[groupIndex].key;
                  final value = displayEntries[groupIndex].value;
                  final name = AnalyticsService.featureNames[feature] ?? feature;
                  return BarTooltipItem(
                    '$name\n',
                    _heebo.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: '$value שימושים',
                        style: _heebo.copyWith(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= displayEntries.length) {
                      return const SizedBox();
                    }
                    final feature = displayEntries[index].key;
                    final name = AnalyticsService.featureNames[feature] ?? feature;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name,
                        style: _heebo.copyWith(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: max(1, maxValue / 4),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: _heebo.copyWith(fontSize: 10, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: max(1, maxValue / 4),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(displayEntries.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: displayEntries[i].value.toDouble(),
                    color: chartColors[i % chartColors.length],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PIE CHART - Distribution
  // ════════════════════════════════════════════════════════════════

  static Widget distributionPieChart({
    required Map<String, int> data,
    String title = 'התפלגות',
  }) {
    if (data.isEmpty) {
      return _emptyChart(title);
    }

    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return _emptyChart(title);

    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return _chartContainer(
      title: title,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  sections: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dataEntry = entry.value;
                    final percentage = (dataEntry.value / total * 100);
                    
                    return PieChartSectionData(
                      value: dataEntry.value.toDouble(),
                      color: chartColors[index % chartColors.length],
                      title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                      titleStyle: _heebo.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 55,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final dataEntry = entry.value;
                final name = AnalyticsService.featureNames[dataEntry.key] ?? dataEntry.key;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: chartColors[index % chartColors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: _heebo.copyWith(fontSize: 11, color: kDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${dataEntry.value} (${(dataEntry.value / total * 100).toStringAsFixed(1)}%)',
                              style: _heebo.copyWith(fontSize: 9, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ENGAGEMENT METRICS
  // ════════════════════════════════════════════════════════════════

  static Widget engagementMetricsCard({
    required Map<String, dynamic> engagement,
  }) {
    final posts = engagement['posts'] as Map<String, dynamic>? ?? {};
    final events = engagement['events'] as Map<String, dynamic>? ?? {};
    final marketplace = engagement['marketplace'] as Map<String, dynamic>? ?? {};

    return _chartContainer(
      title: 'מדדי מעורבות תוכן',
      child: Column(
        children: [
          _engagementRow(
            icon: Icons.article_rounded,
            color: const Color(0xFFC5CAE9),
            label: 'פוסטים',
            created: posts['created'] ?? 0,
            interactions: (posts['likes'] ?? 0) + (posts['comments'] ?? 0),
          ),
          const Divider(height: 24),
          _engagementRow(
            icon: Icons.event_rounded,
            color: const Color(0xFFE8D5B7),
            label: 'אירועים',
            created: events['created'] ?? 0,
            interactions: events['rsvps'] ?? 0,
          ),
          const Divider(height: 24),
          _engagementRow(
            icon: Icons.store_rounded,
            color: const Color(0xFFD4A3A3),
            label: 'מסירות',
            created: marketplace['created'] ?? 0,
            interactions: marketplace['sold'] ?? 0,
          ),
        ],
      ),
    );
  }

  static Widget _engagementRow({
    required IconData icon,
    required Color color,
    required String label,
    required int created,
    required int interactions,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _heebo.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
              Text('נוצרו: $created', style: _heebo.copyWith(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$interactions',
              style: _heebo.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
            ),
            Text(
              'אינטראקציות',
              style: _heebo.copyWith(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // REVENUE CHART
  // ════════════════════════════════════════════════════════════════

  static Widget revenueChart({
    required Map<String, double> revenue,
    String? currency = '₪',
  }) {
    final total = revenue['total'] ?? 0.0;
    if (total == 0) {
      return _chartContainer(
        title: 'הכנסות',
        child: const SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'אין נתוני הכנסות',
              style: _heebo,
            ),
          ),
        ),
      );
    }

    final categories = {
      'marketplace': 'מסירות',
      'events': 'אירועים',
      'premium': 'פרימיום',
    };

    return _chartContainer(
      title: 'הכנסות',
      subtitle: 'סה״כ: $currency${total.toStringAsFixed(0)}',
      child: Column(
        children: categories.entries.map((entry) {
          final value = revenue[entry.key] ?? 0.0;
          final percentage = (value / total * 100);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.value, style: _heebo.copyWith(fontSize: 12, color: kDark)),
                    Text(
                      '$currency${value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                      style: _heebo.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: kDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      chartColors[categories.keys.toList().indexOf(entry.key) % chartColors.length],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DATE RANGE SELECTOR
  // ════════════════════════════════════════════════════════════════

  static Widget dateRangeSelector({
    required TimeRange currentRange,
    required ValueChanged<TimeRange> onRangeChanged,
    VoidCallback? onCustomRange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            currentRange.label,
            style: _heebo.copyWith(fontSize: 13, color: kDark),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<TimeRange>(
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            itemBuilder: (context) => [
              ...TimeRange.presets.map((range) => PopupMenuItem(
                value: range,
                child: Text(range.label, style: _heebo),
              )),
              if (onCustomRange != null)
                PopupMenuItem(
                  value: null,
                  onTap: onCustomRange,
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 18),
                      const SizedBox(width: 8),
                      Text('טווח מותאם', style: _heebo),
                    ],
                  ),
                ),
            ],
            onSelected: (range) {
              if (range != null) onRangeChanged(range);
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // EXPORT BUTTONS
  // ════════════════════════════════════════════════════════════════

  static Widget exportButtons({
    required VoidCallback onExportCsv,
    required VoidCallback onExportPdf,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _exportButton(
          label: 'CSV',
          icon: Icons.table_chart_outlined,
          onTap: onExportCsv,
        ),
        const SizedBox(width: 8),
        _exportButton(
          label: 'PDF',
          icon: Icons.picture_as_pdf_outlined,
          onTap: onExportPdf,
        ),
      ],
    );
  }

  static Widget _exportButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: kPrimary),
            const SizedBox(width: 4),
            Text(label, style: _heebo.copyWith(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ACTIVITY FEED
  // ════════════════════════════════════════════════════════════════

  static Widget activityFeed({
    required List<UserAction> actions,
    int maxItems = 10,
  }) {
    if (actions.isEmpty) {
      return _chartContainer(
        title: 'פעילות אחרונה',
        child: const SizedBox(
          height: 100,
          child: Center(child: Text('אין פעילות אחרונה', style: _heebo)),
        ),
      );
    }

    final displayActions = actions.take(maxItems).toList();

    return _chartContainer(
      title: 'פעילות אחרונה',
      child: Column(
        children: displayActions.map<Widget>((action) => _activityItem(action)).toList(),
      ),
    );
  }

  static Widget _activityItem(UserAction action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActionIcon(action.action),
              size: 18,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionText(action),
                  style: _heebo.copyWith(fontSize: 13, color: kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatRelativeTime(action.timestamp),
                  style: _heebo.copyWith(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════

  static Widget _chartContainer({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: _heebo.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kDark,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: _heebo.copyWith(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  static Widget _emptyChart(String title) {
    return _chartContainer(
      title: title,
      child: SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('אין נתונים זמינים', style: _heebo.copyWith(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatShortDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d/M').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatLongDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'view':
        return Icons.visibility_outlined;
      case 'click':
        return Icons.touch_app_outlined;
      case 'create':
        return Icons.add_circle_outlined;
      case 'like':
        return Icons.favorite_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'share':
        return Icons.share_outlined;
      case 'purchase':
        return Icons.shopping_cart_outlined;
      case 'login':
        return Icons.login_outlined;
      case 'register':
        return Icons.person_add_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  static String _getActionText(UserAction action) {
    final feature = AnalyticsService.featureNames[action.feature] ?? action.feature ?? '';
    final actionName = _translateAction(action.action);
    return feature.isNotEmpty ? '$actionName - $feature' : actionName;
  }

  static String _translateAction(String action) {
    switch (action.toLowerCase()) {
      case 'view': return 'צפייה';
      case 'click': return 'לחיצה';
      case 'create': return 'יצירה';
      case 'like': return 'לייק';
      case 'comment': return 'תגובה';
      case 'share': return 'שיתוף';
      case 'purchase': return 'רכישה';
      case 'login': return 'התחברות';
      case 'register': return 'הרשמה';
      default: return action;
    }
  }
}
