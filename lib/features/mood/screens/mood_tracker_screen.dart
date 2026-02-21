import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

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

  final List<Map<String, dynamic>> _moodHistory = [
    {'icon': Icons.sentiment_very_satisfied_rounded, 'date': 'היום', 'note': 'יום נהדר עם הילדים!', 'time': '09:30'},
    {'icon': Icons.bedtime_outlined, 'date': 'אתמול', 'note': 'לילה ארוך, אבל עברתי את זה', 'time': '22:15'},
    {'icon': Icons.sentiment_satisfied_rounded, 'date': 'שלשום', 'note': 'פגשתי חברה לקפה', 'time': '14:00'},
    {'icon': Icons.sentiment_dissatisfied_rounded, 'date': 'לפני 3 ימים', 'note': 'יום קשה, הרבה בכי', 'time': '20:45'},
    {'icon': Icons.sentiment_very_satisfied_rounded, 'date': 'לפני 4 ימים', 'note': 'הצעד הראשון של התינוק!', 'time': '11:30'},
    {'icon': Icons.sentiment_neutral_rounded, 'date': 'לפני 5 ימים', 'note': '', 'time': '18:00'},
    {'icon': Icons.sentiment_satisfied_rounded, 'date': 'לפני 6 ימים', 'note': 'יוגה עם אמהות', 'time': '10:00'},
  ];

  final List<String> _quickTags = [
    'שינה טובה', 'שינה גרועה', 'זמן לעצמי', 'יום עמוס',
    'התפרצות', 'רגע מתוק', 'עייפות', 'הצלחה', 'תסכול',
    'גאווה', 'אושר', 'בדידות', 'תמיכה', 'חיוך',
  ];

  final List<String> _selectedTags = [];

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
          onPressed: () {
            setState(() {
              _moodHistory.insert(0, {
                'emoji': mood['icon'],
                'date': 'עכשיו',
                'note': _note.isNotEmpty ? _note : _selectedTags.join(', '),
                'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              });
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
    final days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
    final weekIcons = [
      Icons.sentiment_very_satisfied_rounded,
      Icons.bedtime_outlined,
      Icons.sentiment_satisfied_rounded,
      Icons.sentiment_dissatisfied_rounded,
      Icons.sentiment_very_satisfied_rounded,
      Icons.sentiment_neutral_rounded,
      Icons.sentiment_satisfied_rounded,
    ];
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
              Text('ממוצע: טוב', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == 0;
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
                    child: Center(child: Icon(weekIcons[i], size: 20, color: isToday ? AppColors.primary : AppColors.textSecondary)),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodHistory() {
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
          ...(_moodHistory.take(5).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(entry['icon'] as IconData, size: 28, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entry['date'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(entry['time'], style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                        if ((entry['note'] as String).isNotEmpty)
                          Text(
                            entry['note'],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
            _buildInsightCardIcon(Icons.star_outline_rounded, 'ממוצע שבועי', 'מצב הרוח הממוצע שלך השבוע: טוב', AppColors.success),
            _buildInsightCardIcon(Icons.trending_up_rounded, 'מגמה חיובית', 'את מרגישה טוב יותר מהשבוע שעבר', AppColors.primary),
            _buildInsightCardIcon(Icons.bedtime_outlined, 'השפעת שינה', 'בימים שישנת טוב - מצב הרוח היה טוב יותר', AppColors.info),
            _buildInsightCardIcon(Icons.people_outline_rounded, 'קשר חברתי', 'מפגשים עם חברות שיפרו את מצב הרוח', const Color(0xFFD1C2D3)),
          ],
        ),
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
