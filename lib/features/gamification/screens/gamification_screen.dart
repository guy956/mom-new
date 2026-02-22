import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// מערכת גמיפיקציה - תגמולים, אתגרים, דרגות
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, dynamic> _userStats = {
    'level': 12,
    'levelName': 'סופר אמא 🦸‍♀️',
    'xp': 2450,
    'nextLevelXp': 3000,
    'coins': 580,
    'streak': 7,
    'badges': 8,
    'rank': 23,
  };

  final List<Map<String, dynamic>> _badges = [
    {'icon': Icons.star_outline_rounded, 'name': 'מתחילה', 'desc': 'הצטרפת לקהילה', 'earned': true},
    {'icon': Icons.chat_bubble_outline_rounded, 'name': 'דברנית', 'desc': '50 הודעות', 'earned': true},
    {'icon': Icons.favorite_outline_rounded, 'name': 'לב של זהב', 'desc': '100 לייקים', 'earned': true},
    {'icon': Icons.handshake_outlined, 'name': 'עוזרת', 'desc': 'עזרת ל-10 אמהות', 'earned': true},
    {'icon': Icons.edit_note_rounded, 'name': 'סופרת', 'desc': '20 פוסטים', 'earned': true},
    {'icon': Icons.local_fire_department_outlined, 'name': '7 ימים רצוף', 'desc': 'סטריק של שבוע', 'earned': true},
    {'icon': Icons.workspace_premium_outlined, 'name': 'מלכת הפיד', 'desc': 'פוסט עם 100 לייקים', 'earned': true},
    {'icon': Icons.emoji_events_outlined, 'name': 'מובילה', 'desc': 'טופ 50 בקהילה', 'earned': true},
    {'icon': Icons.event_outlined, 'name': 'מארגנת', 'desc': 'ארגנת אירוע', 'earned': false},
    {'icon': Icons.psychology_outlined, 'name': 'מומחית', 'desc': '100 תגובות מועילות', 'earned': false},
    {'icon': Icons.diamond_outlined, 'name': 'יהלום', 'desc': 'שנה בקהילה', 'earned': false},
    {'icon': Icons.spa_outlined, 'name': 'מנטורית', 'desc': 'הנחית 5 אמהות חדשות', 'earned': false},
  ];

  final List<Map<String, dynamic>> _challenges = [
    {'title': 'שתפי 3 טיפים השבוע', 'progress': 2, 'total': 3, 'reward': 50, 'icon': Icons.lightbulb_outline_rounded, 'daysLeft': 3},
    {'title': 'גיבי 10 תגובות תומכות', 'progress': 7, 'total': 10, 'reward': 80, 'icon': Icons.volunteer_activism_outlined, 'daysLeft': 5},
    {'title': 'הצטרפי לאירוע קהילתי', 'progress': 0, 'total': 1, 'reward': 100, 'icon': Icons.celebration_outlined, 'daysLeft': 7},
    {'title': 'שלחי הודעה ל-5 אמהות חדשות', 'progress': 3, 'total': 5, 'reward': 60, 'icon': Icons.waving_hand_outlined, 'daysLeft': 4},
    {'title': 'עדכני מצב רוח 7 ימים', 'progress': 5, 'total': 7, 'reward': 120, 'icon': Icons.sentiment_satisfied_outlined, 'daysLeft': 2},
  ];

  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'נועה ישראלי', 'xp': 5200, 'level': 18},
    {'name': 'מיכל לוין', 'xp': 4800, 'level': 17},
    {'name': 'יעל כהן', 'xp': 4500, 'level': 16},
    {'name': 'דנה אברהם', 'xp': 3900, 'level': 15},
    {'name': 'שירה מזרחי', 'xp': 3200, 'level': 14},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ההישגים שלי', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'מסך ראשי',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLevelCard(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'אתגרים'),
              Tab(text: 'תגים'),
              Tab(text: 'דירוג'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesTab(),
                _buildBadgesTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    final progress = _userStats['xp'] / _userStats['nextLevelXp'];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${_userStats['level']}', style: const TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userStats['levelName'], style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${_userStats['xp']}/${_userStats['nextLevelXp']} XP', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMiniIcon(Icons.toll_outlined, '${_userStats['coins']}', 'מטבעות'),
              _buildStatMiniIcon(Icons.local_fire_department_outlined, '${_userStats['streak']} ימים', 'סטריק'),
              _buildStatMiniIcon(Icons.military_tech_outlined, '${_userStats['badges']}', 'תגים'),
              _buildStatMiniIcon(Icons.leaderboard_outlined, '#${_userStats['rank']}', 'דירוג'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
        Text(value, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Text('🎯 אתגרים שבועיים', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ..._challenges.map((ch) {
          final progress = (ch['progress'] as int) / (ch['total'] as int);
          final isComplete = ch['progress'] == ch['total'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isComplete ? AppColors.success.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isComplete ? Border.all(color: AppColors.success.withValues(alpha: 0.3)) : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(ch['icon'] as IconData, size: 28, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch['title'], style: TextStyle(
                            fontFamily: 'Heebo', fontWeight: FontWeight.w600,
                            decoration: isComplete ? TextDecoration.lineThrough : null,
                          )),
                          Row(
                            children: [
                              Text('🪙 ${ch['reward']}', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.accent)),
                              const SizedBox(width: 10),
                              Text('⏰ ${ch['daysLeft']} ימים', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isComplete)
                      const Icon(Icons.check_circle, color: AppColors.success, size: 28)
                    else
                      Text('${ch['progress']}/${ch['total']}', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(isComplete ? AppColors.success : AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBadgesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        final earned = badge['earned'] as bool;
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${badge['name']}: ${badge['desc']}', style: const TextStyle(fontFamily: 'Heebo')),
                backgroundColor: earned ? AppColors.primary : AppColors.textHint,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: earned ? Colors.white : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: earned ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  badge['icon'] as IconData,
                  size: earned ? 36 : 28, color: earned ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(height: 6),
                Text(
                  badge['name'],
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
                    color: earned ? AppColors.textPrimary : AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!earned)
                  const Icon(Icons.lock, size: 14, color: AppColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🏆 מובילות השבוע', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(_leaderboard.length, (i) {
          final user = _leaderboard[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFFDF6F7) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: i == 0 ? Border.all(color: AppColors.accent.withValues(alpha: 0.5)) : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '#${i + 1}',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: i < 3 ? 22 : 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(child: Icon(Icons.person_outline_rounded, size: 24, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                      Text('רמה ${user['level']}', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${user['xp']}', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text('XP', style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          );
        }),
        // Current user
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 30, child: Text('#23', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.momGradient,
                ),
                child: const Center(child: Text('שכ', style: TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('שרה כהן (את!)', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
                    Text('רמה 12', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('2,450', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('XP', style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
