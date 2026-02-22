import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mom_connect/models/user_model.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/branding_config_service.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/core/constants/color_config.dart';

/// Global app state with full user data persistence and Firestore real-time sync.
class AppState extends ChangeNotifier {
  static const String _themeKey = 'momit_theme_mode';
  static const String _userDataKey = 'momit_user_data';
  static const String _notifCountKey = 'momit_notif_count';
  static const String _msgCountKey = 'momit_msg_count';
  static const String _loginHistoryKey = 'momit_login_history';
  static const String _featureFlagsKey = 'momit_feature_flags';
  static const String _appConfigKey = 'momit_app_config';
  static const String _announcementKey = 'momit_announcement';
  static const String _uiConfigKey = 'momit_ui_config';
  static const String _textOverridesKey = 'momit_text_overrides';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Feature flags - controls which features are visible to users
  Map<String, bool> _featureFlags = {
    'chat': true, 'events': true, 'marketplace': true, 'experts': true,
    'tips': true, 'mood': true, 'sos': true, 'gamification': true,
    'aiChat': true, 'whatsapp': true, 'album': true, 'tracking': true,
  };
  Map<String, bool> get featureFlags => Map.unmodifiable(_featureFlags);
  bool isFeatureEnabled(String feature) => _featureFlags[feature] ?? true;

  // App config - branding, links, contacts
  Map<String, dynamic> _appConfig = {};
  Map<String, dynamic> get appConfig => Map.unmodifiable(_appConfig);
  dynamic getConfig(String key) => _appConfig[key];

  // Announcement banner
  Map<String, dynamic> _announcement = {'enabled': false, 'text': '', 'color': '#D1C2D3', 'link': ''};
  Map<String, dynamic> get announcement => Map.unmodifiable(_announcement);
  bool get hasActiveAnnouncement => _announcement['enabled'] == true && (_announcement['text'] ?? '').toString().isNotEmpty;

  // UI Config - colors, menu order, categories (synced from Firestore)
  Map<String, dynamic> _uiConfig = {};
  Map<String, dynamic> get uiConfig => Map.unmodifiable(_uiConfig);

  // Text overrides - per-section text override maps (synced from Firestore)
  Map<String, dynamic> _textOverrides = {};
  Map<String, dynamic> get textOverrides => Map.unmodifiable(_textOverrides);
  String get primaryColor => (_uiConfig['primaryColor'] ?? '#D4A1AC').toString();
  String get secondaryColor => (_uiConfig['secondaryColor'] ?? '#EDD3D8').toString();
  String get accentColor => (_uiConfig['accentColor'] ?? '#DBC8B0').toString();
  List<String> get menuOrder => List<String>.from(_uiConfig['menuOrder'] ?? ['בית', 'צ\'אט', 'קהילה', 'מומחים', 'פרופיל']);
  List<String> get expertCategories => List<String>.from(_uiConfig['expertCategories'] ?? []);
  List<String> get tipCategories => List<String>.from(_uiConfig['tipCategories'] ?? []);
  List<String> get marketplaceCategories => List<String>.from(_uiConfig['marketplaceCategories'] ?? []);

  // ── Navigation config getters ──

  /// Bottom nav label for the given tab index (0-4).
  String bottomNavLabel(int index) {
    final labels = List<String>.from(_uiConfig['bottomNavLabels'] ?? ['בית', 'מעקב', 'אירועים', 'הודעות', 'פרופיל']);
    if (index >= 0 && index < labels.length) return labels[index];
    return '';
  }

  /// All bottom nav labels list (for admin editor).
  List<String> get bottomNavLabels =>
      List<String>.from(_uiConfig['bottomNavLabels'] ?? ['בית', 'מעקב', 'אירועים', 'הודעות', 'פרופיל']);

  /// Quick access buttons filtered by feature flags and sorted by order.
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

