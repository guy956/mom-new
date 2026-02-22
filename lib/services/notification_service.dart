import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mom_connect/services/email_service.dart';
import 'package:mom_connect/services/audit_log_service.dart';

/// Type of admin notification
enum AdminNotificationType {
  newEvent,
  newPost,
  newMarketplaceItem,
  newExpert,
  newUser,
  newReport,
  contentUpdated,
  approvalRequired,
  other,
}

/// Extension for notification type
extension AdminNotificationTypeExtension on AdminNotificationType {
  String get value {
    switch (this) {
      case AdminNotificationType.newEvent:
        return 'new_event';
      case AdminNotificationType.newPost:
        return 'new_post';
      case AdminNotificationType.newMarketplaceItem:
        return 'new_marketplace_item';
      case AdminNotificationType.newExpert:
        return 'new_expert';
      case AdminNotificationType.newUser:
        return 'new_user';
      case AdminNotificationType.newReport:
        return 'new_report';
      case AdminNotificationType.contentUpdated:
        return 'content_updated';
      case AdminNotificationType.approvalRequired:
        return 'approval_required';
      case AdminNotificationType.other:
        return 'other';
    }
  }

  String get hebrewLabel {
    switch (this) {
      case AdminNotificationType.newEvent:
        return 'אירוע חדש';
      case AdminNotificationType.newPost:
        return 'פוסט חדש';
      case AdminNotificationType.newMarketplaceItem:
        return 'מוצר חדש במסירות';
      case AdminNotificationType.newExpert:
        return 'מומחה חדש';
      case AdminNotificationType.newUser:
        return 'משתמש חדש';
      case AdminNotificationType.newReport:
        return 'דיווח חדש';
      case AdminNotificationType.contentUpdated:
        return 'תוכן עודכן';
      case AdminNotificationType.approvalRequired:
        return 'נדרש אישור';
      case AdminNotificationType.other:
        return 'אחר';
    }
  }

  String get icon {
    switch (this) {
      case AdminNotificationType.newEvent:
        return '📅';
      case AdminNotificationType.newPost:
        return '📝';
      case AdminNotificationType.newMarketplaceItem:
        return '🛍️';
      case AdminNotificationType.newExpert:
        return '👩‍⚕️';
      case AdminNotificationType.newUser:
        return '👤';
      case AdminNotificationType.newReport:
        return '⚠️';
      case AdminNotificationType.contentUpdated:
        return '🔄';
      case AdminNotificationType.approvalRequired:
        return '⏳';
      case AdminNotificationType.other:
        return '🔔';
    }
  }
}

