// ════════════════════════════════════════════════════════════════
//  DYNAMIC ADMIN DASHBOARD - USAGE EXAMPLES
// ════════════════════════════════════════════════════════════════

// In your main.dart, add the service to providers:
/*
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FirestoreService()),
    ChangeNotifierProvider(create: (_) => DynamicConfigService()),
    // ... other providers
  ],
  child: MyApp(),
)
*/

// ════════════════════════════════════════════════════════════════
//  READ DYNAMIC SECTIONS IN UI
// ════════════════════════════════════════════════════════════════

/*
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DynamicSection>>(
      stream: context.read<DynamicConfigService>().activeSectionsStream,
      builder: (context, snapshot) {
        final sections = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return DynamicSectionWidget(section: section);
          },
        );
      },
    );
  }
}
*/

// ════════════════════════════════════════════════════════════════
//  READ CONTENT FOR A SECTION
// ════════════════════════════════════════════════════════════════

/*
class DynamicSectionWidget extends StatelessWidget {
  final DynamicSection section;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContentItem>>(
      stream: context.read<DynamicConfigService>()
          .getContentForSectionStream(section.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        
        switch (section.type) {
          case SectionType.hero:
            return HeroSection(items: items, settings: section.settings);
          case SectionType.features:
            return FeaturesSection(items: items, settings: section.settings);
          case SectionType.carousel:
            return CarouselSection(items: items, settings: section.settings);
          default:
            return DefaultSection(items: items, settings: section.settings);
        }
      },
    );
  }
}
*/

// ════════════════════════════════════════════════════════════════
//  READ APP CONFIG
// ════════════════════════════════════════════════════════════════

/*
class AppNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppConfig>(
      stream: context.read<DynamicConfigService>().appConfigStream,
      builder: (context, snapshot) {
        final config = snapshot.data;
        if (config == null) return const SizedBox.shrink();
        
        // Use config.navigationOrder to build navigation
        // Use config.featureVisibility to show/hide features
        
        return BottomNavigationBar(
          items: config.navigationOrder
              .where((key) => config.featureVisibility[key] ?? true)
              .map((key) => _buildNavItem(key))
              .toList(),
        );
      },
    );
  }
}
*/

// ════════════════════════════════════════════════════════════════
//  ADMIN USAGE
// ════════════════════════════════════════════════════════════════

// The admin dashboard now includes a new tab "דינמי" (Dynamic)
// that allows:
//
// 1. View all dynamic sections
// 2. Reorder sections via drag & drop
// 3. Toggle section visibility (active/inactive)
// 4. Edit section properties (name, key, type, settings)
// 5. Delete sections
// 6. Create new sections
// 7. Edit content within sections
// 8. Reorder content items
// 9. Publish/unpublish content
// 10. Edit navigation order and visibility

// ════════════════════════════════════════════════════════════════
//  FIRESTORE COLLECTIONS
// ════════════════════════════════════════════════════════════════

// Required collections:
// - app_config (main doc with navigation and feature settings)
// - dynamic_sections (section definitions)
// - content_management (content items for sections)

// See DYNAMIC_ADMIN_SETUP.md for detailed setup instructions