  /// All quick access buttons unfiltered (for admin editor).
  List<Map<String, dynamic>> get allQuickAccessButtons {
    return List<Map<String, dynamic>>.from(
      (_uiConfig['quickAccessButtons'] ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// Drawer label for a feature key.
  String drawerLabel(String featureKey) {
    final labels = Map<String, dynamic>.from(_uiConfig['drawerLabels'] ?? {});
    return (labels[featureKey] ?? featureKey).toString();
  }

  /// Full drawer labels map (for admin editor).
  Map<String, String> get drawerLabels {
    final raw = Map<String, dynamic>.from(_uiConfig['drawerLabels'] ?? {});
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => AuthService.isAdminEmail(_currentUser?.email ?? '');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  int _messageCount = 0;
  int get messageCount => _messageCount;

  // Login history for analytics
  List<Map<String, dynamic>> _loginHistory = [];
  List<Map<String, dynamic>> get loginHistory => _loginHistory;

  // Pending approvals for admin
  final List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> get pendingApprovals => _pendingApprovals;

  SharedPreferences? _prefs;

  // Firestore subscriptions
  StreamSubscription? _featureFlagsSub;
  StreamSubscription? _appConfigSub;
  StreamSubscription? _announcementSub;
  StreamSubscription? _uiConfigSub;
  StreamSubscription? _textOverridesSub;

  // Branding service
  BrandingConfigService get brandingService => BrandingConfigService.instance;

  /// Initialize state from persistent storage (fast, local cache)
  /// 
  /// This method loads all cached data from SharedPreferences and
  /// initializes related services. It is safe to call multiple times.
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize branding service and connect to TextConfig
      await brandingService.initialize();
      TextConfig.initialize(brandingService);

    // Restore theme
    final themeIndex = _prefs?.getInt(_themeKey) ?? 0;
    _themeMode = themeIndex == 1 ? ThemeMode.dark : ThemeMode.light;

    // Restore notification and message counts
    _notificationCount = _prefs?.getInt(_notifCountKey) ?? 0;
    _messageCount = _prefs?.getInt(_msgCountKey) ?? 0;

    // Restore login history
    final historyJson = _prefs?.getString(_loginHistoryKey);
    if (historyJson != null) {
      try {
        _loginHistory = List<Map<String, dynamic>>.from(
          (jsonDecode(historyJson) as List).map((e) => Map<String, dynamic>.from(e))
        );
      } catch (_) {
        _loginHistory = [];
      }
    }

    // Restore user data
    final userJson = _prefs?.getString(_userDataKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        _currentUser = null;
      }
    }

    // Restore feature flags (from cache, will be overridden by Firestore)
    final flagsJson = _prefs?.getString(_featureFlagsKey);
    if (flagsJson != null) {
      try {
        _featureFlags = Map<String, bool>.from(
          (jsonDecode(flagsJson) as Map).map((k, v) => MapEntry(k.toString(), v as bool))
        );
      } catch (_) {}
    }

    // Restore app config (from cache)
    final configJson = _prefs?.getString(_appConfigKey);
    if (configJson != null) {
      try {
        _appConfig = Map<String, dynamic>.from(jsonDecode(configJson));
      } catch (_) {}
    }

    // Restore announcement (from cache)
    final annJson = _prefs?.getString(_announcementKey);
    if (annJson != null) {
      try {
        _announcement = Map<String, dynamic>.from(jsonDecode(annJson));
      } catch (_) {}
    }

    // Restore UI config (from cache)
    final uiJson = _prefs?.getString(_uiConfigKey);
    if (uiJson != null) {
      try {
        _uiConfig = Map<String, dynamic>.from(jsonDecode(uiJson));
      } catch (_) {}
    }

    // Restore text overrides (from cache)
    final textJson = _prefs?.getString(_textOverridesKey);
    if (textJson != null) {
      try {
        _textOverrides = Map<String, dynamic>.from(jsonDecode(textJson));
      } catch (_) {}
    }

    // Bridge cached values to config classes
    TextConfig.updateOverrides(_textOverrides);
    ColorConfig.updateOverrides(_uiConfig);

    notifyListeners();
    debugPrint('[AppState] Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('[AppState] Error during initialization: $e');
      debugPrint('[AppState] Stack trace: $stackTrace');
      // Continue with defaults - don't crash the app
    }
  }

  /// Connect to Firestore for real-time config sync.
  /// Call this after Firebase is initialized and FirestoreService is ready.
  /// 
  /// Streams are handled with error handling and automatic reconnection
  /// is managed by Firestore SDK.
  void connectToFirestore(FirestoreService fs) {
    // Disconnect any existing streams first
    disconnectFirestore();
    
    debugPrint('[AppState] Connecting to Firestore real-time streams...');
    
    // Listen to feature flags
    _featureFlagsSub = fs.featureFlagsStream.listen(
      (flags) {
        try {
          _featureFlags = Map<String, bool>.from(flags);
          _prefs?.setString(_featureFlagsKey, jsonEncode(_featureFlags));
          notifyListeners();
          debugPrint('[AppState] Feature flags updated: ${_featureFlags.length} flags');
        } catch (e, stackTrace) {
          debugPrint('[AppState] Error processing feature flags: $e');
          debugPrint('[AppState] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[AppState] Feature flags stream error: $e');
        debugPrint('[AppState] Stack trace: $stackTrace');
        // Don't rethrow - let Firestore SDK handle reconnection
      },
      onDone: () {
        debugPrint('[AppState] Feature flags stream closed');
      },
    );

    // Listen to app config
    _appConfigSub = fs.appConfigStream.listen(
      (config) {
        try {
          final clean = Map<String, dynamic>.from(config);
          clean.remove('updatedAt');
          clean.remove('createdAt');
          _appConfig = clean;
          _prefs?.setString(_appConfigKey, jsonEncode(_appConfig));
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('[AppState] Error processing app config: $e');
          debugPrint('[AppState] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[AppState] App config stream error: $e');
        debugPrint('[AppState] Stack trace: $stackTrace');
      },
      onDone: () => debugPrint('[AppState] App config stream closed'),
    );

    // Listen to announcement
    _announcementSub = fs.announcementStream.listen(
      (ann) {
        try {
          final clean = Map<String, dynamic>.from(ann);
          clean.remove('updatedAt');
          clean.remove('createdAt');
          _announcement = clean;
          _prefs?.setString(_announcementKey, jsonEncode(_announcement));
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('[AppState] Error processing announcement: $e');
          debugPrint('[AppState] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[AppState] Announcement stream error: $e');
        debugPrint('[AppState] Stack trace: $stackTrace');
      },
      onDone: () => debugPrint('[AppState] Announcement stream closed'),
    );

    // Listen to UI config
    _uiConfigSub = fs.uiConfigStream.listen(
      (config) {
        try {
          final clean = Map<String, dynamic>.from(config);
          clean.remove('updatedAt');
          clean.remove('createdAt');
          _uiConfig = clean;
          _prefs?.setString(_uiConfigKey, jsonEncode(_uiConfig));
          ColorConfig.updateOverrides(clean);
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('[AppState] Error processing UI config: $e');
          debugPrint('[AppState] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[AppState] UI config stream error: $e');
        debugPrint('[AppState] Stack trace: $stackTrace');
      },
      onDone: () => debugPrint('[AppState] UI config stream closed'),
    );

    // Listen to text overrides
    _textOverridesSub = fs.textOverridesStream.listen(
      (data) {
        try {
          final clean = Map<String, dynamic>.from(data);
          clean.remove('updatedAt');
          clean.remove('createdAt');
          _textOverrides = clean;
          _prefs?.setString(_textOverridesKey, jsonEncode(_textOverrides));
          TextConfig.updateOverrides(clean);
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('[AppState] Error processing text overrides: $e');
          debugPrint('[AppState] Stack trace: $stackTrace');
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[AppState] Text overrides stream error: $e');
        debugPrint('[AppState] Stack trace: $stackTrace');
      },
      onDone: () => debugPrint('[AppState] Text overrides stream closed'),
    );

    debugPrint('[AppState] Connected to Firestore real-time streams');
  }

  /// Disconnect Firestore streams
  void disconnectFirestore() {
    _featureFlagsSub?.cancel();
    _appConfigSub?.cancel();
    _announcementSub?.cancel();
    _uiConfigSub?.cancel();
    _textOverridesSub?.cancel();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setInt(_themeKey, mode == ThemeMode.dark ? 1 : 0);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setInt(_themeKey, _themeMode == ThemeMode.dark ? 1 : 0);
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _currentUser = user;
    _persistUserData();
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setNotificationCount(int count) {
    _notificationCount = count;
    _prefs?.setInt(_notifCountKey, count);
    notifyListeners();
  }

  void decrementNotificationCount() {
    if (_notificationCount > 0) {
      _notificationCount--;
      _prefs?.setInt(_notifCountKey, _notificationCount);
      notifyListeners();
    }
  }

  void setMessageCount(int count) {
    _messageCount = count;
    _prefs?.setInt(_msgCountKey, count);
    notifyListeners();
  }

  /// Update user profile fields.
  /// Pass empty string for [profileImage] to clear it (set to null).
  void updateUserProfile({
    String? fullName,
    String? phone,
    String? email,
    String? city,
    String? bio,
    String? profession,
    String? maritalStatus,
    String? profileImage,
    bool clearProfileImage = false,
    List<String>? interests,
  }) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      fullName: fullName ?? _currentUser!.fullName,
      phone: phone ?? _currentUser!.phone,
      email: email ?? _currentUser!.email,
      city: city ?? _currentUser!.city,
      bio: bio ?? _currentUser!.bio,
      profession: profession ?? _currentUser!.profession,
      maritalStatus: maritalStatus ?? _currentUser!.maritalStatus,
      profileImage: clearProfileImage ? null : (profileImage ?? _currentUser!.profileImage),
      interests: interests ?? _currentUser!.interests,
    );
    _persistUserData();
    notifyListeners();
  }

  /// Add child to current user
  void addChild(ChildModel child) {
    if (_currentUser == null) return;
    final children = List<ChildModel>.from(_currentUser!.children)..add(child);
    _currentUser = _currentUser!.copyWith(children: children);
    _persistUserData();
    notifyListeners();
  }

  /// Remove child from current user
  void removeChild(String childId) {
    if (_currentUser == null) return;
    final children = _currentUser!.children.where((c) => c.id != childId).toList();
    _currentUser = _currentUser!.copyWith(children: children);
    _persistUserData();
    notifyListeners();
  }

  /// Update an existing child in-place (preserves order)
  void updateChild(ChildModel updatedChild) {
    if (_currentUser == null) return;
    final children = _currentUser!.children.map((c) => c.id == updatedChild.id ? updatedChild : c).toList();
    _currentUser = _currentUser!.copyWith(children: children);
    _persistUserData();
    notifyListeners();
  }

  // Admin config setters (also write to Firestore via service)
  void setFeatureFlag(String feature, bool enabled) {
    _featureFlags[feature] = enabled;
    _prefs?.setString(_featureFlagsKey, jsonEncode(_featureFlags));
    notifyListeners();
  }

  void setAllFeatureFlags(Map<String, bool> flags) {
    _featureFlags = Map<String, bool>.from(flags);
    _prefs?.setString(_featureFlagsKey, jsonEncode(_featureFlags));
    notifyListeners();
  }

  void setAppConfig(Map<String, dynamic> config) {
    _appConfig = Map<String, dynamic>.from(config);
    _prefs?.setString(_appConfigKey, jsonEncode(_appConfig));
    notifyListeners();
  }

  void updateAppConfigKey(String key, dynamic value) {
    _appConfig[key] = value;
    _prefs?.setString(_appConfigKey, jsonEncode(_appConfig));
    notifyListeners();
  }

  void setAnnouncement(Map<String, dynamic> ann) {
    _announcement = Map<String, dynamic>.from(ann);
    _prefs?.setString(_announcementKey, jsonEncode(_announcement));
    notifyListeners();
  }

  void setUIConfig(Map<String, dynamic> config) {
    _uiConfig = Map<String, dynamic>.from(config);
    _prefs?.setString(_uiConfigKey, jsonEncode(_uiConfig));
    notifyListeners();
  }

  /// Logout - clears state AND AuthService session
  void logout() {
    _addLoginHistoryEntry('logout');
    _currentUser = null;
    _notificationCount = 0;
    _messageCount = 0;
    _prefs?.remove(_userDataKey);
    _prefs?.setInt(_notifCountKey, 0);
    _prefs?.setInt(_msgCountKey, 0);
    // Also clear the auth session
    AuthService.instance.logout();
    notifyListeners();
  }

  /// Login as regular user with full data persistence
  void loginUser(String email, String name, {String? phone, String? city}) {
    _currentUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: name,
      phone: phone,
      city: city,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isOnline: true,
    );
    _persistUserData();
    _addLoginHistoryEntry('login');
    notifyListeners();
  }

  /// Login from AuthService data (full data)
  void loginFromAuthData(Map<String, dynamic> data) {
    _currentUser = AuthService.instance.userModelFromData(data);
    _persistUserData();
    _addLoginHistoryEntry('login');
    notifyListeners();
  }

  /// Login as admin
  void loginAsAdmin(String email) {
    _currentUser = UserModel(
      id: 'admin_1',
      email: email,
      fullName: 'מנהלת MOMIT',
      city: 'ישראל',
      isVerified: true,
      createdAt: DateTime(2023, 1, 1),
      lastLoginAt: DateTime.now(),
      isOnline: true,
    );
    _persistUserData();
    _addLoginHistoryEntry('admin_login');
    notifyListeners();
  }

  // Admin functions
  void addPendingApproval(Map<String, dynamic> item) {
    _pendingApprovals.add(item);
    notifyListeners();
  }

  void approveItem(String id) {
    _pendingApprovals.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void rejectItem(String id) {
    _pendingApprovals.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  /// Get all registered users count (from AuthService)
  Future<int> getRegisteredUsersCount() async {
    try {
      return await AuthService.instance.getRegisteredUsersCount();
    } catch (_) {
      return 0;
    }
  }

  // Private helpers
  void _persistUserData() {
    if (_prefs != null && _currentUser != null) {
      _prefs!.setString(_userDataKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  void _addLoginHistoryEntry(String action) {
    _loginHistory.add({
      'action': action,
      'email': _currentUser?.email ?? '',
      'time': DateTime.now().toIso8601String(),
    });
    // Keep only last 50 entries
    if (_loginHistory.length > 50) {
      _loginHistory = _loginHistory.sublist(_loginHistory.length - 50);
    }
    _prefs?.setString(_loginHistoryKey, jsonEncode(_loginHistory));
  }

  @override
  void dispose() {
    disconnectFirestore();
    super.dispose();
  }
}
