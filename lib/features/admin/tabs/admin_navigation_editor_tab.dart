import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// Navigation Editor Tab - Allows admins to customize app navigation structure
class AdminNavigationEditorTab extends StatefulWidget {
  const AdminNavigationEditorTab({super.key});

  @override
  State<AdminNavigationEditorTab> createState() => _AdminNavigationEditorTabState();
}

class _AdminNavigationEditorTabState extends State<AdminNavigationEditorTab> {
  bool _isLoading = false;
  final Map<String, bool> _navigationVisibility = {};

  void _showFeatureInDevelopmentDialog(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('פיצר בפיתוח', style: TextStyle(fontFamily: 'Heebo')),
            ),
          ],
        ),
        content: Text(
          'הפיצר "$featureName" נמצא כרגע בפיתוח ויהיה זמין בקרוב.',
          style: const TextStyle(fontFamily: 'Heebo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('הבנתי', style: TextStyle(fontFamily: 'Heebo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'עורך ניווט',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'התאמה אישית של תפריטי הניווט באפליקציה',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildNavigationStructureCard(),
                  const SizedBox(height: 24),
                  _buildQuickLinksCard(),
                ],
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _navigationVisibility.addAll({
      'home': true,
      'feed': true,
      'tracking': true,
      'events': false,
      'chat': true,
      'profile': true,
    });
  }

  Widget _buildNavigationStructureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'מבנה הניווט',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('כאן תוכלי לערוך את מבנה תפריטי הניווט הראשיים'),
            const SizedBox(height: 16),
            _buildNavigationItem('home', 'דף הבית', Icons.home_rounded),
            _buildNavigationItem('feed', 'פיד', Icons.feed_rounded),
            _buildNavigationItem('tracking', 'מעקב', Icons.track_changes_rounded),
            _buildNavigationItem('events', 'אירועים', Icons.event_rounded),
            _buildNavigationItem('chat', 'צ\'אט', Icons.chat_rounded),
            _buildNavigationItem('profile', 'פרופיל', Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(String key, String label, IconData icon) {
    final isVisible = _navigationVisibility[key] ?? true;
    return ListTile(
      leading: Icon(icon, color: isVisible ? AppColors.primary : AppColors.textHint),
      title: Text(label, style: TextStyle(
        color: isVisible ? null : AppColors.textHint,
        decoration: isVisible ? null : TextDecoration.lineThrough,
      )),
      trailing: Switch(
        value: isVisible,
        activeColor: AppColors.primary,
        onChanged: (value) {
          setState(() {
            _navigationVisibility[key] = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value ? '$label מוצג בניווט' : '$label הוסתר מהניווט',
                style: const TextStyle(fontFamily: 'Heebo'),
              ),
              backgroundColor: value ? AppColors.success : AppColors.textHint,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  'קישורים מהירים',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('ניהול קישורים מהירים בתפריט הצדדי'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showFeatureInDevelopmentDialog('הוספת קישור מהיר');
              },
              icon: const Icon(Icons.add),
              label: const Text('הוסף קישור חדש'),
            ),
          ],
        ),
      ),
    );
  }
}
