import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing FCM push notifications
/// Handles token registration, foreground messages, and permission requests
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _currentToken;
  String? _currentUserId;

  /// Initialize push notifications
  /// Call after Firebase.initializeApp() and after user is authenticated
  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;

    try {
      // Request permission (web shows browser prompt, mobile shows system dialog)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('[PushNotificationService] Permission granted');
        await _getAndSaveToken();
        _setupTokenRefresh();
        _setupForegroundMessages();
      } else {
        debugPrint('[PushNotificationService] Permission denied');
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Init error: $e');
    }
  }

  /// Get FCM token and save to Firestore
  Future<void> _getAndSaveToken() async {
    try {
      // For web, you may need a VAPID key. If not configured, getToken() will
      // use the default FCM sender ID from firebase config.
      final token = await _messaging.getToken();
      if (token != null && token != _currentToken) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        debugPrint('[PushNotificationService] Token saved');
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Error getting token: $e');
    }
  }

  /// Save FCM token to Firestore for server-side sending
  Future<void> _saveTokenToFirestore(String token) async {
    if (_currentUserId == null) return;

    try {
      await _db.collection('fcm_tokens').doc(token).set({
        'token': token,
        'userId': _currentUserId,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PushNotificationService] Error saving token: $e');
    }
  }

  /// Listen for token refresh
  void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken != _currentToken) {
        // Delete old token
        if (_currentToken != null) {
          try {
            await _db.collection('fcm_tokens').doc(_currentToken).delete();
          } catch (_) {}
        }
        _currentToken = newToken;
        await _saveTokenToFirestore(newToken);
        debugPrint('[PushNotificationService] Token refreshed');
      }
    });
  }

  /// Handle foreground messages (when app is open)
  void _setupForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Foreground message: ${message.notification?.title}');
      // In-app notifications are handled by the Firestore notification stream
      // This listener is for logging and potential future in-app banners
    });
  }

  /// Clean up token when user logs out
  Future<void> cleanup() async {
    try {
      if (_currentToken != null) {
        await _db.collection('fcm_tokens').doc(_currentToken).delete();
        await _messaging.deleteToken();
        _currentToken = null;
        _currentUserId = null;
        debugPrint('[PushNotificationService] Token cleaned up');
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Cleanup error: $e');
    }
  }
}
