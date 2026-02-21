import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mom_connect/models/feature_flag_model.dart';

/// Service for managing feature flags
/// 
/// Provides:
/// - Loading feature flags from Firestore
/// - Caching flags locally
/// - Real-time updates
/// - Checking if features are enabled
class FeatureFlagService extends ChangeNotifier {
  static const String _featureFlagsCollection = 'feature_flags';
  static const String _cacheKey = 'momit_feature_flags_cache';
  static const String _cacheTimestampKey = 'momit_feature_flags_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  // Singleton pattern
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  static FeatureFlagService get instance => _instance;
  
  factory FeatureFlagService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  
  // Feature flags storage
  Map<String, FeatureFlag> _flags = {};
  Map<String, FeatureFlag> get flags => Map.unmodifiable(_flags);
  
  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _flagsSubscription;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error state
  String? _error;
  String? get error => _error;
  
  // Last sync time
  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;
  
  // Stream controller for flag changes
  final _flagChangesController = StreamController<Map<String, FeatureFlag>>.broadcast();
  Stream<Map<String, FeatureFlag>> get flagChanges => _flagChangesController.stream;

  FeatureFlagService._internal() {
    _initializeDefaults();
  }

  /// Initialize with default feature flags
  void _initializeDefaults() {
    _flags = Map<String, FeatureFlag>.from(FeatureFlagIds.defaults);
  }

  /// Initialize the service and load cached flags
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load cached flags first (fast)
      await _loadCachedFlags();
      
