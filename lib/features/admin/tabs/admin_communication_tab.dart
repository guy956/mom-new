import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminCommunicationTab extends StatefulWidget {
  const AdminCommunicationTab({super.key});

  @override
  State<AdminCommunicationTab> createState() => _AdminCommunicationTabState();
}

class _AdminCommunicationTabState extends State<AdminCommunicationTab>
    with SingleTickerProviderStateMixin {
  late TabController _sectionTab;

  // Push notification fields
  final _pushTitleCtrl = TextEditingController();
  final _pushBodyCtrl = TextEditingController();
  String _pushTarget = 'all';
  bool _sending = false;

  // Announcement banner fields
  final _annTextCtrl = TextEditingController();
  final _annLinkCtrl = TextEditingController();
  String _annColor = '#D1C2D3';
  bool _annEnabled = false;
  bool _annInitialized = false;

  @override
  void initState() {
    super.initState();
    _sectionTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sectionTab.dispose();
    _pushTitleCtrl.dispose();
    _pushBodyCtrl.dispose();
    _annTextCtrl.dispose();
    _annLinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _sectionTab,
                labelColor: const Color(0xFF43363A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD1C2D3),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'הודעות Push'),
                  Tab(text: 'באנר הודעות'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _sectionTab,
                children: [
                  _buildPushSection(context.read<FirestoreService>()),
                  _buildAnnouncementSection(context.read<FirestoreService>()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PUSH NOTIFICATIONS SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildPushSection(FirestoreService fs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminWidgets.sectionTitle('שליחת הודעת Push', icon: Icons.notifications_active_rounded),
          const SizedBox(height: 4),
          Text('שלחו הודעה לכל המשתמשות או לקבוצה מסוימת', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),

          Container(
            decoration: AdminWidgets.cardDecor(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminWidgets.configField(label: 'כותרת ההודעה', controller: _pushTitleCtrl, icon: Icons.title),
                AdminWidgets.configField(label: 'תוכן ההודעה', controller: _pushBodyCtrl, icon: Icons.message, maxLines: 3),
                const SizedBox(height: 8),
                const Text('קהל יעד', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _targetChip('כל המשתמשות', 'all', Icons.people),
                    _targetChip('משתמשות חדשות', 'new', Icons.fiber_new),
                    _targetChip('משתמשות פעילות', 'active', Icons.trending_up),
                    _targetChip('מומחים', 'experts', Icons.school),
                  ],
                ),
                const SizedBox(height: 16),
                AdminWidgets.saveButton(
                  label: 'שלח הודעה',
                  loading: _sending,
                  onPressed: () => _sendPushNotification(fs),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          AdminWidgets.sectionTitle('היסטוריית הודעות', icon: Icons.history_rounded),
          const SizedBox(height: 8),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: fs.notificationsHistoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return AdminWidgets.emptyState('אין הודעות קודמות', icon: Icons.notifications_off_rounded);
              }

              return Column(
                children: notifications.map((n) {
                  final title = n['title'] ?? '';
                  final body = n['body'] ?? '';
                  final target = n['target'] ?? 'all';

                  String targetLabel;
                  switch (target) {
                    case 'new': targetLabel = 'חדשות'; break;
                    case 'active': targetLabel = 'פעילות'; break;
                    case 'experts': targetLabel = 'מומחים'; break;
                    default: targetLabel = 'כולם';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AdminWidgets.cardDecor(),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD1C2D3),
                        child: Icon(Icons.notifications, color: Colors.white, size: 20),
                      ),
                      title: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(body, style: const TextStyle(fontFamily: 'Heebo', fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          AdminWidgets.chip(targetLabel, const Color(0xFFD1C2D3).withValues(alpha: 0.2), const Color(0xFF43363A)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                        onPressed: () async {
                          final confirmed = await AdminWidgets.confirmDelete(context, 'ההודעה');
                          if (confirmed) await fs.deletePushNotification(n['id']);
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _targetChip(String label, String value, IconData icon) {
    final isSelected = _pushTarget == value;
    return FilterChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFFD1C2D3),
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() => _pushTarget = value),
    );
  }

  Future<void> _sendPushNotification(FirestoreService fs) async {
    final title = _pushTitleCtrl.text.trim();
    final body = _pushBodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      AdminWidgets.snack(context, 'נא למלא כותרת ותוכן', color: Colors.orange);
      return;
    }

    setState(() => _sending = true);
    try {
      await fs.savePushNotification({
        'title': title,
        'body': body,
        'target': _pushTarget,
        'status': 'sent',
        'sentBy': 'מנהלת',
      });

      await fs.logActivity(action: 'שליחת Push: $title', user: 'מנהלת', type: 'communication');

      _pushTitleCtrl.clear();
      _pushBodyCtrl.clear();
      setState(() => _pushTarget = 'all');

      if (mounted) AdminWidgets.snack(context, 'ההודעה נשלחה בהצלחה');
    } catch (e) {
      if (mounted) AdminWidgets.snack(context, 'שגיאה בשליחה: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  ANNOUNCEMENT BANNER SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildAnnouncementSection(FirestoreService fs) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fs.announcementStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_annInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && !_annInitialized) {
          final data = snapshot.data!;
          _annTextCtrl.text = data['text'] ?? '';
          _annLinkCtrl.text = data['link'] ?? '';
          _annColor = data['color'] ?? '#D1C2D3';
          _annEnabled = data['enabled'] ?? false;
          _annInitialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminWidgets.sectionTitle('באנר הודעות', icon: Icons.campaign_rounded),
              const SizedBox(height: 4),
              Text('הודעה שמוצגת לכל המשתמשות בראש האפליקציה', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),

              // Live preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminWidgets.parseColor(_annColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminWidgets.parseColor(_annColor).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(Icons.campaign, color: AdminWidgets.parseColor(_annColor)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _annTextCtrl.text.isNotEmpty ? _annTextCtrl.text : 'תצוגה מקדימה של ההודעה...',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: _annTextCtrl.text.isNotEmpty ? Colors.black87 : Colors.grey),
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              AdminWidgets.featureToggle(
                label: 'הצג באנר',
                description: 'הפעלה/כיבוי של הבאנר בכל האפליקציה',
                value: _annEnabled,
                icon: Icons.visibility,
                onChanged: (val) => setState(() => _annEnabled = val),
              ),
              const SizedBox(height: 12),
              AdminWidgets.configField(label: 'טקסט ההודעה', controller: _annTextCtrl, icon: Icons.text_fields, maxLines: 2),
              AdminWidgets.configField(label: 'קישור (אופציונלי)', controller: _annLinkCtrl, icon: Icons.link),
              const SizedBox(height: 4),
              Text('צבע הבאנר', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['#D1C2D3', '#D4A1AC', '#B5C8B9', '#DBC8B0', '#E8D5B7', '#C5CAE9', '#FFAB91', '#80CBC4'].map((hex) {
                  final isSelected = _annColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _annColor = hex),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AdminWidgets.parseColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.black87 : Colors.transparent, width: isSelected ? 3 : 0),
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              AdminWidgets.saveButton(
                label: 'שמור הודעה',
                onPressed: () async {
                  await fs.updateAnnouncement({
                    'enabled': _annEnabled,
                    'text': _annTextCtrl.text.trim(),
                    'link': _annLinkCtrl.text.trim(),
                    'color': _annColor,
                  });
                  await fs.logActivity(action: 'עדכון באנר הודעות', user: 'מנהלת', type: 'communication');
                  if (context.mounted) AdminWidgets.snack(context, 'הבאנר עודכן בהצלחה');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
