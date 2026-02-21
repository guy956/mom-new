import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/audit_log_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminAuditLogTab extends StatefulWidget {
  const AdminAuditLogTab({super.key});

  @override
  State<AdminAuditLogTab> createState() => _AdminAuditLogTabState();
}

class _AdminAuditLogTabState extends State<AdminAuditLogTab> {
  String _typeFilter = 'הכל';
  String _actionFilter = 'הכל';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const _typeFilters = ['הכל', 'משתמש', 'מומחה', 'אירוע', 'תוכן', 'הגדרות', 'מדיה', 'דיווח', 'תקשורת', 'הודעה'];
  static const _typeMap = {
    'משתמש': 'user',
    'מומחה': 'expert',
    'אירוע': 'event',
    'תוכן': 'post',
    'הגדרות': 'config',
    'מדיה': 'media',
    'דיווח': 'report',
    'תקשורת': 'communication',
    'הודעה': 'announcement',
  };

  static const _actionFilters = ['הכל', 'יצירה', 'עדכון', 'מחיקה', 'צפייה', 'אישור', 'דחייה', 'חסימה', 'התחברות'];
  static const _actionMap = {
    'יצירה': 'create',
    'עדכון': 'update',
    'מחיקה': 'delete',
    'צפייה': 'view',
    'אישור': 'approve',
    'דחייה': 'reject',
    'חסימה': 'block',
    'התחברות': 'login',
  };

