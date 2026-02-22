import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _statusFilter = 'הכל';
  String _severityFilter = 'הכל';

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'post':
        return Icons.article;
      case 'user':
        return Icons.person;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.flag;
    }
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'low':
        return const Color(0xFFB5C8B9);
      case 'medium':
        return const Color(0xFFDBC8B0);
      case 'high':
        return const Color(0xFFD4A3A3);
      case 'critical':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  String _severityLabel(String? severity) {
    switch (severity) {
      case 'low':
        return 'נמוך';
      case 'medium':
        return 'בינוני';
      case 'high':
        return 'גבוה';
      case 'critical':
        return 'קריטי';
      default:
        return severity ?? 'לא ידוע';
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'post':
        return 'פוסט';
      case 'user':
        return 'משתמש';
      case 'comment':
        return 'תגובה';
      default:
        return type ?? 'אחר';
    }
  }

  List<Map<String, dynamic>> _filterReports(List<Map<String, dynamic>> reports) {
    return reports.where((r) {
      if (_statusFilter != 'הכל') {
        final statusValue = _statusFilter == 'ממתין' ? 'pending' : 'closed';
        if (r['status'] != statusValue) return false;
      }
      if (_severityFilter != 'הכל') {
        final severityMap = {'נמוך': 'low', 'בינוני': 'medium', 'גבוה': 'high', 'קריטי': 'critical'};
        if (r['severity'] != severityMap[_severityFilter]) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _confirmDelete(BuildContext context, FirestoreService fs, String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'מחיקת דיווח',
            style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'האם למחוק את הדיווח? פעולה זו אינה ניתנת לביטול.',
            style: TextStyle(fontFamily: 'Heebo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'מחק',
                style: TextStyle(fontFamily: 'Heebo', color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await fs.deleteReport(reportId);
      await fs.logActivity(action: 'דיווח נמחק: $reportId', user: 'מנהלת', type: 'report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: fs.reportsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'שגיאה בטעינת דיווחים',
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 16),
                ),
              );
            }

            final allReports = snapshot.data ?? [];
            final pendingCount = allReports.where((r) => r['status'] == 'pending').length;
            final closedCount = allReports.where((r) => r['status'] == 'closed').length;
            final filteredReports = _filterReports(allReports);

            return Column(
              children: [
                // Stats row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard('סה"כ דיווחים', allReports.length, Colors.blueGrey),
                      const SizedBox(width: 12),
                      _buildStatCard('ממתינים', pendingCount, Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatCard('סגורים', closedCount, Colors.green),
                    ],
                  ),
                ),

                // Status filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildFilterChip('הכל'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ממתין'),
                      const SizedBox(width: 8),
                      _buildFilterChip('סגור'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Severity filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['הכל', 'נמוך', 'בינוני', 'גבוה', 'קריטי'].map((label) {
                      final isSelected = _severityFilter == label;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD4A3A3),
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          onSelected: (_) => setState(() => _severityFilter = label),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Reports list
                Expanded(
                  child: filteredReports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'אין דיווחים להצגה',
                                style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _statusFilter == 'הכל'
                                    ? 'לא נמצאו דיווחים במערכת'
                                    : 'לא נמצאו דיווחים בסטטוס "$_statusFilter"',
                                style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(context, fs, report);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _statusFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFD4A3A3),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFD4A3A3) : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _statusFilter = label;
        });
      },
    );
  }

  Widget _buildReportCard(BuildContext context, FirestoreService fs, Map<String, dynamic> report) {
    final id = report['id'] as String? ?? '';
    final type = report['type'] as String?;
    final content = report['content'] as String? ?? '';
    final reporter = report['reporter'] as String? ?? 'לא ידוע';
    final reported = report['reported'] as String? ?? 'לא ידוע';
    final reason = report['reason'] as String? ?? '';
    final severity = report['severity'] as String?;
    final status = report['status'] as String? ?? 'pending';
    final reportedUserId = report['reportedUserId'] as String?;
    final reportedPostId = report['reportedPostId'] as String? ?? report['postId'] as String?;
    final reporterEmail = report['reporterEmail'] as String?;
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPending
            ? const Border(
                right: BorderSide(color: Colors.orange, width: 4),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type badge + severity + status
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(type), size: 16, color: Colors.blueGrey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        _typeLabel(type),
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Severity chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor(severity).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _severityLabel(severity),
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: severity == 'critical'
                          ? const Color(0xFFC62828)
                          : _severityColor(severity).withValues(alpha: 1),
                    ),
                  ),
                ),

                const Spacer(),

                // Status chip
                AdminWidgets.statusChip(status),
              ],
            ),

            const SizedBox(height: 12),

            // Content preview
            if (content.isNotEmpty) ...[
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Details
            _buildDetailRow(Icons.person_outline, 'מדווח/ת', reporter),
            const SizedBox(height: 6),
            _buildDetailRow(Icons.person, 'מדווח עליו/ה', reported),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildDetailRow(Icons.info_outline, 'סיבה', reason),
            ],

            // Admin note
            if ((report['adminNote'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      'הערת מנהלת: ${report['adminNote']}',
                      style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.blue.shade800),
                    )),
                  ],
                ),
              ),
            ],

            // Actions
            if (isPending) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Close report with admin note
                  _buildActionButton(
                    label: 'סגור דיווח',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onPressed: () => _closeReportWithNote(context, fs, id),
                  ),

                  // Delete report
                  _buildActionButton(
                    label: 'מחק',
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onPressed: () => _confirmDelete(context, fs, id),
                  ),

                  // Remove reported content (post)
                  if (type == 'post' && reportedPostId != null && reportedPostId.isNotEmpty)
                    _buildActionButton(
                      label: 'מחק תוכן',
                      icon: Icons.delete_sweep,
                      color: Colors.deepOrange,
                      onPressed: () async {
                        final confirmed = await AdminWidgets.confirmDelete(context, 'התוכן המדווח');
                        if (confirmed) {
                          await fs.deletePost(reportedPostId);
                          await fs.updateReportStatus(id, 'closed');
                          await fs.logActivity(
                            action: 'מחיקת פוסט מדווח $reportedPostId וסגירת דיווח $id',
                            user: 'מנהלת',
                            type: 'report',
                          );
                        }
                      },
                    ),

                  // Ban user (if reportedUserId exists)
                  if (reportedUserId != null && reportedUserId.isNotEmpty)
                    _buildActionButton(
                      label: 'חסום משתמש',
                      icon: Icons.block,
                      color: const Color(0xFFC62828),
                      onPressed: () async {
                        await fs.updateUserStatus(reportedUserId, 'banned');
                        await fs.updateReportStatus(id, 'closed');
                        await fs.logActivity(
                          action: 'חסימת משתמש $reportedUserId בעקבות דיווח $id',
                          user: 'מנהלת',
                          type: 'report',
                        );
                      },
                    ),

                  // Send email about report
                  _buildActionButton(
                    label: 'שלח מייל',
                    icon: Icons.email_outlined,
                    color: Colors.blueGrey,
                    onPressed: () async {
                      final email = reporterEmail ?? 'support@momit.co.il';
                      final subject = Uri.encodeComponent('בנוגע לדיווח #$id - MOMIT');
                      final body = Uri.encodeComponent('שלום,\n\nבנוגע לדיווח שהגשת על ${_typeLabel(type)}:\n"$content"\n\n');
                      final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _closeReportWithNote(BuildContext context, FirestoreService fs, String reportId) async {
    final noteCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('סגירת דיווח', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('הוסיפי הערה (אופציונלי):', style: TextStyle(fontFamily: 'Heebo', fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Heebo'),
                decoration: const InputDecoration(
                  hintText: 'הערת מנהלת...',
                  hintStyle: TextStyle(fontFamily: 'Heebo'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('סגור דיווח', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final note = noteCtrl.text.trim();
      if (note.isNotEmpty) {
        await fs.addReportNote(reportId, note);
      }
      await fs.updateReportStatus(reportId, 'closed');
      await fs.logActivity(action: 'דיווח נסגר: $reportId', user: 'מנהלת', type: 'report');
      if (context.mounted) AdminWidgets.snack(context, 'הדיווח נסגר');
    }
    noteCtrl.dispose();
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
