import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mom_connect/services/auth_service.dart';

// Forward declaration - SecureTokenStorage is defined in auth_service.dart

/// Enum representing different types of admin actions
enum AuditActionType {
  create,
  update,
  delete,
  view,
  approve,
  reject,
  block,
  unblock,
  login,
  logout,
  configChange,
  export,
  other,
}

/// Extension to convert enum to string
extension AuditActionTypeExtension on AuditActionType {
  String get value {
    switch (this) {
      case AuditActionType.create:
        return 'create';
      case AuditActionType.update:
        return 'update';
      case AuditActionType.delete:
        return 'delete';
      case AuditActionType.view:
        return 'view';
      case AuditActionType.approve:
        return 'approve';
      case AuditActionType.reject:
        return 'reject';
      case AuditActionType.block:
        return 'block';
      case AuditActionType.unblock:
        return 'unblock';
      case AuditActionType.login:
        return 'login';
      case AuditActionType.logout:
        return 'logout';
      case AuditActionType.configChange:
        return 'config_change';
      case AuditActionType.export:
        return 'export';
      case AuditActionType.other:
        return 'other';
    }
  }

  String get hebrewLabel {
    switch (this) {
      case AuditActionType.create:
        return 'יצירה';
      case AuditActionType.update:
        return 'עדכון';
      case AuditActionType.delete:
        return 'מחיקה';
      case AuditActionType.view:
        return 'צפייה';
      case AuditActionType.approve:
        return 'אישור';
      case AuditActionType.reject:
        return 'דחייה';
      case AuditActionType.block:
        return 'חסימה';
      case AuditActionType.unblock:
        return 'ביטול חסימה';
      case AuditActionType.login:
        return 'התחברות';
      case AuditActionType.logout:
        return 'התנתקות';
      case AuditActionType.configChange:
        return 'שינוי הגדרות';
      case AuditActionType.export:
        return 'ייצוא';
      case AuditActionType.other:
        return 'אחר';
    }
  }
}

/// Enum representing different entity types that can be audited
enum AuditEntityType {
  user,
  expert,
  event,
  post,
  tip,
  marketplace,
  config,
  media,
  report,
  communication,
  announcement,
  other,
}

/// Extension to convert enum to string
extension AuditEntityTypeExtension on AuditEntityType {
  String get value {
    switch (this) {
      case AuditEntityType.user:
        return 'user';
      case AuditEntityType.expert:
        return 'expert';
      case AuditEntityType.event:
        return 'event';
      case AuditEntityType.post:
        return 'post';
      case AuditEntityType.tip:
        return 'tip';
      case AuditEntityType.marketplace:
        return 'marketplace';
      case AuditEntityType.config:
        return 'config';
      case AuditEntityType.media:
        return 'media';
      case AuditEntityType.report:
        return 'report';
      case AuditEntityType.communication:
        return 'communication';
      case AuditEntityType.announcement:
        return 'announcement';
      case AuditEntityType.other:
        return 'other';
    }
  }

  String get hebrewLabel {
    switch (this) {
      case AuditEntityType.user:
        return 'משתמש';
      case AuditEntityType.expert:
        return 'מומחה';
      case AuditEntityType.event:
        return 'אירוע';
      case AuditEntityType.post:
        return 'פוסט';
      case AuditEntityType.tip:
        return 'טיפ';
      case AuditEntityType.marketplace:
        return 'מוצר';
      case AuditEntityType.config:
        return 'הגדרות';
      case AuditEntityType.media:
        return 'מדיה';
      case AuditEntityType.report:
        return 'דיווח';
      case AuditEntityType.communication:
        return 'תקשורת';
      case AuditEntityType.announcement:
        return 'הודעה';
      case AuditEntityType.other:
        return 'אחר';
    }
  }
}

/// Model representing a single audit log entry
class AuditLogEntry {
  final String id;
  final String adminId;
  final String adminEmail;
  final String adminName;
  final AuditActionType actionType;
  final AuditEntityType entityType;
  final String entityId;
  final String entityName;
  final String description;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;

  AuditLogEntry({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.adminName,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.description,
    this.beforeData,
    this.afterData,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.metadata,
  });

