import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dynamic Theme Provider - Listens to Firestore for real-time theme updates
/// All app colors are configurable from admin dashboard
class ThemeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _themeSubscription;

  // Default colors (fallback if Firestore is unavailable)
  static const Color _defaultPrimary = Color(0xFFD4A1AC);
  static const Color _defaultSecondary = Color(0xFFC4939C);
  static const Color _defaultAccent = Color(0xFFCCBBB4);
  static const Color _defaultBackground = Color(0xFFFCFAF9);
  static const Color _defaultSurface = Color(0xFFFFFFFF);
  static const Color _defaultTextPrimary = Color(0xFF140F11);
  static const Color _defaultTextSecondary = Color(0xFF45393C);
  static const Color _defaultTextHint = Color(0xFF7A6E70);
  static const Color _defaultBorder = Color(0xFFD8C9CB);
  static const Color _defaultError = Color(0xFFC97878);
  static const Color _defaultSuccess = Color(0xFF7BA886);
  static const Color _defaultWarning = Color(0xFFD4AC78);

  // Dynamic colors (loaded from Firestore)
  Color _primary = _defaultPrimary;
  Color _secondary = _defaultSecondary;
  Color _accent = _defaultAccent;
  Color _background = _defaultBackground;
  Color _surface = _defaultSurface;
  Color _surfaceVariant = Color(0xFFF7F3F2);
  Color _textPrimary = _defaultTextPrimary;
  Color _textSecondary = _defaultTextSecondary;
  Color _textHint = _defaultTextHint;
  Color _textOnPrimary = Colors.white;
  Color _textOnSecondary = Colors.white;
  Color _border = _defaultBorder;
  Color _divider = Color(0xFFE5DADC);
  Color _error = _defaultError;
  Color _success = _defaultSuccess;
  Color _warning = _defaultWarning;
  Color _info = Color(0xFF7E9BB5);

  // Dark mode colors
  Color _darkBackground = Color(0xFF1A1516);
  Color _darkSurface = Color(0xFF262022);
  Color _darkCard = Color(0xFF322A2C);
  Color _darkTextPrimary = Color(0xFFF5EFEF);
  Color _darkTextSecondary = Color(0xFFBDB5B7);

  // Feature colors - Categories
  Color _categoryQuestions = Color(0xFF7E9BB5);
  Color _categoryTips = Color(0xFF7BA886);
  Color _categoryRecommendations = Color(0xFFD4AC78);
  Color _categoryMoments = Color(0xFFB09DC0);
  Color _categoryHelp = Color(0xFFC97878);

  // Feature colors - Tracking
  Color _trackingFeeding = Color(0xFFD4A1AC);
  Color _trackingSleep = Color(0xFFB09DC0);
  Color _trackingGrowth = Color(0xFF7BA886);
  Color _trackingDiaper = Color(0xFFD4AC78);
  Color _trackingHealth = Color(0xFF7E9BB5);

  // Loading state
  bool _isLoading = true;
  bool _hasError = false;

  // Getters
  Color get primary => _primary;
  Color get secondary => _secondary;
  Color get accent => _accent;
  Color get background => _background;
  Color get surface => _surface;
  Color get surfaceVariant => _surfaceVariant;
  Color get textPrimary => _textPrimary;
  Color get textSecondary => _textSecondary;
  Color get textHint => _textHint;
  Color get textOnPrimary => _textOnPrimary;
  Color get textOnSecondary => _textOnSecondary;
  Color get border => _border;
  Color get divider => _divider;
  Color get error => _error;
  Color get success => _success;
  Color get warning => _warning;
  Color get info => _info;

  Color get darkBackground => _darkBackground;
  Color get darkSurface => _darkSurface;
  Color get darkCard => _darkCard;
  Color get darkTextPrimary => _darkTextPrimary;
  Color get darkTextSecondary => _darkTextSecondary;

  // Feature colors - Categories
  Color get categoryQuestions => _categoryQuestions;
  Color get categoryTips => _categoryTips;
  Color get categoryRecommendations => _categoryRecommendations;
  Color get categoryMoments => _categoryMoments;
  Color get categoryHelp => _categoryHelp;

  // Feature colors - Tracking
  Color get trackingFeeding => _trackingFeeding;
  Color get trackingSleep => _trackingSleep;
  Color get trackingGrowth => _trackingGrowth;
  Color get trackingDiaper => _trackingDiaper;
  Color get trackingHealth => _trackingHealth;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // Computed colors
  Color get primaryLight => _lighten(_primary, 0.15);
  Color get primaryDark => _darken(_primary, 0.1);
  Color get primarySoft => _lighten(_primary, 0.35);
  Color get primaryMist => _lighten(_primary, 0.25);

  Color get secondaryLight => _lighten(_secondary, 0.15);
  Color get secondaryDark => _darken(_secondary, 0.1);
  Color get secondarySoft => _lighten(_secondary, 0.35);

  Color get accentSoft => _lighten(_accent, 0.35);

  /// Initialize the theme provider and start listening to Firestore
  ThemeProvider() {
    _initialize();
  }

  void _initialize() {
    try {
      _themeSubscription = _db
          .collection('admin_config')
          .doc('theme')
          .snapshots()
          .listen(
            _onThemeUpdate,
            onError: (error) {
              debugPrint('[ThemeProvider] Error loading theme: $error');
              _hasError = true;
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('[ThemeProvider] Failed to initialize: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onThemeUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      // Use defaults if no theme doc exists
      _isLoading = false;
      notifyListeners();
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>;

    _primary = _parseColor(data['primaryColor'], _defaultPrimary);
    _secondary = _parseColor(data['secondaryColor'], _defaultSecondary);
    _accent = _parseColor(data['accentColor'], _defaultAccent);
    _background = _parseColor(data['backgroundColor'], _defaultBackground);
    _surface = _parseColor(data['surfaceColor'], _defaultSurface);
    _surfaceVariant = _parseColor(data['surfaceVariantColor'], Color(0xFFF7F3F2));
    _textPrimary = _parseColor(data['textPrimaryColor'], _defaultTextPrimary);
    _textSecondary = _parseColor(data['textSecondaryColor'], _defaultTextSecondary);
    _textHint = _parseColor(data['textHintColor'], _defaultTextHint);
    _textOnPrimary = _parseColor(data['textOnPrimaryColor'], Colors.white);
    _textOnSecondary = _parseColor(data['textOnSecondaryColor'], Colors.white);
    _border = _parseColor(data['borderColor'], _defaultBorder);
    _divider = _parseColor(data['dividerColor'], Color(0xFFE5DADC));
    _error = _parseColor(data['errorColor'], _defaultError);
    _success = _parseColor(data['successColor'], _defaultSuccess);
    _warning = _parseColor(data['warningColor'], _defaultWarning);
    _info = _parseColor(data['infoColor'], Color(0xFF7E9BB5));

    // Dark mode colors
    _darkBackground = _parseColor(data['darkBackgroundColor'], Color(0xFF1A1516));
    _darkSurface = _parseColor(data['darkSurfaceColor'], Color(0xFF262022));
    _darkCard = _parseColor(data['darkCardColor'], Color(0xFF322A2C));
    _darkTextPrimary = _parseColor(data['darkTextPrimaryColor'], Color(0xFFF5EFEF));
    _darkTextSecondary = _parseColor(data['darkTextSecondaryColor'], Color(0xFFBDB5B7));

    // Feature colors - Categories
    _categoryQuestions = _parseColor(data['categoryQuestionsColor'], Color(0xFF7E9BB5));
    _categoryTips = _parseColor(data['categoryTipsColor'], Color(0xFF7BA886));
    _categoryRecommendations = _parseColor(data['categoryRecommendationsColor'], Color(0xFFD4AC78));
    _categoryMoments = _parseColor(data['categoryMomentsColor'], Color(0xFFB09DC0));
    _categoryHelp = _parseColor(data['categoryHelpColor'], Color(0xFFC97878));

    // Feature colors - Tracking
    _trackingFeeding = _parseColor(data['trackingFeedingColor'], Color(0xFFD4A1AC));
    _trackingSleep = _parseColor(data['trackingSleepColor'], Color(0xFFB09DC0));
    _trackingGrowth = _parseColor(data['trackingGrowthColor'], Color(0xFF7BA886));
    _trackingDiaper = _parseColor(data['trackingDiaperColor'], Color(0xFFD4AC78));
    _trackingHealth = _parseColor(data['trackingHealthColor'], Color(0xFF7E9BB5));

    _isLoading = false;
    _hasError = false;
    notifyListeners();

    debugPrint('[ThemeProvider] Theme updated from Firestore');
  }

  /// Parse a color from various formats
  Color _parseColor(dynamic value, Color defaultColor) {
    if (value == null) return defaultColor;
    if (value is int) return Color(value);
    if (value is String) {
      try {
        String hex = value.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      } catch (e) {
        debugPrint('[ThemeProvider] Failed to parse color: $value');
      }
    }
    return defaultColor;
  }

  /// Lighten a color by a percentage (0.0 - 1.0)
  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Darken a color by a percentage (0.0 - 1.0)
  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Create a light ColorScheme from dynamic colors
  ColorScheme get lightColorScheme => ColorScheme.light(
        primary: _primary,
        onPrimary: _textOnPrimary,
        secondary: _secondary,
        onSecondary: _textOnSecondary,
        tertiary: _accent,
        surface: _surface,
        onSurface: _textPrimary,
        error: _error,
        onError: Colors.white,
      );

  /// Create a dark ColorScheme from dynamic colors
  ColorScheme get darkColorScheme => ColorScheme.dark(
        primary: primaryLight,
        onPrimary: _textPrimary,
        secondary: secondaryLight,
        onSecondary: _textPrimary,
        tertiary: _accent,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: _error,
        onError: Colors.white,
      );

  /// Get shadows with dynamic primary color
  List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: _primary.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1E1517).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: const Color(0xFF1E1517).withValues(alpha: 0.06),
          blurRadius: 30,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  /// Create gradients from dynamic colors
  LinearGradient get primaryGradient => LinearGradient(
        colors: [_primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => LinearGradient(
        colors: [_secondary, secondaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get accentGradient => LinearGradient(
        colors: [_accent, accentSoft],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get momGradient => LinearGradient(
        colors: [_primary, _accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Premium card decoration with dynamic colors
  BoxDecoration get premiumCard => BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: softShadow,
      );

  BoxDecoration get elevatedCard => BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: mediumShadow,
      );

  BoxDecoration get glassCard => BoxDecoration(
        color: _surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border, width: 0.8),
      );

  /// Save theme configuration to Firestore (admin use)
  Future<void> saveTheme(Map<String, dynamic> themeConfig) async {
    try {
      await _db.collection('admin_config').doc('theme').set({
        ...themeConfig,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[ThemeProvider] Theme saved to Firestore');
    } catch (e) {
      debugPrint('[ThemeProvider] Failed to save theme: $e');
      throw Exception('Failed to save theme: $e');
    }
  }

  /// Get current theme configuration as Map
  Map<String, dynamic> get currentThemeConfig => {
        'primaryColor': '#${_primary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'secondaryColor': '#${_secondary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'accentColor': '#${_accent.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'backgroundColor': '#${_background.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'surfaceColor': '#${_surface.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'surfaceVariantColor': '#${_surfaceVariant.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'textPrimaryColor': '#${_textPrimary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'textSecondaryColor': '#${_textSecondary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'textHintColor': '#${_textHint.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'textOnPrimaryColor': '#${_textOnPrimary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'textOnSecondaryColor': '#${_textOnSecondary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'borderColor': '#${_border.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'dividerColor': '#${_divider.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'errorColor': '#${_error.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'successColor': '#${_success.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'warningColor': '#${_warning.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'infoColor': '#${_info.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'darkBackgroundColor': '#${_darkBackground.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'darkSurfaceColor': '#${_darkSurface.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'darkCardColor': '#${_darkCard.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'darkTextPrimaryColor': '#${_darkTextPrimary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'darkTextSecondaryColor': '#${_darkTextSecondary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        // Feature colors - Categories
        'categoryQuestionsColor': '#${_categoryQuestions.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'categoryTipsColor': '#${_categoryTips.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'categoryRecommendationsColor': '#${_categoryRecommendations.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'categoryMomentsColor': '#${_categoryMoments.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'categoryHelpColor': '#${_categoryHelp.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        // Feature colors - Tracking
        'trackingFeedingColor': '#${_trackingFeeding.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'trackingSleepColor': '#${_trackingSleep.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'trackingGrowthColor': '#${_trackingGrowth.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'trackingDiaperColor': '#${_trackingDiaper.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'trackingHealthColor': '#${_trackingHealth.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      };

  @override
  void dispose() {
    _themeSubscription?.cancel();
    super.dispose();
  }
}
