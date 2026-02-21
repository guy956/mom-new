import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/providers/theme_provider.dart';

/// MOMIT - Dynamic Color System
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// Philosophy: "Whisper elegance. Feel warmth. Touch silk."
/// 
/// ALL COLORS ARE NOW DYNAMIC - Loaded from Firestore theme document
/// Use AppColors.of(context) to get the current dynamic colors
/// 
/// For backward compatibility, static getters return fallback colors
/// but you should migrate to context-based access for dynamic theming.
///
/// WCAG 2.1 AA compliant text colors on light backgrounds.
class AppColors {
  AppColors._();

  // ════════════════════════════════════════════════════════════════
  //  STATIC FALLBACK COLORS (Used when context is not available)
  //  These are the default colors before Firestore loads
  // ════════════════════════════════════════════════════════════════

  // ──── Primary: Baby Pink (The Soul) ────
  static const Color primary = Color(0xFFD4A1AC);
  static const Color primaryLight = Color(0xFFE8C8CE);
  static const Color primaryDark = Color(0xFFBE8A93);
  static const Color primarySoft = Color(0xFFFDF5F6);
  static const Color primaryMist = Color(0xFFF6E6E9);

  // ──── Secondary: Deeper rose shade ────
  static const Color secondary = Color(0xFFC4939C);
  static const Color secondaryLight = Color(0xFFDBB5BB);
  static const Color secondaryDark = Color(0xFFAD7D86);
  static const Color secondarySoft = Color(0xFFF7EDEF);

  // ──── Accent: Warm Nude ────
  static const Color accent = Color(0xFFCCBBB4);
  static const Color accentSoft = Color(0xFFF5F0ED);

  // ──── Backgrounds: Warm Ivory ────
  static const Color background = Color(0xFFFCFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F3F2);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ──── Text: Ultra-Sharp ────
  static const Color textPrimary = Color(0xFF140F11);
  static const Color textSecondary = Color(0xFF45393C);
  static const Color textHint = Color(0xFF7A6E70);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // ──── Borders ────
  static const Color border = Color(0xFFD8C9CB);
  static const Color divider = Color(0xFFE5DADC);

  // ──── Status ────
  static const Color success = Color(0xFF7BA886);
  static const Color warning = Color(0xFFD4AC78);
  static const Color error = Color(0xFFC97878);
  static const Color info = Color(0xFF7E9BB5);

  // ──── Dark Mode ────
  static const Color darkBackground = Color(0xFF1A1516);
  static const Color darkSurface = Color(0xFF262022);
  static const Color darkCard = Color(0xFF322A2C);
  static const Color darkTextPrimary = Color(0xFFF5EFEF);
  static const Color darkTextSecondary = Color(0xFFBDB5B7);

  // ════════════════════════════════════════════════════════════════
  //  DYNAMIC COLOR ACCESS (Recommended)
  //  Use AppColors.of(context) to get theme-aware colors
  // ════════════════════════════════════════════════════════════════

  /// Get dynamic colors from the current theme
  /// Usage: final colors = AppColors.of(context);
  static DynamicColors of(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return DynamicColors._(themeProvider);
  }

  /// Get dynamic colors and listen to changes
  /// Usage: final colors = AppColors.watch(context);
  static DynamicColors watch(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return DynamicColors._(themeProvider);
  }

  /// Get a specific color dynamically with fallback
  static Color dynamicPrimary(BuildContext context) => 
      _getColor(context, (t) => t.primary, primary);
  static Color dynamicSecondary(BuildContext context) => 
      _getColor(context, (t) => t.secondary, secondary);
  static Color dynamicAccent(BuildContext context) => 
      _getColor(context, (t) => t.accent, accent);
  static Color dynamicBackground(BuildContext context) => 
      _getColor(context, (t) => t.background, background);
  static Color dynamicSurface(BuildContext context) => 
      _getColor(context, (t) => t.surface, surface);
  static Color dynamicTextPrimary(BuildContext context) => 
      _getColor(context, (t) => t.textPrimary, textPrimary);
  static Color dynamicTextSecondary(BuildContext context) => 
      _getColor(context, (t) => t.textSecondary, textSecondary);
  static Color dynamicBorder(BuildContext context) => 
      _getColor(context, (t) => t.border, border);

