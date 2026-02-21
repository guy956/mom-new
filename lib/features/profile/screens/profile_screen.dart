import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/color_config.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/models/user_model.dart';
import 'package:mom_connect/features/auth/screens/welcome_screen.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/tracking_service.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/features/accessibility/screens/accessibility_screen.dart';
import 'package:mom_connect/features/legal/screens/legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _user = UserModel.demo();
  }

  bool _didSyncChildren = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSyncChildren) return;
    _didSyncChildren = true;

    final appState = context.read<AppState>();
    final appUser = appState.currentUser;
    if (appUser != null) {
      // Sync children from TrackingService into profile (once)
      final trackingService = context.read<TrackingService>();
      if (trackingService.isInitialized) {
        final trackingChildren = trackingService.getChildModelsForProfile();
        // Merge tracking children into user children (deduplicated by id)
        final childMap = <String, ChildModel>{};
        for (final c in appUser.children) {
          childMap[c.id] = c;
        }
        for (final tc in trackingChildren) {
          childMap.putIfAbsent(tc.id, () => tc);
        }
        _user = appUser.copyWith(
          stats: appUser.stats.postsCount > 0 ? appUser.stats : UserStats(
            postsCount: 45,
            commentsCount: 156,
            likesReceived: 892,
            rating: 4.8,
            followersCount: 234,
            followingCount: 156,
          ),
          bio: appUser.bio ?? 'אמא מקסימה בקהילת MOMIT',
          children: childMap.values.toList(),
        );
      } else {
        _user = appUser.copyWith(
          stats: appUser.stats.postsCount > 0 ? appUser.stats : UserStats(
            postsCount: 45,
            commentsCount: 156,
            likesReceived: 892,
            rating: 4.8,
            followersCount: 234,
            followingCount: 156,
          ),
          bio: appUser.bio ?? 'אמא מקסימה בקהילת MOMIT',
          children: _user.children.isEmpty ? UserModel.demo().children : _user.children,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Firestore for real-time app config updates
    return StreamBuilder<AppConfig>(
      stream: DynamicConfigService.instance.appConfigStream,
      builder: (context, configSnapshot) {
        final config = configSnapshot.data ?? AppConfig.defaultConfig();
        
        return Scaffold(
          backgroundColor: ColorConfig.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(),
              _buildProfileHeader(),
              _buildTabBar(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildChildrenTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        TextConfig.profile,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.bold,
          color: ColorConfig.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          color: ColorConfig.textPrimary,
          onPressed: () => _showSettingsSheet(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showProfileImageOptions,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ColorConfig.momGradient,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundImage: _user.profileImage != null
                                ? NetworkImage(_user.profileImage!)
                                : null,
                            child: _user.profileImage == null
                                ? Text(
                                    _user.fullName.isNotEmpty ? _user.fullName[0] : '?',
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: ColorConfig.primary),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_user.isVerified)
                        Positioned(
                          right: 0,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: ColorConfig.primary,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('${_user.stats.postsCount}', 'פוסטים'),
                      _buildStatItem('${_user.stats.followersCount}', 'עוקבות'),
                      _buildStatItem('${_user.stats.followingCount}', 'עוקבת'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _user.fullName,
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_user.isOnline) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorConfig.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ColorConfig.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'מחוברת',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: ColorConfig.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (_user.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: ColorConfig.textHint),
                      const SizedBox(width: 4),
                      Text(
                        _user.city!,
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 13,
                          color: ColorConfig.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_user.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _user.bio!,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_user.children.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ...(_user.children.take(3).map((child) => Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: child.profileImage != null
                                    ? NetworkImage(child.profileImage!)
                                    : null,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: child.profileImage == null
                                    ? Text(
                                        child.gender.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                child.name,
                                style: const TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                child.formattedAge,
                                style: const TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ))),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _tabController.animateTo(1);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('הוספה'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileSheet(),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(TextConfig.editProfile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined),
                    color: AppColors.textPrimary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('קישור הפרופיל הועתק', style: TextStyle(fontFamily: 'Heebo')),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_user.stats.rating > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _user.stats.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'דירוג בקהילה',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Heebo'),
          tabs: const [
            Tab(icon: Icon(Icons.grid_on_rounded), text: 'פוסטים'),
            Tab(icon: Icon(Icons.child_care_rounded), text: 'ילדים'),
            Tab(icon: Icon(Icons.bookmark_outline_rounded), text: 'שמורים'),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('פוסט ${index + 1}', style: const TextStyle(fontFamily: 'Heebo')),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            color: AppColors.surfaceVariant,
            child: Image.network(
              'https://picsum.photos/200?random=$index',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.image, color: AppColors.textHint),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildrenTab() {
    if (_user.children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.child_care_rounded, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'עדיין לא הוספת ילדים',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'הוסיפי את הילדים שלך כדי לעקוב\nאחרי ההתפתחות שלהם',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddChildSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('הוספת ילד/ה', style: TextStyle(fontFamily: 'Heebo')),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _user.children.length + 1,
      itemBuilder: (context, index) {
        if (index == _user.children.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: OutlinedButton.icon(
              onPressed: _showAddChildSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('הוספת ילד/ה', style: TextStyle(fontFamily: 'Heebo')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          );
        }

        final child = _user.children[index];
        return _buildChildCard(child);
      },
    );
  }

  Widget _buildChildCard(ChildModel child) {
    final isBoy = child.gender == Gender.male;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isBoy
                    ? [const Color(0xFFB5BFC9), const Color(0xFFB5BFC9)]
                    : [const Color(0xFFDEB5BD), const Color(0xFFCEA5AD)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: child.profileImage != null
                      ? NetworkImage(child.profileImage!)
                      : null,
                  child: child.profileImage == null
                      ? Text(child.gender.emoji, style: const TextStyle(fontSize: 30))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        child.formattedAge,
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('עריכת פרטי ${child.name}', style: const TextStyle(fontFamily: 'Heebo')),
                        backgroundColor: AppColors.info,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChildStat('📏', '${child.growthRecords.lastOrNull?.height ?? '--'} ס"מ', 'גובה'),
                _buildChildStat('⚖️', '${child.growthRecords.lastOrNull?.weight ?? '--'} ק"ג', 'משקל'),
                _buildChildStat('🎯', '${child.milestones.where((m) => m.isAchieved).length}', 'אבני דרך'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.show_chart_rounded, 'גדילה', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('גרף גדילה של ${child.name}', style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                  );
                }),
                _buildQuickAction(Icons.flag_rounded, 'מיילסטונים', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('אבני דרך של ${child.name}', style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                  );
                }),
                _buildQuickAction(Icons.vaccines_rounded, 'חיסונים', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('לוח חיסונים של ${child.name}', style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSavedTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('פוסט שמור ${index + 1}', style: const TextStyle(fontFamily: 'Heebo')),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            color: AppColors.surfaceVariant,
            child: Image.network(
              'https://picsum.photos/200?random=${index + 10}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.bookmark, color: AppColors.textHint),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileImageOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('בחירה מהגלריה', style: TextStyle(fontFamily: 'Heebo')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('פתיחת הגלריה...', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('צילום תמונה', style: TextStyle(fontFamily: 'Heebo')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('פתיחת המצלמה...', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              if (_user.profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('הסרת תמונה', style: TextStyle(fontFamily: 'Heebo', color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('התמונה הוסרה', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: _user.fullName);
    final bioCtrl = TextEditingController(text: _user.bio ?? '');
    final cityCtrl = TextEditingController(text: _user.city ?? '');
    final phoneCtrl = TextEditingController(text: _user.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint)),
                    ),
                    const Text('עריכת פרופיל', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('הפרופיל עודכן בהצלחה! ✓', style: TextStyle(fontFamily: 'Heebo')),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('שמור', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _showProfileImageOptions,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                backgroundImage: _user.profileImage != null ? NetworkImage(_user.profileImage!) : null,
                                child: _user.profileImage == null ? const Icon(Icons.person, size: 50, color: AppColors.primary) : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildEditField('שם מלא', nameCtrl, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildEditField('ביו', bioCtrl, Icons.info_outline, maxLines: 3),
                      const SizedBox(height: 16),
                      _buildEditField('עיר', cityCtrl, Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      _buildEditField('טלפון', phoneCtrl, Icons.phone_outlined),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(TextConfig.settings, style: const TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSettingsSection('חשבון', [
                      _buildSettingsTile(Icons.person_outline, 'פרטים אישיים', onTap: () {
                        Navigator.pop(context);
                        _showEditProfileSheet();
                      }),
                      _buildSettingsTile(Icons.lock_outline, 'אבטחה', onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הגדרות אבטחה', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                        );
                      }),
                      _buildSettingsTile(Icons.privacy_tip_outlined, 'פרטיות', onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הגדרות פרטיות', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                        );
                      }),
                    ]),
                    _buildSettingsSection('התראות', [
                      _buildSettingsTile(Icons.notifications_outlined, 'הגדרות התראות', onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הגדרות התראות', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                        );
                      }),
                      _buildSettingsTile(Icons.email_outlined, 'עדכונים במייל', onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הגדרות דיוור אלקטרוני', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                        );
                      }),
                    ]),
                    _buildSettingsSection('נגישות ומשפטי', [
                      _buildSettingsTile(Icons.accessibility_new_rounded, 'נגישות', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityScreen()));
                      }),
                      _buildSettingsTile(Icons.gavel_rounded, 'מדיניות ותנאי שימוש', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen()));
                      }),
                    ]),
                    _buildSettingsSection('כללי', [
                      _buildSettingsTile(Icons.language_outlined, 'שפה', trailing: const Text('עברית', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint))),
                      _buildDarkModeTile(appState),
                      _buildSettingsTile(Icons.help_outline, 'עזרה', onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('support@momconnect.co.il', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
                        );
                      }),
                      _buildSettingsTile(Icons.info_outline, 'אודות', onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      }),
                    ]),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLogoutConfirmation();
                        },
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        label: Text(TextConfig.logout, style: const TextStyle(color: AppColors.error, fontFamily: 'Heebo')),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeTile(AppState appState) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isDark = appState.themeMode == ThemeMode.dark;
        return ListTile(
          leading: const Icon(Icons.dark_mode_outlined, color: AppColors.textPrimary),
          title: const Text('מצב כהה', style: TextStyle(fontFamily: 'Heebo')),
          trailing: Switch(
            value: isDark,
            thumbColor: WidgetStateProperty.all(AppColors.primary),
            trackColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.5)),
            onChanged: (value) {
              setLocalState(() {});
              appState.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHint)),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(fontFamily: 'Heebo')),
      trailing: trailing ?? const Icon(Icons.chevron_left_rounded, color: AppColors.textHint),
      onTap: onTap ?? () {},
    );
  }

  void _showAddChildSheet() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    String selectedGender = 'female';
    DateTime selectedBirthDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Text('הוספת ילד/ה', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'שם הילד/ה',
                    labelStyle: const TextStyle(fontFamily: 'Heebo'),
                    prefixIcon: const Icon(Icons.child_care),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                // Birthdate picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedBirthDate,
                      firstDate: DateTime(2018),
                      lastDate: DateTime.now(),
                      locale: const Locale('he'),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedBirthDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: AppColors.textHint),
                        const SizedBox(width: 12),
                        Text(
                          'תאריך לידה: ${DateFormat('dd/MM/yyyy').format(selectedBirthDate)}',
                          style: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('מין:', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedGender = 'female'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedGender == 'female' ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedGender == 'female' ? AppColors.secondary : AppColors.border),
                          ),
                          child: Center(child: Text('👧 בת', style: TextStyle(fontFamily: 'Heebo', fontWeight: selectedGender == 'female' ? FontWeight.bold : FontWeight.normal))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedGender = 'male'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedGender == 'male' ? AppColors.info.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedGender == 'male' ? AppColors.info : AppColors.border),
                          ),
                          child: Center(child: Text('👦 בן', style: TextStyle(fontFamily: 'Heebo', fontWeight: selectedGender == 'male' ? FontWeight.bold : FontWeight.normal))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('נא להזין שם', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
                      final gender = selectedGender == 'male' ? Gender.male : Gender.female;

                      // Add to AppState (profile)
                      final newChild = ChildModel(
                        id: childId,
                        name: nameCtrl.text.trim(),
                        birthDate: selectedBirthDate,
                        gender: gender,
                      );
                      context.read<AppState>().addChild(newChild);

                      // Also add to TrackingService for sync
                      final trackingService = context.read<TrackingService>();
                      if (trackingService.isInitialized) {
                        trackingService.addChild(trackingService.childModelToProfile(newChild));
                      }

                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${nameCtrl.text} נוסף/ה בהצלחה! 🎉', style: const TextStyle(fontFamily: 'Heebo')),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('הוסף', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(gradient: AppColors.momGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(TextConfig.appName, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MOMIT - רשת חברתית סגורה ומהימנה שבנויה על ידי אמהות, בשביל אמהות.\n\nכי רק אמא מבינה אמא.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Heebo', height: 1.5),
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('התנתקות', style: TextStyle(fontFamily: 'Heebo')),
        content: const Text('האם את בטוחה שברצונך להתנתק?', style: TextStyle(fontFamily: 'Heebo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.instance.logout();
              if (!context.mounted) return;
              context.read<AppState>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('התנתקי', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
