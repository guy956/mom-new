import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Centralized App Configuration Provider
///
/// This is the single source of truth for all app configuration.
/// It listens to Firestore in real-time and broadcasts changes to all listeners.
/// All widgets should use this provider for dynamic content.
///
/// NOTE: Some fields here (feature flags, UI config, text overrides, app config,
/// announcement) overlap with [AppState], which retains them for backwards
/// compatibility. This class is the preferred source for dynamic configuration.
/// [AppState] should be used for user session, theme, and admin state management.
class AppConfigProvider extends ChangeNotifier {
  static final AppConfigProvider _instance = AppConfigProvider._internal();
  factory AppConfigProvider() => _instance;
  AppConfigProvider._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  // ════════════════════════════════════════════════════════════════
  //  CONFIG STATE
  // ════════════════════════════════════════════════════════════════

  /// Feature flags - controls which features are visible
  Map<String, bool> _featureFlags = {};
  Map<String, bool> get featureFlags => Map.unmodifiable(_featureFlags);
  bool isFeatureEnabled(String feature) => _featureFlags[feature] ?? true;

  /// UI Configuration - colors, menu order, categories
  Map<String, dynamic> _uiConfig = {};
  Map<String, dynamic> get uiConfig => Map.unmodifiable(_uiConfig);

  /// Text overrides - per-section text customizations
  Map<String, dynamic> _textOverrides = {};
  Map<String, dynamic> get textOverrides => Map.unmodifiable(_textOverrides);

  /// App configuration - branding, links, contacts
  Map<String, dynamic> _appConfig = {};
  Map<String, dynamic> get appConfig => Map.unmodifiable(_appConfig);

  /// Announcement banner
  Map<String, dynamic> _announcement = {'enabled': false, 'text': '', 'color': '#D1C2D3', 'link': ''};
  Map<String, dynamic> get announcement => Map.unmodifiable(_announcement);

  /// Dynamic sections - ordered content sections
  List<DynamicSectionConfig> _dynamicSections = [];
  List<DynamicSectionConfig> get dynamicSections => List.unmodifiable(_dynamicSections);
  List<DynamicSectionConfig> get activeSections => _dynamicSections.where((s) => s.isActive).toList();

  /// Loading state
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Error state
  String? _error;
  String? get error => _error;

  /// Last sync timestamp
  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  /// Is connected to Firestore
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ════════════════════════════════════════════════════════════════
  //  CONVENIENCE GETTERS
  // ════════════════════════════════════════════════════════════════

  // Colors
  String get primaryColor => _uiConfig['primaryColor']?.toString() ?? '#D4A1AC';
  String get secondaryColor => _uiConfig['secondaryColor']?.toString() ?? '#EDD3D8';
  String get accentColor => _uiConfig['accentColor']?.toString() ?? '#DBC8B0';
  String get backgroundColor => _uiConfig['backgroundColor']?.toString() ?? '#FFFFFF';
  String get textColor => _uiConfig['textColor']?.toString() ?? '#333333';

  // Navigation
  List<String> get menuOrder => List<String>.from(_uiConfig['menuOrder'] ?? ['בית', 'צ\'אט', 'קהילה', 'מומחים', 'פרופיל']);
  List<String> get bottomNavLabels => List<String>.from(_uiConfig['bottomNavLabels'] ?? ['בית', 'מעקב', 'אירועים', 'הודעות', 'פרופיל']);

  // Categories
  List<String> get expertCategories => List<String>.from(_uiConfig['expertCategories'] ?? []);
  List<String> get tipCategories => List<String>.from(_uiConfig['tipCategories'] ?? []);
  List<String> get marketplaceCategories => List<String>.from(_uiConfig['marketplaceCategories'] ?? []);