  final AuditLogService _auditLogService = AuditLogService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'user': return Icons.person_rounded;
      case 'expert': return Icons.school_rounded;
      case 'event': return Icons.event_rounded;
      case 'post': return Icons.article_rounded;
      case 'tip': return Icons.lightbulb_rounded;
      case 'config': return Icons.settings_rounded;
      case 'media': return Icons.cloud_upload_rounded;
      case 'report': return Icons.flag_rounded;
      case 'communication': return Icons.campaign_rounded;
      case 'announcement': return Icons.announcement_rounded;
      case 'marketplace': return Icons.store_rounded;
      default: return Icons.history_rounded;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'user': return const Color(0xFFD1C2D3);
      case 'expert': return const Color(0xFFDBC8B0);
      case 'event': return const Color(0xFFB5C8B9);
      case 'post': return const Color(0xFF7986CB);
      case 'tip': return const Color(0xFF90CAF9);
      case 'config': return const Color(0xFFE8D5B7);
      case 'media': return const Color(0xFF64B5F6);
      case 'report': return const Color(0xFFD4A3A3);
      case 'communication': return const Color(0xFFFF8A65);
      case 'announcement': return const Color(0xFFCE93D8);
      case 'marketplace': return const Color(0xFF81C784);
      default: return Colors.grey;
    }
  }

  Color _actionColor(String? action) {
    switch (action) {
      case 'create': return Colors.green;
      case 'update': return Colors.blue;
      case 'delete': return Colors.red;
      case 'view': return Colors.grey;
      case 'approve': return Colors.green.shade700;
      case 'reject': return Colors.orange;
      case 'block': return Colors.red.shade700;
      case 'unblock': return Colors.teal;
      case 'login': return Colors.purple;
      case 'logout': return Colors.purple.shade300;
      case 'config_change': return Colors.amber;
      case 'export': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  String _actionLabel(String? action) {
    switch (action) {
      case 'create': return 'יצירה';
      case 'update': return 'עדכון';
      case 'delete': return 'מחיקה';
      case 'view': return 'צפייה';
      case 'approve': return 'אישור';
      case 'reject': return 'דחייה';
      case 'block': return 'חסימה';
      case 'unblock': return 'ביטול חסימה';
      case 'login': return 'התחברות';
      case 'logout': return 'התנתקות';
      case 'config_change': return 'שינוי הגדרות';
      case 'export': return 'ייצוא';
      default: return action ?? 'אחר';
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    final dateStr = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק\'';
    if (diff.inHours < 24) return 'היום $timeStr';
    if (diff.inDays < 2) return 'אתמול $timeStr';
    return '$dateStr $timeStr';
  }

  void _showLogDetails(AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(_typeIcon(log.entityType.value), color: _typeColor(log.entityType.value)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'פרטי פעולה',
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('סוג פעולה', _actionLabel(log.actionType.value)),
                _buildDetailRow('סוג ישות', log.entityType.hebrewLabel),
                _buildDetailRow('שם ישות', log.entityName),
                _buildDetailRow('מזהה ישות', log.entityId),
                _buildDetailRow('תיאור', log.description),
                _buildDetailRow('מנהל', '${log.adminName} (${log.adminEmail})'),
                _buildDetailRow('זמן', _formatTimestamp(log.timestamp)),
                if (log.beforeData != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'נתונים לפני:',
                    style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatData(log.beforeData!),
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 12),
                    ),
                  ),
                ],
                if (log.afterData != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'נתונים אחרי:',
                    style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatData(log.afterData!),
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 12),
                    ),
                  ),
                ],
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'מטא-דאטה:',
                    style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatData(log.metadata!),
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Heebo'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  Future<void> _exportLogs() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('מייצא לוגים...', style: TextStyle(fontFamily: 'Heebo')),
            ],
          ),
        ),
      ),
    );

    try {
      final json = await _auditLogService.exportToJson();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הייצוא הושלם בהצלחה', style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא: $e', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF9F5F4),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF43363A), size: 24),
                  const SizedBox(width: 8),
                  const Text('יומן ביקורת - Audit Log', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Export button
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'ייצוא לוגים',
                    onPressed: _exportLogs,
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<List<AuditLogEntry>>(
                    stream: _auditLogService.getAuditLogStream(limit: 1000),
                    builder: (_, snap) {
                      final count = snap.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD1C2D3).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                        child: Text('$count רשומות', style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Heebo'),
                decoration: InputDecoration(
                  hintText: 'חיפוש בפעולות...',
                  hintStyle: const TextStyle(fontFamily: 'Heebo'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Entity type filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _typeFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _typeFilters.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13)),
                      )).toList(),
                      onChanged: (value) => setState(() => _typeFilter = value ?? 'הכל'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action type filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _actionFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _actionFilters.map((action) => DropdownMenuItem(
                        value: action,
                        child: Text(action, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13)),
                      )).toList(),
                      onChanged: (value) => setState(() => _actionFilter = value ?? 'הכל'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Audit log list
            Expanded(
              child: StreamBuilder<List<AuditLogEntry>>(
                stream: _auditLogService.getAuditLogStream(limit: 500),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('שגיאה בטעינת הלוגים: ${snapshot.error}', 
                            style: TextStyle(fontFamily: 'Heebo', color: Colors.red.shade700)),
                        ],
                      ),
                    );
                  }

                  final allLogs = snapshot.data ?? [];
                  final filtered = allLogs.where((log) {
                    // Type filter
                    if (_typeFilter != 'הכל' && log.entityType.value != _typeMap[_typeFilter]) return false;
                    // Action filter
                    if (_actionFilter != 'הכל' && log.actionType.value != _actionMap[_actionFilter]) return false;
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      final description = log.description.toLowerCase();
                      final adminName = log.adminName.toLowerCase();
                      final adminEmail = log.adminEmail.toLowerCase();
                      final entityName = log.entityName.toLowerCase();
                      if (!description.contains(query) && 
                          !adminName.contains(query) && 
                          !adminEmail.contains(query) &&
                          !entityName.contains(query)) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return AdminWidgets.emptyState('אין רשומות פעילות', icon: Icons.history_rounded);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildLogEntry(filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(AuditLogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: _typeColor(log.entityType.value), width: 3)),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _typeColor(log.entityType.value).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon(log.entityType.value), color: _typeColor(log.entityType.value), size: 18),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  log.description,
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _actionColor(log.actionType.value).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _actionLabel(log.actionType.value),
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 10,
                    color: _actionColor(log.actionType.value),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(log.adminName, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Icon(Icons.label_outline, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(log.entityType.hebrewLabel, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade500)),
              if (log.beforeData != null || log.afterData != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.edit_note, size: 12, color: Colors.blue.shade400),
              ],
            ],
          ),
          trailing: Text(
            _formatTimestamp(log.timestamp),
            style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}