  factory AuditLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntry(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      adminName: data['adminName'] ?? '',
      actionType: _parseActionType(data['actionType']),
      entityType: _parseEntityType(data['entityType']),
      entityId: data['entityId'] ?? '',
      entityName: data['entityName'] ?? '',
      description: data['description'] ?? '',
      beforeData: data['beforeData'] as Map<String, dynamic>?,
      afterData: data['afterData'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'actionType': actionType.value,
      'entityType': entityType.value,
      'entityId': entityId,
      'entityName': entityName,
      'description': description,
      'beforeData': beforeData,
      'afterData': afterData,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  static AuditActionType _parseActionType(String? value) {
    switch (value) {
      case 'create':
        return AuditActionType.create;
      case 'update':
        return AuditActionType.update;
      case 'delete':
        return AuditActionType.delete;
      case 'view':
        return AuditActionType.view;
      case 'approve':
        return AuditActionType.approve;
      case 'reject':
        return AuditActionType.reject;
      case 'block':
        return AuditActionType.block;
      case 'unblock':
        return AuditActionType.unblock;
      case 'login':
        return AuditActionType.login;
      case 'logout':
        return AuditActionType.logout;
      case 'config_change':
        return AuditActionType.configChange;
      case 'export':
        return AuditActionType.export;
      default:
        return AuditActionType.other;
    }
  }

  static AuditEntityType _parseEntityType(String? value) {
    switch (value) {
      case 'user':
        return AuditEntityType.user;
      case 'expert':
        return AuditEntityType.expert;
      case 'event':
        return AuditEntityType.event;
      case 'post':
        return AuditEntityType.post;
      case 'tip':
        return AuditEntityType.tip;
      case 'marketplace':
        return AuditEntityType.marketplace;
      case 'config':
        return AuditEntityType.config;
      case 'media':
        return AuditEntityType.media;
      case 'report':
        return AuditEntityType.report;
      case 'communication':
        return AuditEntityType.communication;
      case 'announcement':
        return AuditEntityType.announcement;
      default:
        return AuditEntityType.other;
    }
  }

  /// Get a human-readable summary of the change
  String get changeSummary {
    if (beforeData == null && afterData == null) {
      return description;
    }

    final changes = <String>[];
    if (beforeData != null && afterData != null) {
      afterData!.forEach((key, value) {
        if (beforeData![key] != value) {
          changes.add('$key: ${_formatValue(beforeData![key])} → ${_formatValue(value)}');
        }
      });
    }

    return changes.isEmpty ? description : changes.join(', ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'ריק';
    if (value is bool) return value ? 'כן' : 'לא';
    if (value is List) return '${value.length} פריטים';
    return value.toString();
  }
}

/// Service for managing audit logging
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'admin_audit_log';

  /// Get current admin info from secure storage
  Future<Map<String, String>?> _getCurrentAdminInfo() async {
    try {
      final userData = await SecureTokenStorage.loadUserData();
      if (userData == null) return null;

      final email = userData['email']?.toString() ?? '';
      if (!AuthService.isAdminEmail(email)) return null;

      return {
        'id': userData['id']?.toString() ?? '',
        'email': email,
        'name': userData['fullName']?.toString() ?? email.split('@').first,
      };
    } catch (e) {
      debugPrint('[AuditLogService] Error getting admin info: $e');
      return null;
    }
  }

  /// Log an admin action with full details
  Future<void> logAction({
    required AuditActionType actionType,
    required AuditEntityType entityType,
    required String entityId,
    required String entityName,
    required String description,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminInfo = await _getCurrentAdminInfo();
      if (adminInfo == null) {
        debugPrint('[AuditLogService] Cannot log action: No admin user found');
        return;
      }

      final entry = AuditLogEntry(
        id: '',
        adminId: adminInfo['id']!,
        adminEmail: adminInfo['email']!,
        adminName: adminInfo['name']!,
        actionType: actionType,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        description: description,
        beforeData: beforeData,
        afterData: afterData,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _db.collection(_collectionName).add(entry.toFirestore());
      debugPrint('[AuditLogService] Logged: ${actionType.value} on ${entityType.value} ($entityId)');
    } catch (e) {
      debugPrint('[AuditLogService] Error logging action: $e');
    }
  }

  /// Quick log method for simple actions
  Future<void> quickLog({
    required AuditActionType actionType,
    required AuditEntityType entityType,
    required String entityId,
    required String entityName,
    required String description,
  }) async {
    await logAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      description: description,
    );
  }

  /// Log an update with before/after tracking
  Future<void> logUpdate({
    required AuditEntityType entityType,
    required String entityId,
    required String entityName,
    required String description,
    required Map<String, dynamic> beforeData,
    required Map<String, dynamic> afterData,
    Map<String, dynamic>? metadata,
  }) async {
    await logAction(
      actionType: AuditActionType.update,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      description: description,
      beforeData: beforeData,
      afterData: afterData,
      metadata: metadata,
    );
  }

  /// Log a delete action
  Future<void> logDelete({
    required AuditEntityType entityType,
    required String entityId,
    required String entityName,
    required Map<String, dynamic> deletedData,
    String? description,
  }) async {
    await logAction(
      actionType: AuditActionType.delete,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      description: description ?? 'מחק ${entityType.hebrewLabel}: $entityName',
      beforeData: deletedData,
    );
  }

  /// Log admin login
  Future<void> logAdminLogin({String? ipAddress, String? userAgent}) async {
    final adminInfo = await _getCurrentAdminInfo();
    if (adminInfo == null) return;

    await logAction(
      actionType: AuditActionType.login,
      entityType: AuditEntityType.user,
      entityId: adminInfo['id']!,
      entityName: adminInfo['name']!,
      description: 'התחברות למערכת הניהול',
      metadata: {
        'ipAddress': ipAddress,
        'userAgent': userAgent,
      },
    );
  }

  /// Log admin logout
  Future<void> logAdminLogout() async {
    final adminInfo = await _getCurrentAdminInfo();
    if (adminInfo == null) return;

    await logAction(
      actionType: AuditActionType.logout,
      entityType: AuditEntityType.user,
      entityId: adminInfo['id']!,
      entityName: adminInfo['name']!,
      description: 'התנתקות מהמערכת',
    );
  }

  /// Get audit log stream with optional filters
  Stream<List<AuditLogEntry>> getAuditLogStream({
    AuditActionType? actionType,
    AuditEntityType? entityType,
    String? adminId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    Query query = _db
        .collection(_collectionName)
        .orderBy('timestamp', descending: true);

    if (actionType != null) {
      query = query.where('actionType', isEqualTo: actionType.value);
    }

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType.value);
    }

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogEntry.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all audit logs paginated
  Future<List<AuditLogEntry>> getAuditLogs({
    AuditActionType? actionType,
    AuditEntityType? entityType,
    String? adminId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection(_collectionName)
        .orderBy('timestamp', descending: true);

    if (actionType != null) {
      query = query.where('actionType', isEqualTo: actionType.value);
    }

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType.value);
    }

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AuditLogEntry.fromFirestore(doc))
        .toList();
  }

