import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/core/widgets/common_widgets.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';
import 'package:mom_connect/models/feature_flag_model.dart';
import 'package:mom_connect/services/branding_config_service.dart';
import 'package:mom_connect/services/feature_flag_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/storage_service.dart';
import 'package:mom_connect/features/feed/screens/feed_screen.dart';
import 'package:mom_connect/features/tracking/screens/tracking_screen.dart';
import 'package:mom_connect/features/events/screens/events_screen.dart';
import 'package:mom_connect/features/chat/screens/chat_screen.dart';
import 'package:mom_connect/features/profile/screens/profile_screen.dart';
import 'package:mom_connect/features/marketplace/screens/marketplace_screen.dart';
import 'package:mom_connect/features/auth/screens/welcome_screen.dart';
import 'package:mom_connect/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:mom_connect/features/sos/screens/sos_screen.dart';
import 'package:mom_connect/features/tips/screens/daily_tips_screen.dart';
import 'package:mom_connect/features/mood/screens/mood_tracker_screen.dart';
import 'package:mom_connect/features/experts/screens/experts_screen.dart';
import 'package:mom_connect/features/whatsapp/screens/whatsapp_screen.dart';
import 'package:mom_connect/features/gamification/screens/gamification_screen.dart';
import 'package:mom_connect/features/album/screens/photo_album_screen.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';
import 'package:mom_connect/features/accessibility/screens/accessibility_screen.dart';
import 'package:mom_connect/features/legal/screens/legal_screen.dart';
import 'package:mom_connect/features/notifications/screens/notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabAnimController;

  /// Map of screen keys to their widget builders
  final Map<String, Widget Function()> _screenBuilders = {
    'feed': () => const FeedScreen(),
    'tracking': () => const TrackingScreen(),
    'events': () => const EventsScreen(),
    'chat': () => const ChatScreen(),
    'profile': () => const ProfileScreen(),
    'home': () => const FeedScreen(),
  };

  /// Build screens list from navigation items
  List<Widget> _buildScreens(List<NavigationItem> items) {
    return items.map((item) {
      final builder = _screenBuilders[item.key];
      if (builder != null) {
        return builder();
      }
      // Fallback for unknown keys
      return const SizedBox.shrink();
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppConfig>(
      stream: DynamicConfigService.instance.appConfigStream,
      builder: (context, snapshot) {
        final config = snapshot.data;
        final navigationItems = config?.visibleNavigationItems ?? NavigationItemDefaults.defaultItems;
        final screens = _buildScreens(navigationItems);

        // Adjust current index if it exceeds the number of items
        if (_currentIndex >= navigationItems.length && navigationItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 0);
          });
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildPremiumAppBar(),
          drawer: _buildPremiumDrawer(navigationItems),
          body: Column(
            children: [
              // Announcement banner from admin
              Consumer<AppState>(builder: (_, appState, __) {
                if (!appState.hasActiveAnnouncement) return const SizedBox.shrink();
                final ann = appState.announcement;
                Color bgColor;
                try { final hex = (ann['color'] ?? '#D1C2D3').toString().replaceAll('#', ''); bgColor = Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16)); } catch (_) { bgColor = const Color(0xFFD1C2D3); }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: bgColor),
                  child: Row(children: [
                    const Icon(Icons.campaign_rounded, color: Colors.white, size: 20), const SizedBox(width: 10),
                    Expanded(child: Text(ann['text'] ?? '', style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))),
                    if ((ann['link'] ?? '').toString().isNotEmpty) IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
                      final link = ann['link'].toString();
                      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                    }),
                  ]),
                );
              }),
              if (_currentIndex == 0) _buildPremiumQuickAccess(config?.quickAccessItems ?? []),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: IndexedStack(
                    key: ValueKey(_currentIndex),
                    index: navigationItems.isNotEmpty ? _currentIndex : 0,
                    children: screens.isNotEmpty ? screens : [const FeedScreen()],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildGlassBottomNav(navigationItems),
          floatingActionButton: _currentIndex == 0 && navigationItems.isNotEmpty ? _buildPremiumFAB() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  // ===== PREMIUM APP BAR =====
  PreferredSizeWidget _buildPremiumAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: StreamBuilder<BrandingConfig>(
        stream: BrandingConfigService.instance.brandingStream,
        initialData: BrandingConfigService.instance.config,
        builder: (context, brandingSnapshot) {
          final branding = brandingSnapshot.data ?? BrandingConfig.defaultConfig();
          final hasLogo = branding.logoUrl != null && branding.logoUrl!.isNotEmpty;
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildIconBtn(
                      Icons.menu_rounded,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 12),
                    // Dynamic Logo - uses custom logo if available, fallback to default icon
                    if (hasLogo)
                      _buildDynamicLogo(branding.logoUrl!)
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.momGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      ),
                    const SizedBox(width: 10),
                    // Dynamic App Name - updates in real-time
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        branding.appName,
                        key: ValueKey(branding.appName),
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          letterSpacing: -0.5,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFD4A1AC), Color(0xFFBE8A93)],
                            ).createShader(const Rect.fromLTWH(0, 0, 120, 30)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildIconBtn(Icons.search_rounded, onTap: _showSearchSheet),
                    const SizedBox(width: 6),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Provider.of<FirestoreService>(context, listen: false)
                          .userNotificationsStream(context.read<AppState>().currentUser?.id ?? ''),
                      builder: (ctx, snap) {
                        final unread = (snap.data ?? []).where((n) => n['isRead'] != true).length;
                        return NotificationBadge(
                          count: unread,
                          child: _buildIconBtn(
                            Icons.notifications_outlined,
                            onTap: _showNotifications,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build dynamic logo widget from URL
  Widget _buildDynamicLogo(String logoUrl) {
    Widget logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logoUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.momGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
          );
        },
      ),
    );
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: logoWidget,
    );
  }

  Widget _buildIconBtn(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  // ===== PREMIUM QUICK ACCESS =====
  Widget _buildPremiumQuickAccess(List<QuickAccessItem> items) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            final color = AppColors.fromHex(item.color);
            return _buildPremiumQuickAction(
              item.labelHe,
              color,
              item.iconData,
              () => _navigateQuickAccess(item.key),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPremiumQuickAction(String label, Color color, IconData fallbackIcon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(fallbackIcon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateQuickAccess(String key) {
    final routes = <String, Widget Function()>{
      'aiChat': () => const AIChatScreen(),
      'sos': () => const SOSScreen(),
      'whatsapp': () => const WhatsAppIntegrationScreen(),
      'marketplace': () => const MarketplaceScreen(),
      'mood': () => const MoodTrackerScreen(),
      'album': () => const PhotoAlbumScreen(),
      'experts': () => const ExpertsScreen(),
      'tips': () => const DailyTipsScreen(),
      'gamification': () => const GamificationScreen(),
    };
    final builder = routes[key];
    if (builder != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
    }
  }

  // ===== GLASS BOTTOM NAV =====
  Widget _buildGlassBottomNav(List<NavigationItem> navigationItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              // Chat badge - no hardcoded count
              final badge = 0;
              return _buildNavItem(
                index,
                item.iconData,
                item.activeIconData,
                item.labelHe,
                badge: badge,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 20 : 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.primaryLight.withValues(alpha: 0.06),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: NotificationBadge(
                    count: badge,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey(isActive),
                        color: isActive ? AppColors.primary : AppColors.textHint,
                        size: isActive ? 26 : 23,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? 11 : 10,
                    fontFamily: 'Heebo',
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== PREMIUM FAB =====
  Widget? _buildPremiumFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16), // Adjust padding for side position
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.momGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showFullCreatePostSheet(); // Directly open post sheet
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  // ===== PREMIUM DRAWER =====
  Widget _buildPremiumDrawer(List<NavigationItem> navigationItems) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.momGradient,
                        ),
                        child: ProfileAvatar(
                          name: context.watch<AppState>().currentUser?.fullName ?? 'Guest',
                          size: 52,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.watch<AppState>().currentUser?.fullName ?? 'Guest',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Heebo'),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                                      const SizedBox(width: 3),
                                      Text('מאומת', style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textHint),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Gamification stats card - only show if gamification is enabled
                  Consumer2<AppState, FeatureFlagService>(builder: (_, appState, featureService, __) {
                    // Check both legacy and new feature flag systems
                    final isGamificationEnabled = appState.isFeatureEnabled('gamification') || 
                                                  featureService.isGamificationEnabled;
                    if (!isGamificationEnabled) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEDD3D8), Color(0xFFDBC8B0)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFEDD3D8).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('הישגים', Icons.trending_up_rounded),
                            _buildDividerDot(),
                            _buildMiniStat('נקודות', Icons.stars_rounded),
                            _buildDividerDot(),
                            _buildMiniStat('רצף', Icons.local_fire_department_rounded),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  Builder(builder: (context) {
                    final appState = context.watch<AppState>();
                    final featureService = context.watch<FeatureFlagService>();
                    
                    // Helper function that checks both legacy and new feature flag systems
                    bool isEnabled(String feature) {
                      // Map legacy feature keys to new FeatureFlagIds
                      final flagId = _mapLegacyFeatureToFlagId(feature);
                      return appState.isFeatureEnabled(feature) || 
                             (flagId != null && featureService.isEnabled(flagId));
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDrawerSection(appState.drawerLabel('mainNav')),
                        ...navigationItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildDrawerItem(
                            item.activeIconData,
                            item.labelHe,
                            () {
                              setState(() => _currentIndex = index);
                              Navigator.pop(context);
                            },
                            isSelected: _currentIndex == index,
                          );
                        }),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
                        ),
                        _buildDrawerSection(appState.drawerLabel('advancedFeatures')),
                        if (isEnabled('aiChat')) _buildDrawerItem(Icons.auto_awesome_rounded, appState.drawerLabel('aiChat'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())); }, iconColor: const Color(0xFFD1C2D3)),
                        if (isEnabled('sos')) _buildDrawerItem(Icons.sos_rounded, appState.drawerLabel('sos'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen())); }, iconColor: AppColors.error),
                        if (isEnabled('whatsapp')) _buildDrawerItem(Icons.chat_rounded, appState.drawerLabel('whatsapp'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppIntegrationScreen())); }, iconColor: const Color(0xFFB5C8B9)),
                        if (isEnabled('marketplace')) _buildDrawerItem(Icons.volunteer_activism_rounded, appState.drawerLabel('marketplace'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())); }),
                        if (isEnabled('mood')) _buildDrawerItem(Icons.mood_rounded, appState.drawerLabel('mood'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackerScreen())); }, iconColor: const Color(0xFFD1C2D3)),
                        if (isEnabled('album')) _buildDrawerItem(Icons.photo_album_rounded, appState.drawerLabel('album'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoAlbumScreen())); }, iconColor: const Color(0xFFEDD3D8)),
                        if (isEnabled('experts')) _buildDrawerItem(Icons.local_hospital_rounded, appState.drawerLabel('experts'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertsScreen())); }),
                        if (isEnabled('tips')) _buildDrawerItem(Icons.lightbulb_rounded, appState.drawerLabel('tips'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTipsScreen())); }),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
                        ),
                        _buildDrawerSection(appState.drawerLabel('settingsSection')),
                      ],
                    );
                  }),
                  _buildDrawerItem(Icons.settings_rounded, 'הגדרות', () { Navigator.pop(context); _showSettingsSheet(); }),
                  _buildDrawerItem(Icons.accessibility_new_rounded, 'נגישות', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityScreen())); }, iconColor: AppColors.info),
                  _buildDrawerItem(Icons.gavel_rounded, 'משפטי ומדיניות', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())); }),
                  _buildDrawerItem(Icons.help_outline_rounded, 'עזרה', () { Navigator.pop(context); _showHelpSheet(); }),
                  _buildDrawerItem(Icons.info_outline_rounded, 'אודות', () { Navigator.pop(context); _showAboutDialog(); }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('התנתקות', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 15),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildDividerDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), shape: BoxShape.circle),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 22, top: 10, bottom: 4, left: 22),
      child: Text(
        title,
        style: TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon, String title, VoidCallback onTap, {
    bool isSelected = false, int badge = 0, Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (iconColor ?? (isSelected ? AppColors.primary : AppColors.textSecondary)).withValues(alpha: isSelected ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? (isSelected ? AppColors.primary : AppColors.textSecondary), size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Heebo', fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          trailing: badge > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              : null,
          selected: isSelected,
          selectedTileColor: AppColors.primary.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
          onTap: onTap,
        ),
      ),
    );
  }

  // ===== SHEETS & DIALOGS =====

  void _showFullCreatePostSheet({String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _QuickPostSheet(initialType: initialType),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsSheet(),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _SearchSheet(),
    );
  }

  void _showSettingsSheet() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('הגדרות', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _settingsTile(Icons.person_outline_rounded, 'פרופיל', trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }),
              _settingsTile(Icons.notifications_outlined, 'התראות', trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
              _settingsTile(Icons.lock_outline_rounded, 'פרטיות', trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint), onTap: () {
                Navigator.pop(context);
                AppSnackbar.info(context, 'הגדרות פרטיות בקרוב...');
              }),
              _settingsTile(Icons.accessibility_new_rounded, 'נגישות', trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityScreen()));
              }),
              _settingsTile(Icons.gavel_rounded, 'מדיניות ותנאים', trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen()));
              }),
              _settingsTile(Icons.language_rounded, 'שפה', trailing: Text('עברית', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint, fontSize: 13)), onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('כרגע האפליקציה זמינה בעברית בלבד. שפות נוספות בקרוב!', style: TextStyle(fontFamily: 'Heebo')), behavior: SnackBarBehavior.floating),
                );
              }),
              _settingsTile(
                Icons.dark_mode_outlined, 'מצב כהה',
                trailing: Switch(
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    appState.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    setSheetState(() {});
                    setState(() {});
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  thumbColor: WidgetStateProperty.all(AppColors.primary),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 15)),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showHelpSheet() {
    final appState = context.read<AppState>();
    final featureService = context.read<FeatureFlagService>();
    
    // Check both legacy and new feature flag systems
    final isAiChatEnabled = appState.isFeatureEnabled('aiChat') || 
                            featureService.isAiChatEnabled;
    
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('עזרה ותמיכה', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (isAiChatEnabled)
              _settingsTile(Icons.auto_awesome_rounded, 'שאלי את MomBot', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())); }),
            _settingsTile(Icons.email_outlined, 'צרי קשר', onTap: () {
              Navigator.pop(context);
              _openContactEmail();
            }),
            _settingsTile(Icons.flag_outlined, 'דווחי על בעיה', onTap: () {
              Navigator.pop(context);
              _showReportDialog();
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _openContactEmail() async {
    // Try to get contact email from app config, fallback to empty
    final configSnap = await FirebaseFirestore.instance.collection('admin_config').doc('app_config').get();
    final email = configSnap.data()?['contactEmail']?.toString() ?? '';
    if (email.isNotEmpty) {
      final uri = Uri(scheme: 'mailto', path: email, queryParameters: {'subject': 'פנייה מאפליקציית MOMIT'});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (mounted) AppSnackbar.info(context, 'לא הוגדר אימייל קשר. ניתן להגדיר בלוח הבקרה.');
  }

  void _showReportDialog() {
    final reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('דיווח על בעיה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: TextField(
          controller: reportController,
          textDirection: TextDirection.rtl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'תארי את הבעיה...',
            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
          ElevatedButton(
            onPressed: () async {
              final text = reportController.text.trim();
              if (text.isEmpty) return;
              final userId = context.read<AppState>().currentUser?.id ?? 'anonymous';
              await FirebaseFirestore.instance.collection('reports').add({
                'type': 'bug_report',
                'content': text,
                'reporterId': userId,
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) AppSnackbar.success(context, 'תודה! הדיווח נשלח בהצלחה');
              reportController.dispose();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('שלחי', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppColors.momGradient, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(TextConfig.appName, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MOMIT - רשת חברתית סגורה ומהימנה שבנויה על ידי אמהות, בשביל אמהות.\n\nכי רק אמא מבינה אמא.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Heebo', height: 1.6),
            ),
            SizedBox(height: 16),
            Text('גרסה 3.0.0', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo'))),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await context.showLogoutConfirm();
    if (confirmed && mounted) {
      await AuthService.instance.logout();
      if (!mounted) return;
      context.read<AppState>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  /// Maps legacy feature keys to new FeatureFlagIds
  String? _mapLegacyFeatureToFlagId(String legacyKey) {
    final mapping = {
      'aiChat': FeatureFlagIds.enableAiChat,
      'sos': FeatureFlagIds.enableSos,
      'whatsapp': FeatureFlagIds.enableWhatsapp,
      'marketplace': FeatureFlagIds.enableMarketplace,
      'mood': FeatureFlagIds.enableMoodTracker,
      'album': FeatureFlagIds.enableAlbum,
      'experts': FeatureFlagIds.enableExperts,
      'tips': FeatureFlagIds.enableDailyTips,
      'gamification': FeatureFlagIds.enableGamification,
      'chat': FeatureFlagIds.enableChat,
      'events': FeatureFlagIds.enableEvents,
      'tracking': FeatureFlagIds.enableTracking,
    };
    return mapping[legacyKey];
  }
}

// ===== NOTIFICATIONS SHEET =====
class _NotificationsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('התראות', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Heebo')),
                Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                    child: Text('הצג הכל', style: TextStyle(fontFamily: 'Heebo', color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {
                      final userId = context.read<AppState>().currentUser?.id ?? '';
                      Provider.of<FirestoreService>(context, listen: false).markAllNotificationsRead(userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('כל ההתראות סומנו כנקראו', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      );
                    },
                    child: Text('סמני הכל כנקרא', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<FirestoreService>(context, listen: false)
                  .userNotificationsStream(context.read<AppState>().currentUser?.id ?? ''),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return const Center(child: Text('אין התראות חדשות', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifs.length > 10 ? 10 : notifs.length,
                  itemBuilder: (ctx, i) {
                    final n = notifs[i];
                    final isUnread = n['isRead'] != true;
                    final title = n['title'] ?? '';
                    final body = n['body'] ?? '';
                    final type = n['type'] ?? 'general';
                    IconData icon = Icons.notifications_rounded;
                    Color color = AppColors.primary;
                    if (type == 'like') { icon = Icons.favorite_rounded; color = AppColors.secondary; }
                    else if (type == 'comment') { icon = Icons.chat_bubble_rounded; color = AppColors.primary; }
                    else if (type == 'sos') { icon = Icons.sos_rounded; color = AppColors.error; }
                    else if (type == 'event') { icon = Icons.event_rounded; color = AppColors.accent; }
                    final createdAt = n['createdAt'];
                    String timeStr = '';
                    if (createdAt is Timestamp) {
                      timeStr = timeago.format(createdAt.toDate(), locale: 'he');
                    }
                    return _buildNotif(title, body, icon, color, timeStr, isUnread, onTap: () {
                      Navigator.pop(context);
                      final fs = Provider.of<FirestoreService>(context, listen: false);
                      if (n['id'] != null && isUnread) fs.markNotificationRead(n['id']);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotif(String title, String subtitle, IconData icon, Color color, String time, bool isUnread, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? color.withValues(alpha: 0.04) : AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isUnread ? Border.all(color: color.withValues(alpha: 0.12)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600, fontFamily: 'Heebo', fontSize: 14))),
                    if (isUnread) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Heebo')),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: AppColors.textHint, fontSize: 11, fontFamily: 'Heebo')),
        ],
      ),
    ),
    );
  }
}

// ===== SEARCH SHEET =====
class _SearchSheet extends StatefulWidget {
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Heebo'),
              decoration: InputDecoration(
                hintText: 'חיפוש אמהות, פוסטים, אירועים...',
                hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(child: _searchQuery.isEmpty ? _buildSuggestions() : _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Text('נושאים פופולריים', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: ['האכלה', 'שינה', 'התפתחות', 'בריאות', 'תינוקות', 'צעצועים', 'מומחים', 'אירועים']
              .map((t) => GestureDetector(
                    onTap: () { _searchController.text = t; setState(() => _searchQuery = t); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.06), AppColors.primary.withValues(alpha: 0.02)]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Text(t, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<List<Map<String, dynamic>>>>(
      stream: _searchFirestore(fs, query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        final results = snapshot.data ?? [];
        final posts = results.isNotEmpty ? results[0] : <Map<String, dynamic>>[];
        final events = results.length > 1 ? results[1] : <Map<String, dynamic>>[];
        final experts = results.length > 2 ? results[2] : <Map<String, dynamic>>[];
        final tips = results.length > 3 ? results[3] : <Map<String, dynamic>>[];

        final allEmpty = posts.isEmpty && events.isEmpty && experts.isEmpty && tips.isEmpty;
        if (allEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('לא נמצאו תוצאות עבור "$_searchQuery"', style: const TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)),
              ],
            ),
          ));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const Text('תוצאות חיפוש', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ...posts.take(3).map((p) => _buildResult(
              p['title'] ?? p['content'] ?? '',
              'פוסט',
              Icons.article_rounded, AppColors.success,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen())); },
            )),
            ...events.take(3).map((e) => _buildResult(
              e['title'] ?? '',
              e['location'] ?? 'אירוע',
              Icons.event_rounded, AppColors.accent,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())); },
            )),
            ...experts.take(3).map((e) => _buildResult(
              e['name'] ?? e['fullName'] ?? '',
              e['specialty'] ?? 'מומחה/ת',
              Icons.medical_services_rounded, AppColors.info,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertsScreen())); },
            )),
            ...tips.take(3).map((t) => _buildResult(
              t['title'] ?? '',
              t['category'] ?? 'טיפ',
              Icons.lightbulb_rounded, AppColors.primary,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTipsScreen())); },
            )),
          ],
        );
      },
    );
  }

  Stream<List<List<Map<String, dynamic>>>> _searchFirestore(FirestoreService fs, String query) {
    // Search across multiple collections using streams
    return fs.postsStream.map((posts) {
      final filteredPosts = posts.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final content = (p['content'] ?? '').toString().toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
      return filteredPosts;
    }).asyncMap((posts) async {
      // Also search events, experts, tips
      final eventsSnap = await FirebaseFirestore.instance.collection('events').get();
      final expertsSnap = await FirebaseFirestore.instance.collection('experts').get();
      final tipsSnap = await FirebaseFirestore.instance.collection('tips').get();

      final events = eventsSnap.docs.where((d) {
        final title = (d.data()['title'] ?? '').toString().toLowerCase();
        return title.contains(query);
      }).map((d) => {'id': d.id, ...d.data()}).toList();

      final experts = expertsSnap.docs.where((d) {
        final name = (d.data()['name'] ?? d.data()['fullName'] ?? '').toString().toLowerCase();
        final specialty = (d.data()['specialty'] ?? '').toString().toLowerCase();
        return name.contains(query) || specialty.contains(query);
      }).map((d) => {'id': d.id, ...d.data()}).toList();

      final tips = tipsSnap.docs.where((d) {
        final title = (d.data()['title'] ?? '').toString().toLowerCase();
        final content = (d.data()['content'] ?? '').toString().toLowerCase();
        return title.contains(query) || content.contains(query);
      }).map((d) => {'id': d.id, ...d.data()}).toList();

      return [posts, events, experts, tips];
    });
  }

  Widget _buildResult(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 13)),
      onTap: onTap ?? () => Navigator.pop(context),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ===== QUICK POST SHEET =====
