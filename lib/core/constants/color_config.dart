import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// Dynamic color configuration that overlays Firestore hex overrides on top of
/// static [AppColors] defaults. Gradients are auto-derived from resolved colors.
class ColorConfig {
  ColorConfig._();

  static Map<String, String> _overrides = {};

  /// Called by AppState whenever `ui_config` Firestore doc changes.
  static void updateOverrides(Map<String, dynamic> raw) {
    final parsed = <String, String>{};
    for (final e in raw.entries) {
      if (e.value is String && (e.value as String).startsWith('#')) {
        parsed[e.key] = e.value as String;
      }
    }
    _overrides = parsed;
  }

  /// Raw overrides map (for admin editor).
  static Map<String, String> get overrides => _overrides;

  // ── Internal resolver ──
  static Color _r(String key, Color fallback) {
    final hex = _overrides[key];
    if (hex == null) return fallback;
    return AppColors.fromHex(hex);
  }

  // ════════════════════════════════════════════════════════════════
  //  Primary family
  // ════════════════════════════════════════════════════════════════
  static Color get primary => _r('primaryColor', AppColors.primary);
  static Color get primaryLight => _r('primaryLightColor', AppColors.primaryLight);
  static Color get primaryDark => _r('primaryDarkColor', AppColors.primaryDark);
  static Color get primarySoft => _r('primarySoftColor', AppColors.primarySoft);
  static Color get primaryMist => _r('primaryMistColor', AppColors.primaryMist);

  // ════════════════════════════════════════════════════════════════
  //  Secondary family
  // ════════════════════════════════════════════════════════════════
  static Color get secondary => _r('secondaryColor', AppColors.secondary);
  static Color get secondaryLight => _r('secondaryLightColor', AppColors.secondaryLight);
  static Color get secondaryDark => _r('secondaryDarkColor', AppColors.secondaryDark);
  static Color get secondarySoft => _r('secondarySoftColor', AppColors.secondarySoft);

  // ════════════════════════════════════════════════════════════════
  //  Accent
  // ════════════════════════════════════════════════════════════════
  static Color get accent => _r('accentColor', AppColors.accent);
  static Color get accentSoft => _r('accentSoftColor', AppColors.accentSoft);

  // ════════════════════════════════════════════════════════════════
  //  Backgrounds
  // ════════════════════════════════════════════════════════════════
  static Color get background => _r('backgroundColor', AppColors.background);
  static Color get surface => _r('surfaceColor', AppColors.surface);
  static Color get surfaceVariant => _r('surfaceVariantColor', AppColors.surfaceVariant);
  static Color get cardBackground => _r('cardBackgroundColor', AppColors.cardBackground);

  // ════════════════════════════════════════════════════════════════
  //  Text colors
  // ════════════════════════════════════════════════════════════════
  static Color get textPrimary => _r('textPrimaryColor', AppColors.textPrimary);
  static Color get textSecondary => _r('textSecondaryColor', AppColors.textSecondary);
  static Color get textHint => _r('textHintColor', AppColors.textHint);
  static Color get textOnPrimary => _r('textOnPrimaryColor', AppColors.textOnPrimary);
  static Color get textOnSecondary => _r('textOnSecondaryColor', AppColors.textOnSecondary);

  // ════════════════════════════════════════════════════════════════
  //  Borders
  // ════════════════════════════════════════════════════════════════
  static Color get border => _r('borderColor', AppColors.border);
  static Color get divider => _r('dividerColor', AppColors.divider);

  // ════════════════════════════════════════════════════════════════
  //  Status
  // ════════════════════════════════════════════════════════════════
  static Color get success => _r('successColor', AppColors.success);
  static Color get warning => _r('warningColor', AppColors.warning);
  static Color get error => _r('errorColor', AppColors.error);
  static Color get info => _r('infoColor', AppColors.info);