  /// Get audit logs for a specific entity
  Stream<List<AuditLogEntry>> getEntityAuditLogStream({
    required AuditEntityType entityType,
    required String entityId,
    int limit = 50,
  }) {
    return _db
        .collection(_collectionName)
        .where('entityType', isEqualTo: entityType.value)
        .where('entityId', isEqualTo: entityId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogEntry.fromFirestore(doc))
          .toList();
    });
  }

  /// Get audit logs by admin
  Stream<List<AuditLogEntry>> getAdminAuditLogStream({
    required String adminId,
    int limit = 50,
  }) {
    return _db
        .collection(_collectionName)
        .where('adminId', isEqualTo: adminId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogEntry.fromFirestore(doc))
          .toList();
    });
  }

  /// Delete old audit logs (for cleanup)
  Future<int> deleteOldLogs(DateTime before) async {
    try {
      final snapshot = await _db
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(before))
          .limit(500)
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('[AuditLogService] Deleted ${snapshot.docs.length} old audit logs');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[AuditLogService] Error deleting old logs: $e');
      return 0;
    }
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection(_collectionName);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final actionCounts = <String, int>{};
      final entityCounts = <String, int>{};
      final adminCounts = <String, int>{};

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;

        final actionType = data['actionType'] as String?;
        if (actionType != null) {
          actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
        }

        final entityType = data['entityType'] as String?;
        if (entityType != null) {
          entityCounts[entityType] = (entityCounts[entityType] ?? 0) + 1;
        }

        final adminId = data['adminId'] as String?;
        if (adminId != null) {
          adminCounts[adminId] = (adminCounts[adminId] ?? 0) + 1;
        }
      }

      return {
        'totalActions': docs.length,
        'actionCounts': actionCounts,
        'entityCounts': entityCounts,
        'adminCounts': adminCounts,
        'uniqueAdmins': adminCounts.length,
      };
    } catch (e) {
      debugPrint('[AuditLogService] Error getting statistics: $e');
      return {
        'totalActions': 0,
        'actionCounts': {},
        'entityCounts': {},
        'adminCounts': {},
        'uniqueAdmins': 0,
      };
    }
  }

  /// Export audit logs to JSON
  Future<String> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
    AuditActionType? actionType,
    AuditEntityType? entityType,
  }) async {
    try {
      Query query = _db.collection(_collectionName).orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (actionType != null) {
        query = query.where('actionType', isEqualTo: actionType.value);
      }

      if (entityType != null) {
        query = query.where('entityType', isEqualTo: entityType.value);
      }

      final snapshot = await query.limit(10000).get();
      final logs = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>))
          .toList();

      return logs.toString();
    } catch (e) {
      debugPrint('[AuditLogService] Error exporting logs: $e');
      return '[]';
    }
  }
}

/// Mixin to easily add audit logging to any service
mixin AuditLoggerMixin {
  final AuditLogService _auditLogService = AuditLogService();

  AuditLogService get auditLog => _auditLogService;

  /// Log an action with all details
  Future<void> logAuditAction({
    required AuditActionType actionType,
    required AuditEntityType entityType,
    required String entityId,
    required String entityName,
    required String description,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    Map<String, dynamic>? metadata,
  }) async {
    await _auditLogService.logAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      description: description,
      beforeData: beforeData,
      afterData: afterData,
      metadata: metadata,
    );
  }
}
