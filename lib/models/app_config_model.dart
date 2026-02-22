// ═══════════════════════════════════════════════════════════════
// App Config Model - Complete Application Configuration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Complete App Configuration Model
/// Contains all app-wide settings including branding, features, and defaults
class AppConfiguration {
  final String appName;
  final String version;
  final BrandingConfig branding;
  final Map<String, bool> defaultFeatures;
  final Map<String, dynamic> settings;
  final DateTime? updatedAt;
  final String? updatedBy;

  const AppConfiguration({
    required this.appName,
    required this.version,
    required this.branding,
    this.defaultFeatures = const {},
    this.settings = const {},
    this.updatedAt,
    this.updatedBy,
  });

  /// Create from Firestore document data
  factory AppConfiguration.fromFirestore(Map<String, dynamic> data) {
    return AppConfiguration(
      appName: data['appName'] ?? 'MOMIT',
      version: data['version'] ?? '1.0.0',
      branding: data['branding'] != null
          ? BrandingConfig.fromMap(Map<String, dynamic>.from(data['branding']))
          : BrandingConfig.defaultConfig(),
      defaultFeatures: Map<String, bool>.from(data['defaultFeatures'] ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      updatedAt: data['updatedAt']?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'appName': appName,
      'version': version,
      'branding': branding.toMap(),
      'defaultFeatures': defaultFeatures,
      'settings': settings,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  /// Create from JSON (for local cache)
  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      appName: json['appName'] ?? 'MOMIT',
      version: json['version'] ?? '1.0.0',
      branding: json['branding'] != null
          ? BrandingConfig.fromMap(Map<String, dynamic>.from(json['branding']))
          : BrandingConfig.defaultConfig(),
      defaultFeatures: Map<String, bool>.from(json['defaultFeatures'] ?? {}),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      updatedBy: json['updatedBy'],
    );
  }

  /// Convert to JSON (for local cache)
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'version': version,
      'branding': branding.toMap(),
      'defaultFeatures': defaultFeatures,
      'settings': settings,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  /// Create a copy with updated fields
  AppConfiguration copyWith({
    String? appName,
    String? version,
    BrandingConfig? branding,
    Map<String, bool>? defaultFeatures,
    Map<String, dynamic>? settings,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppConfiguration(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      branding: branding ?? this.branding,
      defaultFeatures: defaultFeatures ?? this.defaultFeatures,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Default configuration
  factory AppConfiguration.defaultConfig() {
    return AppConfiguration(
      appName: 'MOMIT',
      version: '1.0.0',
      branding: BrandingConfig.defaultConfig(),
      defaultFeatures: {
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
      },
      settings: {
        'maintenanceMode': false,
        'maintenanceMessage': 'האפליקציה במצב תחזוקה. נחזור בקרוב!',
        'minAppVersion': '1.0.0',
        'forceUpdate': false,
        'updateMessage': 'גרסה חדשה זמינה! עדכני עכשיו כדי לקבל את התכונות החדשות.',
        'supportEmail': 'support@momit.co.il',
        'supportPhone': '',
      },
    );
  }

  @override
  String toString() {
    return 'AppConfiguration(appName: $appName, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfiguration &&
        other.appName == appName &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(appName, version);
}

/// Branding Configuration
/// Contains all branding-related settings
class BrandingConfig {
  final String appName;
  final String slogan;
  final String tagline;
  final String? logoUrl;
  final String? faviconUrl;
  final String? appIconUrl;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;

  const BrandingConfig({
    required this.appName,
    required this.slogan,
    required this.tagline,
    this.logoUrl,
    this.faviconUrl,
    this.appIconUrl,
    this.primaryColor = '#D4A1AC',
    this.secondaryColor = '#EDD3D8',
    this.accentColor = '#DBC8B0',
  });

  factory BrandingConfig.fromMap(Map<String, dynamic> map) {
    return BrandingConfig(
      appName: map['appName'] ?? 'MOMIT',
      slogan: map['slogan'] ?? 'הרשת החברתית לאמהות',
      tagline: map['tagline'] ?? 'מקום בטוח לשתף, ללמוד ולהתחבר',
      logoUrl: map['logoUrl'],
      faviconUrl: map['faviconUrl'],
      appIconUrl: map['appIconUrl'],
      primaryColor: map['primaryColor'] ?? '#D4A1AC',
      secondaryColor: map['secondaryColor'] ?? '#EDD3D8',
      accentColor: map['accentColor'] ?? '#DBC8B0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'slogan': slogan,
      'tagline': tagline,
      'logoUrl': logoUrl,
      'faviconUrl': faviconUrl,
      'appIconUrl': appIconUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
    };
  }

  factory BrandingConfig.fromJson(Map<String, dynamic> json) =>
      BrandingConfig.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  BrandingConfig copyWith({
    String? appName,
    String? slogan,
    String? tagline,
    String? logoUrl,
    String? faviconUrl,
    String? appIconUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
  }) {
    return BrandingConfig(
      appName: appName ?? this.appName,
      slogan: slogan ?? this.slogan,
      tagline: tagline ?? this.tagline,
      logoUrl: logoUrl ?? this.logoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      appIconUrl: appIconUrl ?? this.appIconUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  factory BrandingConfig.defaultConfig() {
    return const BrandingConfig(
      appName: 'MOMIT',
      slogan: 'הרשת החברתית לאמהות',
      tagline: 'מקום בטוח לשתף, ללמוד ולהתחבר עם אמהות אחרות',
      primaryColor: '#D4A1AC',
      secondaryColor: '#EDD3D8',
      accentColor: '#DBC8B0',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrandingConfig &&
        other.appName == appName &&
        other.slogan == slogan;
  }

  @override
  int get hashCode => Object.hash(appName, slogan);
}

/// Color Configuration
/// Represents a single color configuration with metadata
class AppColorConfig {
  final String key;
  final String value;
  final String name;
  final String? nameHe;
  final String? description;
  final bool isEnabled;

  const AppColorConfig({
    required this.key,
    required this.value,
    required this.name,
    this.nameHe,
    this.description,
    this.isEnabled = true,
  });

  factory AppColorConfig.fromMap(String key, Map<String, dynamic> map) {
    return AppColorConfig(
      key: key,
      value: map['value'] ?? '#D4A1AC',
      name: map['name'] ?? key,
      nameHe: map['nameHe'],
      description: map['description'],
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'name': name,
      'nameHe': nameHe,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  factory AppColorConfig.fromJson(Map<String, dynamic> json) =>
      AppColorConfig.fromMap(json['key'] ?? '', json);

  Map<String, dynamic> toJson() => {
        ...toMap(),
        'key': key,
      };

  AppColorConfig copyWith({
    String? key,
    String? value,
    String? name,
    String? nameHe,
    String? description,
    bool? isEnabled,
  }) {
    return AppColorConfig(
      key: key ?? this.key,
      value: value ?? this.value,
      name: name ?? this.name,
      nameHe: nameHe ?? this.nameHe,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert hex string to Flutter Color
  Color toColor() {
    try {
      String hex = value.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFFD4A1AC);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppColorConfig &&
        other.key == key &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => 'AppColorConfig($key: $value)';
}

/// Layout Configuration
/// Represents a layout configuration with padding, margins, and styling
class AppLayoutConfig {
  final String key;
  final double padding;
  final double margin;
  final double borderRadius;
  final double elevation;
  final String? backgroundColor;
  final Map<String, dynamic> customValues;

  const AppLayoutConfig({
    required this.key,
    this.padding = 16.0,
    this.margin = 8.0,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.backgroundColor,
    this.customValues = const {},
  });

  factory AppLayoutConfig.fromMap(String key, Map<String, dynamic> map) {
    return AppLayoutConfig(
      key: key,
      padding: (map['padding'] ?? 16.0).toDouble(),
      margin: (map['margin'] ?? 8.0).toDouble(),
      borderRadius: (map['borderRadius'] ?? 12.0).toDouble(),
      elevation: (map['elevation'] ?? 2.0).toDouble(),
      backgroundColor: map['backgroundColor'],
      customValues: Map<String, dynamic>.from(map['customValues'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'padding': padding,
      'margin': margin,
      'borderRadius': borderRadius,
      'elevation': elevation,
      'backgroundColor': backgroundColor,
      'customValues': customValues,
    };
  }

  factory AppLayoutConfig.fromJson(Map<String, dynamic> json) =>
      AppLayoutConfig.fromMap(json['key'] ?? '', json);

  Map<String, dynamic> toJson() => {
        ...toMap(),
        'key': key,
      };

  AppLayoutConfig copyWith({
    String? key,
    double? padding,
    double? margin,
    double? borderRadius,
    double? elevation,
    String? backgroundColor,
    Map<String, dynamic>? customValues,
  }) {
    return AppLayoutConfig(
      key: key ?? this.key,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      customValues: customValues ?? this.customValues,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppLayoutConfig &&
        other.key == key &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(key, padding);

  @override
  String toString() => 'AppLayoutConfig($key)';
}

/// Home Widget Configuration
/// Represents a single widget configuration on the home screen
class HomeWidgetConfig {
  final String key;
  final String type;
  final String title;
  final String? subtitle;
  final int order;
  final bool isVisible;
  final bool isEnabled;
  final Map<String, dynamic> data;
  final Map<String, dynamic> styling;

  const HomeWidgetConfig({
    required this.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.order = 0,
    this.isVisible = true,
    this.isEnabled = true,
    this.data = const {},
    this.styling = const {},
  });

  factory HomeWidgetConfig.fromMap(Map<String, dynamic> map) {
    return HomeWidgetConfig(
      key: map['key'] ?? '',
      type: map['type'] ?? 'default',
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      order: map['order'] ?? 0,
      isVisible: map['isVisible'] ?? true,
      isEnabled: map['isEnabled'] ?? true,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      styling: Map<String, dynamic>.from(map['styling'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'order': order,
      'isVisible': isVisible,
      'isEnabled': isEnabled,
      'data': data,
      'styling': styling,
    };
  }

  factory HomeWidgetConfig.fromJson(Map<String, dynamic> json) =>
      HomeWidgetConfig.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  HomeWidgetConfig copyWith({
    String? key,
    String? type,
    String? title,
    String? subtitle,
    int? order,
    bool? isVisible,
    bool? isEnabled,
    Map<String, dynamic>? data,
    Map<String, dynamic>? styling,
  }) {
    return HomeWidgetConfig(
      key: key ?? this.key,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      isEnabled: isEnabled ?? this.isEnabled,
      data: data ?? this.data,
      styling: styling ?? this.styling,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeWidgetConfig &&
        other.key == key &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(key, order);

  @override
  String toString() => 'HomeWidgetConfig($key: $title)';
}

/// Home Layout Configuration
/// Contains the complete home screen layout configuration
class HomeLayoutConfig {
  final Map<String, HomeWidgetConfig> widgets;
  final String layoutType;
  final Map<String, dynamic> settings;

  const HomeLayoutConfig({
    this.widgets = const {},
    this.layoutType = 'default',
    this.settings = const {},
  });

  factory HomeLayoutConfig.fromMap(Map<String, dynamic> map) {
    final widgetsMap = <String, HomeWidgetConfig>{};
    final widgetsData = map['widgets'] as Map<String, dynamic>?;
    if (widgetsData != null) {
      widgetsData.forEach((key, value) {
        if (value is Map) {
          widgetsMap[key] = HomeWidgetConfig.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return HomeLayoutConfig(
      widgets: widgetsMap,
      layoutType: map['layoutType'] ?? 'default',
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'widgets': widgets.map((key, value) => MapEntry(key, value.toMap())),
      'layoutType': layoutType,
      'settings': settings,
    };
  }

  factory HomeLayoutConfig.fromJson(Map<String, dynamic> json) =>
      HomeLayoutConfig.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  HomeLayoutConfig copyWith({
    Map<String, HomeWidgetConfig>? widgets,
    String? layoutType,
    Map<String, dynamic>? settings,
  }) {
    return HomeLayoutConfig(
      widgets: widgets ?? this.widgets,
      layoutType: layoutType ?? this.layoutType,
      settings: settings ?? this.settings,
    );
  }

  /// Get sorted widgets by order
  List<HomeWidgetConfig> get sortedWidgets {
    final list = widgets.values.toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list.where((w) => w.isVisible && w.isEnabled).toList();
  }

  factory HomeLayoutConfig.defaultConfig() {
    return HomeLayoutConfig(
      layoutType: 'default',
      widgets: {
        'welcome': const HomeWidgetConfig(
          key: 'welcome',
          type: 'welcome_card',
          title: 'ברוכה הבאה',
          order: 0,
        ),
        'daily_tip': const HomeWidgetConfig(
          key: 'daily_tip',
          type: 'daily_tip',
          title: 'הטיפ היומי',
          order: 1,
        ),
        'quick_actions': const HomeWidgetConfig(
          key: 'quick_actions',
          type: 'quick_actions',
          title: 'גישה מהירה',
          order: 2,
        ),
        'feed': const HomeWidgetConfig(
          key: 'feed',
          type: 'feed_preview',
          title: 'הפיד שלך',
          order: 3,
        ),
        'events': const HomeWidgetConfig(
          key: 'events',
          type: 'events_preview',
          title: 'אירועים קרובים',
          order: 4,
        ),
        'marketplace': const HomeWidgetConfig(
          key: 'marketplace',
          type: 'marketplace_preview',
          title: 'חדש בשוק',
          order: 5,
        ),
      },
      settings: {
        'showWelcomeOnFirstVisit': true,
        'animateWidgets': true,
        'refreshInterval': 300,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeLayoutConfig &&
        other.layoutType == layoutType &&
        other.widgets.length == widgets.length;
  }

  @override
  int get hashCode => Object.hash(layoutType, widgets.length);

  @override
  String toString() => 'HomeLayoutConfig($layoutType, ${widgets.length} widgets)';
}
