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
            const Text('כאן תוכל לערוך את מבנה תפריטי הניווט הראשיים'),
            const SizedBox(height: 16),
            _buildNavigationItem('דף הבית', Icons.home_rounded, true),
            _buildNavigationItem('פיד', Icons.feed_rounded, true),
            _buildNavigationItem('מעקב', Icons.track_changes_rounded, true),
            _buildNavigationItem('אירועים', Icons.event_rounded, false),
            _buildNavigationItem('צ\'אט', Icons.chat_rounded, true),
            _buildNavigationItem('פרופיל', Icons.person_rounded, true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(String label, IconData icon, bool isVisible) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Switch(
        value: isVisible,
        onChanged: (value) {
          // TODO: Implement visibility toggle
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
                // TODO: Implement add quick link
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