class _QuickPostSheet extends StatefulWidget {
  final String? initialType;
  const _QuickPostSheet({this.initialType});

  @override
  State<_QuickPostSheet> createState() => _QuickPostSheetState();
}

class _QuickPostSheetState extends State<_QuickPostSheet> {
  final _contentController = TextEditingController();
  bool _isPoll = false;
  bool _isAnonymous = false;
  String _selectedCategory = 'general';
  String? _selectedImagePath;
  String? _selectedImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isPoll = widget.initialType == 'poll';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('שגיאה בבחירת תמונה', style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty && _selectedImagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;
      final content = _contentController.text.trim();

      // Upload image to Firebase Storage if selected
      String? imageUrl;
      if (_selectedImagePath != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadImage(
          filePath: _selectedImagePath!,
          folder: 'posts/${currentUser?.id ?? 'anonymous'}',
          customFileName: _selectedImageName,
        );
      }

      // Prepare post data
      final postData = <String, dynamic>{
        'content': content,
        'authorName': _isAnonymous ? 'אנונימית' : (currentUser?.fullName ?? 'משתמשת'),
        'authorImage': '',
        'category': _selectedCategory,
        'isAnonymous': _isAnonymous,
        'isPoll': _isPoll,
        'likes': 0,
        'comments': 0,
        'isPinned': false,
        'reportCount': 0,
        'creatorId': currentUser?.id ?? '',
        'creatorName': currentUser?.fullName ?? '',
        'creatorEmail': currentUser?.email ?? '',
        'creatorPhone': currentUser?.phone ?? '',
      };

      if (imageUrl != null) {
        postData['images'] = [imageUrl];
        postData['imageName'] = _selectedImageName ?? '';
      }

      await fs.addPost(postData);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPoll ? 'הסקר פורסם!' : 'הפוסט פורסם!', style: const TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('שגיאה בפרסום הפוסט', style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _contentController.text.isNotEmpty || _selectedImagePath != null;
    
    return Column(
      children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context), 
                child: Text('ביטול', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint))
              ),
              Text(_isPoll ? 'סקר חדש' : 'פוסט חדש', style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: canSubmit && !_isLoading ? _submitPost : null,
                child: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                    )
                  : Text('פרסום', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, color: canSubmit ? AppColors.primary : AppColors.textHint)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isAnonymous ? 'אנונימית' : 'את', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                        GestureDetector(
                          onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                          child: Row(
                            children: [
                              Icon(_isAnonymous ? Icons.visibility_off_rounded : Icons.public_rounded, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(_isAnonymous ? 'אנונימי' : 'ציבורי', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 5,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'מה על הלב? שתפי...',
                    hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_selectedImagePath != null) ...[
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                ],
                const SizedBox(height: 16),
                _buildImagePickerButton(),
                const SizedBox(height: 24),
                const Text('קטגוריה:', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildCat('general', 'כללי'), _buildCat('questions', 'שאלות'), _buildCat('tips', 'טיפים'), _buildCat('moments', 'רגעים'), _buildCat('help', 'עזרה'),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Bottom Submit Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSubmit && !_isLoading ? _submitPost : null,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 18, 
                      height: 18, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Icon(Icons.send_rounded, size: 20),
                label: Text(_isPoll ? 'פרסמי סקר' : 'פרסמי פוסט', style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary.withValues(alpha: 0.8), size: 22),
            const SizedBox(width: 8),
            Text(
              'הוסיפי תמונה',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppColors.surfaceVariant,
            child: _selectedImagePath != null
              ? (kIsWeb
                  ? Image.network(_selectedImagePath!, fit: BoxFit.cover)
                  : Image.file(File(_selectedImagePath!), fit: BoxFit.cover))
              : const Center(child: Icon(Icons.image_rounded, size: 50, color: AppColors.textHint)),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCat(String id, String name) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(name, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}