  static Color _getColor(BuildContext context, Color Function(ThemeProvider) getter, Color fallback) {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      return getter(themeProvider);
    } catch (e) {
      return fallback;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS (Static - update to use ThemeProvider for dynamic)
  // ════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4A1AC), Color(0xFFE8C8CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFC4939C), Color(0xFFDBB5BB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFCCBBB4), Color(0xFFDFD2CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient momGradient = LinearGradient(
    colors: [Color(0xFFD4A1AC), Color(0xFFCCBBB4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFD4A1AC), Color(0xFFC4939C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFE8C8CE), Color(0xFFF5F0ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFDF5F6), Color(0xFFF7F3F2), Color(0xFFFCFAF9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF2A1B1F), Color(0xFF1A1012), Color(0xFF0F0A0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGlow = LinearGradient(
    colors: [Color(0xFFE8C8CE), Color(0xFFD4A1AC), Color(0xFFC4939C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════
  //  SHADOWS
  // ════════════════════════════════════════════════════════════════

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1E1517).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: const Color(0xFF1E1517).withValues(alpha: 0.06),
          blurRadius: 30,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get luxeShadow => [
        BoxShadow(
          color: const Color(0xFF1E1517).withValues(alpha: 0.03),
          blurRadius: 40,
          offset: const Offset(0, 14),
          spreadRadius: -6,
        ),
      ];

  // ════════════════════════════════════════════════════════════════
  //  CARDS
  // ════════════════════════════════════════════════════════════════

  static BoxDecoration get premiumCard => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.8),
        boxShadow: softShadow,
      );

  static BoxDecoration get elevatedCard => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: mediumShadow,
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 0.8),
      );

  // ════════════════════════════════════════════════════════════════
  //  FEATURE COLORS
  // ════════════════════════════════════════════════════════════════

  static const Color categoryQuestions = Color(0xFF7E9BB5);
  static const Color categoryTips = Color(0xFF7BA886);
  static const Color categoryRecommendations = Color(0xFFD4AC78);
  static const Color categoryMoments = Color(0xFFB09DC0);
  static const Color categoryHelp = Color(0xFFC97878);

  static const Color trackingFeeding = Color(0xFFD4A1AC);
  static const Color trackingSleep = Color(0xFFB09DC0);
  static const Color trackingGrowth = Color(0xFF7BA886);
  static const Color trackingDiaper = Color(0xFFD4AC78);
  static const Color trackingHealth = Color(0xFF7E9BB5);

  // ════════════════════════════════════════════════════════════════
  //  UTILITIES
  // ════════════════════════════════════════════════════════════════

  /// Parse a hex color string (e.g. '#D4A1AC' or 'D4A1AC') to a Color.
  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Convert a Color to hex string
  static String toHex(Color color, {bool withHash = true}) {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return withHash ? '#$hex' : hex;
  }
}

/// Dynamic color container - provides access to theme-aware colors
class DynamicColors {
  final ThemeProvider _theme;

  DynamicColors._(this._theme);

  // Core colors
  Color get primary => _theme.primary;
  Color get secondary => _theme.secondary;
  Color get accent => _theme.accent;
  Color get background => _theme.background;
  Color get surface => _theme.surface;
  Color get surfaceVariant => _theme.surfaceVariant;

  // Text colors
  Color get textPrimary => _theme.textPrimary;
  Color get textSecondary => _theme.textSecondary;
  Color get textHint => _theme.textHint;
  Color get textOnPrimary => _theme.textOnPrimary;
  Color get textOnSecondary => _theme.textOnSecondary;

  // UI colors
  Color get border => _theme.border;
  Color get divider => _theme.divider;
  Color get error => _theme.error;
  Color get success => _theme.success;
  Color get warning => _theme.warning;
  Color get info => _theme.info;

  // Derived colors
  Color get primaryLight => _theme.primaryLight;
  Color get primaryDark => _theme.primaryDark;
  Color get primarySoft => _theme.primarySoft;
  Color get primaryMist => _theme.primaryMist;
  Color get secondaryLight => _theme.secondaryLight;
  Color get secondaryDark => _theme.secondaryDark;
  Color get secondarySoft => _theme.secondarySoft;
  Color get accentSoft => _theme.accentSoft;

  // Dark mode
  Color get darkBackground => _theme.darkBackground;
  Color get darkSurface => _theme.darkSurface;
  Color get darkCard => _theme.darkCard;
  Color get darkTextPrimary => _theme.darkTextPrimary;
  Color get darkTextSecondary => _theme.darkTextSecondary;

  // Shadows
  List<BoxShadow> get softShadow => _theme.softShadow;
  List<BoxShadow> get mediumShadow => _theme.mediumShadow;
  List<BoxShadow> get primaryShadow => _theme.primaryShadow;

  // Gradients
  LinearGradient get primaryGradient => _theme.primaryGradient;
  LinearGradient get secondaryGradient => _theme.secondaryGradient;
  LinearGradient get accentGradient => _theme.accentGradient;
  LinearGradient get momGradient => _theme.momGradient;

  // Decorations
  BoxDecoration get premiumCard => _theme.premiumCard;
  BoxDecoration get elevatedCard => _theme.elevatedCard;
  BoxDecoration get glassCard => _theme.glassCard;

  // Color schemes
  ColorScheme get lightColorScheme => _theme.lightColorScheme;
  ColorScheme get darkColorScheme => _theme.darkColorScheme;

  // Feature colors - Categories
  Color get categoryQuestions => _theme.categoryQuestions;
  Color get categoryTips => _theme.categoryTips;
  Color get categoryRecommendations => _theme.categoryRecommendations;
  Color get categoryMoments => _theme.categoryMoments;
  Color get categoryHelp => _theme.categoryHelp;

  // Feature colors - Tracking
  Color get trackingFeeding => _theme.trackingFeeding;
  Color get trackingSleep => _theme.trackingSleep;
  Color get trackingGrowth => _theme.trackingGrowth;
  Color get trackingDiaper => _theme.trackingDiaper;
  Color get trackingHealth => _theme.trackingHealth;

  /// Check if theme is still loading
  bool get isLoading => _theme.isLoading;

  /// Check if there was an error loading theme
  bool get hasError => _theme.hasError;
}

/// Extension for easy color darkening/lightening
extension ColorExtension on Color {
  /// Lighten the color by a percentage (0.0 - 1.0)
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Darken the color by a percentage (0.0 - 1.0)
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Get color with specific opacity
  Color withOpacity(double opacity) => withValues(alpha: opacity);
}
