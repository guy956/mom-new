import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/app_router.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/notification_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// מסך SOS חירום - עזרה מיידית מהקהילה
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _sosActive = false;
  bool _isSubmitting = false;
  bool _submissionFailed = false;
  String? _lastFailedCategory;
  String? _lastFailedMessage;
  String? _activeAlertId;
  String _selectedCategoryLabel = '';

  final List<Map<String, dynamic>> _sosCategories = [
    {'icon': Icons.medical_services, 'label': 'חירום רפואי', 'color': AppColors.error, 'desc': 'מצב רפואי דחוף לתינוק/ילד'},
    {'icon': Icons.psychology, 'label': 'משבר רגשי', 'color': Color(0xFFD1C2D3), 'desc': 'מרגישה מוצפת ומחפשת אוזן קשבת'},
    {'icon': Icons.child_care, 'label': 'צריכה שמרטפית דחוף', 'color': AppColors.accent, 'desc': 'חייבת מישהי עכשיו לשמור על הילדים'},
    {'icon': Icons.directions_car, 'label': 'צריכה הסעה', 'color': AppColors.info, 'desc': 'צריכה להגיע דחוף למקום'},
    {'icon': Icons.shopping_basket, 'label': 'חסר לי משהו דחוף', 'color': AppColors.success, 'desc': 'חסרה לי חיתול/פורמולה/תרופה'},
    {'icon': Icons.help_outline, 'label': 'עזרה אחרת', 'color': AppColors.primary, 'desc': 'כל בקשה אחרת שדורשת עזרה מיידית'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosActive ? AppColors.error.withValues(alpha: 0.05) : Colors.white,
      appBar: AppBar(
        backgroundColor: _sosActive ? AppColors.error : Colors.white,
        foregroundColor: _sosActive ? Colors.white : AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'חזרה',
        ),
        title: Text(
          _sosActive ? 'SOS פעיל' : 'עזרה מהקהילה',
          style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_sosActive)
            TextButton(
              onPressed: _cancelSOS,
              child: const Text('בטלי', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
            ),
          IconButton(
            icon: Icon(Icons.home_outlined, color: _sosActive ? Colors.white70 : AppColors.textSecondary),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'מסך ראשי',
          ),
        ],
      ),
      body: _isSubmitting
          ? _buildSubmittingView()
          : _sosActive
              ? _buildActiveSOSView()
              : _buildSOSCategories(),
    );
  }

  Widget _buildSubmittingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'שולחת את בקשת העזרה...',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'אנא המתיני, זה ייקח רק רגע',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryBanner() {
    if (!_submissionFailed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'השליחה האחרונה נכשלה. בדקי את החיבור לאינטרנט ונסי שוב.',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'ניסיון חוזר לשליחת בקשת SOS',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _retrySOS,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('נסי שוב', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCategories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3 + _pulseController.value * 0.3),
                            blurRadius: 15 + _pulseController.value * 10,
                            spreadRadius: _pulseController.value * 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 40),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'צריכה עזרה? הקהילה כאן בשבילך!',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'אמהות מהקהילה זמינות לעזור',
                  style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Retry banner if last submission failed
          _buildRetryBanner(),

          // Categories
          const Text('במה צריכה עזרה?', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_sosCategories.map((cat) {
            return Semantics(
              label: 'בקשת עזרה: ${cat['label']} - ${cat['desc']}',
              button: true,
              hint: 'לחצי לשליחת בקשת עזרה',
              child: GestureDetector(
                onTap: () => _showSOSConfirmation(cat),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat['label'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(cat['desc'], style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            );
          })),
          const SizedBox(height: 24),

          // Emergency contacts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('קווי חירום', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildEmergencyContact('מד"א', '101', Icons.local_hospital),
                _buildEmergencyContact('ער"ן - עזרה ראשונה נפשית', '*2784', Icons.psychology),
                _buildEmergencyContact('נט"ל - קו חם לילדים', '*6581', Icons.child_care),
                _buildEmergencyContact('משטרה', '100', Icons.local_police),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14))),
          Semantics(
            label: 'חייגי ל$name: $number',
            button: true,
            hint: 'לחצי לחיוג לשירותי חירום',
            child: GestureDetector(
              onTap: () async {
                final success = await launchUrl(Uri.parse('tel:$number'));
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('לא ניתן לחייג ל-$number', style: const TextStyle(fontFamily: 'Heebo')),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(number, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSOSView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Active SOS status
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.1), blurRadius: 15)],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 15,
                            spreadRadius: _pulseController.value * 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 50),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'בקשת העזרה שלך נשלחה!',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'קטגוריה: $_selectedCategoryLabel',
                  style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'ממתינה לעזרה מהקהילה...',
                        style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Helpful info while waiting
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('בינתיים...', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'הבקשה שלך נרשמה במערכת ואמהות מהקהילה יוכלו לראות אותה. אם מדובר במצב רפואי דחוף, התקשרי גם למד"א 101.',
                  style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'פתיחת צ\'אט הקהילה לתיאום עזרה',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AppRouter.navigateTo(context, AppRouter.chat);
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('פתחי צ\'אט', style: TextStyle(fontFamily: 'Heebo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirmation(Map<String, dynamic> category) {
    HapticFeedback.heavyImpact();
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(category['icon'] as IconData, color: category['color'] as Color),
            const SizedBox(width: 10),
            Expanded(child: Text(category['label'], style: const TextStyle(fontFamily: 'Heebo'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Heebo'),
              decoration: InputDecoration(
                hintText: 'ספרי בקצרה מה קורה...',
                hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.security, size: 16, color: AppColors.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('הבקשה תשלח לקהילה ולמנהלת', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _activateSOS(
                category: category['label'] as String,
                message: messageController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('שלחי SOS', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _activateSOS({required String category, required String message}) async {
    HapticFeedback.heavyImpact();

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submissionFailed = false;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final user = appState.currentUser;

    try {
      final sosData = {
        'userId': user?.id ?? 'anonymous',
        'userName': user?.fullName ?? 'אנונימית',
        'category': category,
        'message': message,
        'creatorName': user?.fullName ?? 'אנונימית',
        'creatorEmail': user?.email ?? '',
        'creatorPhone': user?.phone ?? '',
      };
      final alertId = await fs.createSosAlert(sosData);

      // Send automatic urgent email notification to admin
      NotificationService().notifyAdminNewContent(
        type: 'report',
        content: {...sosData, 'id': alertId, 'title': 'SOS - $category'},
      );

      if (mounted) {
        setState(() {
          _sosActive = true;
          _isSubmitting = false;
          _submissionFailed = false;
          _selectedCategoryLabel = category;
          _activeAlertId = alertId;
          _lastFailedCategory = null;
          _lastFailedMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('בקשת העזרה נשלחה בהצלחה! הקהילה תקבל התראה.', style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('SOS submission error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionFailed = true;
          _lastFailedCategory = category;
          _lastFailedMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'לא הצלחנו לשלוח את בקשת העזרה. בדקי את החיבור לאינטרנט ונסי שוב.',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'נסי שוב',
              textColor: Colors.white,
              onPressed: () => _retrySOS(),
            ),
          ),
        );
      }
    }
  }

  void _retrySOS() {
    if (_lastFailedCategory != null) {
      _activateSOS(
        category: _lastFailedCategory!,
        message: _lastFailedMessage ?? '',
      );
    }
  }

  Future<void> _cancelSOS() async {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    if (_activeAlertId != null) {
      try {
        await fs.closeSosAlert(_activeAlertId!);
        if (mounted) {
          setState(() {
            _sosActive = false;
            _activeAlertId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('בקשת ה-SOS בוטלה', style: TextStyle(fontFamily: 'Heebo')),
              backgroundColor: AppColors.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('לא הצלחנו לבטל את הבקשה. נסי שוב מאוחר יותר.', style: TextStyle(fontFamily: 'Heebo')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      setState(() {
        _sosActive = false;
        _activeAlertId = null;
      });
    }
  }
}
