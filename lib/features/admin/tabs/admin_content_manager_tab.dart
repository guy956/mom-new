import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/firestore_service.dart';

/// Content Manager Tab - Allows admins to manage app content
class AdminContentManagerTab extends StatefulWidget {
  final void Function(String tabId)? onNavigateToTab;
  const AdminContentManagerTab({super.key, this.onNavigateToTab});

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
    final fs = context.read<FirestoreService>();
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
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.postsStream,
              builder: (_, snap) => _buildStatRow(
                'פוסטים',
                snap.hasData ? '${snap.data!.length}' : '...',
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.tipsStream,
              builder: (_, snap) => _buildStatRow(
                'טיפים',
                snap.hasData ? '${snap.data!.length}' : '...',
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.eventsStream,
              builder: (_, snap) => _buildStatRow(
                'אירועים',
                snap.hasData ? '${snap.data!.length}' : '...',
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.marketplaceStream,
              builder: (_, snap) => _buildStatRow(
                'מסירות',
                snap.hasData ? '${snap.data!.length}' : '...',
              ),
            ),
            const Divider(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.postsStream,
              builder: (_, postsSnap) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fs.eventsStream,
                  builder: (_, eventsSnap) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: fs.marketplaceStream,
                      builder: (_, marketSnap) {
                        int pending = 0;
                        if (postsSnap.hasData) {
                          pending += postsSnap.data!.where((p) => p['status'] == 'pending').length;
                        }
                        if (eventsSnap.hasData) {
                          pending += eventsSnap.data!.where((e) => e['status'] == 'pending').length;
                        }
                        if (marketSnap.hasData) {
                          pending += marketSnap.data!.where((m) => m['status'] == 'pending').length;
                        }
                        final hasData = postsSnap.hasData || eventsSnap.hasData || marketSnap.hasData;
                        return _buildStatRow(
                          'ממתין לאישור',
                          hasData ? '$pending' : '...',
                          valueColor: pending > 0 ? Colors.orange : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
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
                  color: valueColor ?? AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentModerationCard() {
    final fs = context.read<FirestoreService>();
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
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.reportsStream,
              builder: (_, snap) {
                final pending = snap.hasData
                    ? snap.data!.where((r) => r['status'] == 'pending').length
                    : 0;
                return _buildModerationItem(
                  'תוכן מדווח',
                  snap.hasData ? '$pending' : '...',
                  Colors.red,
                );
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.postsStream,
              builder: (_, postsSnap) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fs.eventsStream,
                  builder: (_, eventsSnap) {
                    int pending = 0;
                    if (postsSnap.hasData) {
                      pending += postsSnap.data!.where((p) => p['status'] == 'pending').length;
                    }
                    if (eventsSnap.hasData) {
                      pending += eventsSnap.data!.where((e) => e['status'] == 'pending').length;
                    }
                    final hasData = postsSnap.hasData || eventsSnap.hasData;
                    return _buildModerationItem(
                      'ממתין לאישור',
                      hasData ? '$pending' : '...',
                      Colors.orange,
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.postsStream,
              builder: (_, snap) {
                final rejected = snap.hasData
                    ? snap.data!.where((p) => p['status'] == 'rejected').length
                    : 0;
                return _buildModerationItem(
                  'נדחה לאחרונה',
                  snap.hasData ? '$rejected' : '...',
                  Colors.grey,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationItem(String label, String count, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 12),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(count),
            backgroundColor: color.withValues(alpha: 0.1),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          if (widget.onNavigateToTab != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ),
        ],
      ),
      onTap: () {
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!('approvals');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('עברי לטאב "אישורים" לביקורת תוכן', style: TextStyle(fontFamily: 'Heebo')),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
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
