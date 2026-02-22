/// Centralized Firestore collection names for MOMIT app
/// 
/// Use these constants instead of hardcoded strings to ensure consistency
/// across the entire codebase.
class FirestoreCollections {
  // Private constructor to prevent instantiation
  FirestoreCollections._();

  // ════════════════════════════════════════════════════════════════
  //  USER & AUTH COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Main users collection - stores user profiles
  static const String users = 'users';
  
  /// User subcollections
  static const String userNotifications = 'notifications';
  static const String userTracking = 'tracking';

  // ════════════════════════════════════════════════════════════════
  //  CONTENT COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// User posts collection
  static const String posts = 'posts';
  
  /// Tips collection - daily tips for users
  static const String tips = 'tips';
  
  /// Events collection - community events
  static const String events = 'events';
  
  /// Marketplace collection - buy/sell items
  static const String marketplace = 'marketplace';
  
  /// Experts collection - professional listings
  static const String experts = 'experts';

  // ════════════════════════════════════════════════════════════════
  //  DYNAMIC CONFIGURATION COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Dynamic sections for homepage layout
  static const String dynamicSections = 'dynamic_sections';
  
  /// Content management for dynamic sections
  static const String contentManagement = 'content_management';

  // ════════════════════════════════════════════════════════════════
  //  APP CONFIGURATION COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Admin configuration collection - stores app config docs
  /// Document IDs: app_config, feature_flags, ui_config, text_overrides, announcement
  static const String adminConfig = 'admin_config';
  
  /// Main app configuration (alternative to admin_config)
  static const String appConfig = 'app_config';
  
  /// Feature flags collection
  static const String featureFlags = 'feature_flags';
  
  /// UI configuration collection
  static const String uiConfig = 'ui_config';

  // ════════════════════════════════════════════════════════════════
  //  ADMIN & MODERATION COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Audit log for admin actions
  static const String adminAuditLog = 'admin_audit_log';
  
  /// Activity log for user actions
  static const String activityLog = 'activity_log';
  
  /// User reports collection
  static const String reports = 'reports';
  
  /// Media library for uploaded files
  static const String mediaLibrary = 'media_library';
  
  /// Error logs collection
  static const String errorLogs = 'error_logs';
  
  /// Analytics data collection
  static const String analytics = 'analytics';

  // ════════════════════════════════════════════════════════════════
  //  COMMUNICATION COLLECTIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Push notifications history
  static const String pushNotifications = 'push_notifications';
  
  /// Chat groups collection
  static const String chatGroups = 'chatGroups';

  /// Direct messages collection
  static const String directMessages = 'directMessages';

  /// Chat messages subcollection
  static const String chatMessages = 'messages';

  /// Admin notifications collection
  static const String adminNotifications = 'admin_notifications';

  /// User notifications collection (flat, with userId field)
  static const String notifications = 'notifications';

  /// FCM token storage collection
  static const String fcmTokens = 'fcm_tokens';

  // ════════════════════════════════════════════════════════════════
  //  DOCUMENT IDs
  // ════════════════════════════════════════════════════════════════
  
  /// Singleton document IDs within admin_config collection
  static const String docAppConfig = 'app_config';
  static const String docFeatureFlags = 'feature_flags';
  static const String docUiConfig = 'ui_config';
  static const String docTextOverrides = 'text_overrides';
  static const String docAnnouncement = 'announcement';
  static const String docRegistrationForm = 'registration_form';
  static const String docSosForm = 'sos_form';
  static const String docMain = 'main';
  static const String docTheme = 'theme';
  static const String docBranding = 'branding';
  static const String docNavigation = 'navigation';
  static const String docAdsConfig = 'ads_config';
}

/// Firestore field names used across collections
class FirestoreFields {
  FirestoreFields._();

  // Common fields
  static const String id = 'id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String timestamp = 'timestamp';
  
  // User fields
  static const String email = 'email';
  static const String fullName = 'fullName';
  static const String status = 'status';
  static const String isAdmin = 'isAdmin';
  static const String role = 'role';
  static const String lastActive = 'lastActive';
  static const String lastLogin = 'lastLogin';
  
  // Content fields
  static const String title = 'title';
  static const String description = 'description';
  static const String content = 'content';
  static const String isActive = 'isActive';
  static const String isPublished = 'isPublished';
  static const String order = 'order';
  static const String type = 'type';
  
  // Section/Content management
  static const String sectionId = 'sectionId';
  static const String key = 'key';
  
  // Status values
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusBanned = 'banned';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
}