  // Quick access buttons
  List<Map<String, dynamic>> get quickAccessButtons {
    final raw = List<Map<String, dynamic>>.from(
      (_uiConfig['quickAccessButtons'] ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final filtered = raw.where((b) {
      if (b['enabled'] == false) return false;
      final key = b['key'] as String? ?? '';
      return isFeatureEnabled(key);
    }).toList();
    filtered.sort((a, b) => ((a['order'] as num?) ?? 99).compareTo((b['order'] as num?) ?? 99));
    return filtered;
  }

  // App info
  String get appName => _appConfig['appName']?.toString() ?? 'MOMIT';
  String get slogan => _appConfig['slogan']?.toString() ?? 'כי רק אמא מבינה אמא';
  String get welcomeTitle => _appConfig['welcomeTitle']?.toString() ?? 'ברוכה הבאה ל-MOMIT';
  String get welcomeSubtitle => _appConfig['welcomeSubtitle']?.toString() ?? 'הרשת החברתית לאמהות';

  // Links
  String get whatsappLink => _appConfig['whatsappLink']?.toString() ?? '';
  String get instagramLink => _appConfig['instagram']?.toString() ?? '';
  String get facebookLink => _appConfig['facebook']?.toString() ?? '';
  String get contactEmail => _appConfig['contactEmail']?.toString() ?? '';
  String get contactPhone => _appConfig['contactPhone']?.toString() ?? '';

  // Announcement
  bool get hasActiveAnnouncement => _announcement['enabled'] == true && (_announcement['text'] ?? '').toString().isNotEmpty;
  String get announcementText => _announcement['text']?.toString() ?? '';
  String get announcementColor => _announcement['color']?.toString() ?? '#D1C2D3';
  String get announcementLink => _announcement['link']?.toString() ?? '';

  // ════════════════════════════════════════════════════════════════
  //  STREAM SUBSCRIPTIONS
  // ════════════════════════════════════════════════════════════════

  // Only streams actually consumed by AppConfigProvider's UI consumers.
  // Feature flags, announcements, and dynamic sections are handled by AppState.
  StreamSubscription? _uiConfigSub;
  StreamSubscription? _textOverridesSub;
  StreamSubscription? _appConfigSub;

  // ════════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ════════════════════════════════════════════════════════════════

  /// Initialize the provider - call this in main.dart before runApp
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load cached data first (fast initial render)
    await _loadFromCache();
    
    _isLoading = false;
    _safeNotifyListeners();
    
    debugPrint('[AppConfigProvider] Initialized with cached data');
  }

  /// Connect to Firestore for real-time updates
  /// Call this after Firebase is initialized
  void connectToFirestore() {
    if (_isConnected) return;

    debugPrint('[AppConfigProvider] Connecting to Firestore...');

    // UI Config Stream (colors, layout settings)
    _uiConfigSub = _db.collection('admin_config').doc('ui_config').snapshots().listen(
      (snap) {
        if (snap.exists) {
          final data = Map<String, dynamic>.from(snap.data() ?? {});
          _updateUIConfig(data);
        }
      },
      onError: (e) => debugPrint('[AppConfigProvider] UI config error: $e'),
    );

    // Text Overrides Stream
    _textOverridesSub = _db.collection('admin_config').doc('text_overrides').snapshots().listen(
      (snap) {
        if (snap.exists) {
          final data = Map<String, dynamic>.from(snap.data() ?? {});
          _updateTextOverrides(data);
        }
      },
      onError: (e) => debugPrint('[AppConfigProvider] Text overrides error: $e'),
    );

    // App Config Stream
    _appConfigSub = _db.collection('admin_config').doc('app_config').snapshots().listen(
      (snap) {
        if (snap.exists) {
          final data = Map<String, dynamic>.from(snap.data() ?? {});
          _updateAppConfig(data);
        }
      },
      onError: (e) => debugPrint('[AppConfigProvider] App config error: $e'),
    );

    // Note: Feature flags, announcements, and dynamic sections are
    // handled exclusively by AppState to avoid duplicate Firestore listeners.

    _isConnected = true;
    debugPrint('[AppConfigProvider] Connected to Firestore real-time streams');
  }

  /// Disconnect from Firestore (call on logout)
  void disconnect() {
    _uiConfigSub?.cancel();
    _textOverridesSub?.cancel();
    _appConfigSub?.cancel();
    _isConnected = false;
    debugPrint('[AppConfigProvider] Disconnected from Firestore');
  }

  // ════════════════════════════════════════════════════════════════
  //  UPDATE METHODS (with caching)
  // ════════════════════════════════════════════════════════════════

  void _updateFeatureFlags(Map<String, dynamic> data) {
    final newFlags = <String, bool>{};
    for (final entry in data.entries) {
      if (entry.value is bool) {
        newFlags[entry.key] = entry.value;
      }
    }
    if (_featureFlags.toString() != newFlags.toString()) {
      _featureFlags = newFlags;
      _cacheData('feature_flags', data);
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] Feature flags updated');
    }
  }

