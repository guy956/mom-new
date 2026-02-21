/**
 * Feature Flag Model
 * 
 * Represents a feature flag/toggle in the application.
 * Used to enable/disable features remotely without code changes.
 */

class FeatureFlag {
  final String id;
  final String name;
  final String description;
  final bool enabled;
  final int rolloutPercentage;
  final DateTime? updatedAt;
  final String? updatedBy;
  final Map<String, dynamic> metadata;

  const FeatureFlag({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = false,
    this.rolloutPercentage = 100,
    this.updatedAt,
    this.updatedBy,
    this.metadata = const {},
  });

  /// Create from Firestore document data
  factory FeatureFlag.fromFirestore(String id, Map<String, dynamic> data) {
    return FeatureFlag(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      enabled: data['enabled'] ?? false,
      rolloutPercentage: data['rolloutPercentage'] ?? 100,
      updatedAt: data['updatedAt']?.toDate(),
      updatedBy: data['updatedBy'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'enabled': enabled,
      'rolloutPercentage': rolloutPercentage,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'metadata': metadata,
    };
  }

  /// Create from JSON (for local cache)
  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      enabled: json['enabled'] ?? false,
      rolloutPercentage: json['rolloutPercentage'] ?? 100,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      updatedBy: json['updatedBy'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Convert to JSON (for local cache)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enabled': enabled,
      'rolloutPercentage': rolloutPercentage,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  FeatureFlag copyWith({
    String? id,
    String? name,
    String? description,
    bool? enabled,
    int? rolloutPercentage,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? metadata,
  }) {
    return FeatureFlag(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this feature is enabled for a specific user (based on rollout percentage)
  bool isEnabledForUser(String userId) {
    if (!enabled) return false;
    if (rolloutPercentage >= 100) return true;
    if (rolloutPercentage <= 0) return false;
    
    // Deterministic rollout based on user ID hash
    final hash = userId.hashCode.abs();
    final userPercentage = hash % 100;
    return userPercentage < rolloutPercentage;
  }

  @override
  String toString() {
    return 'FeatureFlag(id: $id, name: $name, enabled: $enabled, rollout: $rolloutPercentage%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureFlag &&
        other.id == id &&
        other.name == name &&
        other.enabled == enabled &&
        other.rolloutPercentage == rolloutPercentage;
  }

  @override
  int get hashCode => Object.hash(id, name, enabled, rolloutPercentage);
}

/// Predefined feature flag IDs for the application
class FeatureFlagIds {
  static const String enableAiChat = 'enable_ai_chat';
  static const String enableMarketplace = 'enable_marketplace';
  static const String enableEvents = 'enable_events';
  static const String enableGamification = 'enable_gamification';
  static const String enableWhatsapp = 'enable_whatsapp';
  static const String enableExperts = 'enable_experts';
  static const String enableSos = 'enable_sos';
  static const String enableDailyTips = 'enable_daily_tips';
  static const String enableMoodTracker = 'enable_mood_tracker';
  static const String enableAlbum = 'enable_album';
  static const String enableTracking = 'enable_tracking';
  static const String enableChat = 'enable_chat';

  /// Get all feature flag IDs
  static List<String> get all => [
    enableAiChat,
    enableMarketplace,
    enableEvents,
    enableGamification,
    enableWhatsapp,
    enableExperts,
    enableSos,
    enableDailyTips,
    enableMoodTracker,
    enableAlbum,
    enableTracking,
    enableChat,
  ];

  /// Get default feature flags configuration
  static Map<String, FeatureFlag> get defaults => {
    enableAiChat: FeatureFlag(
      id: enableAiChat,
      name: 'צ\'אט AI',
      description: 'מאפשר גישה לעוזרת AI חכמה',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableMarketplace: FeatureFlag(
      id: enableMarketplace,
      name: 'שוק יד שניה',
      description: 'מאפשר מסירות והחלפות בין משתמשות',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableEvents: FeatureFlag(
      id: enableEvents,
      name: 'אירועים',
      description: 'מאפשר צפייה ויצירת אירועים',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableGamification: FeatureFlag(
      id: enableGamification,
      name: 'גיימיפיקציה',
      description: 'מערכת נקודות ותגים',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableWhatsapp: FeatureFlag(
      id: enableWhatsapp,
      name: 'WhatsApp',
      description: 'קישור לקבוצת WhatsApp',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableExperts: FeatureFlag(
      id: enableExperts,
      name: 'מומחים',
      description: 'גישה למומחים וייעוץ מקצועי',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableSos: FeatureFlag(
      id: enableSos,
      name: 'SOS',
      description: 'כפתור חירום למצבי קריטיים',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableDailyTips: FeatureFlag(
      id: enableDailyTips,
      name: 'טיפים יומיים',
      description: 'הצגת טיפים ותוכן מקצועי',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableMoodTracker: FeatureFlag(
      id: enableMoodTracker,
      name: 'מד מצב רוח',
      description: 'מעקב אחר מצב הרוח',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableAlbum: FeatureFlag(
      id: enableAlbum,
      name: 'אלבום תמונות',
      description: 'אלבום תמונות אישי',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableTracking: FeatureFlag(
      id: enableTracking,
      name: 'מעקב התפתחות',
      description: 'מעקב אחר התפתחות הילד',
      enabled: true,
      rolloutPercentage: 100,
    ),
    enableChat: FeatureFlag(
      id: enableChat,
      name: 'צ\'אט',
      description: 'צ\'אט בין משתמשות',
      enabled: true,
      rolloutPercentage: 100,
    ),
  };
}