      // Check if cache is still valid
      if (_isCacheValid()) {
        debugPrint('[FeatureFlagService] Using cached feature flags');
      } else {
        debugPrint('[FeatureFlagService] Cache expired, will fetch from Firestore');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize feature flags: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('[FeatureFlagService] Error: $_error');
    }
  }

  /// Load feature flags from local cache
  Future<void> _loadCachedFlags() async {
    try {
      final cachedJson = _prefs?.getString(_cacheKey);
      if (cachedJson != null) {
        final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedFlags = <String, FeatureFlag>{};
        
        cachedData.forEach((key, value) {
          try {
            cachedFlags[key] = FeatureFlag.fromJson(value as Map<String, dynamic>);
          } catch (e) {
            debugPrint('[FeatureFlagService] Error parsing cached flag $key: $e');
          }
        });
        
        // Merge with defaults to ensure all flags exist
        _flags = {...FeatureFlagIds.defaults, ...cachedFlags};
        
        // Load last sync time
        final timestampStr = _prefs?.getString(_cacheTimestampKey);
        if (timestampStr != null) {
          _lastSync = DateTime.tryParse(timestampStr);
        }
        
        _flagChangesController.add(Map.unmodifiable(_flags));
        debugPrint('[FeatureFlagService] Loaded ${_flags.length} flags from cache');
      }
    } catch (e) {
      debugPrint('[FeatureFlagService] Error loading cache: $e');
    }
  }

  /// Save feature flags to local cache
  Future<void> _saveToCache() async {
    try {
      final data = _flags.map((key, flag) => MapEntry(key, flag.toJson()));
      await _prefs?.setString(_cacheKey, jsonEncode(data));
      await _prefs?.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      _lastSync = DateTime.now();
    } catch (e) {
      debugPrint('[FeatureFlagService] Error saving cache: $e');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastSync == null) return false;
    final age = DateTime.now().difference(_lastSync!);
    return age < _cacheValidityDuration;
  }

  /// Fetch feature flags from Firestore (one-time)
  Future<void> fetchFlags() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _db.collection(_featureFlagsCollection).get();
      
      final fetchedFlags = <String, FeatureFlag>{};
      for (final doc in snapshot.docs) {
        try {
          final flag = FeatureFlag.fromFirestore(doc.id, doc.data());
          fetchedFlags[doc.id] = flag;
        } catch (e) {
          debugPrint('[FeatureFlagService] Error parsing flag ${doc.id}: $e');
        }
      }
      
      // Merge with defaults to ensure all flags exist
      _flags = {...FeatureFlagIds.defaults, ...fetchedFlags};
      
      await _saveToCache();
      _flagChangesController.add(Map.unmodifiable(_flags));
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('[FeatureFlagService] Fetched ${_flags.length} flags from Firestore');
    } catch (e) {
      _error = 'Failed to fetch feature flags: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('[FeatureFlagService] Error: $_error');
    }
  }

  /// Enable real-time updates from Firestore
  void enableRealtimeUpdates() {
    _flagsSubscription?.cancel();
    
    _flagsSubscription = _db
        .collection(_featureFlagsCollection)
        .snapshots()
        .listen(
          (snapshot) {
            final updatedFlags = <String, FeatureFlag>{};
            
            for (final change in snapshot.docChanges) {
              final doc = change.doc;
              if (change.type == DocumentChangeType.removed) {
                _flags.remove(doc.id);
                debugPrint('[FeatureFlagService] Flag removed: ${doc.id}');
              } else {
                try {
                  final data = doc.data();
                  if (data != null) {
                    final flag = FeatureFlag.fromFirestore(doc.id, data);
                    updatedFlags[doc.id] = flag;
                    debugPrint('[FeatureFlagService] Flag updated: ${doc.id} = ${flag.enabled}');
                  }
                } catch (e) {
                  debugPrint('[FeatureFlagService] Error parsing flag ${doc.id}: $e');
                }
              }
            }
            
            if (updatedFlags.isNotEmpty) {
              _flags = {..._flags, ...updatedFlags};
              _saveToCache();
              _flagChangesController.add(Map.unmodifiable(_flags));
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint('[FeatureFlagService] Real-time updates error: $e');
            _error = 'Real-time updates error: $e';
            notifyListeners();
          },
        );
    
    debugPrint('[FeatureFlagService] Real-time updates enabled');
  }

  /// Disable real-time updates
  void disableRealtimeUpdates() {
    _flagsSubscription?.cancel();
    _flagsSubscription = null;
    debugPrint('[FeatureFlagService] Real-time updates disabled');
  }

  /// Check if a feature is enabled (global check)
  bool isEnabled(String flagId) {
    final flag = _flags[flagId];
    if (flag == null) {
      // Return default value if flag not found
      final defaultFlag = FeatureFlagIds.defaults[flagId];
      return defaultFlag?.enabled ?? false;
    }
    return flag.enabled;
  }

  /// Check if a feature is enabled for a specific user (with rollout percentage)
  bool isEnabledForUser(String flagId, String userId) {
    final flag = _flags[flagId];
    if (flag == null) {
      final defaultFlag = FeatureFlagIds.defaults[flagId];
      return defaultFlag?.isEnabledForUser(userId) ?? false;
    }
    return flag.isEnabledForUser(userId);
  }

  /// Get a specific feature flag
  FeatureFlag? getFlag(String flagId) {
    return _flags[flagId] ?? FeatureFlagIds.defaults[flagId];
  }

  /// Get all enabled feature flags
  List<FeatureFlag> get enabledFlags {
    return _flags.values.where((f) => f.enabled).toList();
  }

  /// Get all disabled feature flags
  List<FeatureFlag> get disabledFlags {
    return _flags.values.where((f) => !f.enabled).toList();
  }

  /// Update a feature flag (admin only)
  Future<void> updateFlag(String flagId, {bool? enabled, int? rolloutPercentage}) async {
    try {
      final existingFlag = _flags[flagId];
      if (existingFlag == null && !FeatureFlagIds.defaults.containsKey(flagId)) {
        throw Exception('Feature flag $flagId does not exist');
      }

      final updatedFlag = (existingFlag ?? FeatureFlagIds.defaults[flagId]!).copyWith(
        enabled: enabled,
        rolloutPercentage: rolloutPercentage,
        updatedAt: DateTime.now(),
      );

      await _db.collection(_featureFlagsCollection).doc(flagId).set(
        updatedFlag.toFirestore(),
        SetOptions(merge: true),
      );

      _flags[flagId] = updatedFlag;
      await _saveToCache();
      notifyListeners();
      
      debugPrint('[FeatureFlagService] Updated flag $flagId: enabled=${updatedFlag.enabled}');
    } catch (e) {
      debugPrint('[FeatureFlagService] Error updating flag: $e');
      rethrow;
    }
  }

  /// Toggle a feature flag on/off (admin only)
  Future<void> toggleFlag(String flagId) async {
    final currentValue = isEnabled(flagId);
    await updateFlag(flagId, enabled: !currentValue);
  }

  /// Set multiple feature flags at once (admin only)
  Future<void> updateMultipleFlags(Map<String, bool> flagStates) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final entry in flagStates.entries) {
      final flagId = entry.key;
      final enabled = entry.value;
      
      final existingFlag = _flags[flagId] ?? FeatureFlagIds.defaults[flagId];
      if (existingFlag != null) {
        final updatedFlag = existingFlag.copyWith(
          enabled: enabled,
          updatedAt: now,
        );
        
        final ref = _db.collection(_featureFlagsCollection).doc(flagId);
        batch.set(ref, updatedFlag.toFirestore(), SetOptions(merge: true));
        _flags[flagId] = updatedFlag;
      }
    }

    await batch.commit();
    await _saveToCache();
    _flagChangesController.add(Map.unmodifiable(_flags));
    notifyListeners();
    
    debugPrint('[FeatureFlagService] Updated ${flagStates.length} flags');
  }

  /// Reset all feature flags to defaults (admin only)
  Future<void> resetToDefaults() async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final entry in FeatureFlagIds.defaults.entries) {
      final flag = entry.value.copyWith(updatedAt: now);
      final ref = _db.collection(_featureFlagsCollection).doc(entry.key);
      batch.set(ref, flag.toFirestore());
      _flags[entry.key] = flag;
    }

    await batch.commit();
    await _saveToCache();
    _flagChangesController.add(Map.unmodifiable(_flags));
    notifyListeners();
    
    debugPrint('[FeatureFlagService] Reset all flags to defaults');
  }

  /// Seed initial feature flags to Firestore (call once during setup)
  Future<void> seedInitialFlags() async {
    try {
      final existing = await _db.collection(_featureFlagsCollection).limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('[FeatureFlagService] Feature flags already seeded');
        return;
      }

      final batch = _db.batch();
      final now = DateTime.now();

      for (final entry in FeatureFlagIds.defaults.entries) {
        final flag = entry.value.copyWith(
          updatedAt: now,
          updatedBy: 'system',
        );
        final ref = _db.collection(_featureFlagsCollection).doc(entry.key);
        batch.set(ref, flag.toFirestore());
      }

      await batch.commit();
      debugPrint('[FeatureFlagService] Seeded ${FeatureFlagIds.defaults.length} initial flags');
    } catch (e) {
      debugPrint('[FeatureFlagService] Error seeding flags: $e');
    }
  }

  /// Clear local cache
  Future<void> clearCache() async {
    await _prefs?.remove(_cacheKey);
    await _prefs?.remove(_cacheTimestampKey);
    _lastSync = null;
    _initializeDefaults();
    notifyListeners();
    debugPrint('[FeatureFlagService] Cache cleared');
  }

  /// Refresh feature flags from Firestore
  Future<void> refresh() async {
    await fetchFlags();
  }

  /// Dispose resources
  @override
  void dispose() {
    disableRealtimeUpdates();
    _flagChangesController.close();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  CONVENIENCE METHODS FOR SPECIFIC FEATURES
  // ════════════════════════════════════════════════════════════════

  /// Check if AI Chat is enabled
  bool get isAiChatEnabled => isEnabled(FeatureFlagIds.enableAiChat);
  
  /// Check if Marketplace is enabled
  bool get isMarketplaceEnabled => isEnabled(FeatureFlagIds.enableMarketplace);
  
  /// Check if Events is enabled
  bool get isEventsEnabled => isEnabled(FeatureFlagIds.enableEvents);
  
  /// Check if Gamification is enabled
  bool get isGamificationEnabled => isEnabled(FeatureFlagIds.enableGamification);
  
  /// Check if WhatsApp is enabled
  bool get isWhatsappEnabled => isEnabled(FeatureFlagIds.enableWhatsapp);
  
  /// Check if Experts is enabled
  bool get isExpertsEnabled => isEnabled(FeatureFlagIds.enableExperts);
  
  /// Check if SOS is enabled
  bool get isSosEnabled => isEnabled(FeatureFlagIds.enableSos);
  
  /// Check if Daily Tips is enabled
  bool get isDailyTipsEnabled => isEnabled(FeatureFlagIds.enableDailyTips);
  
  /// Check if Mood Tracker is enabled
  bool get isMoodTrackerEnabled => isEnabled(FeatureFlagIds.enableMoodTracker);
  
  /// Check if Album is enabled
  bool get isAlbumEnabled => isEnabled(FeatureFlagIds.enableAlbum);
  
  /// Check if Tracking is enabled
  bool get isTrackingEnabled => isEnabled(FeatureFlagIds.enableTracking);
  
  /// Check if Chat is enabled
  bool get isChatEnabled => isEnabled(FeatureFlagIds.enableChat);
}
