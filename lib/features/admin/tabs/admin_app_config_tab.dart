import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminAppConfigTab extends StatefulWidget {
  const AdminAppConfigTab({super.key});

  @override
  State<AdminAppConfigTab> createState() => _AdminAppConfigTabState();
}

class _AdminAppConfigTabState extends State<AdminAppConfigTab> {
  // General Info
  final _appNameCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Social Links
  final _whatsappLinkCtrl = TextEditingController();
  final _whatsappGroupCtrl = TextEditingController();
  final _whatsappMembersCtrl = TextEditingController();
  final _whatsappDescCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  // Contact
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Legal
  final _termsUrlCtrl = TextEditingController();
  final _privacyUrlCtrl = TextEditingController();

  // Welcome Screen
  final _welcomeTitleCtrl = TextEditingController();
  final _welcomeSubtitleCtrl = TextEditingController();
  final _welcomeDescCtrl = TextEditingController();

  bool _loading = false;
  bool _initialized = false;

  void _initControllers(Map<String, dynamic> data) {
    if (_initialized) return;

    _appNameCtrl.text = data['appName'] ?? '';
    _sloganCtrl.text = data['slogan'] ?? '';
    _descriptionCtrl.text = data['description'] ?? '';

    _whatsappLinkCtrl.text = data['whatsappLink'] ?? '';
    _whatsappGroupCtrl.text = data['whatsappGroupName'] ?? '';
    _whatsappMembersCtrl.text = data['whatsappMembers'] ?? '';
    _whatsappDescCtrl.text = data['whatsappDescription'] ?? '';
    _instagramCtrl.text = data['instagram'] ?? '';
    _facebookCtrl.text = data['facebook'] ?? '';
    _websiteCtrl.text = data['website'] ?? '';

    _emailCtrl.text = data['contactEmail'] ?? '';
    _phoneCtrl.text = data['contactPhone'] ?? '';

    _termsUrlCtrl.text = data['termsUrl'] ?? '';
    _privacyUrlCtrl.text = data['privacyUrl'] ?? '';

    _welcomeTitleCtrl.text = data['welcomeTitle'] ?? '';
    _welcomeSubtitleCtrl.text = data['welcomeSubtitle'] ?? '';
    _welcomeDescCtrl.text = data['welcomeDescription'] ?? '';

    _initialized = true;
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _sloganCtrl.dispose();
    _descriptionCtrl.dispose();
    _whatsappLinkCtrl.dispose();
    _whatsappGroupCtrl.dispose();
    _whatsappMembersCtrl.dispose();
    _whatsappDescCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _termsUrlCtrl.dispose();
    _privacyUrlCtrl.dispose();
    _welcomeTitleCtrl.dispose();
    _welcomeSubtitleCtrl.dispose();
    _welcomeDescCtrl.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return true;
    return Uri.tryParse(url)?.hasScheme ?? false;
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  String? _validateFields() {
    if (!_isValidEmail(_emailCtrl.text.trim())) return 'כתובת אימייל לא תקינה';
    final urlFields = [_whatsappLinkCtrl, _instagramCtrl, _facebookCtrl, _websiteCtrl, _termsUrlCtrl, _privacyUrlCtrl];
    for (final ctrl in urlFields) {
      if (!_isValidUrl(ctrl.text.trim())) return 'קישור לא תקין: ${ctrl.text}';
    }
    return null;
  }

  void _resetToDefaults() {
    final defaults = FirestoreService.defaultAppConfig;
    setState(() {
      _appNameCtrl.text = defaults['appName'] ?? '';
      _sloganCtrl.text = defaults['slogan'] ?? '';
      _descriptionCtrl.text = defaults['description'] ?? '';
      _whatsappLinkCtrl.text = defaults['whatsappLink'] ?? '';
      _whatsappGroupCtrl.text = defaults['whatsappGroupName'] ?? '';
      _whatsappMembersCtrl.text = defaults['whatsappMembers'] ?? '';
      _whatsappDescCtrl.text = defaults['whatsappDescription'] ?? '';
      _instagramCtrl.text = defaults['instagram'] ?? '';
      _facebookCtrl.text = defaults['facebook'] ?? '';
      _websiteCtrl.text = defaults['website'] ?? '';
      _emailCtrl.text = defaults['contactEmail'] ?? '';
      _phoneCtrl.text = defaults['contactPhone'] ?? '';
      _termsUrlCtrl.text = defaults['termsUrl'] ?? '';
      _privacyUrlCtrl.text = defaults['privacyUrl'] ?? '';
      _welcomeTitleCtrl.text = defaults['welcomeTitle'] ?? '';
      _welcomeSubtitleCtrl.text = defaults['welcomeSubtitle'] ?? '';
      _welcomeDescCtrl.text = defaults['welcomeDescription'] ?? '';
    });
    AdminWidgets.snack(context, 'הוחזרו ערכי ברירת מחדל');
  }

  Future<void> _saveConfig(FirestoreService fs) async {
    final error = _validateFields();
    if (error != null) {
      AdminWidgets.snack(context, error, color: Colors.red.shade400);
      return;
    }

    setState(() => _loading = true);

    try {
      final configMap = {
        'appName': _appNameCtrl.text,
        'slogan': _sloganCtrl.text,
        'description': _descriptionCtrl.text,
        'whatsappLink': _whatsappLinkCtrl.text,
        'whatsappGroupName': _whatsappGroupCtrl.text,
        'whatsappMembers': _whatsappMembersCtrl.text,
        'whatsappDescription': _whatsappDescCtrl.text,
        'instagram': _instagramCtrl.text,
        'facebook': _facebookCtrl.text,
        'website': _websiteCtrl.text,
        'contactEmail': _emailCtrl.text,
        'contactPhone': _phoneCtrl.text,
        'termsUrl': _termsUrlCtrl.text,
        'privacyUrl': _privacyUrlCtrl.text,
        'welcomeTitle': _welcomeTitleCtrl.text,
        'welcomeSubtitle': _welcomeSubtitleCtrl.text,
        'welcomeDescription': _welcomeDescCtrl.text,
      };

      await fs.updateAppConfig(configMap);
      await fs.logActivity(
        action: 'עדכון הגדרות אפליקציה',
        user: 'מנהלת',
        type: 'config',
      );

      if (mounted) {
        AdminWidgets.snack(context, 'ההגדרות נשמרו בהצלחה!');
      }
    } catch (e) {
      if (mounted) {
        AdminWidgets.snack(context, 'שגיאה בשמירה: $e', color: Colors.red.shade400);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: fs.appConfigStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_initialized) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              _initControllers(snapshot.data!);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section: מידע כללי
                  AdminWidgets.sectionTitle('מידע כללי', icon: Icons.info_outline),
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AdminWidgets.configField(
                          controller: _appNameCtrl,
                          label: 'שם האפליקציה',
                          icon: Icons.apps_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _sloganCtrl,
                          label: 'סלוגן',
                          icon: Icons.format_quote_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _descriptionCtrl,
                          label: 'תיאור',
                          icon: Icons.description_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: רשתות חברתיות
                  AdminWidgets.sectionTitle('רשתות חברתיות', icon: Icons.share_rounded),
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AdminWidgets.configField(
                          controller: _whatsappLinkCtrl,
                          label: 'קישור WhatsApp',
                          icon: Icons.chat_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _whatsappGroupCtrl,
                          label: 'שם קבוצת WhatsApp',
                          icon: Icons.group_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _whatsappMembersCtrl,
                          label: 'מספר חברות בקבוצה',
                          icon: Icons.people_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        AdminWidgets.configField(
                          controller: _whatsappDescCtrl,
                          label: 'תיאור קבוצת WhatsApp',
                          icon: Icons.info_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _instagramCtrl,
                          label: 'אינסטגרם',
                          icon: Icons.camera_alt_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _facebookCtrl,
                          label: 'פייסבוק',
                          icon: Icons.facebook_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _websiteCtrl,
                          label: 'אתר אינטרנט',
                          icon: Icons.language_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: יצירת קשר
                  AdminWidgets.sectionTitle('יצירת קשר', icon: Icons.contact_mail_rounded),
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AdminWidgets.configField(
                          controller: _emailCtrl,
                          label: 'אימייל ליצירת קשר',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        AdminWidgets.configField(
                          controller: _phoneCtrl,
                          label: 'טלפון ליצירת קשר',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: משפטי
                  AdminWidgets.sectionTitle('משפטי', icon: Icons.gavel_rounded),
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AdminWidgets.configField(
                          controller: _termsUrlCtrl,
                          label: 'קישור תנאי שימוש',
                          icon: Icons.article_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _privacyUrlCtrl,
                          label: 'קישור מדיניות פרטיות',
                          icon: Icons.privacy_tip_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: מסך פתיחה
                  AdminWidgets.sectionTitle('מסך פתיחה', icon: Icons.launch_rounded),
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AdminWidgets.configField(
                          controller: _welcomeTitleCtrl,
                          label: 'כותרת מסך פתיחה',
                          icon: Icons.title_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _welcomeSubtitleCtrl,
                          label: 'כותרת משנה',
                          icon: Icons.subtitles_rounded,
                        ),
                        AdminWidgets.configField(
                          controller: _welcomeDescCtrl,
                          label: 'תיאור מסך פתיחה',
                          icon: Icons.text_snippet_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reset + Save Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await AdminWidgets.confirmAction(
                              context,
                              title: 'איפוס',
                              message: 'להחזיר את כל ההגדרות לברירת מחדל?',
                              confirmLabel: 'אפס',
                              confirmColor: Colors.orange,
                            );
                            if (confirmed) _resetToDefaults();
                          },
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text('ברירת מחדל', style: TextStyle(fontFamily: 'Heebo')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AdminWidgets.saveButton(
                          loading: _loading,
                          onPressed: () => _saveConfig(fs),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
