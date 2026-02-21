import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing dynamic app sections and content.
/// Handles real-time updates for dynamic_sections and content_management collections.
class DynamicConfigService extends ChangeNotifier {
  static final DynamicConfigService _instance = DynamicConfigService._internal();
  static DynamicConfigService get instance => _instance;

  DynamicConfigService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════
  //  STREAMS - Real-time data
  // ════════════════════════════════════════════════════════════════

  /// Stream of all dynamic sections ordered by display order
  Stream<List<DynamicSection>> get dynamicSectionsStream =>
      _db.collection('dynamic_sections')
          .orderBy('order', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => DynamicSection.fromMap({'id': d.id, ...d.data()}))
              .toList());

  /// Stream of active sections only
  Stream<List<DynamicSection>> get activeSectionsStream =>
      _db.collection('dynamic_sections')
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => DynamicSection.fromMap({'id': d.id, ...d.data()}))
              .toList());

  /// Stream of a specific section by ID
  Stream<DynamicSection?> getSectionStream(String sectionId) =>
      _db.collection('dynamic_sections').doc(sectionId).snapshots().map(
          (snap) => snap.exists
              ? DynamicSection.fromMap({'id': snap.id, ...snap.data()!})
              : null);

  /// Stream of content items for a specific section
  Stream<List<ContentItem>> getContentForSectionStream(String sectionId) =>
      _db.collection('content_management')
          .where('sectionId', isEqualTo: sectionId)
          .where('isPublished', isEqualTo: true)
          .orderBy('order', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ContentItem.fromMap({'id': d.id, ...d.data()}))
              .toList());

  /// Stream of all content items (for admin)
  Stream<List<ContentItem>> get allContentStream =>
      _db.collection('content_management')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ContentItem.fromMap({'id': d.id, ...d.data()}))
              .toList());

  /// Stream of app configuration
  Stream<AppConfig> get appConfigStream =>
      _db.collection('app_config').doc('main').snapshots().map((snap) =>
          snap.exists
              ? AppConfig.fromMap({'id': snap.id, ...snap.data()!})
              : AppConfig.defaultConfig());

  // ════════════════════════════════════════════════════════════════
  //  CRUD - Dynamic Sections
  // ════════════════════════════════════════════════════════════════

  Future<String> createSection(DynamicSection section) async {
    final docRef = await _db.collection('dynamic_sections').add({
      ...section.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateSection(String sectionId, Map<String, dynamic> data) async {
    await _db.collection('dynamic_sections').doc(sectionId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSectionOrder(String sectionId, int newOrder) async {
    await _db.collection('dynamic_sections').doc(sectionId).update({
      'order': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleSectionActive(String sectionId, bool isActive) async {
    await _db.collection('dynamic_sections').doc(sectionId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSection(String sectionId) async {
    // Delete associated content first
    final contentQuery = await _db.collection('content_management')
        .where('sectionId', isEqualTo: sectionId)
        .get();
    
    final batch = _db.batch();
    for (final doc in contentQuery.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('dynamic_sections').doc(sectionId));
    await batch.commit();
  }

  /// Reorder sections - updates order for multiple sections
  Future<void> reorderSections(List<String> sectionIds) async {
    final batch = _db.batch();
    for (int i = 0; i < sectionIds.length; i++) {
      batch.update(
        _db.collection('dynamic_sections').doc(sectionIds[i]),
        {'order': i, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════
  //  CRUD - Content Management
  // ════════════════════════════════════════════════════════════════

  Future<String> createContent(ContentItem content) async {
    final docRef = await _db.collection('content_management').add({
      ...content.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateContent(String contentId, Map<String, dynamic> data) async {
    await _db.collection('content_management').doc(contentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateContentOrder(String contentId, int newOrder) async {
    await _db.collection('content_management').doc(contentId).update({
      'order': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleContentPublished(String contentId, bool isPublished) async {
    await _db.collection('content_management').doc(contentId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContent(String contentId) async {
    await _db.collection('content_management').doc(contentId).delete();
  }

  /// Reorder content items within a section
  Future<void> reorderContent(String sectionId, List<String> contentIds) async {
    final batch = _db.batch();
    for (int i = 0; i < contentIds.length; i++) {
      batch.update(
        _db.collection('content_management').doc(contentIds[i]),
        {'order': i, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════════
  //  CRUD - App Config
  // ════════════════════════════════════════════════════════════════

  Future<void> updateAppConfig(AppConfig config) async {
    await _db.collection('app_config').doc('main').set({
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNavigationOrder(List<String> navOrder) async {
    await _db.collection('app_config').doc('main').set({
      'navigationOrder': navOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update the full navigation items configuration
  Future<void> updateNavigationItems(List<NavigationItem> items) async {
    final itemsData = items
        .asMap()
        .entries
        .map((e) => {
              ...e.value.toMap(),
              'order': e.key,
            })
        .toList();

    await _db.collection('app_config').doc('main').set({
      'navigationItems': itemsData,
      'navigationOrder': items.map((e) => e.key).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Toggle visibility of a navigation item
  Future<void> toggleNavigationItemVisibility(String itemKey, bool isVisible) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['navigationItems'] as List<dynamic>? ?? []).toList();

    // Find and update the item
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      if (item['key'] == itemKey) {
        items[i] = {
          ...item,
          'isVisible': isVisible,
        };
        break;
      }
    }

    await _db.collection('app_config').doc('main').set({
      'navigationItems': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Reorder navigation items
  Future<void> reorderNavigationItems(List<String> orderedKeys) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['navigationItems'] as List<dynamic>? ?? []).toList();

    // Create a map of key to item
    final itemsMap = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = item['key'] as String?;
      if (key != null) {
        itemsMap[key] = item as Map<String, dynamic>;
      }
    }

    // Reorder based on orderedKeys
    final reorderedItems = orderedKeys
        .where((key) => itemsMap.containsKey(key))
        .map((key) => itemsMap[key]!)
        .toList();

    await _db.collection('app_config').doc('main').set({
      'navigationItems': reorderedItems,
      'navigationOrder': orderedKeys,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update navigation item label
  Future<void> updateNavigationItemLabel(String itemKey, String newLabel, {String? labelHe}) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['navigationItems'] as List<dynamic>? ?? []).toList();

    // Find and update the item
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      if (item['key'] == itemKey) {
        items[i] = {
          ...item,
          'label': newLabel,
          if (labelHe != null) 'labelHe': labelHe,
        };
        break;
      }
    }

    await _db.collection('app_config').doc('main').set({
      'navigationItems': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ════════════════════════════════════════════════════════════════
  //  CRUD - Quick Access Items
  // ════════════════════════════════════════════════════════════════

  /// Update the full quick access items configuration
  Future<void> updateQuickAccessItems(List<QuickAccessItem> items) async {
    final itemsData = items
        .asMap()
        .entries
        .map((e) => {
              ...e.value.toMap(),
              'order': e.key,
            })
        .toList();

    await _db.collection('app_config').doc('main').set({
      'quickAccessItems': itemsData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Toggle visibility of a quick access item
  Future<void> toggleQuickAccessItemVisibility(String itemKey, bool isVisible) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['quickAccessItems'] as List<dynamic>? ?? []).toList();

    // Find and update the item
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      if (item['key'] == itemKey) {
        items[i] = {
          ...item,
          'isVisible': isVisible,
        };
        break;
      }
    }

    await _db.collection('app_config').doc('main').set({
      'quickAccessItems': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Reorder quick access items
  Future<void> reorderQuickAccessItems(List<String> orderedKeys) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['quickAccessItems'] as List<dynamic>? ?? []).toList();

    // Create a map of key to item
    final itemsMap = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = item['key'] as String?;
      if (key != null) {
        itemsMap[key] = item as Map<String, dynamic>;
      }
    }

    // Reorder based on orderedKeys
    final reorderedItems = orderedKeys
        .where((key) => itemsMap.containsKey(key))
        .map((key) => itemsMap[key]!)
        .toList();

    await _db.collection('app_config').doc('main').set({
      'quickAccessItems': reorderedItems,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update quick access item label and icon
  Future<void> updateQuickAccessItem(String itemKey, {
    String? newLabel,
    String? labelHe,
    String? iconName,
    String? color,
  }) async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return;

    final data = doc.data();
    final items = (data?['quickAccessItems'] as List<dynamic>? ?? []).toList();

    // Find and update the item
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      if (item['key'] == itemKey) {
        items[i] = {
          ...item,
          if (newLabel != null) 'label': newLabel,
          if (labelHe != null) 'labelHe': labelHe,
          if (iconName != null) 'iconName': iconName,
          if (color != null) 'color': color,
        };
        break;
      }
    }

    await _db.collection('app_config').doc('main').set({
      'quickAccessItems': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ════════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ════════════════════════════════════════════════════════════════

  /// Seeds default sections if none exist
  Future<void> seedDefaultSections() async {
    final existing = await _db.collection('dynamic_sections').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    final defaults = _defaultSections;
    
    for (final section in defaults) {
      final ref = _db.collection('dynamic_sections').doc();
      batch.set(ref, {
        ...section.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    debugPrint('[DynamicConfigService] Seeded ${defaults.length} default sections');
  }

  /// Seeds default app config with navigation and quick access if none exists
  Future<void> seedDefaultAppConfig() async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (doc.exists) return;

    final defaultConfig = AppConfig.defaultConfig();
    
    await _db.collection('app_config').doc('main').set({
      'appName': defaultConfig.appName,
      'slogan': defaultConfig.slogan,
      'navigationItems': defaultConfig.navigationItems.map((e) => e.toMap()).toList(),
      'navigationOrder': defaultConfig.navigationOrder,
      'quickAccessItems': defaultConfig.quickAccessItems.map((e) => e.toMap()).toList(),
      'featureVisibility': defaultConfig.featureVisibility,
      'themeSettings': defaultConfig.themeSettings,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('[DynamicConfigService] Seeded default app config with navigation and quick access');
  }

  /// Seeds all defaults (sections and app config)
  Future<void> seedAllDefaults() async {
    await seedDefaultSections();
    await seedDefaultAppConfig();
  }

  static final List<DynamicSection> _defaultSections = [
    DynamicSection(
      id: '',
      key: 'hero',
      name: 'כותרת ראשית',
      description: 'אזור הכותרת הראשית בדף הבית',
      type: SectionType.hero,
      iconName: 'view_day',
      route: '/home',
      order: 0,
      isActive: true,
      settings: {'backgroundImage': '', 'textAlign': 'center'},
    ),
    DynamicSection(
      id: '',
      key: 'features',
      name: 'תכונות עיקריות',
      description: 'כרטיסיות תכונות בדף הבית',
      type: SectionType.features,
      iconName: 'grid',
      route: '/features',
      order: 1,
      isActive: true,
      settings: {'columns': 3, 'showIcons': true},
    ),
    DynamicSection(
      id: '',
      key: 'tips',
      name: 'טיפים יומיים',
      description: 'אזור טיפים בדף הבית',
      type: SectionType.content,
      iconName: 'tips',
      route: '/tips',
      order: 2,
      isActive: true,
      settings: {'itemsToShow': 3, 'autoRotate': true},
    ),
    DynamicSection(
      id: '',
      key: 'community',
      name: 'קהילה',
      description: 'אזור קהילה בדף הבית',
      type: SectionType.community,
      iconName: 'groups',
      route: '/community',
      order: 3,
      isActive: true,
      settings: {'showStats': true},
    ),
    DynamicSection(
      id: '',
      key: 'cta',
      name: 'קריאה לפעולה',
      description: 'כפתורי פעולה בדף הבית',
      type: SectionType.cta,
      iconName: 'touch_app',
      route: '/cta',
      order: 4,
      isActive: true,
      settings: {'buttons': 2},
    ),
  ];
}

// ════════════════════════════════════════════════════════════════
//  MODEL CLASSES
// ════════════════════════════════════════════════════════════════

enum SectionType {
  hero,
  features,
  content,
  community,
  cta,
  custom,
  carousel,
  grid;

  String get displayName {
    switch (this) {
      case SectionType.hero: return 'כותרת ראשית';
      case SectionType.features: return 'תכונות';
      case SectionType.content: return 'תוכן';
      case SectionType.community: return 'קהילה';
      case SectionType.cta: return 'קריאה לפעולה';
      case SectionType.custom: return 'מותאם אישית';
      case SectionType.carousel: return 'קרוסלה';
      case SectionType.grid: return 'רשת';
    }
  }

  IconData get icon {
    switch (this) {
      case SectionType.hero: return Icons.view_day_rounded;
      case SectionType.features: return Icons.grid_view_rounded;
      case SectionType.content: return Icons.article_rounded;
      case SectionType.community: return Icons.people_rounded;
      case SectionType.cta: return Icons.touch_app_rounded;
      case SectionType.custom: return Icons.dashboard_customize_rounded;
      case SectionType.carousel: return Icons.view_carousel_rounded;
      case SectionType.grid: return Icons.grid_on_rounded;
    }
  }
}

class DynamicSection {
  final String id;
  final String key;
  final String name;
  final String description;
  final SectionType type;
  final String iconName; // Icon identifier for the section
  final String route; // Navigation route for the section
  final int order;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DynamicSection({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    this.iconName = 'dashboard_customize',
    this.route = '',
    required this.order,
    required this.isActive,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory DynamicSection.fromMap(Map<String, dynamic> map) {
    return DynamicSection(
      id: map['id'] ?? '',
      key: map['key'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: SectionType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'custom'),
        orElse: () => SectionType.custom,
      ),
      iconName: map['iconName'] ?? 'dashboard_customize',
      route: map['route'] ?? '',
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'name': name,
    'description': description,
    'type': type.name,
    'iconName': iconName,
    'route': route,
    'order': order,
    'isActive': isActive,
    'settings': settings,
  };

  /// Get the IconData for this section based on iconName
  IconData get iconData => _iconNameToIconData(iconName);

  static IconData _iconNameToIconData(String name) {
    switch (name) {
      case 'home': return Icons.home_rounded;
      case 'person': return Icons.person_rounded;
      case 'chat': return Icons.chat_rounded;
      case 'event': return Icons.event_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'info': return Icons.info_rounded;
      case 'settings': return Icons.settings_rounded;
      case 'notifications': return Icons.notifications_rounded;
      case 'search': return Icons.search_rounded;
      case 'menu': return Icons.menu_rounded;
      case 'dashboard': return Icons.dashboard_rounded;
      case 'article': return Icons.article_rounded;
      case 'image': return Icons.image_rounded;
      case 'video': return Icons.video_library_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'map': return Icons.map_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'email': return Icons.email_rounded;
      case 'share': return Icons.share_rounded;
      case 'star': return Icons.star_rounded;
      case 'bookmark': return Icons.bookmark_rounded;
      case 'help': return Icons.help_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'schedule': return Icons.schedule_rounded;
      case 'calendar': return Icons.calendar_today_rounded;
      case 'camera': return Icons.camera_alt_rounded;
      case 'location': return Icons.location_on_rounded;
      case 'groups': return Icons.groups_rounded;
      case 'work': return Icons.work_rounded;
      case 'school': return Icons.school_rounded;
      case 'health': return Icons.favorite_border_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'family': return Icons.family_restroom_rounded;
      case 'local_hospital': return Icons.local_hospital_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'store': return Icons.store_rounded;
      case 'support': return Icons.support_agent_rounded;
      case 'tips': return Icons.lightbulb_rounded;
      case 'news': return Icons.newspaper_rounded;
      case 'forum': return Icons.forum_rounded;
      case 'list': return Icons.list_rounded;
      case 'grid': return Icons.grid_view_rounded;
      case 'view_day': return Icons.view_day_rounded;
      case 'touch_app': return Icons.touch_app_rounded;
      case 'view_carousel': return Icons.view_carousel_rounded;
      case 'grid_on': return Icons.grid_on_rounded;
      default: return Icons.dashboard_customize_rounded;
    }
  }

  DynamicSection copyWith({
    String? id,
    String? key,
    String? name,
    String? description,
    SectionType? type,
    String? iconName,
    String? route,
    int? order,
    bool? isActive,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DynamicSection(
    id: id ?? this.id,
    key: key ?? this.key,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    iconName: iconName ?? this.iconName,
    route: route ?? this.route,
    order: order ?? this.order,
    isActive: isActive ?? this.isActive,
    settings: settings ?? this.settings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum ContentType {
  text,
  image,
  video,
  link,
  button,
  card,
  banner;

  String get displayName {
    switch (this) {
      case ContentType.text: return 'טקסט';
      case ContentType.image: return 'תמונה';
      case ContentType.video: return 'וידאו';
      case ContentType.link: return 'קישור';
      case ContentType.button: return 'כפתור';
      case ContentType.card: return 'כרטיס';
      case ContentType.banner: return 'באנר';
    }
  }
}

class ContentItem {
  final String id;
  final String sectionId;
  final String title;
  final String subtitle;
  final String body;
  final ContentType type;
  final String? mediaUrl;
  final String? linkUrl;
  final String? linkText;
  final int order;
  final bool isPublished;
  final Map<String, dynamic> metadata;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContentItem({
    required this.id,
    required this.sectionId,
    required this.title,
    this.subtitle = '',
    this.body = '',
    required this.type,
    this.mediaUrl,
    this.linkUrl,
    this.linkText,
    required this.order,
    this.isPublished = true,
    this.metadata = const {},
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ContentItem.fromMap(Map<String, dynamic> map) {
    return ContentItem(
      id: map['id'] ?? '',
      sectionId: map['sectionId'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      body: map['body'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => ContentType.text,
      ),
      mediaUrl: map['mediaUrl'],
      linkUrl: map['linkUrl'],
      linkText: map['linkText'],
      order: map['order'] ?? 0,
      isPublished: map['isPublished'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sectionId': sectionId,
    'title': title,
    'subtitle': subtitle,
    'body': body,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'linkUrl': linkUrl,
    'linkText': linkText,
    'order': order,
    'isPublished': isPublished,
    'metadata': metadata,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
  };

  ContentItem copyWith({
    String? id,
    String? sectionId,
    String? title,
    String? subtitle,
    String? body,
    ContentType? type,
    String? mediaUrl,
    String? linkUrl,
    String? linkText,
    int? order,
    bool? isPublished,
    Map<String, dynamic>? metadata,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContentItem(
    id: id ?? this.id,
    sectionId: sectionId ?? this.sectionId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    body: body ?? this.body,
    type: type ?? this.type,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    linkUrl: linkUrl ?? this.linkUrl,
    linkText: linkText ?? this.linkText,
    order: order ?? this.order,
    isPublished: isPublished ?? this.isPublished,
    metadata: metadata ?? this.metadata,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Navigation item for bottom navigation bar
class NavigationItem {
  final String id;
  final String key;
  final String label;
  final String labelHe;
  final String iconName;
  final String activeIconName;
  final String route;
  final int order;
  final bool isVisible;
  final Map<String, dynamic> metadata;

  NavigationItem({
    required this.id,
    required this.key,
    required this.label,
    required this.labelHe,
    required this.iconName,
    required this.activeIconName,
    required this.route,
    required this.order,
    this.isVisible = true,
    this.metadata = const {},
  });

  factory NavigationItem.fromMap(Map<String, dynamic> map) {
    return NavigationItem(
      id: map['id'] ?? '',
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      labelHe: map['labelHe'] ?? map['label'] ?? '',
      iconName: map['iconName'] ?? 'home_outlined',
      activeIconName: map['activeIconName'] ?? 'home_rounded',
      route: map['route'] ?? '',
      order: map['order'] ?? 0,
      isVisible: map['isVisible'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'label': label,
    'labelHe': labelHe,
    'iconName': iconName,
    'activeIconName': activeIconName,
    'route': route,
    'order': order,
    'isVisible': isVisible,
    'metadata': metadata,
  };

  NavigationItem copyWith({
    String? id,
    String? key,
    String? label,
    String? labelHe,
    String? iconName,
    String? activeIconName,
    String? route,
    int? order,
    bool? isVisible,
    Map<String, dynamic>? metadata,
  }) => NavigationItem(
    id: id ?? this.id,
    key: key ?? this.key,
    label: label ?? this.label,
    labelHe: labelHe ?? this.labelHe,
    iconName: iconName ?? this.iconName,
    activeIconName: activeIconName ?? this.activeIconName,
    route: route ?? this.route,
    order: order ?? this.order,
    isVisible: isVisible ?? this.isVisible,
    metadata: metadata ?? this.metadata,
  );

  /// Get IconData for the inactive state
  IconData get iconData => _iconNameToIconData(iconName);

  /// Get IconData for the active state
  IconData get activeIconData => _iconNameToIconData(activeIconName);

  static IconData _iconNameToIconData(String name) {
    switch (name) {
      case 'home_outlined': return Icons.home_outlined;
      case 'home_rounded': return Icons.home_rounded;
      case 'child_care_outlined': return Icons.child_care_outlined;
      case 'child_care': return Icons.child_care;
      case 'child_care_rounded': return Icons.child_care_rounded;
      case 'event_outlined': return Icons.event_outlined;
      case 'event_rounded': return Icons.event_rounded;
      case 'chat_bubble_outline': return Icons.chat_bubble_outline;
      case 'chat_bubble_rounded': return Icons.chat_bubble_rounded;
      case 'person_outline_rounded': return Icons.person_outline_rounded;
      case 'person_rounded': return Icons.person_rounded;
      case 'person_outline': return Icons.person_outline;
      case 'person': return Icons.person;
      case 'chat_outlined': return Icons.chat_outlined;
      case 'chat_rounded': return Icons.chat_rounded;
      case 'chat': return Icons.chat;
      case 'calendar_today_outlined': return Icons.calendar_today_outlined;
      case 'calendar_today_rounded': return Icons.calendar_today_rounded;
      case 'favorite_outline_rounded': return Icons.favorite_outline_rounded;
      case 'favorite_rounded': return Icons.favorite_rounded;
      case 'feed_outlined': return Icons.feed_outlined;
      case 'feed_rounded': return Icons.feed_rounded;
      case 'forum_outlined': return Icons.forum_outlined;
      case 'forum_rounded': return Icons.forum_rounded;
      case 'groups_outlined': return Icons.groups_outlined;
      case 'groups_rounded': return Icons.groups_rounded;
      case 'store_outlined': return Icons.store_outlined;
      case 'store_rounded': return Icons.store_rounded;
      case 'shopping_bag_outlined': return Icons.shopping_bag_outlined;
      case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'settings_outlined': return Icons.settings_outlined;
      case 'settings_rounded': return Icons.settings_rounded;
      case 'search_outlined': return Icons.search_outlined;
      case 'search_rounded': return Icons.search_rounded;
      case 'notifications_outlined': return Icons.notifications_outlined;
      case 'notifications_rounded': return Icons.notifications_rounded;
      case 'add_circle_outline': return Icons.add_circle_outline;
      case 'add_circle_rounded': return Icons.add_circle_rounded;
      case 'menu': return Icons.menu;
      case 'menu_rounded': return Icons.menu_rounded;
      default: return Icons.circle;
    }
  }
}

class QuickAccessItem {
  final String id;
  final String key;
  final String label;
  final String labelHe;
  final String iconName;
  final String color;
  final String route;
  final int order;
  final bool isVisible;
  final Map<String, dynamic> metadata;

  QuickAccessItem({
    required this.id,
    required this.key,
    required this.label,
    required this.labelHe,
    required this.iconName,
    required this.color,
    required this.route,
    required this.order,
    this.isVisible = true,
    this.metadata = const {},
  });

  factory QuickAccessItem.fromMap(Map<String, dynamic> map) {
    return QuickAccessItem(
      id: map['id'] ?? '',
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      labelHe: map['labelHe'] ?? map['label'] ?? '',
      iconName: map['iconName'] ?? 'circle',
      color: map['color'] ?? '#D1C2D3',
      route: map['route'] ?? '',
      order: map['order'] ?? 0,
      isVisible: map['isVisible'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'label': label,
    'labelHe': labelHe,
    'iconName': iconName,
    'color': color,
    'route': route,
    'order': order,
    'isVisible': isVisible,
    'metadata': metadata,
  };

  QuickAccessItem copyWith({
    String? id,
    String? key,
    String? label,
    String? labelHe,
    String? iconName,
    String? color,
    String? route,
    int? order,
    bool? isVisible,
    Map<String, dynamic>? metadata,
  }) => QuickAccessItem(
    id: id ?? this.id,
    key: key ?? this.key,
    label: label ?? this.label,
    labelHe: labelHe ?? this.labelHe,
    iconName: iconName ?? this.iconName,
    color: color ?? this.color,
    route: route ?? this.route,
    order: order ?? this.order,
    isVisible: isVisible ?? this.isVisible,
    metadata: metadata ?? this.metadata,
  );

  /// Get IconData based on iconName
  IconData get iconData => _iconNameToIconData(iconName);

  static IconData _iconNameToIconData(String name) {
    switch (name) {
      case 'auto_awesome': return Icons.auto_awesome;
      case 'sos': return Icons.sos_rounded;
      case 'chat': return Icons.chat_rounded;
      case 'volunteer_activism': return Icons.volunteer_activism_rounded;
      case 'mood': return Icons.mood_rounded;
      case 'photo_album': return Icons.photo_album_rounded;
      case 'local_hospital': return Icons.local_hospital_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'home': return Icons.home_rounded;
      case 'person': return Icons.person_rounded;
      case 'event': return Icons.event_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'info': return Icons.info_rounded;
      case 'settings': return Icons.settings_rounded;
      case 'notifications': return Icons.notifications_rounded;
      case 'search': return Icons.search_rounded;
      case 'menu': return Icons.menu_rounded;
      case 'dashboard': return Icons.dashboard_rounded;
      case 'article': return Icons.article_rounded;
      case 'image': return Icons.image_rounded;
      case 'video': return Icons.video_library_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'map': return Icons.map_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'email': return Icons.email_rounded;
      case 'share': return Icons.share_rounded;
      case 'star': return Icons.star_rounded;
      case 'bookmark': return Icons.bookmark_rounded;
      case 'help': return Icons.help_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'schedule': return Icons.schedule_rounded;
      case 'calendar': return Icons.calendar_today_rounded;
      case 'camera': return Icons.camera_alt_rounded;
      case 'location': return Icons.location_on_rounded;
      case 'groups': return Icons.groups_rounded;
      case 'work': return Icons.work_rounded;
      case 'school': return Icons.school_rounded;
      case 'health': return Icons.favorite_border_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'family': return Icons.family_restroom_rounded;
      case 'store': return Icons.store_rounded;
      case 'support': return Icons.support_agent_rounded;
      case 'tips': return Icons.lightbulb_rounded;
      case 'newspaper': return Icons.newspaper_rounded;
      case 'forum': return Icons.forum_rounded;
      case 'list': return Icons.list_rounded;
      case 'grid': return Icons.grid_view_rounded;
      case 'view_day': return Icons.view_day_rounded;
      case 'touch_app': return Icons.touch_app_rounded;
      case 'smart_toy': return Icons.smart_toy_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'medical_services': return Icons.medical_services_rounded;
      case 'healing': return Icons.healing_rounded;
      case 'self_improvement': return Icons.self_improvement_rounded;
      case 'sports': return Icons.sports_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'local_offer': return Icons.local_offer_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'celebration': return Icons.celebration_rounded;
      default: return Icons.circle;
    }
  }

  /// Default quick access items
  static List<QuickAccessItem> get defaults => [
    QuickAccessItem(
      id: 'qa_0',
      key: 'aiChat',
      label: 'AI Chat',
      labelHe: 'צ\'אט AI',
      iconName: 'auto_awesome',
      color: '#D1C2D3',
      route: '/ai_chat',
      order: 0,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_1',
      key: 'sos',
      label: 'SOS',
      labelHe: 'SOS',
      iconName: 'sos',
      color: '#E74C3C',
      route: '/sos',
      order: 1,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_2',
      key: 'whatsapp',
      label: 'WhatsApp',
      labelHe: 'וואטסאפ',
      iconName: 'chat',
      color: '#25D366',
      route: '/whatsapp',
      order: 2,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_3',
      key: 'marketplace',
      label: 'Marketplace',
      labelHe: 'מסירות',
      iconName: 'volunteer_activism',
      color: '#B5C8B9',
      route: '/marketplace',
      order: 3,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_4',
      key: 'mood',
      label: 'Mood',
      labelHe: 'מצב רוח',
      iconName: 'mood',
      color: '#D1C2D3',
      route: '/mood',
      order: 4,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_5',
      key: 'album',
      label: 'Album',
      labelHe: 'אלבום',
      iconName: 'photo_album',
      color: '#EDD3D8',
      route: '/album',
      order: 5,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_6',
      key: 'experts',
      label: 'Experts',
      labelHe: 'מומחים',
      iconName: 'local_hospital',
      color: '#D4A1AC',
      route: '/experts',
      order: 6,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_7',
      key: 'tips',
      label: 'Tips',
      labelHe: 'טיפים',
      iconName: 'lightbulb',
      color: '#DBC8B0',
      route: '/tips',
      order: 7,
      isVisible: true,
    ),
    QuickAccessItem(
      id: 'qa_8',
      key: 'gamification',
      label: 'Rewards',
      labelHe: 'הישגים',
      iconName: 'emoji_events',
      color: '#F39C12',
      route: '/gamification',
      order: 8,
      isVisible: true,
    ),
  ];
}

class AppConfig {
  final String id;
  final String appName;
  final String slogan;
  final List<String> navigationOrder;
  final List<NavigationItem> navigationItems;
  final List<QuickAccessItem> quickAccessItems;
  final Map<String, bool> featureVisibility;
  final Map<String, dynamic> themeSettings;
  final DateTime? updatedAt;

  AppConfig({
    required this.id,
    required this.appName,
    required this.slogan,
    required this.navigationOrder,
    required this.navigationItems,
    required this.quickAccessItems,
    required this.featureVisibility,
    required this.themeSettings,
    this.updatedAt,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    // Parse navigation items from the new format
    List<NavigationItem> items = [];
    if (map['navigationItems'] != null) {
      items = (map['navigationItems'] as List)
          .asMap()
          .entries
          .map((e) => NavigationItem.fromMap({
                'id': 'nav_${e.key}',
                ...e.value as Map<String, dynamic>,
                'order': e.key,
              }))
          .toList();
    }

    // Parse quick access items
    List<QuickAccessItem> quickItems = [];
    if (map['quickAccessItems'] != null) {
      quickItems = (map['quickAccessItems'] as List)
          .asMap()
          .entries
          .map((e) => QuickAccessItem.fromMap({
                'id': 'qa_${e.key}',
                ...e.value as Map<String, dynamic>,
                'order': e.key,
              }))
          .toList();
    }

    return AppConfig(
      id: map['id'] ?? 'main',
      appName: map['appName'] ?? 'MOMIT',
      slogan: map['slogan'] ?? 'כי רק אמא מבינה אמא',
      navigationOrder: List<String>.from(map['navigationOrder'] ?? ['feed', 'tracking', 'events', 'chat', 'profile']),
      navigationItems: items,
      quickAccessItems: quickItems,
      featureVisibility: Map<String, bool>.from(map['featureVisibility'] ?? {}),
      themeSettings: Map<String, dynamic>.from(map['themeSettings'] ?? {}),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'appName': appName,
    'slogan': slogan,
    'navigationOrder': navigationOrder,
    'navigationItems': navigationItems.map((e) => e.toMap()).toList(),
    'quickAccessItems': quickAccessItems.map((e) => e.toMap()).toList(),
    'featureVisibility': featureVisibility,
    'themeSettings': themeSettings,
  };

  /// Get visible navigation items sorted by order
  List<NavigationItem> get visibleNavigationItems {
    return navigationItems
        .where((item) => item.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get visible quick access items sorted by order
  List<QuickAccessItem> get visibleQuickAccessItems {
    return quickAccessItems
        .where((item) => item.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  factory AppConfig.defaultConfig() => AppConfig(
    id: 'main',
    appName: 'MOMIT',
    slogan: 'כי רק אמא מבינה אמא',
    navigationOrder: ['feed', 'tracking', 'events', 'chat', 'profile'],
    navigationItems: NavigationItemDefaults.defaultItems,
    quickAccessItems: QuickAccessItem.defaults,
    featureVisibility: {
      'chat': true,
      'events': true,
      'marketplace': true,
      'experts': true,
      'tips': true,
    },
    themeSettings: {},
  );
}

/// Default navigation items factory
class NavigationItemDefaults {
  static List<NavigationItem> get defaultItems => [
    NavigationItem(
      id: 'nav_0',
      key: 'feed',
      label: 'Home',
      labelHe: 'בית',
      iconName: 'home_outlined',
      activeIconName: 'home_rounded',
      route: '/feed',
      order: 0,
      isVisible: true,
    ),
    NavigationItem(
      id: 'nav_1',
      key: 'tracking',
      label: 'Tracking',
      labelHe: 'מעקב',
      iconName: 'child_care_outlined',
      activeIconName: 'child_care',
      route: '/tracking',
      order: 1,
      isVisible: true,
    ),
    NavigationItem(
      id: 'nav_2',
      key: 'events',
      label: 'Events',
      labelHe: 'אירועים',
      iconName: 'event_outlined',
      activeIconName: 'event_rounded',
      route: '/events',
      order: 2,
      isVisible: true,
    ),
    NavigationItem(
      id: 'nav_3',
      key: 'chat',
      label: 'Chat',
      labelHe: 'צ\'אט',
      iconName: 'chat_bubble_outline',
      activeIconName: 'chat_bubble_rounded',
      route: '/chat',
      order: 3,
      isVisible: true,
    ),
    NavigationItem(
      id: 'nav_4',
      key: 'profile',
      label: 'Profile',
      labelHe: 'פרופיל',
      iconName: 'person_outline_rounded',
      activeIconName: 'person_rounded',
      route: '/profile',
      order: 4,
      isVisible: true,
    ),
  ];
}
