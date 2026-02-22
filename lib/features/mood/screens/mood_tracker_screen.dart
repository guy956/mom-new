import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';

/// Mood Tracker - מעקב מצב רוח יומי לאמהות
class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int? _selectedMoodIndex;
  String _note = '';
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'icon': Icons.sentiment_very_satisfied_rounded, 'label': 'מעולה', 'color': const Color(0xFFB5C8B9)},
    {'icon': Icons.sentiment_satisfied_rounded, 'label': 'טוב', 'color': const Color(0xFFB5C8B9)},
    {'icon': Icons.sentiment_neutral_rounded, 'label': 'בסדר', 'color': const Color(0xFFDBC8B0)},
    {'icon': Icons.sentiment_dissatisfied_rounded, 'label': 'עצוב', 'color': const Color(0xFFDBC8B0)},
    {'icon': Icons.sentiment_very_dissatisfied_rounded, 'label': 'קשה', 'color': const Color(0xFFD4A3A3)},
    {'icon': Icons.mood_bad_rounded, 'label': 'מתוסכל', 'color': const Color(0xFFD1C2D3)},
    {'icon': Icons.bedtime_outlined, 'label': 'עייף', 'color': const Color(0xFF9B8F92)},
    {'icon': Icons.psychology_outlined, 'label': 'חרדה', 'color': const Color(0xFFD6C7C1)},
  ];

  final List<String> _quickTags = [
    'שינה טובה', 'שינה גרועה', 'זמן לעצמי', 'יום עמוס',
    'התפרצות', 'רגע מתוק', 'עייפות', 'הצלחה', 'תסכול',
    'גאווה', 'אושר', 'בדידות', 'תמיכה', 'חיוך',
  ];

  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('איך את מרגישה?', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsights(),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'מסך ראשי',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMoodSelector(),
            if (_selectedMoodIndex != null) ...[
              _buildTagsSection(),
              _buildNoteSection(),
              _buildSaveButton(),
            ],
            _buildWeeklyOverview(),
            _buildMoodHistory(),
            _buildSupportSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text(
            'איך את מרגישה עכשיו?',
            style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'לחצי על המצב רוח שמתאר אותך',
            style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_moods.length, (index) {
              final mood = _moods[index];
              final isSelected = _selectedMoodIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedMoodIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (mood['color'] as Color).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? mood['color'] as Color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mood['icon'] as IconData,
                        size: isSelected ? 36 : 28,
                        color: mood['color'] as Color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? mood['color'] as Color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('מה קורה?', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_moods[_selectedMoodIndex!]['color'] as Color).withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: _moods[_selectedMoodIndex!]['color'] as Color)
                        : null,
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 13,
                      color: isSelected ? _moods[_selectedMoodIndex!]['color'] as Color : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('רוצה להוסיף הערה?', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'Heebo'),
            decoration: InputDecoration(
              hintText: 'כתבי מה על הלב...',
              hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => _note = val,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    if (_selectedMoodIndex == null) return const SizedBox.shrink();
    final mood = _moods[_selectedMoodIndex!];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final fs = Provider.of<FirestoreService>(context, listen: false);
            final appState = Provider.of<AppState>(context, listen: false);
            final userId = appState.currentUser?.id ?? 'anonymous';
            try {
              await fs.saveMoodEntry({
                'userId': userId,
                'moodIndex': _selectedMoodIndex,
                'moodLabel': mood['label'],
                'note': _note.isNotEmpty ? _note : '',
                'tags': List<String>.from(_selectedTags),
                'timestamp': DateTime.now().toIso8601String(),
              });
              if (mounted) {
                setState(() {
                  _selectedMoodIndex = null;
                  _selectedTags.clear();
                  _noteController.clear();
                  _note = '';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('נשמר! תודה ששיתפת', style: TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: mood['color'] as Color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('שגיאה בשמירה: $e', style: const TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: mood['color'] as Color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mood['icon'] as IconData, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              const Text('שמרי מצב רוח', style: TextStyle(fontFamily: 'Heebo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id ?? 'anonymous';
    final days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.moodEntriesStream(userId),
      builder: (context, snapshot) {
        // Build a map: weekday (1=Mon..7=Sun) -> last mood entry for that day
        final Map<int, int> weekdayMoodIndex = {};
        if (snapshot.hasData) {
          final now = DateTime.now();
          for (final entry in snapshot.data!) {
            DateTime? dt;
            final ts = entry['createdAt'];
            if (ts is Timestamp) {
              dt = ts.toDate();
            } else {
              final raw = entry['timestamp'];
              if (raw is String) {
                dt = DateTime.tryParse(raw);
              }
            }
            if (dt != null && now.difference(dt).inDays < 7) {
              final wd = dt.weekday; // 1=Mon..7=Sun
              if (!weekdayMoodIndex.containsKey(wd)) {
                weekdayMoodIndex[wd] = (entry['moodIndex'] as int?) ?? 2;
              }
            }
          }
        }

        // Hebrew week starts Sunday; map display index to weekday
        // Display: א=Sun(7), ב=Mon(1), ג=Tue(2), ד=Wed(3), ה=Thu(4), ו=Fri(5), ש=Sat(6)
        final displayToWeekday = [7, 1, 2, 3, 4, 5, 6];
        final todayWeekday = DateTime.now().weekday;

        // Compute average label
        String avgLabel = '';
        if (weekdayMoodIndex.isNotEmpty) {
          final avg = weekdayMoodIndex.values.reduce((a, b) => a + b) / weekdayMoodIndex.length;
          final avgIdx = avg.round().clamp(0, _moods.length - 1);
          avgLabel = 'ממוצע: ${_moods[avgIdx]['label']}';
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('סקירה שבועית', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  if (avgLabel.isNotEmpty)
                    Text(avgLabel, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final wd = displayToWeekday[i];
                  final isToday = wd == todayWeekday;
                  final moodIdx = weekdayMoodIndex[wd];
                  final icon = moodIdx != null
                      ? (_moods[moodIdx.clamp(0, _moods.length - 1)]['icon'] as IconData)
                      : Icons.remove_rounded;
                  return Column(
                    children: [
                      Text(days[i], style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                      const SizedBox(height: 6),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                          border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Center(child: Icon(icon, size: 20, color: isToday ? AppColors.primary : AppColors.textSecondary)),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dateOnly).inDays;
    if (diff == 0) return 'היום';
    if (diff == 1) return 'אתמול';
    if (diff == 2) return 'שלשום';
    return 'לפני $diff ימים';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMoodHistory() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id ?? 'anonymous';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.moodEntriesStream(userId),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('היסטוריה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'אין היסטוריה עדיין. שתפי את מצב הרוח שלך!',
                      style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textHint),
                    ),
                  ),
                )
              else
                ...(entries.take(5).map((entry) {
                  DateTime? dt;
                  final ts = entry['createdAt'];
                  if (ts is Timestamp) {
                    dt = ts.toDate();
                  } else {
                    final raw = entry['timestamp'];
                    if (raw is String) dt = DateTime.tryParse(raw);
                  }
                  final moodIdx = (entry['moodIndex'] as int?) ?? 2;
                  final clampedIdx = moodIdx.clamp(0, _moods.length - 1);
                  final icon = _moods[clampedIdx]['icon'] as IconData;
                  final note = (entry['note'] as String?) ?? '';
                  final tags = entry['tags'];
                  final displayNote = note.isNotEmpty
                      ? note
                      : (tags is List && tags.isNotEmpty ? tags.join(', ') : '');
                  final dateStr = dt != null ? _formatDate(dt) : '';
                  final timeStr = dt != null ? _formatTime(dt) : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 28, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(dateStr, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(timeStr, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                                ],
                              ),
                              if (displayNote.isNotEmpty)
                                Text(
                                  displayNote,
                                  style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                })),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD1C2D3).withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1C2D3).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFFD1C2D3), size: 20),
              SizedBox(width: 8),
              Text('זכרי - את לא לבד', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'אם את מרגישה קשה לאורך זמן, אל תהססי לפנות לעזרה. ער"ן - *2784',
            style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showInsights() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id ?? 'anonymous';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.moodEntriesStream(userId),
        builder: (ctx, snapshot) {
          final entries = snapshot.data ?? [];

          // Calculate insights from real data
          String avgLabel = 'אין מספיק נתונים';
          String trendDesc = 'צריך לפחות כמה רישומים כדי לזהות מגמות';
          String topTagDesc = 'שתפי יותר כדי לגלות תובנות';
          String countDesc = 'סה"כ ${entries.length} רישומים';

          if (entries.isNotEmpty) {
            // Weekly average
            final now = DateTime.now();
            final weekEntries = entries.where((e) {
              DateTime? dt;
              final ts = e['createdAt'];
              if (ts is Timestamp) dt = ts.toDate();
              else {
                final raw = e['timestamp'];
                if (raw is String) dt = DateTime.tryParse(raw);
              }
              return dt != null && now.difference(dt).inDays < 7;
            }).toList();

            if (weekEntries.isNotEmpty) {
              final avgIdx = weekEntries
                  .map((e) => (e['moodIndex'] as int?) ?? 2)
                  .reduce((a, b) => a + b) / weekEntries.length;
              final clampedAvg = avgIdx.round().clamp(0, _moods.length - 1);
              avgLabel = 'מצב הרוח הממוצע שלך השבוע: ${_moods[clampedAvg]['label']}';
            } else {
              avgLabel = 'אין רישומים מהשבוע האחרון';
            }

            // Trend: compare first half vs second half of entries
            if (entries.length >= 4) {
              final half = entries.length ~/ 2;
              final recentAvg = entries.sublist(0, half)
                  .map((e) => (e['moodIndex'] as int?) ?? 2)
                  .reduce((a, b) => a + b) / half;
              final olderAvg = entries.sublist(half)
                  .map((e) => (e['moodIndex'] as int?) ?? 2)
                  .reduce((a, b) => a + b) / (entries.length - half);
              if (recentAvg < olderAvg) {
                trendDesc = 'מצב הרוח שלך השתפר לאחרונה!';
              } else if (recentAvg > olderAvg) {
                trendDesc = 'נראה שמצב הרוח ירד קצת לאחרונה. שמרי על עצמך.';
              } else {
                trendDesc = 'מצב הרוח שלך יציב.';
              }
            }

            // Top tags
            final tagCounts = <String, int>{};
            for (final e in entries) {
              final tags = e['tags'];
              if (tags is List) {
                for (final t in tags) {
                  tagCounts[t.toString()] = (tagCounts[t.toString()] ?? 0) + 1;
                }
              }
            }
            if (tagCounts.isNotEmpty) {
              final sorted = tagCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final topTags = sorted.take(3).map((e) => e.key).join(', ');
              topTagDesc = 'התגיות הנפוצות שלך: $topTags';
            }
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Center(child: Text('תובנות', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
                _buildInsightCardIcon(Icons.star_outline_rounded, 'ממוצע שבועי', avgLabel, AppColors.success),
                _buildInsightCardIcon(Icons.trending_up_rounded, 'מגמה', trendDesc, AppColors.primary),
                _buildInsightCardIcon(Icons.tag_rounded, 'תגיות נפוצות', topTagDesc, AppColors.info),
                _buildInsightCardIcon(Icons.bar_chart_rounded, 'סיכום', countDesc, const Color(0xFFD1C2D3)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCardIcon(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
