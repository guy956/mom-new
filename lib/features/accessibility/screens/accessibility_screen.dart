import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/accessibility_service.dart';

/// MOMIT Accessibility Settings Screen
/// WCAG 2.2 AA compliant with comprehensive accessibility controls
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, a11y, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'נגישות',
            style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () {
                a11y.resetAll();
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הגדרות הנגישות אופסו', style: TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('איפוס', style: TextStyle(fontFamily: 'Heebo', color: AppColors.error)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Accessibility Statement Banner
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.accessibility_new_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOMIT מחויבת לנגישות',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'התאימי את האפליקציה לצרכים שלך. כל ההגדרות נשמרות אוטומטית.',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Text Size
            _buildSection(
              'גודל טקסט',
              Icons.format_size_rounded,
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('גודל נוכחי: ${(a11y.fontScale * 100).toInt()}%',
                              style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a11y.fontScale == 1.0 ? 'רגיל' : a11y.fontScale < 1.0 ? 'מוקטן' : 'מוגדל',
                              style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('א', style: TextStyle(fontFamily: 'Heebo', fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: a11y.fontScale,
                              min: 0.8,
                              max: 2.0,
                              divisions: 12,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.border,
                              onChanged: (v) => a11y.setFontScale(v),
                            ),
                          ),
                          const Text('א', style: TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'זוהי תצוגה מקדימה של גודל הטקסט הנבחר. כך ייראה הטקסט באפליקציה.',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 14,
                            fontWeight: a11y.boldText ? FontWeight.w600 : FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Display Settings
            _buildSection(
              'תצוגה',
              Icons.visibility_rounded,
              [
                _buildToggleTile(
                  'ניגודיות גבוהה',
                  'הגברת הניגודיות בין הטקסט לרקע',
                  Icons.contrast_rounded,
                  a11y.highContrast,
                  a11y.setHighContrast,
                ),
                _buildToggleTile(
                  'טקסט מודגש',
                  'הגברת עובי הטקסט לקריאות טובה יותר',
                  Icons.format_bold_rounded,
                  a11y.boldText,
                  a11y.setBoldText,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Motion Settings
            _buildSection(
              'תנועה ואנימציה',
              Icons.animation_rounded,
              [
                _buildToggleTile(
                  'צמצום תנועה',
                  'הפחתת אנימציות ומעברים',
                  Icons.motion_photos_off_rounded,
                  a11y.reduceMotion,
                  a11y.setReduceMotion,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Touch Settings
            _buildSection(
              'מגע ואינטראקציה',
              Icons.touch_app_rounded,
              [
                _buildToggleTile(
                  'כפתורים גדולים',
                  'הגדלת אזורי המגע לנוחות שימוש',
                  Icons.open_with_rounded,
                  a11y.largeTouch,
                  a11y.setLargeTouch,
                ),
                _buildToggleTile(
                  'מותאם לקורא מסך',
                  'מיטוב תיוגים ותיאורים לקורא מסך',
                  Icons.record_voice_over_rounded,
                  a11y.screenReaderOptimized,
                  a11y.setScreenReaderOptimized,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Color Blind Mode
            _buildSection(
              'עיוורון צבעים',
              Icons.palette_rounded,
              [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'התאמת צבעים למוגבלות ראייה:',
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildColorBlindChip('רגיל', 'none', a11y),
                          _buildColorBlindChip('פרוטנופיה', 'protanopia', a11y),
                          _buildColorBlindChip('דויטרנופיה', 'deuteranopia', a11y),
                          _buildColorBlindChip('טריטנופיה', 'tritanopia', a11y),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Accessibility Statement Link
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppColors.textSecondary, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'הצהרת נגישות',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MOMIT פועלת בהתאם לתקנות שוויון זכויות לאנשים עם מוגבלות (התאמות נגישות לשירות), התשע"ג-2013, '
                    'ועומדת בתקן הנגישות הבינלאומי WCAG 2.2 ברמה AA. '
                    'האפליקציה תומכת בקוראי מסך, ניווט מקלדת, גודל טקסט מתכוונן, '
                    'ניגודיות גבוהה והתאמות עיוורון צבעים. '
                    '\n\nלדיווח על בעיית נגישות: accessibility@momit.co.il',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: value ? AppColors.primary : AppColors.textSecondary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        },
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.border),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textHint),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildColorBlindChip(String label, String mode, AccessibilityService a11y) {
    final isSelected = a11y.colorBlindMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        a11y.setColorBlindMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
