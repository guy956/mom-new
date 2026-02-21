import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Branding configuration model - holds all dynamic branding assets
class BrandingConfig {
  final String appName;
  final String appNameEnglish;
  final String slogan;
  final String tagline;
  final String? logoUrl;
  final String? splashImageUrl;
  final String? appIconUrl;
  final Color? primaryColor;
  final Color? secondaryColor;
  final DateTime? updatedAt;

  BrandingConfig({
    required this.appName,
    required this.appNameEnglish,
    required this.slogan,
    required this.tagline,
    this.logoUrl,
    this.splashImageUrl,
    this.appIconUrl,
    this.primaryColor,
    this.secondaryColor,
    this.updatedAt,
  });

  factory BrandingConfig.fromMap(Map<String, dynamic> map) {
    Color? parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return null;
      try {
        final cleanHex = hex.replaceAll('#', '');
        return Color(int.parse(cleanHex.length == 6 ? 'FF$cleanHex' : cleanHex, radix: 16));
      } catch (_) {
        return null;
      }
    }

    return BrandingConfig(
      appName: map['appName'] ?? 'MOMIT',
      appNameEnglish: map['appNameEnglish'] ?? 'MOMIT',
      slogan: map['slogan'] ?? 'כי רק אמא מבינה אמא',
      tagline: map['tagline'] ?? '',
      logoUrl: map['logoUrl'],
      splashImageUrl: map['splashImageUrl'],
      appIconUrl: map['appIconUrl'],
      primaryColor: parseColor(map['primaryColor']?.toString()),
      secondaryColor: parseColor(map['secondaryColor']?.toString()),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'appName': appName,
    'appNameEnglish': appNameEnglish,
    'slogan': slogan,
    'tagline': tagline,
    'logoUrl': logoUrl,
    'splashImageUrl': splashImageUrl,
    'appIconUrl': appIconUrl,
    'primaryColor': primaryColor?.toARGB32().toRadixString(16).substring(2),
    'secondaryColor': secondaryColor?.toARGB32().toRadixString(16).substring(2),
  };

  factory BrandingConfig.defaultConfig() => BrandingConfig(
    appName: 'MOMIT',
    appNameEnglish: 'MOMIT',
    slogan: 'כי רק אמא מבינה אמא',
    tagline: 'רשת חברתית לאמהות',
  );