  void _updateUIConfig(Map<String, dynamic> data) {
    data.remove('updatedAt');
    data.remove('createdAt');
    if (_uiConfig.toString() != data.toString()) {
      _uiConfig = data;
      _cacheData('ui_config', data);
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] UI config updated');
    }
  }

  void _updateTextOverrides(Map<String, dynamic> data) {
    data.remove('updatedAt');
    data.remove('createdAt');
    if (_textOverrides.toString() != data.toString()) {
      _textOverrides = data;
      _cacheData('text_overrides', data);
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] Text overrides updated');
    }
  }

  void _updateAppConfig(Map<String, dynamic> data) {
    data.remove('updatedAt');
    data.remove('createdAt');
    if (_appConfig.toString() != data.toString()) {
      _appConfig = data;
      _cacheData('app_config', data);
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] App config updated');
    }
  }

  void _updateAnnouncement(Map<String, dynamic> data) {
    data.remove('updatedAt');
    data.remove('createdAt');
    if (_announcement.toString() != data.toString()) {
      _announcement = data;
      _cacheData('announcement', data);
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] Announcement updated');
    }
  }

  void _updateDynamicSections(List<DynamicSectionConfig> sections) {
    if (_dynamicSections.length != sections.length ||
        _dynamicSections.toString() != sections.toString()) {
      _dynamicSections = sections;
      _cacheData('dynamic_sections', sections.map((s) => s.toMap()).toList());
      _lastSync = DateTime.now();
      _safeNotifyListeners();
      debugPrint('[AppConfigProvider] Dynamic sections updated (${sections.length})');
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  CACHING
  // ════════════════════════════════════════════════════════════════

  Future<void> _loadFromCache() async {
    try {
      // Feature Flags
      final flagsJson = _prefs?.getString('cache_feature_flags');
      if (flagsJson != null) {
        _featureFlags = Map<String, bool>.from(
          (jsonDecode(flagsJson) as Map).map((k, v) => MapEntry(k.toString(), v as bool)),
        );
      }

      // UI Config
      final uiJson = _prefs?.getString('cache_ui_config');
      if (uiJson != null) {
        _uiConfig = Map<String, dynamic>.from(jsonDecode(uiJson));
      }

      // Text Overrides
      final textJson = _prefs?.getString('cache_text_overrides');
      if (textJson != null) {
        _textOverrides = Map<String, dynamic>.from(jsonDecode(textJson));
      }

      // App Config
      final appJson = _prefs?.getString('cache_app_config');
      if (appJson != null) {
        _appConfig = Map<String, dynamic>.from(jsonDecode(appJson));
      }

      // Announcement
      final annJson = _prefs?.getString('cache_announcement');
      if (annJson != null) {
        _announcement = Map<String, dynamic>.from(jsonDecode(annJson));
      }

      // Dynamic Sections
      final sectionsJson = _prefs?.getString('cache_dynamic_sections');
      if (sectionsJson != null) {
        final sectionsList = jsonDecode(sectionsJson) as List;
        _dynamicSections = sectionsList
            .map((s) => DynamicSectionConfig.fromMap(Map<String, dynamic>.from(s)))
            .toList();
      }

      debugPrint('[AppConfigProvider] Loaded from cache');
    } catch (e) {
      debugPrint('[AppConfigProvider] Cache load error: $e');
    }
  }

  Future<void> _cacheData(String key, dynamic data) async {
    try {
      await _prefs?.setString('cache_$key', jsonEncode(data));
    } catch (e) {
      debugPrint('[AppConfigProvider] Cache save error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  TEXT RESOLUTION
  // ════════════════════════════════════════════════════════════════

  /// Get text with fallback - checks overrides first, then returns fallback
  String getText(String section, String key, {String fallback = ''}) {
    final sectionOverrides = _textOverrides[section];
    if (sectionOverrides is Map) {
      final value = sectionOverrides[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  /// Get text for a specific screen
  String getScreenText(String screen, String key, {String fallback = ''}) {
    return getText(screen, key, fallback: fallback);
  }

  // ════════════════════════════════════════════════════════════════
  //  CLEANUP
  // ════════════════════════════════════════════════════════════════

  /// Check if provider is disposed (to prevent setState after dispose)
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    _prefs = null;
    super.dispose();
  }

  /// Safe notify listeners that checks disposed state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  DYNAMIC SECTION CONFIG MODEL
// ════════════════════════════════════════════════════════════════

class DynamicSectionConfig {
  final String id;
  final String key;
  final String name;
  final String description;
  final String type;
  final String iconName;
  final String route;
  final int order;
  final bool isActive;
  final Map<String, dynamic> settings;

  const DynamicSectionConfig({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.iconName,
    required this.route,
    required this.order,
    required this.isActive,
    required this.settings,
  });

  factory DynamicSectionConfig.fromFirestore(String id, Map<String, dynamic> data) {
    return DynamicSectionConfig(
      id: id,
      key: data['key']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      type: data['type']?.toString() ?? 'custom',
      iconName: data['iconName']?.toString() ?? 'dashboard_customize',
      route: data['route']?.toString() ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  factory DynamicSectionConfig.fromMap(Map<String, dynamic> map) {
    return DynamicSectionConfig(
      id: map['id']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? 'custom',
      iconName: map['iconName']?.toString() ?? 'dashboard_customize',
      route: map['route']?.toString() ?? '',
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'key': key,
    'name': name,
    'description': description,
    'type': type,
    'iconName': iconName,
    'route': route,
    'order': order,
    'isActive': isActive,
    'settings': settings,
  };

  @override
  String toString() => 'DynamicSectionConfig($key: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicSectionConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          key == other.key;

  @override
  int get hashCode => id.hashCode ^ key.hashCode;
}
