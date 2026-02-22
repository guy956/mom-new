import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_connect/services/notification_service.dart';

/// Central Firestore service for MOMIT admin dashboard and real-time sync.
/// All admin CRUD operations and real-time streams go through this service.
class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  FirestoreService() {
    // Enable offline persistence for web
    _db.settings = const Settings(persistenceEnabled: true);
  }

  // ════════════════════════════════════════════════════════════════
  //  ADMIN CONFIG STREAMS (singleton docs - consumed by all users)
  // ════════════════════════════════════════════════════════════════

  Stream<Map<String, dynamic>> get appConfigStream =>
      _db.collection('admin_config').doc('app_config').snapshots().map(
          (snap) => snap.exists ? (snap.data() ?? {}) : _defaultAppConfig);

  Stream<Map<String, bool>> get featureFlagsStream =>
      _db.collection('admin_config').doc('feature_flags').snapshots().map(
          (snap) {
        if (!snap.exists) return _defaultFeatureFlags;
        final data = snap.data() ?? {};
        final flags = <String, bool>{};
        for (final key in _defaultFeatureFlags.keys) {
          flags[key] = data[key] is bool ? data[key] : true;
        }
        return flags;
      });

  Stream<Map<String, bool>> get moderationSettingsStream =>
      _db.collection('admin_config').doc('feature_flags').snapshots().map(
          (snap) {
        if (!snap.exists) return _defaultModerationSettings;
        final data = snap.data() ?? {};
        return {
          'requireUserApproval': data['requireUserApproval'] ?? true,
          'autoContentFilter': data['autoContentFilter'] ?? true,
          'profanityFilter': data['profanityFilter'] ?? true,
          'requireEventApproval': data['requireEventApproval'] ?? true,
        };
      });

  Stream<Map<String, dynamic>> get uiConfigStream =>
      _db.collection('admin_config').doc('ui_config').snapshots().map(
          (snap) => snap.exists ? (snap.data() ?? {}) : _defaultUIConfig);

  Stream<Map<String, dynamic>> get announcementStream =>
      _db.collection('admin_config').doc('announcement').snapshots().map(
          (snap) => snap.exists
              ? (snap.data() ?? _defaultAnnouncement)
              : _defaultAnnouncement);

  Stream<Map<String, dynamic>> get textOverridesStream =>
      _db.collection('admin_config').doc('text_overrides').snapshots().map(
          (snap) => snap.exists ? (snap.data() ?? {}) : {});

  // ════════════════════════════════════════════════════════════════
  //  COLLECTION STREAMS (for admin dashboard tabs)
  // ════════════════════════════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> get usersStream =>
      _db.collection('users').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get expertsStream =>
      _db.collection('experts').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get eventsStream =>
      _db.collection('events').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get marketplaceStream =>
      _db.collection('marketplace').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get tipsStream =>
      _db.collection('tips').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get postsStream =>
      _db.collection('posts').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get reportsStream =>
      _db.collection('reports').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get activityLogStream =>
      _db.collection('activity_log').orderBy('createdAt', descending: true).limit(50).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> get fullActivityLogStream =>
      _db.collection('activity_log').orderBy('createdAt', descending: true).limit(500).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  // ════════════════════════════════════════════════════════════════
  //  MEDIA LIBRARY STREAMS & CRUD
  // ════════════════════════════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> get mediaLibraryStream =>
      _db.collection('media_library').orderBy('createdAt', descending: true).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> addMediaItem(Map<String, dynamic> data) =>
      _db.collection('media_library').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteMediaItem(String itemId) =>
      _db.collection('media_library').doc(itemId).delete();

  // ════════════════════════════════════════════════════════════════
  //  PUSH NOTIFICATIONS CRUD
  // ════════════════════════════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> get notificationsHistoryStream =>
      _db.collection('push_notifications').orderBy('createdAt', descending: true).limit(50).snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> savePushNotification(Map<String, dynamic> data) =>
      _db.collection('push_notifications').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> deletePushNotification(String id) =>
      _db.collection('push_notifications').doc(id).delete();

  // ════════════════════════════════════════════════════════════════
  //  DYNAMIC FORMS CONFIG
  // ════════════════════════════════════════════════════════════════

  Stream<Map<String, dynamic>> get registrationFormStream =>
      _db.collection('admin_config').doc('registration_form').snapshots().map(
          (snap) => snap.exists ? (snap.data() ?? _defaultRegistrationForm) : _defaultRegistrationForm);

  Stream<Map<String, dynamic>> get sosFormStream =>
      _db.collection('admin_config').doc('sos_form').snapshots().map(
          (snap) => snap.exists ? (snap.data() ?? _defaultSosForm) : _defaultSosForm);

  Future<void> updateRegistrationForm(Map<String, dynamic> form) =>
      _db.collection('admin_config').doc('registration_form').set({
        ...form,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateSosForm(Map<String, dynamic> form) =>
      _db.collection('admin_config').doc('sos_form').set({
        ...form,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ════════════════════════════════════════════════════════════════
  //  USERS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addUser(Map<String, dynamic> data) async {
    final docRef = await _db.collection('users').add({
      ...data,
      'status': data['status'] ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification for new user registration if requires approval
    if (data['status'] == 'pending' || data['status'] == null) {
      await _notificationService.notifyAdminNewContent(
        type: 'user',
        content: {
          ...data,
          'id': docRef.id,
        },
      );
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _db.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateUserStatus(String userId, String status) =>
      _db.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setUserAdmin(String userId, bool isAdmin) =>
      _db.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteUser(String userId) =>
      _db.collection('users').doc(userId).delete();

  /// Sync a user from AuthService to Firestore (used during registration)
  Future<void> syncUserToFirestore(Map<String, dynamic> userData) async {
    final email = (userData['email'] ?? '').toString().toLowerCase().trim();
    if (email.isEmpty) return;
    final existing = await _db.collection('users')
        .where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isEmpty) {
      await _db.collection('users').add({
        ...userData,
        'status': 'active',
        'posts': 0,
        'reports': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('users').doc(existing.docs.first.id).update({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  EXPERTS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addExpert(Map<String, dynamic> data) async {
    final docRef = await _db.collection('experts').add({
      ...data,
      'rating': data['rating'] ?? 0.0,
      'consultations': data['consultations'] ?? 0,
      'queues': data['queues'] ?? 0,
      'status': data['status'] ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification for new expert requiring approval
    if (data['status'] == 'pending' || data['status'] == null) {
      await _notificationService.notifyAdminNewContent(
        type: 'expert',
        content: {
          ...data,
          'id': docRef.id,
        },
      );
    }
  }

  Future<void> updateExpert(String expertId, Map<String, dynamic> data) =>
      _db.collection('experts').doc(expertId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateExpertStatus(String expertId, String status) =>
      _db.collection('experts').doc(expertId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteExpert(String expertId) =>
      _db.collection('experts').doc(expertId).delete();

  // ════════════════════════════════════════════════════════════════
  //  EVENTS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> createEvent(Map<String, dynamic> data) async {
    final docRef = await _db.collection('events').add({
      ...data,
      'attendees': data['attendees'] ?? 0,
      'maxAttendees': data['maxAttendees'] ?? 50,
      'status': data['status'] ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification if approval is required
    if (data['status'] == 'pending' || data['status'] == null) {
      await _notificationService.notifyAdminNewContent(
        type: 'event',
        content: {
          ...data,
          'id': docRef.id,
        },
      );
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) =>
      _db.collection('events').doc(eventId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateEventStatus(String eventId, String status) =>
      _db.collection('events').doc(eventId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteEvent(String eventId) =>
      _db.collection('events').doc(eventId).delete();

  // ════════════════════════════════════════════════════════════════
  //  MARKETPLACE CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addMarketplaceItem(Map<String, dynamic> data) async {
    final docRef = await _db.collection('marketplace').add({
      ...data,
      'status': data['status'] ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification if approval is required
    if (data['status'] == 'pending' || data['status'] == null) {
      await _notificationService.notifyAdminNewContent(
        type: 'marketplace',
        content: {
          ...data,
          'id': docRef.id,
        },
      );
    }
  }

  Future<void> updateMarketplaceItem(String itemId, Map<String, dynamic> data) =>
      _db.collection('marketplace').doc(itemId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateMarketplaceItemStatus(String itemId, String status) =>
      _db.collection('marketplace').doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteMarketplaceItem(String itemId) =>
      _db.collection('marketplace').doc(itemId).delete();

  // ════════════════════════════════════════════════════════════════
  //  TIPS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addTip(Map<String, dynamic> data) =>
      _db.collection('tips').add({
        ...data,
        'active': data['active'] ?? true,
        'status': data['status'] ?? 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateTip(String tipId, Map<String, dynamic> data) =>
      _db.collection('tips').doc(tipId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> toggleTipActive(String tipId, bool active) =>
      _db.collection('tips').doc(tipId).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateTipStatus(String tipId, String status) =>
      _db.collection('tips').doc(tipId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteTip(String tipId) =>
      _db.collection('tips').doc(tipId).delete();

  /// Batch add multiple tips (from file upload)
  Future<void> batchAddTips(List<Map<String, dynamic>> tips) async {
    final batch = _db.batch();
    for (final tip in tips) {
      final ref = _db.collection('tips').doc();
      batch.set(ref, {
        ...tip,
        'active': true,
        'status': tip['status'] ?? 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════
  //  POSTS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addPost(Map<String, dynamic> data) async {
    final docRef = await _db.collection('posts').add({
      ...data,
      'likes': data['likes'] ?? 0,
      'comments': data['comments'] ?? 0,
      'reports': data['reports'] ?? 0,
      'status': data['status'] ?? 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification if approval is required
    if (data['status'] == 'pending' || data['status'] == null) {
      await _notificationService.notifyAdminNewContent(
        type: 'post',
        content: {
          ...data,
          'id': docRef.id,
        },
      );
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) =>
      _db.collection('posts').doc(postId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deletePost(String postId) =>
      _db.collection('posts').doc(postId).delete();

  // ════════════════════════════════════════════════════════════════
  //  POST COMMENTS CRUD (subcollection: posts/{postId}/comments)
  // ════════════════════════════════════════════════════════════════

  /// Stream of comments for a specific post, ordered by creation time
  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) =>
      _db.collection('posts').doc(postId).collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Add a comment to a post and increment the post's comments count
  Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      ...commentData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Increment the comments count on the post document
    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a comment from a post and decrement the post's comments count
  Future<void> deleteComment(String postId, String commentId) async {
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════════════
  //  USER NOTIFICATIONS (per-user collection)
  // ════════════════════════════════════════════════════════════════

  /// Stream of notifications for a specific user, ordered by creation time descending
  Stream<List<Map<String, dynamic>>> userNotificationsStream(String userId) =>
      _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Mark a single notification as read
  Future<void> markNotificationRead(String notificationId) =>
      _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) =>
      _db.collection('notifications').doc(notificationId).delete();

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    final snap = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════
  //  REPORTS CRUD
  // ════════════════════════════════════════════════════════════════

  Future<void> addReport(Map<String, dynamic> data) async {
    final docRef = await _db.collection('reports').add({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send admin notification for new report (always requires attention)
    await _notificationService.notifyAdminNewContent(
      type: 'report',
      content: {
        ...data,
        'id': docRef.id,
      },
    );
  }

  Future<void> updateReportStatus(String reportId, String status) =>
      _db.collection('reports').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> addReportNote(String reportId, String note) =>
      _db.collection('reports').doc(reportId).update({
        'adminNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteReport(String reportId) =>
      _db.collection('reports').doc(reportId).delete();

  // ════════════════════════════════════════════════════════════════
  //  ADMIN CONFIG CRUD (singleton docs)
  // ════════════════════════════════════════════════════════════════

  Future<void> updateAppConfig(Map<String, dynamic> config) =>
      _db.collection('admin_config').doc('app_config').set({
        ...config,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateFeatureFlags(Map<String, dynamic> flags) =>
      _db.collection('admin_config').doc('feature_flags').set({
        ...flags,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateUIConfig(Map<String, dynamic> config) =>
      _db.collection('admin_config').doc('ui_config').set({
        ...config,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateAnnouncement(Map<String, dynamic> announcement) =>
      _db.collection('admin_config').doc('announcement').set({
        ...announcement,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateTextOverrides(Map<String, dynamic> overrides) =>
      _db.collection('admin_config').doc('text_overrides').set({
        ...overrides,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateTextOverrideSection(String section, Map<String, String> values) =>
      _db.collection('admin_config').doc('text_overrides').set({
        section: values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ════════════════════════════════════════════════════════════════
  //  ACTIVITY LOG
  // ════════════════════════════════════════════════════════════════

  Future<void> logActivity({
    required String action,
    required String user,
    String? userId,
    required String type,
  }) =>
      _db.collection('activity_log').add({
        'action': action,
        'user': user,
        'userId': userId,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ════════════════════════════════════════════════════════════════
  //  AGGREGATE COUNTS (for overview tab)
  // ════════════════════════════════════════════════════════════════

  Future<int> getCollectionCount(String collection) async {
    final snap = await _db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  Future<int> getFilteredCount(String collection, String field, dynamic value) async {
    final snap = await _db.collection(collection)
        .where(field, isEqualTo: value).count().get();
    return snap.count ?? 0;
  }

  // ════════════════════════════════════════════════════════════════
  //  ANALYTICS STREAMS & METHODS
  // ════════════════════════════════════════════════════════════════

  /// Stream of daily active users (users who logged in today)
  Stream<int> get dailyActiveUsersStream {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db.collection('users')
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of weekly active users
  Stream<int> get weeklyActiveUsersStream {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _db.collection('users')
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of monthly active users
  Stream<int> get monthlyActiveUsersStream {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _db.collection('users')
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of new registrations in the last 24 hours
  Stream<int> get dailyNewRegistrationsStream {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    return _db.collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayAgo))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of new registrations in the last 7 days
  Stream<int> get weeklyNewRegistrationsStream {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _db.collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of new registrations in the last 30 days
  Stream<int> get monthlyNewRegistrationsStream {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _db.collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get user registration trend data (last 30 days, daily)
  Stream<List<Map<String, dynamic>>> get userRegistrationTrendStream async* {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    await for (final snap in _db.collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('createdAt', descending: false)
        .snapshots()) {
      
      final dailyCounts = <DateTime, int>{};
      for (var i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: 29 - i));
        dailyCounts[DateTime(date.year, date.month, date.day)] = 0;
      }
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime dt;
          if (createdAt is Timestamp) {
            dt = createdAt.toDate();
          } else if (createdAt is DateTime) {
            dt = createdAt;
          } else {
            continue;
          }
          final dateKey = DateTime(dt.year, dt.month, dt.day);
          dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
        }
      }
      
      final result = dailyCounts.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      yield result;
    }
  }

  /// Get most active sections based on activity log
  Stream<List<Map<String, dynamic>>> get mostActiveSectionsStream async* {
    await for (final snap in _db.collection('activity_log')
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .snapshots()) {
      
      final sectionCounts = <String, int>{};
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime dt;
          if (createdAt is Timestamp) {
            dt = createdAt.toDate();
          } else if (createdAt is DateTime) {
            dt = createdAt;
          } else {
            continue;
          }
          if (dt.isAfter(weekAgo)) {
            final type = (data['type'] ?? 'other').toString();
            sectionCounts[type] = (sectionCounts[type] ?? 0) + 1;
          }
        }
      }
      
      final sorted = sectionCounts.entries
          .map((e) => {'section': _getSectionName(e.key), 'type': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      yield sorted.take(8).toList();
    }
  }

  String _getSectionName(String type) {
    final names = {
      'user': 'משתמשים',
      'expert': 'מומחים',
      'event': 'אירועים',
      'marketplace': 'מסירות',
      'post': 'פוסטים',
      'tip': 'טיפים',
      'report': 'דיווחים',
      'chat': 'צ׳אט',
      'notification': 'התראות',
      'admin': 'מנהל',
    };
    return names[type] ?? type;
  }

  /// Stream of error logs (last 24 hours)
  Stream<List<Map<String, dynamic>>> get recentErrorsStream {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    return _db.collection('error_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dayAgo))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Stream of error count by severity
  Stream<Map<String, int>> get errorStatsStream async* {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    await for (final snap in _db.collection('error_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dayAgo))
        .snapshots()) {
      
      final stats = {'critical': 0, 'error': 0, 'warning': 0, 'info': 0};
      for (final doc in snap.docs) {
        final severity = (doc.data()['severity'] ?? 'error').toString().toLowerCase();
        stats[severity] = (stats[severity] ?? 0) + 1;
      }
      yield stats;
    }
  }

  /// Stream of performance metrics
  Stream<Map<String, dynamic>> get performanceMetricsStream {
    return _db.collection('analytics').doc('performance').snapshots().map(
      (snap) => snap.exists ? (snap.data() ?? _defaultPerformanceMetrics) : _defaultPerformanceMetrics
    );
  }

  /// Stream of user retention data
  Stream<Map<String, dynamic>> get userRetentionStream async* {
    await for (final snap in _db.collection('users').snapshots()) {
      final now = DateTime.now();
      final total = snap.docs.length;
      
      if (total == 0) {
        yield {'day1': 0.0, 'day7': 0.0, 'day30': 0.0, 'total': 0};
        continue;
      }
      
      int day1Active = 0;
      int day7Active = 0;
      int day30Active = 0;
      
      final day1Ago = now.subtract(const Duration(days: 1));
      final day7Ago = now.subtract(const Duration(days: 7));
      final day30Ago = now.subtract(const Duration(days: 30));
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final lastActive = data['lastActive'];
        if (lastActive != null) {
          DateTime dt;
          if (lastActive is Timestamp) {
            dt = lastActive.toDate();
          } else if (lastActive is DateTime) {
            dt = lastActive;
          } else {
            continue;
          }
          
          if (dt.isAfter(day1Ago)) day1Active++;
          if (dt.isAfter(day7Ago)) day7Active++;
          if (dt.isAfter(day30Ago)) day30Active++;
        }
      }
      
      yield {
        'day1': (day1Active / total * 100).round(),
        'day7': (day7Active / total * 100).round(),
        'day30': (day30Active / total * 100).round(),
        'total': total,
      };
    }
  }

  /// Get hourly activity distribution
  Stream<List<int>> get hourlyActivityStream async* {
    await for (final snap in _db.collection('activity_log')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()) {
      
      final hours = List<int>.filled(24, 0);
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime dt;
          if (createdAt is Timestamp) {
            dt = createdAt.toDate();
          } else if (createdAt is DateTime) {
            dt = createdAt;
          } else {
            continue;
          }
          if (dt.isAfter(dayAgo)) {
            hours[dt.hour]++;
          }
        }
      }
      
      yield hours;
    }
  }

  static final Map<String, dynamic> _defaultPerformanceMetrics = {
    'avgResponseTime': 0,
    'apiSuccessRate': 100.0,
    'appLoadTime': 0,
    'crashFreeRate': 100.0,
    'lastUpdated': null,
  };

  // ════════════════════════════════════════════════════════════════
  //  SEED INITIAL DATA
  // ════════════════════════════════════════════════════════════════

  /// Creates default admin config docs if they don't exist yet
  Future<void> seedInitialData() async {
    try {
      final configDoc = await _db.collection('admin_config').doc('app_config').get();
      if (!configDoc.exists) {
        await _db.collection('admin_config').doc('app_config').set({
          ..._defaultAppConfig,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FirestoreService] Seeded app_config');
      }

      final flagsDoc = await _db.collection('admin_config').doc('feature_flags').get();
      if (!flagsDoc.exists) {
        await _db.collection('admin_config').doc('feature_flags').set({
          ..._defaultFeatureFlags,
          ..._defaultModerationSettings,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FirestoreService] Seeded feature_flags');
      }

      final uiDoc = await _db.collection('admin_config').doc('ui_config').get();
      if (!uiDoc.exists) {
        await _db.collection('admin_config').doc('ui_config').set({
          ..._defaultUIConfig,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FirestoreService] Seeded ui_config');
      }

      final textDoc = await _db.collection('admin_config').doc('text_overrides').get();
      if (!textDoc.exists) {
        await _db.collection('admin_config').doc('text_overrides').set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FirestoreService] Seeded text_overrides');
      }

      final annDoc = await _db.collection('admin_config').doc('announcement').get();
      if (!annDoc.exists) {
        await _db.collection('admin_config').doc('announcement').set({
          ..._defaultAnnouncement,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FirestoreService] Seeded announcement');
      }
    } catch (e) {
      debugPrint('[FirestoreService] Seed error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  DEFAULTS
  // ════════════════════════════════════════════════════════════════

  static final Map<String, dynamic> _defaultAppConfig = {
    'appName': 'MOMIT',
    'slogan': 'כי רק אמא מבינה אמא',
    'description': 'רשת חברתית לאמהות בישראל',
    'whatsappLink': 'https://chat.whatsapp.com/momit',
    'whatsappGroupName': 'MOMIT Community',
    'whatsappMembers': '500',
    'whatsappDescription': 'קבוצת WhatsApp הרשמית של MOMIT',
    'instagram': 'https://instagram.com/momit_il',
    'facebook': 'https://facebook.com/momit.il',
    'website': 'https://momit.pages.dev',
    'contactEmail': 'support@momconnect.co.il',
    'contactPhone': '03-1234567',
    'termsUrl': 'https://momit.pages.dev/terms',
    'privacyUrl': 'https://momit.pages.dev/privacy',
    'welcomeTitle': 'ברוכה הבאה ל-MOMIT',
    'welcomeSubtitle': 'הרשת החברתית לאמהות',
    'welcomeDescription': 'הצטרפי לקהילה הכי חמה בישראל',
  };

  static final Map<String, bool> _defaultFeatureFlags = {
    'chat': true, 'events': true, 'marketplace': true, 'experts': true,
    'tips': true, 'mood': true, 'sos': true, 'gamification': true,
    'aiChat': true, 'whatsapp': true, 'album': true, 'tracking': true,
  };

  static final Map<String, bool> _defaultModerationSettings = {
    'requireUserApproval': true, 'autoContentFilter': true,
    'profanityFilter': true, 'requireEventApproval': true,
  };

  static final Map<String, dynamic> _defaultUIConfig = {
    'primaryColor': '#D4A1AC',
    'secondaryColor': '#EDD3D8',
    'accentColor': '#DBC8B0',
    'menuOrder': ['בית', 'צ\'אט', 'קהילה', 'מומחים', 'פרופיל'],
    'expertCategories': ['רופאת ילדים', 'יועצת שינה', 'יועצת הנקה', 'דיאטנית', 'פסיכולוגית', 'מטפלת רגשית', 'פיזיותרפיסטית', 'אחר'],
    'tipCategories': ['שינה', 'האכלה', 'התפתחות', 'בריאות', 'כושר', 'רווחה נפשית', 'טיפול בתינוק', 'תזונה'],
    'marketplaceCategories': ['ציוד לתינוק', 'עגלות', 'ריהוט', 'ביגוד', 'צעצועים', 'ספרים', 'אחר'],
    'bottomNavLabels': ['בית', 'מעקב', 'אירועים', 'הודעות', 'פרופיל'],
    'quickAccessButtons': [
      {'key': 'aiChat', 'label': 'MomBot', 'color': '#D1C2D3', 'enabled': true, 'order': 0},
      {'key': 'sos', 'label': 'SOS', 'color': '#D4A3A3', 'enabled': true, 'order': 1},
      {'key': 'whatsapp', 'label': 'WhatsApp', 'color': '#B5C8B9', 'enabled': true, 'order': 2},
      {'key': 'marketplace', 'label': 'מסירות', 'color': '#D6C7C1', 'enabled': true, 'order': 3},
      {'key': 'mood', 'label': 'מצב רוח', 'color': '#D1C2D3', 'enabled': true, 'order': 4},
      {'key': 'album', 'label': 'אלבום', 'color': '#EDD3D8', 'enabled': true, 'order': 5},
      {'key': 'experts', 'label': 'מומחים', 'color': '#B5BFC9', 'enabled': true, 'order': 6},
      {'key': 'tips', 'label': 'טיפים', 'color': '#DBC8B0', 'enabled': true, 'order': 7},
      {'key': 'gamification', 'label': 'הישגים', 'color': '#DBC8B0', 'enabled': true, 'order': 8},
    ],
    'drawerLabels': {
      'aiChat': 'MomBot AI',
      'sos': 'SOS חירום',
      'whatsapp': 'WhatsApp',
      'marketplace': 'מסירות ותרומות',
      'mood': 'מצב רוח',
      'album': 'אלבום',
      'experts': 'מומחים',
      'tips': 'טיפים',
      'mainNav': 'ניווט ראשי',
      'advancedFeatures': 'תכונות מתקדמות',
      'settingsSection': 'הגדרות',
    },
  };

  static final Map<String, dynamic> _defaultAnnouncement = {
    'enabled': false,
    'text': '',
    'color': '#D1C2D3',
    'link': '',
  };

  static final Map<String, dynamic> _defaultRegistrationForm = {
    'fields': [
      {'key': 'fullName', 'label': 'שם מלא', 'type': 'text', 'required': true, 'enabled': true, 'order': 0},
      {'key': 'email', 'label': 'אימייל', 'type': 'email', 'required': true, 'enabled': true, 'order': 1},
      {'key': 'password', 'label': 'סיסמה', 'type': 'password', 'required': true, 'enabled': true, 'order': 2},
      {'key': 'phone', 'label': 'טלפון', 'type': 'phone', 'required': true, 'enabled': true, 'order': 3},
      {'key': 'city', 'label': 'עיר', 'type': 'text', 'required': true, 'enabled': true, 'order': 4},
      {'key': 'bio', 'label': 'ביוגרפיה', 'type': 'textarea', 'required': false, 'enabled': false, 'order': 5},
    ],
  };

  static final Map<String, dynamic> _defaultSosForm = {
    'fields': [
      {'key': 'name', 'label': 'שם', 'type': 'text', 'required': true, 'enabled': true, 'order': 0},
      {'key': 'phone', 'label': 'טלפון', 'type': 'phone', 'required': true, 'enabled': true, 'order': 1},
      {'key': 'situation', 'label': 'תאר/י את המצב', 'type': 'textarea', 'required': true, 'enabled': true, 'order': 2},
      {'key': 'location', 'label': 'מיקום', 'type': 'text', 'required': false, 'enabled': true, 'order': 3},
      {'key': 'urgency', 'label': 'דחיפות', 'type': 'select', 'required': true, 'enabled': true, 'order': 4, 'options': ['נמוכה', 'בינונית', 'גבוהה', 'קריטית']},
    ],
  };

  static Map<String, dynamic> get defaultRegistrationForm => Map.from(_defaultRegistrationForm);
  static Map<String, dynamic> get defaultSosForm => Map.from(_defaultSosForm);

  /// Get default values (for fallback when Firestore is unavailable)
  static Map<String, dynamic> get defaultAppConfig => Map.from(_defaultAppConfig);
  static Map<String, bool> get defaultFeatureFlags => Map.from(_defaultFeatureFlags);
  static Map<String, bool> get defaultModerationSettings => Map.from(_defaultModerationSettings);
  static Map<String, dynamic> get defaultUIConfig => Map.from(_defaultUIConfig);
  static Map<String, dynamic> get defaultAnnouncement => Map.from(_defaultAnnouncement);

  // ════════════════════════════════════════════════════════════════
  //  CHAT GROUPS CRUD
  // ════════════════════════════════════════════════════════════════

  /// Stream of all chat groups (for admin dashboard)
  Stream<List<Map<String, dynamic>>> get chatGroupsStream =>
      _db.collection('chatGroups')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Create a new chat group
  Future<String> createChatGroup({
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,
    required String creatorEmail,
    required String creatorPhone,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _db.collection('chatGroups').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorEmail': creatorEmail,
        'creatorPhone': creatorPhone,
        'members': [creatorId],
        'memberCount': 1,
        'status': 'pending', // Requires admin approval
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin about new chat group
      await _notificationService.notifyAdminNewContent(
        type: 'chat_group',
        content: {
          'id': docRef.id,
          'name': name,
          'description': description,
          'creatorName': creatorName,
          'creatorEmail': creatorEmail,
          'creatorPhone': creatorPhone,
          'status': 'pending',
        },
      );

      debugPrint('[FirestoreService] ✅ Chat group created: $name (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('[FirestoreService] ❌ Error creating chat group: $e');
      rethrow;
    }
  }

  /// Update chat group status (approve/reject)
  Future<void> updateChatGroupStatus(String groupId, String status) async {
    try {
      await _db.collection('chatGroups').doc(groupId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If approved, notify all users
      if (status == 'approved') {
        final groupDoc = await _db.collection('chatGroups').doc(groupId).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          await _notificationService.notifyAllUsersNewChatGroup(
            groupId: groupId,
            groupName: groupData['name'] ?? 'קבוצה חדשה',
            groupDescription: groupData['description'] ?? '',
          );
        }
      }

      debugPrint('[FirestoreService] ✅ Chat group status updated: $groupId → $status');
    } catch (e) {
      debugPrint('[FirestoreService] ❌ Error updating chat group status: $e');
      rethrow;
    }
  }

  /// Delete a chat group
  Future<void> deleteChatGroup(String groupId) async {
    try {
      await _db.collection('chatGroups').doc(groupId).delete();
      debugPrint('[FirestoreService] ✅ Chat group deleted: $groupId');
    } catch (e) {
      debugPrint('[FirestoreService] ❌ Error deleting chat group: $e');
      rethrow;
    }
  }

  /// Join a chat group
  Future<void> joinChatGroup(String groupId, String userId) async {
    try {
      await _db.collection('chatGroups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FirestoreService] ✅ User $userId joined group $groupId');
    } catch (e) {
      debugPrint('[FirestoreService] ❌ Error joining chat group: $e');
      rethrow;
    }
  }

  /// Leave a chat group
  Future<void> leaveChatGroup(String groupId, String userId) async {
    try {
      await _db.collection('chatGroups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FirestoreService] ✅ User $userId left group $groupId');
    } catch (e) {
      debugPrint('[FirestoreService] ❌ Error leaving chat group: $e');
      rethrow;
    }
  }
}
