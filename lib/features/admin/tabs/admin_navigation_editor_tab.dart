import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';

/// Navigation Editor Tab - Allows admins to customize app navigation structure
/// Persists changes to Firestore via DynamicConfigService
class AdminNavigationEditorTab extends StatefulWidget {
  const AdminNavigationEditorTab({super.key});

  @override
  State<AdminNavigationEditorTab> createState() => _AdminNavigationEditorTabState();
}

class _AdminNavigationEditorTabState extends State<AdminNavigationEditorTab> {
  static const _navLabels = <String, String>{
    'feed': 'בית / פיד',
    'tracking': 'מעקב',
    'events': 'אירועים',
    'chat': 'צ\'אט',
    'profile': 'פרופיל',
  };

  static const _navIcons = <String, IconData>{
    'feed': Icons.home_rounded,
    'tracking': Icons.track_changes_rounded,
    'events': Icons.event_rounded,
    'chat': Icons.chat_rounded,
    'profile': Icons.person_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('עורך ניווט', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'התאמה אישית של תפריטי הניווט באפליקציה',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildNavigationStructureCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationStructureCard() {
    return StreamBuilder<AppConfig>(
      stream: DynamicConfigService.instance.appConfigStream,
      builder: (context, snapshot) {
        final config = snapshot.data;
        final navItems = config?.navigationItems ?? NavigationItemDefaults.defaultItems;

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
                    Text('מבנה הניווט', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('הפעלה/כיבוי של פריטי ניווט. שינויים נשמרים אוטומטית.', style: TextStyle(fontFamily: 'Heebo')),
                const SizedBox(height: 16),
                ...navItems.map((item) => _buildNavigationItem(item)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final label = _navLabels[item.key] ?? item.labelHe;
    final icon = _navIcons[item.key] ?? Icons.circle;
    final isVisible = item.isVisible;

    return ListTile(
      leading: Icon(icon, color: isVisible ? AppColors.primary : AppColors.textHint),
      title: Text(label, style: TextStyle(
        fontFamily: 'Heebo',
        color: isVisible ? null : AppColors.textHint,
        decoration: isVisible ? null : TextDecoration.lineThrough,
      )),
      trailing: Switch(
        value: isVisible,
        activeColor: AppColors.primary,
        onChanged: (value) async {
          try {
            await DynamicConfigService.instance.toggleNavigationItemVisibility(item.key, value);
            if (!mounted) return;
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
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('שגיאה בעדכון: $e', style: const TextStyle(fontFamily: 'Heebo')),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}
