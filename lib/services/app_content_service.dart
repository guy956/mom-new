import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/app_config_model.dart';

/// ═══════════════════════════════════════════════════════════════
///  APP CONTENT SERVICE - Comprehensive No-Code Configuration
/// ═══════════════════════════════════════════════════════════════
/// 
/// This service enables 100% no-code control of the app through the admin panel.
/// It manages:
/// - Dynamic text content (all UI text)
/// - Colors and themes
/// - Layout configurations
/// - Feature toggles
/// - Images and media
/// - Home screen layout
/// - Navigation configuration
/// - Any app content that needs to be editable
/// 
/// Usage:
/// ```dart
/// final contentService = AppContentService.instance;
/// final welcomeText = contentService.getText('welcome', 'title');
/// final primaryColor = contentService.getColor('primary');
/// ```

class AppContentService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════
  //  SINGLETON INSTANCE
  // ═══════════════════════════════════════════════════════════════
  
  static final AppContentService _instance = AppContentService._internal();
  static AppContentService get instance => _instance;
  
  AppContentService._internal();

  // ═══════════════════════════════════════════════════════════════
  //  DEPENDENCIES
  // ═══════════════════════════════════════════════════════════════
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  
  // ═══════════════════════════════════════════════════════════════
  //  STATE - All Dynamic Content
  // ═══════════════════════════════════════════════════════════════
  
  /// Complete app configuration
  AppConfiguration _config = AppConfiguration.defaultConfig();
  AppConfiguration get config => _config;
  
  /// All text content keyed by screen > key
  Map<String, Map<String, String>> _textContent = {};
  
  /// All color configurations
  Map<String, AppColorConfig> _colors = {};
  
  /// All layout configurations
  Map<String, AppLayoutConfig> _layouts = {};
  
  /// Feature flags
  Map<String, bool> _features = {};
  
  /// Image/Media URLs
  Map<String, String> _media = {};
  
  /// Home screen layout configuration
  HomeLayoutConfig _homeLayout = HomeLayoutConfig.defaultConfig();
  
  /// Loading state
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  /// Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  /// Last sync timestamp
  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;
  
  /// Error state
  String? _error;
  String? get error => _error;

  // ═══════════════════════════════════════════════════════════════
  //  STREAM SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════
  
  StreamSubscription<DocumentSnapshot>? _configSub;
  StreamSubscription<DocumentSnapshot>? _textSub;
  StreamSubscription<DocumentSnapshot>? _colorsSub;
  StreamSubscription<DocumentSnapshot>? _layoutsSub;
  StreamSubscription<DocumentSnapshot>? _featuresSub;
  StreamSubscription<DocumentSnapshot>? _mediaSub;
  StreamSubscription<DocumentSnapshot>? _homeLayoutSub;

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC GETTERS - Quick Access
  // ═══════════════════════════════════════════════════════════════
  
  /// App branding
  String get appName => _config.branding.appName;
  String get appSlogan => _config.branding.slogan;
  String get appTagline => _config.branding.tagline;
  String? get logoUrl => _config.branding.logoUrl;
  
  /// Colors - quick access helpers
  Color get primaryColor => _parseColor(_colors['primary']?.value ?? '#D4A1AC');
  Color get secondaryColor => _parseColor(_colors['secondary']?.value ?? '#EDD3D8');
  Color get accentColor => _parseColor(_colors['accent']?.value ?? '#DBC8B0');
  Color get backgroundColor => _parseColor(_colors['background']?.value ?? '#FFFFFF');
  Color get textColor => _parseColor(_colors['text']?.value ?? '#333333');
  Color get errorColor => _parseColor(_colors['error']?.value ?? '#E74C3C');
  Color get successColor => _parseColor(_colors['success']?.value ?? '#27AE60');
  Color get warningColor => _parseColor(_colors['warning']?.value ?? '#F39C12');
  
  /// Get any color by key
  Color getColor(String key, {Color fallback = const Color(0xFFD4A1AC)}) {
    final config = _colors[key];
    if (config == null) return fallback;
    return _parseColor(config.value);
  }
  
  /// Home layout
  HomeLayoutConfig get homeLayout => _homeLayout;
  
  /// Feature flags
  bool isFeatureEnabled(String key) => _features[key] ?? true;
  Map<String, bool> get allFeatures => Map.unmodifiable(_features);

  // ═══════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════════
  
  /// Initialize the service - call this in main.dart before runApp
  Future<void> initialize() async {
    debugPrint('[AppContentService] Initializing...');
    
    _prefs = await SharedPreferences.getInstance();
    
    // Load from cache first for fast startup
    await _loadFromCache();
    
    _isLoading = false;
    notifyListeners();
    
    debugPrint('[AppContentService] Initialized with cached data');
  }
  
  /// Connect to Firestore for real-time updates
  void connectToFirestore() {
    if (_isConnected) return;
    
    debugPrint('[AppContentService] Connecting to Firestore...');
    
    // Main configuration
    _configSub = _db.collection('app_content').doc('config').snapshots().listen(
      (snap) => _handleConfigUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Config error: $e'),
    );
    
    // Text content
    _textSub = _db.collection('app_content').doc('texts').snapshots().listen(
      (snap) => _handleTextUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Text error: $e'),
    );
    
    // Colors
    _colorsSub = _db.collection('app_content').doc('colors').snapshots().listen(
      (snap) => _handleColorsUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Colors error: $e'),
    );
    
    // Layouts
    _layoutsSub = _db.collection('app_content').doc('layouts').snapshots().listen(
      (snap) => _handleLayoutsUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Layouts error: $e'),
    );
    
    // Features
    _featuresSub = _db.collection('app_content').doc('features').snapshots().listen(
      (snap) => _handleFeaturesUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Features error: $e'),
    );
    
    // Media
    _mediaSub = _db.collection('app_content').doc('media').snapshots().listen(
      (snap) => _handleMediaUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Media error: $e'),
    );
    
    // Home layout
    _homeLayoutSub = _db.collection('app_content').doc('home_layout').snapshots().listen(
      (snap) => _handleHomeLayoutUpdate(snap),
      onError: (e) => debugPrint('[AppContentService] Home layout error: $e'),
    );
    
    _isConnected = true;
    debugPrint('[AppContentService] Connected to Firestore');
  }
  
  /// Disconnect from Firestore (call on logout)
  void disconnect() {
    _configSub?.cancel();
    _textSub?.cancel();
    _colorsSub?.cancel();
    _layoutsSub?.cancel();
    _featuresSub?.cancel();
    _mediaSub?.cancel();
    _homeLayoutSub?.cancel();
    _isConnected = false;
    debugPrint('[AppContentService] Disconnected from Firestore');
  }

  // ═══════════════════════════════════════════════════════════════
  //  UPDATE HANDLERS
  // ═══════════════════════════════════════════════════════════════
  
  void _handleConfigUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    _config = AppConfiguration.fromFirestore(data);
    _cacheData('config', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Config updated');
  }
  
  void _handleTextUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    // Parse nested text structure: { screen: { key: value } }
    final texts = <String, Map<String, String>>{};
    data.forEach((screen, content) {
      if (content is Map) {
        texts[screen] = Map<String, String>.from(
          content.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    });
    
    _textContent = texts;
    _cacheData('texts', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Text content updated (${_textContent.length} screens)');
  }
  
  void _handleColorsUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    final colors = <String, AppColorConfig>{};
    data.forEach((key, value) {
      if (value is Map) {
        colors[key] = AppColorConfig.fromMap(key, Map<String, dynamic>.from(value));
      }
    });
    
    _colors = colors;
    _cacheData('colors', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Colors updated (${_colors.length} colors)');
  }
  
  void _handleLayoutsUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    final layouts = <String, AppLayoutConfig>{};
    data.forEach((key, value) {
      if (value is Map) {
        layouts[key] = AppLayoutConfig.fromMap(key, Map<String, dynamic>.from(value));
      }
    });
    
    _layouts = layouts;
    _cacheData('layouts', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Layouts updated (${_layouts.length} layouts)');
  }
  
  void _handleFeaturesUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    final features = <String, bool>{};
    data.forEach((key, value) {
      if (value is bool) {
        features[key] = value;
      }
    });
    
    _features = features;
    _cacheData('features', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Features updated (${_features.length} features)');
  }
  
  void _handleMediaUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    _media = Map<String, String>.from(
      data.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    _cacheData('media', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Media updated (${_media.length} items)');
  }
  
  void _handleHomeLayoutUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;
    
    _homeLayout = HomeLayoutConfig.fromMap(data);
    _cacheData('home_layout', data);
    _lastSync = DateTime.now();
    notifyListeners();
    debugPrint('[AppContentService] Home layout updated');
  }

  // ═══════════════════════════════════════════════════════════════
  //  CACHING
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _loadFromCache() async {
    try {
      // Config
      final configJson = _prefs?.getString('app_content_config');
      if (configJson != null) {
        final data = jsonDecode(configJson);
        _config = AppConfiguration.fromFirestore(data);
      }
      
      // Texts
      final textsJson = _prefs?.getString('app_content_texts');
      if (textsJson != null) {
        final data = jsonDecode(textsJson);
        final texts = <String, Map<String, String>>{};
        data.forEach((screen, content) {
          if (content is Map) {
            texts[screen] = Map<String, String>.from(
              content.map((k, v) => MapEntry(k.toString(), v.toString())),
            );
          }
        });
        _textContent = texts;
      }
      
      // Colors
      final colorsJson = _prefs?.getString('app_content_colors');
      if (colorsJson != null) {
        final data = jsonDecode(colorsJson);
        final colors = <String, AppColorConfig>{};
        data.forEach((key, value) {
          if (value is Map) {
            colors[key] = AppColorConfig.fromMap(key, Map<String, dynamic>.from(value));
          }
        });
        _colors = colors;
      }
      
      // Layouts
      final layoutsJson = _prefs?.getString('app_content_layouts');
      if (layoutsJson != null) {
        final data = jsonDecode(layoutsJson);
        final layouts = <String, AppLayoutConfig>{};
        data.forEach((key, value) {
          if (value is Map) {
            layouts[key] = AppLayoutConfig.fromMap(key, Map<String, dynamic>.from(value));
          }
        });
        _layouts = layouts;
      }
      
      // Features
      final featuresJson = _prefs?.getString('app_content_features');
      if (featuresJson != null) {
        final data = jsonDecode(featuresJson);
        final features = <String, bool>{};
        data.forEach((key, value) {
          if (value is bool) features[key] = value;
        });
        _features = features;
      }
      
      // Media
      final mediaJson = _prefs?.getString('app_content_media');
      if (mediaJson != null) {
        final data = jsonDecode(mediaJson);
        _media = Map<String, String>.from(
          data.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
      
      // Home layout
      final homeLayoutJson = _prefs?.getString('app_content_home_layout');
      if (homeLayoutJson != null) {
        _homeLayout = HomeLayoutConfig.fromMap(jsonDecode(homeLayoutJson));
      }
      
      debugPrint('[AppContentService] Loaded from cache');
    } catch (e) {
      debugPrint('[AppContentService] Cache load error: $e');
    }
  }
  
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      await _prefs?.setString('app_content_$key', jsonEncode(data));
    } catch (e) {
      debugPrint('[AppContentService] Cache save error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API - Get Content
  // ═══════════════════════════════════════════════════════════════
  
  /// Get text content by screen and key
  /// 
  /// Example:
  /// ```dart
  /// final welcomeTitle = contentService.getText('welcome', 'title', 
  ///   fallback: 'Welcome');
  /// ```
  String getText(String screen, String key, {String fallback = ''}) {
    final screenTexts = _textContent[screen];
    if (screenTexts == null) return fallback;
    return screenTexts[key] ?? fallback;
  }
  
  /// Get all texts for a screen
  Map<String, String> getScreenTexts(String screen) {
    return Map.unmodifiable(_textContent[screen] ?? {});
  }
  
  /// Get all available screens
  List<String> get availableScreens => _textContent.keys.toList();
  
  /// Get all text keys for a screen
  List<String> getTextKeys(String screen) {
    return _textContent[screen]?.keys.toList() ?? [];
  }
  
  /// Get media URL by key
  String? getMediaUrl(String key) => _media[key];
  
  /// Get layout configuration by key
  AppLayoutConfig? getLayout(String key) => _layouts[key];
  
  /// Get color configuration by key
  AppColorConfig? getColorConfig(String key) => _colors[key];
  
  /// Get all available color keys
  List<String> get availableColors => _colors.keys.toList();
  
  /// Get all available layout keys
  List<String> get availableLayouts => _layouts.keys.toList();
  
  /// Get all available media keys
  List<String> get availableMedia => _media.keys.toList();

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API - Admin Updates
  // ═══════════════════════════════════════════════════════════════
  
  /// Update text content (Admin only)
  Future<void> updateText(String screen, String key, String value) async {
    await _db.collection('app_content').doc('texts').set(
      {screen: {key: value}},
      SetOptions(merge: true),
    );
  }
  
  /// Update multiple texts at once (Admin only)
  Future<void> updateTexts(String screen, Map<String, String> texts) async {
    await _db.collection('app_content').doc('texts').set(
      {screen: texts},
      SetOptions(merge: true),
    );
  }
  
  /// Update color configuration (Admin only)
  Future<void> updateColor(String key, AppColorConfig color) async {
    await _db.collection('app_content').doc('colors').set(
      {key: color.toMap()},
      SetOptions(merge: true),
    );
  }
  
  /// Update feature flag (Admin only)
  Future<void> updateFeature(String key, bool enabled) async {
    await _db.collection('app_content').doc('features').set(
      {key: enabled},
      SetOptions(merge: true),
    );
  }
  
  /// Update multiple features at once (Admin only)
  Future<void> updateFeatures(Map<String, bool> features) async {
    await _db.collection('app_content').doc('features').set(
      features,
      SetOptions(merge: true),
    );
  }
  
  /// Update media URL (Admin only)
  Future<void> updateMedia(String key, String url) async {
    await _db.collection('app_content').doc('media').set(
      {key: url},
      SetOptions(merge: true),
    );
  }
  
  /// Update home layout (Admin only)
  Future<void> updateHomeLayout(HomeLayoutConfig layout) async {
    await _db.collection('app_content').doc('home_layout').set(
      layout.toMap(),
      SetOptions(merge: true),
    );
  }
  
  /// Update layout configuration (Admin only)
  Future<void> updateLayout(String key, AppLayoutConfig layout) async {
    await _db.collection('app_content').doc('layouts').set(
      {key: layout.toMap()},
      SetOptions(merge: true),
    );
  }
  
  /// Update complete app configuration (Admin only)
  Future<void> updateConfig(AppConfiguration config) async {
    await _db.collection('app_content').doc('config').set(
      config.toFirestore(),
      SetOptions(merge: true),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API - Home Layout Management
  // ═══════════════════════════════════════════════════════════════
  
  /// Reorder home sections
  Future<void> reorderHomeSections(List<String> orderedKeys) async {
    final currentWidgets = Map<String, HomeWidgetConfig>.from(_homeLayout.widgets);
    final reorderedWidgets = <String, HomeWidgetConfig>{};
    
    for (int i = 0; i < orderedKeys.length; i++) {
      final key = orderedKeys[i];
      if (currentWidgets.containsKey(key)) {
        reorderedWidgets[key] = currentWidgets[key]!.copyWith(order: i);
      }
    }
    
    final newLayout = _homeLayout.copyWith(widgets: reorderedWidgets);
    await updateHomeLayout(newLayout);
  }
  
  /// Toggle home widget visibility
  Future<void> toggleHomeWidget(String key, bool isVisible) async {
    final widgets = Map<String, HomeWidgetConfig>.from(_homeLayout.widgets);
    if (widgets.containsKey(key)) {
      widgets[key] = widgets[key]!.copyWith(isVisible: isVisible);
      await updateHomeLayout(_homeLayout.copyWith(widgets: widgets));
    }
  }
  
  /// Update home widget configuration
  Future<void> updateHomeWidget(String key, HomeWidgetConfig widget) async {
    final widgets = Map<String, HomeWidgetConfig>.from(_homeLayout.widgets);
    widgets[key] = widget;
    await updateHomeLayout(_homeLayout.copyWith(widgets: widgets));
  }

  // ═══════════════════════════════════════════════════════════════
  //  UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════
  
  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFFD4A1AC);
    }
  }
  
  /// Seed default content if none exists
  Future<void> seedDefaults() async {
    final configDoc = await _db.collection('app_content').doc('config').get();
    if (configDoc.exists) {
      debugPrint('[AppContentService] Defaults already seeded');
      return;
    }
    
    debugPrint('[AppContentService] Seeding defaults...');
    
    // Seed all default documents
    final batch = _db.batch();
    
    // Config
    batch.set(
      _db.collection('app_content').doc('config'),
      AppConfiguration.defaultConfig().toFirestore(),
    );
    
    // Default texts
    batch.set(_db.collection('app_content').doc('texts'), _defaultTexts);
    
    // Default colors
    batch.set(_db.collection('app_content').doc('colors'), _defaultColors);
    
    // Default features
    batch.set(_db.collection('app_content').doc('features'), _defaultFeatures);
    
    // Default home layout
    batch.set(
      _db.collection('app_content').doc('home_layout'),
      HomeLayoutConfig.defaultConfig().toMap(),
    );
    
    await batch.commit();
    debugPrint('[AppContentService] Defaults seeded successfully');
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DEFAULT DATA
  // ═══════════════════════════════════════════════════════════════
  
  static final Map<String, dynamic> _defaultTexts = {
    'welcome': {
      'title': 'ברוכה הבאה ל-MOMIT',
      'subtitle': 'הרשת החברתית לאמהות',
      'description': 'מקום בטוח לשתף, ללמוד ולהתחבר עם אמהות אחרות',
      'getStarted': 'התחילי עכשיו',
      'learnMore': 'למידע נוסף',
    },
    'home': {
      'greeting': 'שלום {name}!',
      'dailyTip': 'הטיפ היומי',
      'quickAccess': 'גישה מהירה',
      'community': 'הקהילה שלך',
      'upcomingEvents': 'אירועים קרובים',
    },
    'auth': {
      'loginTitle': 'התחברות',
      'registerTitle': 'הרשמה',
      'emailLabel': 'אימייל',
      'passwordLabel': 'סיסמה',
      'forgotPassword': 'שכחת סיסמה?',
      'loginButton': 'התחברי',
      'registerButton': 'הירשמי',
      'noAccount': 'אין לך חשבון?',
      'hasAccount': 'כבר יש לך חשבון?',
    },
    'chat': {
      'title': 'צ\'אט',
      'placeholder': 'כתבי הודעה...',
      'send': 'שלחי',
      'online': 'מחוברת',
      'offline': 'מנותקת',
    },
    'profile': {
      'title': 'פרופיל',
      'editProfile': 'עריכת פרופיל',
      'settings': 'הגדרות',
      'logout': 'התנתקות',
      'myPosts': 'הפוסטים שלי',
      'savedItems': 'שמורים',
    },
    'navigation': {
      'home': 'בית',
      'chat': 'צ\'אט',
      'events': 'אירועים',
      'profile': 'פרופיל',
      'marketplace': 'שוק',
      'experts': 'מומחים',
      'tips': 'טיפים',
    },
    'buttons': {
      'save': 'שמור',
      'cancel': 'ביטול',
      'delete': 'מחק',
      'edit': 'ערוך',
      'create': 'צור',
      'confirm': 'אשר',
      'back': 'חזור',
      'next': 'הבא',
    },
    'errors': {
      'generic': 'משהו השתבש. נסי שוב.',
      'network': 'בעיית חיבור. בדקי את האינטרנט.',
      'unauthorized': 'אינך מורשית לבצע פעולה זו.',
      'notFound': 'לא נמצא.',
    },
    'onboarding': {
      'slide1Title': 'ברוכה הבאה ל-MOMIT',
      'slide1Subtitle': 'הרשת החברתית לאמהות בישראל',
      'slide2Title': 'תמיכה וליווי',
      'slide2Subtitle': 'קבלי תמיכה מקהילה תומכת וממומחים',
      'slide3Title': 'למידה וצמיחה',
      'slide3Subtitle': 'גישה לטיפים, מאמרים וכלים שיעזרו לך',
      'slide4Title': 'התחילי עכשיו',
      'slide4Subtitle': 'הצטרפי לקהילה הגדולה של אמהות',
      'skip': 'דלגי',
      'next': 'הבא',
      'start': 'התחילי',
    },
  };
  
  static final Map<String, dynamic> _defaultColors = {
    'primary': {
      'value': '#D4A1AC',
      'name': 'Primary',
      'nameHe': 'ראשי',
      'description': 'Main brand color',
    },
    'secondary': {
      'value': '#EDD3D8',
      'name': 'Secondary',
      'nameHe': 'משני',
      'description': 'Secondary brand color',
    },
    'accent': {
      'value': '#DBC8B0',
      'name': 'Accent',
      'nameHe': 'הדגשה',
      'description': 'Accent color for highlights',
    },
    'background': {
      'value': '#FFFFFF',
      'name': 'Background',
      'nameHe': 'רקע',
      'description': 'Main background color',
    },
    'surface': {
      'value': '#F9F5F4',
      'name': 'Surface',
      'nameHe': 'משטח',
      'description': 'Card/surface background',
    },
    'text': {
      'value': '#333333',
      'name': 'Text',
      'nameHe': 'טקסט',
      'description': 'Primary text color',
    },
    'textSecondary': {
      'value': '#666666',
      'name': 'Text Secondary',
      'nameHe': 'טקסט משני',
      'description': 'Secondary/muted text',
    },
    'error': {
      'value': '#E74C3C',
      'name': 'Error',
      'nameHe': 'שגיאה',
      'description': 'Error state color',
    },
    'success': {
      'value': '#27AE60',
      'name': 'Success',
      'nameHe': 'הצלחה',
      'description': 'Success state color',
    },
    'warning': {
      'value': '#F39C12',
      'name': 'Warning',
      'nameHe': 'אזהרה',
      'description': 'Warning state color',
    },
    'info': {
      'value': '#3498DB',
      'name': 'Info',
      'nameHe': 'מידע',
      'description': 'Info state color',
    },
  };
  
  static final Map<String, bool> _defaultFeatures = {
    'chat': true,
    'events': true,
    'marketplace': true,
    'experts': true,
    'tips': true,
    'mood': true,
    'sos': true,
    'gamification': true,
    'aiChat': true,
    'whatsapp': true,
    'album': true,
    'tracking': true,
    'feed': true,
    'notifications': true,
    'search': true,
    'onboarding': true,
  };
}

// ═══════════════════════════════════════════════════════════════
//  EXTENSION METHODS FOR WIDGETS
// ═══════════════════════════════════════════════════════════════

extension AppContentServiceExtension on BuildContext {
  /// Quick access to AppContentService
  AppContentService get appContent => AppContentService.instance;
  
  /// Get text with fallback
  String txt(String screen, String key, {String fallback = ''}) {
    return appContent.getText(screen, key, fallback: fallback);
  }
  
  /// Get color by key
  Color appColor(String key, {Color fallback = const Color(0xFFD4A1AC)}) {
    return appContent.getColor(key, fallback: fallback);
  }
}
