import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/app_state.dart';

/// WhatsApp Integration - חיבור קבוצת וואטסאפ רשמית
/// Uses real-time Firestore data from appConfig via AppState.
class WhatsAppIntegrationScreen extends StatelessWidget {
  const WhatsAppIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final config = appState.appConfig;
        final whatsappLink = (config['whatsappLink'] ?? '').toString();
        final groupName = (config['whatsappGroupName'] ?? '').toString();
        final memberCount = (config['whatsappMembers'] ?? '').toString();
        final description = (config['whatsappDescription'] ?? '').toString();
        final isLoaded = whatsappLink.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFFB5C8B9),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFFB5C8B9), size: 24),
                const SizedBox(width: 10),
                Text(
                  groupName.isNotEmpty ? groupName : 'קבוצת WhatsApp הרשמית',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white70),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                tooltip: 'מסך ראשי',
              ),
            ],
          ),
          body: !isLoaded
              ? _buildLoadingState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOfficialGroupBanner(
                        context: context,
                        groupName: groupName,
                        memberCount: memberCount,
                        whatsappLink: whatsappLink,
                      ),
                      const SizedBox(height: 16),
                      _buildGroupDetails(
                        context: context,
                        groupName: groupName,
                        memberCount: memberCount,
                        description: description,
                        whatsappLink: whatsappLink,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ── Loading / Empty state ──

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFB5C8B9).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB5C8B9),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'טוענת את פרטי הקבוצה...',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB5C8B9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'רק רגע, מתחברת לשרת',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner ──

  Widget _buildOfficialGroupBanner({
    required BuildContext context,
    required String groupName,
    required String memberCount,
    required String whatsappLink,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB5C8B9), Color(0xFFB5C8B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB5C8B9).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.favorite_rounded, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            groupName.isNotEmpty ? groupName : 'MOM Connect',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'הקבוצה הרשמית של MOMIT',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (memberCount.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$memberCount אמהות פעילות',
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsAppGroup(context, whatsappLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB5C8B9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text(
                'הצטרפי לקבוצה ב-WhatsApp',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Group details tile ──

  Widget _buildGroupDetails({
    required BuildContext context,
    required String groupName,
    required String memberCount,
    required String description,
    required String whatsappLink,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'על הקבוצה',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFB5C8B9).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5C8B9).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Icon(Icons.favorite_rounded,
                              size: 24, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  groupName.isNotEmpty
                                      ? groupName
                                      : 'MOM Connect - הקבוצה הרשמית',
                                  style: const TextStyle(
                                    fontFamily: 'Heebo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  size: 16, color: Color(0xFFB5C8B9)),
                            ],
                          ),
                          if (memberCount.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$memberCount חברות',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsAppGroup(context, whatsappLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5C8B9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text(
                      'פתחי ב-WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info section ──

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoCard(
            Icons.security,
            'קבוצה מפוקחת',
            'הקבוצה מנוהלת על ידי צוות MOMIT ושומרת על כללי התנהגות.',
            AppColors.success,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            Icons.people,
            'קהילה תומכת',
            'אלפי אמהות משתפות, עוזרות ותומכות אחת בשנייה.',
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            Icons.verified_user,
            'תוכן אמיתי בלבד',
            'ללא ספאם, ללא פרסום - רק תוכן אמיתי מאמהות אמיתיות.',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── URL launcher ──

  Future<void> _openWhatsAppGroup(
      BuildContext context, String whatsappLink) async {
    if (whatsappLink.isEmpty) return;
    final uri = Uri.parse(whatsappLink);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final browserLaunched =
            await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!browserLaunched) {
          _showOpenFailedDialog(context, whatsappLink);
        }
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        _showOpenFailedDialog(context, whatsappLink);
      }
    }
  }

  void _showOpenFailedDialog(BuildContext context, String whatsappLink) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('פתיחת WhatsApp',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'לא הצלחנו לפתוח את WhatsApp ישירות.\nהקישור הועתק - הדביקי בדפדפן:',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Heebo')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10)),
              child: SelectableText(whatsappLink,
                  style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: AppColors.primary)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: whatsappLink));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('הקישור הועתק!',
                      style: TextStyle(fontFamily: 'Heebo')),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('העתק קישור',
                style: TextStyle(
                    fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo')),
          ),
        ],
      ),
    );
  }
}