  // ════════════════════════════════════════════════════════════════
  //  Category colors
  // ════════════════════════════════════════════════════════════════
  static Color get categoryQuestions => _r('categoryQuestionsColor', AppColors.categoryQuestions);
  static Color get categoryTips => _r('categoryTipsColor', AppColors.categoryTips);
  static Color get categoryRecommendations => _r('categoryRecommendationsColor', AppColors.categoryRecommendations);
  static Color get categoryMoments => _r('categoryMomentsColor', AppColors.categoryMoments);
  static Color get categoryHelp => _r('categoryHelpColor', AppColors.categoryHelp);

  // ════════════════════════════════════════════════════════════════
  //  Tracking colors
  // ════════════════════════════════════════════════════════════════
  static Color get trackingFeeding => _r('trackingFeedingColor', AppColors.trackingFeeding);
  static Color get trackingSleep => _r('trackingSleepColor', AppColors.trackingSleep);
  static Color get trackingGrowth => _r('trackingGrowthColor', AppColors.trackingGrowth);
  static Color get trackingDiaper => _r('trackingDiaperColor', AppColors.trackingDiaper);
  static Color get trackingHealth => _r('trackingHealthColor', AppColors.trackingHealth);

  // ════════════════════════════════════════════════════════════════
  //  Dark mode colors
  // ════════════════════════════════════════════════════════════════
  static Color get darkBackground => _r('darkBackgroundColor', AppColors.darkBackground);
  static Color get darkSurface => _r('darkSurfaceColor', AppColors.darkSurface);
  static Color get darkCard => _r('darkCardColor', AppColors.darkCard);
  static Color get darkTextPrimary => _r('darkTextPrimaryColor', AppColors.darkTextPrimary);
  static Color get darkTextSecondary => _r('darkTextSecondaryColor', AppColors.darkTextSecondary);

  // ════════════════════════════════════════════════════════════════
  //  Auto-derived gradients
  // ════════════════════════════════════════════════════════════════
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get momGradient => LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get premiumGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════
  //  REGISTRY: for admin UI - grouped by family
  // ════════════════════════════════════════════════════════════════
  static const Map<String, Map<String, String>> registry = {
    'ראשי': {
      'primaryColor': 'צבע ראשי',
      'primaryLightColor': 'ראשי בהיר',
      'primaryDarkColor': 'ראשי כהה',
      'primarySoftColor': 'ראשי רך',
      'primaryMistColor': 'ראשי ערפילי',
    },
    'משני': {
      'secondaryColor': 'צבע משני',
      'secondaryLightColor': 'משני בהיר',
      'secondaryDarkColor': 'משני כהה',
      'secondarySoftColor': 'משני רך',
    },
    'הדגשה': {
      'accentColor': 'צבע הדגשה',
      'accentSoftColor': 'הדגשה רכה',
    },
    'רקע': {
      'backgroundColor': 'רקע כללי',
      'surfaceColor': 'משטח',
      'surfaceVariantColor': 'משטח משני',
      'cardBackgroundColor': 'רקע כרטיס',
    },
    'טקסט': {
      'textPrimaryColor': 'טקסט ראשי',
      'textSecondaryColor': 'טקסט משני',
      'textHintColor': 'טקסט רמז',
      'textOnPrimaryColor': 'טקסט על ראשי',
      'textOnSecondaryColor': 'טקסט על משני',
    },
    'גבולות': {
      'borderColor': 'צבע גבול',
      'dividerColor': 'צבע מפריד',
    },
    'סטטוס': {
      'successColor': 'הצלחה',
      'warningColor': 'אזהרה',
      'errorColor': 'שגיאה',
      'infoColor': 'מידע',
    },
    'מצב כהה': {
      'darkBackgroundColor': 'רקע כהה',
      'darkSurfaceColor': 'משטח כהה',
      'darkCardColor': 'כרטיס כהה',
      'darkTextPrimaryColor': 'טקסט ראשי כהה',
      'darkTextSecondaryColor': 'טקסט משני כהה',
    },
    'קטגוריות': {
      'categoryQuestionsColor': 'שאלות',
      'categoryTipsColor': 'טיפים',
      'categoryRecommendationsColor': 'המלצות',
      'categoryMomentsColor': 'רגעים',
      'categoryHelpColor': 'עזרה',
    },
    'מעקב': {
      'trackingFeedingColor': 'הזנה',
      'trackingSleepColor': 'שינה',
      'trackingGrowthColor': 'צמיחה',
      'trackingDiaperColor': 'חיתולים',
      'trackingHealthColor': 'בריאות',
    },
  };

