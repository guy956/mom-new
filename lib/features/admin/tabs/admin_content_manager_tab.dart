import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// Content Manager Tab - Allows admins to manage app content
class AdminContentManagerTab extends StatefulWidget {
  const AdminContentManagerTab({super.key});

  @override
  State<AdminContentManagerTab> createState() => _AdminContentManagerTabState();
}

class _AdminContentManagerTabState extends State<AdminContentManagerTab> {
  bool _isLoading = false;

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
          'הפיצר "$featureName" נמצא כרגע בפיתוח ויהיה זמין בקרוב.\n\nבינתיים, השתמשי בטאב "אישורים" לניהול תוכן.',
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
                    'ניהול תוכן',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ניהול כלל התוכן באפליקציה - פוסטים, תגובות, תמונות ועוד',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildContentOverviewCard(),
                  const SizedBox(height: 24),
                  _buildContentModerationCard(),
                  const SizedBox(height: 24),
                  _buildBulkActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildContentOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'סקירת תוכן',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('פוסטים', '1,234'),
            _buildStatRow('תגובות', '5,678'),
            _buildStatRow('תמונות', '3,456'),
            _buildStatRow('סרטונים', '789'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentModerationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  'ביקורת תוכן',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModerationItem('תוכן מדווח', '12', Colors.red),
            _buildModerationItem('ממתין לאישור', '5', Colors.orange),
            _buildModerationItem('נחסם לאחרונה', '3', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationItem(String label, String count, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 12),
      title: Text(label),
      trailing: Chip(
        label: Text(count),
        backgroundColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        // Navigate to approvals tab for content moderation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('השתמשי בטאב "אישורים" לביקורת תוכן', style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'סגור',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.batch_prediction_rounded, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  'פעולות מרוכזות',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showFeatureInDevelopmentDialog('מחיקה מרוכזת');
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('מחק נבחרים'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showFeatureInDevelopmentDialog('אישור מרוכז');
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('אשר נבחרים'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showFeatureInDevelopmentDialog('ייצוא תוכן');
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('ייצא תוכן'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