/// Model for admin notification
class AdminNotification {
  final String id;
  final AdminNotificationType type;
  final String title;
  final String message;
  final String itemId;
  final String itemType;
  final String status; // unread, read
  final DateTime createdAt;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.itemId,
    required this.itemType,
    required this.status,
    required this.createdAt,
    this.actionUrl,
    this.metadata,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      type: _parseNotificationType(data['type']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      itemId: data['itemId'] ?? '',
      itemType: data['itemType'] ?? '',
      status: data['status'] ?? 'unread',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actionUrl: data['actionUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'title': title,
      'message': message,
      'itemId': itemId,
      'itemType': itemType,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }

  static AdminNotificationType _parseNotificationType(String? value) {
    switch (value) {
      case 'new_event':
        return AdminNotificationType.newEvent;
      case 'new_post':
        return AdminNotificationType.newPost;
      case 'new_marketplace_item':
        return AdminNotificationType.newMarketplaceItem;
      case 'new_expert':
        return AdminNotificationType.newExpert;
      case 'new_user':
        return AdminNotificationType.newUser;
      case 'new_report':
        return AdminNotificationType.newReport;
      case 'content_updated':
        return AdminNotificationType.contentUpdated;
      case 'approval_required':
        return AdminNotificationType.approvalRequired;
      default:
        return AdminNotificationType.other;
    }
  }

  AdminNotification copyWith({
    String? id,
    AdminNotificationType? type,
    String? title,
    String? message,
    String? itemId,
    String? itemType,
    String? status,
    DateTime? createdAt,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isUnread => status == 'unread';
  bool get isRead => status == 'read';
}

/// Service for managing admin notifications
/// Handles creating notifications, sending emails, and logging to activity log
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'admin_notifications';
  final EmailService _emailService = EmailService();
  final AuditLogService _auditLogService = AuditLogService();

  /// Notify admin about new content requiring approval
  ///
  /// [type] - Type of content (event, post, marketplace, etc.)
  /// [content] - Full content data
  /// [sendEmail] - Whether to send email notification (default: true)
  /// [logActivity] - Whether to log to activity log (default: true)
  Future<String?> notifyAdminNewContent({
    required String type,
    required Map<String, dynamic> content,
    bool sendEmail = true,
    bool logActivity = true,
  }) async {
    try {
      // Determine notification type
      final notificationType = _mapContentTypeToNotificationType(type);

      // Extract title from content
      final title = _extractTitle(type, content);

      // Build message
      final message = _buildMessage(type, content);

      // Create notification in Firestore
      final notificationId = await _createNotification(
        type: notificationType,
        title: title,
        message: message,
        itemId: content['id'] ?? 'unknown',
        itemType: type,
        metadata: {
          'createdBy': content['createdBy'] ?? content['userName'] ?? content['author'],
          'status': content['status'] ?? 'pending',
        },
      );

      // Send email notification
      if (sendEmail) {
        await _emailService.sendAdminNotification(
          type: type,
          title: title,
          details: message,
          itemData: content,
          dashboardLink: _buildDashboardLink(type, content['id']),
        );
      }

      // Log to activity log
      if (logActivity) {
        await _logToActivityLog(type, content, title);
      }

      debugPrint('[NotificationService] Admin notified: $type - $title');
      return notificationId;
    } catch (e) {
      debugPrint('[NotificationService] Error notifying admin: $e');
      return null;
    }
  }

  /// Create notification document in Firestore
  Future<String> _createNotification({
    required AdminNotificationType type,
    required String title,
    required String message,
    required String itemId,
    required String itemType,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = AdminNotification(
      id: '',
      type: type,
      title: title,
      message: message,
      itemId: itemId,
      itemType: itemType,
      status: 'unread',
      createdAt: DateTime.now(),
      actionUrl: actionUrl ?? _buildDashboardLink(itemType, itemId),
      metadata: metadata,
    );

    final docRef = await _db.collection(_collectionName).add(notification.toFirestore());
    return docRef.id;
  }

  /// Get real-time stream of admin notifications
  Stream<List<AdminNotification>> getNotificationsStream({
    String? status,
    AdminNotificationType? type,
    int limit = 50,
  }) {
    Query query = _db
        .collection(_collectionName)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.value);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unread notifications count stream
  Stream<int> getUnreadCountStream() {
    return _db
        .collection(_collectionName)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection(_collectionName).doc(notificationId).update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[NotificationService] Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _db
          .collection(_collectionName)
          .where('status', isEqualTo: 'unread')
          .limit(100)
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      debugPrint('[NotificationService] All notifications marked as read');
    } catch (e) {
      debugPrint('[NotificationService] Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection(_collectionName).doc(notificationId).delete();
      debugPrint('[NotificationService] Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
    }
  }

  /// Delete old notifications (cleanup)
  Future<int> deleteOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _db
          .collection(_collectionName)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500)
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('[NotificationService] Deleted ${snapshot.docs.length} old notifications');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[NotificationService] Error deleting old notifications: $e');
      return 0;
    }
  }

  /// Map content type to notification type
  AdminNotificationType _mapContentTypeToNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'event':
      case 'events':
        return AdminNotificationType.newEvent;
      case 'post':
      case 'posts':
        return AdminNotificationType.newPost;
      case 'marketplace':
      case 'marketplace_item':
        return AdminNotificationType.newMarketplaceItem;
      case 'expert':
      case 'experts':
        return AdminNotificationType.newExpert;
      case 'user':
      case 'users':
        return AdminNotificationType.newUser;
      case 'report':
      case 'reports':
        return AdminNotificationType.newReport;
      default:
        return AdminNotificationType.approvalRequired;
    }
  }

  /// Extract title from content based on type
  String _extractTitle(String type, Map<String, dynamic> content) {
    switch (type.toLowerCase()) {
      case 'event':
      case 'events':
        return content['title'] ?? content['name'] ?? 'אירוע ללא שם';
      case 'post':
      case 'posts':
        final text = content['content'] ?? content['text'] ?? '';
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
      case 'marketplace':
      case 'marketplace_item':
        return content['title'] ?? content['name'] ?? 'מוצר ללא שם';
      case 'expert':
      case 'experts':
        return content['fullName'] ?? content['name'] ?? 'מומחה ללא שם';
      case 'user':
      case 'users':
        return content['fullName'] ?? content['name'] ?? content['email'] ?? 'משתמש חדש';
      case 'report':
      case 'reports':
        return content['reason'] ?? 'דיווח חדש';
      default:
        return 'פריט חדש';
    }
  }

  /// Build notification message
  String _buildMessage(String type, Map<String, dynamic> content) {
    final creator = content['createdBy'] ?? content['userName'] ?? content['author'] ?? 'משתמש';
    final typeLabel = _getTypeLabel(type);

    return '$typeLabel חדש מאת $creator מחכה לאישור במערכת';
  }

  /// Get Hebrew type label
  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'event':
      case 'events':
        return 'אירוע';
      case 'post':
      case 'posts':
        return 'פוסט';
      case 'marketplace':
      case 'marketplace_item':
        return 'מוצר';
      case 'expert':
      case 'experts':
        return 'מומחה';
      case 'user':
      case 'users':
        return 'משתמש';
      case 'report':
      case 'reports':
        return 'דיווח';
      default:
        return 'פריט';
    }
  }

  /// Build dashboard link for specific content type
  String _buildDashboardLink(String type, String? itemId) {
    final baseUrl = 'https://momit.pages.dev/admin';

    switch (type.toLowerCase()) {
      case 'event':
      case 'events':
        return '$baseUrl?tab=events';
      case 'post':
      case 'posts':
        return '$baseUrl?tab=posts';
      case 'marketplace':
      case 'marketplace_item':
        return '$baseUrl?tab=marketplace';
      case 'expert':
      case 'experts':
        return '$baseUrl?tab=experts';
      case 'user':
      case 'users':
        return '$baseUrl?tab=users';
      case 'report':
      case 'reports':
        return '$baseUrl?tab=reports';
      default:
        return baseUrl;
    }
  }

  /// Log notification to activity log
  Future<void> _logToActivityLog(String type, Map<String, dynamic> content, String title) async {
    try {
      await _auditLogService.quickLog(
        actionType: AuditActionType.create,
        entityType: _mapTypeToEntityType(type),
        entityId: content['id'] ?? 'unknown',
        entityName: title,
        description: 'התראה נוצרה: $title',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error logging to activity log: $e');
    }
  }

  /// Map content type to audit entity type
  AuditEntityType _mapTypeToEntityType(String type) {
    switch (type.toLowerCase()) {
      case 'event':
      case 'events':
        return AuditEntityType.event;
      case 'post':
      case 'posts':
        return AuditEntityType.post;
      case 'marketplace':
      case 'marketplace_item':
        return AuditEntityType.marketplace;
      case 'expert':
      case 'experts':
        return AuditEntityType.expert;
      case 'user':
      case 'users':
        return AuditEntityType.user;
      case 'report':
      case 'reports':
        return AuditEntityType.report;
      default:
        return AuditEntityType.other;
    }
  }

  /// Test notification system
  Future<bool> sendTestNotification() async {
    try {
      final testContent = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'בדיקת מערכת התראות',
        'createdBy': 'MOMIT System',
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      final notificationId = await notifyAdminNewContent(
        type: 'test',
        content: testContent,
        sendEmail: true,
        logActivity: true,
      );

      return notificationId != null;
    } catch (e) {
      debugPrint('[NotificationService] Test notification failed: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  NOTIFY ALL USERS (when content is approved)
  // ════════════════════════════════════════════════════════════════

  /// Notify all users when a new chat group is approved
  Future<void> notifyAllUsersNewChatGroup({
    required String groupId,
    required String groupName,
    required String groupDescription,
  }) async {
    try {
      // Get all active users
      final usersSnapshot = await _db.collection('users')
          .where('status', isEqualTo: 'active').get();

      // Send notification to each user
      for (final userDoc in usersSnapshot.docs) {
        await sendNotification(
          userId: userDoc.id,
          title: '💬 קבוצת צ\'אט חדשה!',
          body: groupName,
          type: 'new_chat_group',
          data: {
            'groupId': groupId,
            'groupName': groupName,
            'groupDescription': groupDescription,
          },
        );
      }

      debugPrint('[NotificationService] Notified ${usersSnapshot.docs.length} users about new chat group: $groupName');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying all users about chat group: $e');
    }
  }

  /// Notify all users when a new event is approved
  Future<void> notifyAllUsersNewEvent({
    required String eventId,
    required String eventTitle,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final usersSnapshot = await _db.collection('users')
          .where('status', isEqualTo: 'active').get();

      for (final userDoc in usersSnapshot.docs) {
        await sendNotification(
          userId: userDoc.id,
          title: '📅 אירוע חדש!',
          body: eventTitle,
          type: 'new_event',
          data: {
            'eventId': eventId,
            ...eventData,
          },
        );
      }

      debugPrint('[NotificationService] Notified ${usersSnapshot.docs.length} users about new event: $eventTitle');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying all users about event: $e');
    }
  }

  /// Notify all users when a new post is approved
  Future<void> notifyAllUsersNewPost({
    required String postId,
    required String postContent,
    required Map<String, dynamic> postData,
  }) async {
    try {
      final usersSnapshot = await _db.collection('users')
          .where('status', isEqualTo: 'active').get();

      for (final userDoc in usersSnapshot.docs) {
        await sendNotification(
          userId: userDoc.id,
          title: '📝 פוסט חדש בקהילה!',
          body: postContent.length > 100 ? postContent.substring(0, 100) + '...' : postContent,
          type: 'new_post',
          data: {
            'postId': postId,
            ...postData,
          },
        );
      }

      debugPrint('[NotificationService] Notified ${usersSnapshot.docs.length} users about new post');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying all users about post: $e');
    }
  }

  /// Notify all users when a new marketplace item is approved
  Future<void> notifyAllUsersNewMarketplaceItem({
    required String itemId,
    required String itemTitle,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final usersSnapshot = await _db.collection('users')
          .where('status', isEqualTo: 'active').get();

      for (final userDoc in usersSnapshot.docs) {
        await sendNotification(
          userId: userDoc.id,
          title: '🛍️ מוצר חדש במסירות!',
          body: itemTitle,
          type: 'new_marketplace',
          data: {
            'itemId': itemId,
            ...itemData,
          },
        );
      }

      debugPrint('[NotificationService] Notified ${usersSnapshot.docs.length} users about new marketplace item: $itemTitle');
    } catch (e) {
      debugPrint('[NotificationService] Error notifying all users about marketplace item: $e');
    }
  }

  /// Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NotificationService] Error sending notification to user $userId: $e');
    }
  }
}