  BrandingConfig copyWith({
    String? appName,
    String? appNameEnglish,
    String? slogan,
    String? tagline,
    String? logoUrl,
    String? splashImageUrl,
    String? appIconUrl,
    Color? primaryColor,
    Color? secondaryColor,
    DateTime? updatedAt,
  }) => BrandingConfig(
    appName: appName ?? this.appName,
    appNameEnglish: appNameEnglish ?? this.appNameEnglish,
    slogan: slogan ?? this.slogan,
    tagline: tagline ?? this.tagline,
    logoUrl: logoUrl ?? this.logoUrl,
    splashImageUrl: splashImageUrl ?? this.splashImageUrl,
    appIconUrl: appIconUrl ?? this.appIconUrl,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Service for managing dynamic branding configuration
/// Handles real-time updates from Firestore and local caching
class BrandingConfigService extends ChangeNotifier {
  static final BrandingConfigService _instance = BrandingConfigService._internal();
  static BrandingConfigService get instance => _instance;

  BrandingConfigService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  
  // Current branding config
  BrandingConfig _config = BrandingConfig.defaultConfig();
  BrandingConfig get config => _config;
  
  // Stream controller for branding updates
  final _brandingController = StreamController<BrandingConfig>.broadcast();
  Stream<BrandingConfig> get brandingStream => _brandingController.stream;

  // Firestore subscription
  StreamSubscription<DocumentSnapshot>? _brandingSub;

  // Cached file paths (native only, not used on web)
  String? _cachedLogoPath;
  String? _cachedSplashPath;
  String? get cachedLogoPath => _cachedLogoPath;
  String? get cachedSplashPath => _cachedSplashPath;

  static const String _brandingKey = 'momit_branding_config';
  static const String _brandingCacheTimeKey = 'momit_branding_cache_time';
  static const String _cachedLogoUrlKey = 'momit_cached_logo_url';
  static const String _cachedSplashUrlKey = 'momit_cached_splash_url';

  bool _isDisposed = false;
  bool _isInitializing = false;
  bool get isDisposed => _isDisposed;
  bool get isInitializing => _isInitializing;

  /// Initialize the service - load from cache and connect to Firestore
  /// 
  /// This method is safe to call multiple times - it will only run once.
  Future<void> initialize() async {
    if (_isInitializing || (_prefs != null && _isConnected)) {
      debugPrint('[BrandingConfigService] Already initialized, skipping');
      return;
    }
    
    _isInitializing = true;
    
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      // Load cached branding
      await _loadCachedBranding();
      
      // Connect to Firestore for real-time updates
      connectToFirestore();
      
      debugPrint('[BrandingConfigService] Initialized with appName: ${_config.appName}');
    } catch (e, stackTrace) {
      debugPrint('[BrandingConfigService] Initialization error: $e');
      debugPrint('[BrandingConfigService] Stack trace: $stackTrace');
      // Continue with default config
    } finally {
      _isInitializing = false;
    }
  }

  /// Load branding from local cache
  Future<void> _loadCachedBranding() async {
    final json = _prefs?.getString(_brandingKey);
    if (json != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(json));
        _config = BrandingConfig.fromMap(map);
        
        // Load cached file paths
        _cachedLogoPath = _prefs?.getString('momit_logo_path');
        _cachedSplashPath = _prefs?.getString('momit_splash_path');
        
        notifyListeners();
        debugPrint('[BrandingConfigService] Loaded cached branding: ${_config.appName}');
      } catch (e) {
        debugPrint('[BrandingConfigService] Error loading cached branding: $e');
      }
    }
  }

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connect to Firestore for real-time branding updates
  void connectToFirestore() {
    if (_isConnected) {
      debugPrint('[BrandingConfigService] Already connected to Firestore');
      return;
    }

    _brandingSub?.cancel();
    _brandingSub = _db.collection('app_config').doc('branding').snapshots().listen(
      (snapshot) async {
        if (_isDisposed) return;
        
        try {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final newConfig = BrandingConfig.fromMap(data);
            
            // Check if app name changed
            final nameChanged = _config.appName != newConfig.appName;
            final logoChanged = _config.logoUrl != newConfig.logoUrl;
            final splashChanged = _config.splashImageUrl != newConfig.splashImageUrl;
            
            _config = newConfig;
            
            // Cache the config
            await _cacheBrandingConfig();
            
            // Download and cache new images if changed
            if (logoChanged && newConfig.logoUrl != null) {
              await _cacheImage(newConfig.logoUrl!, 'logo');
            }
            if (splashChanged && newConfig.splashImageUrl != null) {
              await _cacheImage(newConfig.splashImageUrl!, 'splash');
            }
            
            if (!_isDisposed) {
              _brandingController.add(_config);
              notifyListeners();
            }
            
            if (nameChanged) {
              debugPrint('[BrandingConfigService] App name updated to: ${_config.appName}');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('[BrandingConfigService] Error processing branding update: $e');
          debugPrint('[BrandingConfigService] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[BrandingConfigService] Firestore stream error: $e');
        debugPrint('[BrandingConfigService] Stack trace: $stackTrace');
        // Firestore SDK will handle reconnection automatically
      },
      onDone: () {
        debugPrint('[BrandingConfigService] Firestore stream closed');
        _isConnected = false;
      },
    );
    
    _isConnected = true;
  }

  /// Cache branding config to SharedPreferences
  Future<void> _cacheBrandingConfig() async {
    try {
      await _prefs?.setString(_brandingKey, jsonEncode(_config.toMap()));
      await _prefs?.setInt(_brandingCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[BrandingConfigService] Error caching branding: $e');
    }
  }

  /// Cache image URL for later use (stores URL only, no file download on web)
  Future<void> _cacheImage(String url, String type) async {
    if (kIsWeb) return; // Skip file caching on web
    try {
      final cachedUrlKey = type == 'logo' ? _cachedLogoUrlKey : _cachedSplashUrlKey;
      await _prefs?.setString(cachedUrlKey, url);
      debugPrint('[BrandingConfigService] Cached $type image URL');
    } catch (e) {
      debugPrint('[BrandingConfigService] Error caching $type image: $e');
    }
  }

  /// Get cached logo URL if available
  String? getCachedLogoUrl() {
    return _prefs?.getString(_cachedLogoUrlKey) ?? _config.logoUrl;
  }

  /// Get cached splash URL if available
  String? getCachedSplashUrl() {
    return _prefs?.getString(_cachedSplashUrlKey) ?? _config.splashImageUrl;
  }

  /// Update branding config (for admin)
  Future<void> updateBranding(BrandingConfig config) async {
    await _db.collection('app_config').doc('branding').set({
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update just the app name
  Future<void> updateAppName(String appName) async {
    await _db.collection('app_config').doc('branding').set({
      'appName': appName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update logo URL
  Future<void> updateLogoUrl(String? url) async {
    await _db.collection('app_config').doc('branding').set({
      'logoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update splash image URL
  Future<void> updateSplashImageUrl(String? url) async {
    await _db.collection('app_config').doc('branding').set({
      'splashImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Clear all cached branding data
  Future<void> clearCachedImages() async {
    try {
      _cachedLogoPath = null;
      _cachedSplashPath = null;
      await _prefs?.remove('momit_logo_path');
      await _prefs?.remove('momit_splash_path');
      await _prefs?.remove(_cachedLogoUrlKey);
      await _prefs?.remove(_cachedSplashUrlKey);
      debugPrint('[BrandingConfigService] Cleared all cached branding data');
    } catch (e) {
      debugPrint('[BrandingConfigService] Error clearing cached data: $e');
    }
  }

  /// Dispose resources
  /// 
  /// Call this when the service is no longer needed.
  /// After disposal, the service cannot be used again.
  @override
  void dispose() {
    _isDisposed = true;
    _isConnected = false;
    _brandingSub?.cancel();
    _brandingSub = null;
    if (!_brandingController.isClosed) {
      _brandingController.close();
    }
    _prefs = null;
    super.dispose();
  }
}