  /// Helper to get hex string from a color.
  static String toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  /// Map of all current resolved colors as hex (for admin editor defaults).
  static Map<String, String> get allDefaults {
    final map = <String, String>{};
    map['primaryColor'] = toHex(AppColors.primary);
    map['primaryLightColor'] = toHex(AppColors.primaryLight);
    map['primaryDarkColor'] = toHex(AppColors.primaryDark);
    map['primarySoftColor'] = toHex(AppColors.primarySoft);
    map['primaryMistColor'] = toHex(AppColors.primaryMist);
    map['secondaryColor'] = toHex(AppColors.secondary);
    map['secondaryLightColor'] = toHex(AppColors.secondaryLight);
    map['secondaryDarkColor'] = toHex(AppColors.secondaryDark);
    map['secondarySoftColor'] = toHex(AppColors.secondarySoft);
    map['accentColor'] = toHex(AppColors.accent);
    map['accentSoftColor'] = toHex(AppColors.accentSoft);
    map['backgroundColor'] = toHex(AppColors.background);
    map['surfaceColor'] = toHex(AppColors.surface);
    map['surfaceVariantColor'] = toHex(AppColors.surfaceVariant);
    map['cardBackgroundColor'] = toHex(AppColors.cardBackground);
    map['textPrimaryColor'] = toHex(AppColors.textPrimary);
    map['textSecondaryColor'] = toHex(AppColors.textSecondary);
    map['textHintColor'] = toHex(AppColors.textHint);
    map['textOnPrimaryColor'] = toHex(AppColors.textOnPrimary);
    map['textOnSecondaryColor'] = toHex(AppColors.textOnSecondary);
    map['borderColor'] = toHex(AppColors.border);
    map['dividerColor'] = toHex(AppColors.divider);
    map['successColor'] = toHex(AppColors.success);
    map['warningColor'] = toHex(AppColors.warning);
    map['errorColor'] = toHex(AppColors.error);
    map['infoColor'] = toHex(AppColors.info);
    map['categoryQuestionsColor'] = toHex(AppColors.categoryQuestions);
    map['categoryTipsColor'] = toHex(AppColors.categoryTips);
    map['categoryRecommendationsColor'] = toHex(AppColors.categoryRecommendations);
    map['categoryMomentsColor'] = toHex(AppColors.categoryMoments);
    map['categoryHelpColor'] = toHex(AppColors.categoryHelp);
    map['trackingFeedingColor'] = toHex(AppColors.trackingFeeding);
    map['trackingSleepColor'] = toHex(AppColors.trackingSleep);
    map['trackingGrowthColor'] = toHex(AppColors.trackingGrowth);
    map['trackingDiaperColor'] = toHex(AppColors.trackingDiaper);
    map['trackingHealthColor'] = toHex(AppColors.trackingHealth);
    // Dark mode colors
    map['darkBackgroundColor'] = toHex(AppColors.darkBackground);
    map['darkSurfaceColor'] = toHex(AppColors.darkSurface);
    map['darkCardColor'] = toHex(AppColors.darkCard);
    map['darkTextPrimaryColor'] = toHex(AppColors.darkTextPrimary);
    map['darkTextSecondaryColor'] = toHex(AppColors.darkTextSecondary);
    return map;
  }
}
