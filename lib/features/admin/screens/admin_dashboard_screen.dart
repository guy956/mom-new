import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/features/auth/screens/welcome_screen.dart';
import 'package:mom_connect/features/home/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/rbac_service.dart';
import 'package:mom_connect/features/admin/tabs/admin_overview_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_users_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_experts_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_media_vault_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_events_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_marketplace_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_content_tips_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_reports_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_app_config_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_feature_toggles_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_ui_design_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_communication_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_dynamic_forms_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_dynamic_sections_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_content_manager_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_navigation_editor_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_audit_log_tab.dart';
import 'package:mom_connect/features/admin/tabs/admin_approvals_tab.dart';

/// Callback type for tab navigation from overview
typedef TabNavigator = void Function(String tabId);

/// Tab definition with permission check
class _AdminTab {
  final String id;
  final String label;
  final IconData icon;
  final Permission permission;
  final Widget Function() builder;
  final Stream<List<Map<String, dynamic>>>? badgeStream;
  final int Function(List<Map<String, dynamic>>)? badgeCounter;

  const _AdminTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.permission,
    required this.builder,
    this.badgeStream,
    this.badgeCounter,
  });
}

/// Shimmer loading widget for better UX
class _ShimmerLoading extends StatefulWidget {
  final Widget child;
  const _ShimmerLoading({required this.child});

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<_AdminTab> _accessibleTabs = [];
  final ScrollController _tabScrollController = ScrollController();

  // Cache for tab indices lookup
  final Map<String, int> _tabIndexMap = {};

  @override
  void initState() {
    super.initState();
    _initializeRbac();
  }

  Future<void> _initializeRbac() async {
    try {
      // Get current user
      final userData = await AuthService.instance.getSavedSession();
      if (userData == null) {
        setState(() {
          _errorMessage = 'לא נמצא משתמש מחובר';
          _isLoading = false;
        });
        return;
      }

      final userId = userData['id'] as String? ?? '';
      
      // Initialize RBAC
      await RbacService.instance.initialize(userId);

      // Check if user has admin access - use single consistent check
      final rbac = RbacService.instance;
      if (!rbac.hasPermission(Permission.accessGodMode)) {
        setState(() {
          _errorMessage = 'אין לך הרשאות לגשת לאזור זה';
          _isLoading = false;
        });
        return;
      }

      // Seed initial Firestore data if needed (admin is now authenticated)
      try {
        final fs = context.read<FirestoreService>();
        await fs.seedInitialData();
      } catch (e) {
        debugPrint('[AdminDashboard] Seed warning: $e');
      }

      // Build accessible tabs list
      _buildAccessibleTabs();

      // Initialize tab controller with animation
      if (_accessibleTabs.isNotEmpty) {
        _tabController = TabController(
          length: _accessibleTabs.length,
          vsync: this,
          animationDuration: const Duration(milliseconds: 300),
        );
        
        // Build tab index map for quick lookup
        _buildTabIndexMap();
      }

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      debugPrint('[AdminDashboard] RBAC initialization error: $e');
      debugPrint('[AdminDashboard] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'שגיאה באתחול לוח הבקרה. נא לנסות שוב.';
        _isLoading = false;
      });
    }
  }

  /// Build a map of tab ID to index for quick navigation
  void _buildTabIndexMap() {
    _tabIndexMap.clear();
    for (int i = 0; i < _accessibleTabs.length; i++) {
      _tabIndexMap[_accessibleTabs[i].id] = i;
    }
  }

  /// Navigate to a specific tab by ID (used by overview quick actions)
  void _navigateToTab(String tabId) {
    final index = _tabIndexMap[tabId];
    if (index != null && _tabController != null) {
      _tabController!.animateTo(index);
      // Scroll tab bar to make the selected tab visible
      _scrollToTab(index);
    } else {
      debugPrint('[AdminDashboard] Tab $tabId not found or not accessible');
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'התפריט אינו זמין להרשאות שלך',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: Color(0xFFD4A3A3),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Scroll tab bar to make specific tab visible
  void _scrollToTab(int index) {
    if (_tabScrollController.hasClients) {
      final tabWidth = 100.0; // Approximate tab width
      final offset = (index * tabWidth) - (MediaQuery.of(context).size.width / 2) + (tabWidth / 2);
      _tabScrollController.animateTo(
        offset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _buildAccessibleTabs() {
    final rbac = RbacService.instance;
    final fs = context.read<FirestoreService>();

    // Define all 18 admin tabs with proper permissions
    final allTabs = [
      // 1. Overview - Analytics dashboard (requires viewAnalytics)
      _AdminTab(
        id: 'overview',
        label: 'סקירה',
        icon: Icons.dashboard_rounded,
        permission: Permission.viewAnalytics,
        builder: () => AdminOverviewTab(tabController: _tabController!),
      ),
      // 2. Approvals - Content approval (requires manageEvents or viewUsers)
      _AdminTab(
        id: 'approvals',
        label: 'אישורים',
        icon: Icons.approval_rounded,
        permission: Permission.manageEvents,
        builder: () => const AdminApprovalsTab(),
        badgeStream: _combinedPendingStream(fs),
        badgeCounter: (items) => items.length,
      ),
      // 3. Users - User management
      _AdminTab(
        id: 'users',
        label: 'משתמשות',
        icon: Icons.people_rounded,
        permission: Permission.viewUsers,
        builder: () => const AdminUsersTab(),
        badgeStream: fs.usersStream,
        badgeCounter: (users) => users.where((u) => u['status'] == 'pending').length,
      ),
      // 4. Experts - Expert management
      _AdminTab(
        id: 'experts',
        label: 'מומחים',
        icon: Icons.verified_rounded,
        permission: Permission.viewExperts,
        builder: () => const AdminExpertsTab(),
        badgeStream: fs.expertsStream,
        badgeCounter: (experts) => experts.where((e) => e['status'] == 'pending').length,
      ),
      // 5. Media - Media vault
      _AdminTab(
        id: 'media',
        label: 'מדיה',
        icon: Icons.cloud_rounded,
        permission: Permission.viewMedia,
        builder: () => const AdminMediaVaultTab(),
      ),
      // 6. Events - Event management
      _AdminTab(
        id: 'events',
        label: 'אירועים',
        icon: Icons.event_rounded,
        permission: Permission.manageEvents,
        builder: () => const AdminEventsTab(),
        badgeStream: fs.eventsStream,
        badgeCounter: (events) => events.where((e) => e['status'] == 'pending').length,
      ),
      // 7. Marketplace - Item listings
      _AdminTab(
        id: 'marketplace',
        label: 'מסירות',
        icon: Icons.store_rounded,
        permission: Permission.viewMarketplace,
        builder: () => const AdminMarketplaceTab(),
      ),
      // 8. Content - Content tips
      _AdminTab(
        id: 'content',
        label: 'תוכן',
        icon: Icons.tips_and_updates_rounded,
        permission: Permission.viewContent,
        builder: () => const AdminContentTipsTab(),
      ),
      // 9. Reports - User reports
      _AdminTab(
        id: 'reports',
        label: 'דיווחים',
        icon: Icons.flag_rounded,
        permission: Permission.viewReports,
        builder: () => const AdminReportsTab(),
        badgeStream: fs.reportsStream,
        badgeCounter: (reports) => reports.where((r) => r['status'] == 'pending').length,
      ),
      // 10. Config - App configuration
      _AdminTab(
        id: 'config',
        label: 'הגדרות',
        icon: Icons.settings_applications_rounded,
        permission: Permission.viewConfig,
        builder: () => const AdminAppConfigTab(),
      ),
      // 11. Features - Feature toggles
      _AdminTab(
        id: 'features',
        label: 'תכונות',
        icon: Icons.toggle_on_rounded,
        permission: Permission.manageFeatures,
        builder: () => const AdminFeatureTogglesTab(),
      ),
      // 12. Design - UI/UX design
      _AdminTab(
        id: 'design',
        label: 'עיצוב',
        icon: Icons.palette_rounded,
        permission: Permission.manageUIDesign,
        builder: () => const AdminUIDesignTab(),
      ),
      // 13. Communication - Notifications & messaging
      _AdminTab(
        id: 'communication',
        label: 'תקשורת',
        icon: Icons.campaign_rounded,
        permission: Permission.manageCommunication,
        builder: () => const AdminCommunicationTab(),
      ),
      // 14. Forms - Dynamic forms
      _AdminTab(
        id: 'forms',
        label: 'טפסים',
        icon: Icons.dynamic_form_rounded,
        permission: Permission.manageForms,
        builder: () => const AdminDynamicFormsTab(),
      ),
      // 15. Navigation - Navigation editor
      _AdminTab(
        id: 'navigation',
        label: 'ניווט',
        icon: Icons.navigation_rounded,
        permission: Permission.editConfig,
        builder: () => const AdminNavigationEditorTab(),
      ),
      // 16. Dynamic - Dynamic sections
      _AdminTab(
        id: 'dynamic',
        label: 'דינמי',
        icon: Icons.dashboard_customize_rounded,
        permission: Permission.editConfig,
        builder: () => const AdminDynamicSectionsTab(),
      ),
      // 17. Content Manager - Content management
      _AdminTab(
        id: 'content_mgr',
        label: 'ניהול תוכן',
        icon: Icons.content_paste_rounded,
        permission: Permission.manageTips,
        builder: () => const AdminContentManagerTab(),
      ),
      // 18. Audit - Security & audit log
      _AdminTab(
        id: 'audit',
        label: 'אבטחה',
        icon: Icons.security_rounded,
        permission: Permission.viewAuditLog,
        builder: () => const AdminAuditLogTab(),
      ),
    ];

    // Filter tabs based on user permissions
    _accessibleTabs = allTabs.where((tab) => rbac.hasPermission(tab.permission)).toList();
    
    debugPrint('[AdminDashboard] Built ${_accessibleTabs.length} accessible tabs from ${allTabs.length} total');
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  /// Refresh dashboard data
  Future<void> _refreshData() async {
    setState(() {});
    
    // Show refresh indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('מעדכן נתונים...', style: TextStyle(fontFamily: 'Heebo')),
            ],
          ),
          backgroundColor: Color(0xFFB5C8B9),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // Simulate a brief delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הנתונים עודכנו', style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: Color(0xFFB5C8B9),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_accessibleTabs.isEmpty) {
      return _buildNoAccessScreen();
    }

    final fs = context.read<FirestoreService>();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F4),
      appBar: _buildAppBar(fs),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD1C2D3),
        backgroundColor: Colors.white,
        child: Column(children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              physics: const BouncingScrollPhysics(),
              children: _accessibleTabs.map((tab) => tab.builder()).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            // Loading text with shimmer
            _ShimmerLoading(
              child: Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD1C2D3)),
            ),
            const SizedBox(height: 16),
            const Text(
              'טוען לוח בקרה...',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A3A3).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, size: 48, color: Color(0xFFD4A3A3)),
              ),
              const SizedBox(height: 24),
              const Text(
                'אירעה שגיאה',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43363A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeRbac();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1C2D3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: const Text('נסה שוב', style: TextStyle(fontFamily: 'Heebo')),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (r) => false,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('חזרה למסך הראשי', style: TextStyle(fontFamily: 'Heebo')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A3A3).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: Color(0xFFD4A3A3)),
              ),
              const SizedBox(height: 24),
              const Text(
                'אין הרשאות גישה',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43363A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'אין לך הרשאות לגשת ללוח הבקרה',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'פנה למנהלת המערכת לקבלת הרשאות',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (r) => false,
                ),
                icon: const Icon(Icons.home_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1C2D3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('חזרה למסך הראשי', style: TextStyle(fontFamily: 'Heebo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(FirestoreService fs) {
    final rbac = RbacService.instance;
    
    return AppBar(
      backgroundColor: const Color(0xFF43363A), foregroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false),
      ),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('MOMIT God-Mode', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (rbac.currentUserRole != null)
                    RoleBadge(role: rbac.currentUserRole!, fontSize: 9) as Widget,
                ],
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.usersStream,
                builder: (_, snap) {
                  final count = snap.data?.length ?? 0;
                  return Text('$count משתמשות', style: const TextStyle(fontFamily: 'Heebo', fontSize: 10, color: Colors.white60));
                },
              ),
            ],
          ),
        ),
      ]),
      actions: [
        // Role indicator button
        if (rbac.currentUserRole != null)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rbac.currentUserRole!.displayName,
                style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.white70),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: _refreshData,
          tooltip: 'רענון',
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: fs.reportsStream,
          builder: (_, snap) {
            final pending = (snap.data ?? []).where((r) => r['status'] == 'pending').length;
            return IconButton(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending', style: const TextStyle(fontSize: 8)),
                child: const Icon(Icons.notifications_outlined, size: 20),
              ),
              onPressed: () => _showNotifications(context, fs),
            );
          },
        ),
        IconButton(icon: const Icon(Icons.logout_rounded, size: 20), onPressed: () => _handleLogout(context)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF43363A),
      child: TabBar(
        controller: _tabController!,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        indicatorColor: const Color(0xFFD1C2D3),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w400, fontSize: 11),
        physics: const BouncingScrollPhysics(),
        tabs: _accessibleTabs.map((tab) {
          if (tab.badgeStream != null && tab.badgeCounter != null) {
            return _buildBadgeTab(tab);
          }
          return _buildSimpleTab(tab);
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleTab(_AdminTab tab) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, size: 15),
          const SizedBox(width: 4),
          Text(tab.label),
        ],
      ),
    );
  }

  Widget _buildBadgeTab(_AdminTab tab) {
    return Tab(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: tab.badgeStream!,
        builder: (_, snap) {
          // Handle error state gracefully
          if (snap.hasError) {
            debugPrint('[AdminDashboard] Badge stream error for ${tab.id}: ${snap.error}');
          }
          
          final count = snap.hasData && !snap.hasError 
              ? tab.badgeCounter!(snap.data!) 
              : 0;
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 15),
              const SizedBox(width: 4),
              Text(tab.label),
              if (count > 0) ...[
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count', 
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context, FirestoreService fs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'התראות מנהלת',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.activityLogStream,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFD4A3A3), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'שגיאה בטעינת ההתראות',
                            style: TextStyle(fontFamily: 'Heebo', color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final logs = snap.data ?? [];
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('אין התראות', style: TextStyle(fontFamily: 'Heebo')),
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final log = logs[i];
                      final timestamp = log['createdAt'];
                      final timeAgo = _formatTimestamp(timestamp);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1C2D3).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1C2D3).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications, color: Color(0xFFD1C2D3), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['action'] ?? '',
                                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      log['user'] ?? '',
                                      style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint),
                                    ),
                                    if (timeAgo.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• $timeAgo',
                                        style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey[400]),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = timestamp.toDate();
      }
      final diff = DateTime.now().difference(dateTime);
      if (diff.inMinutes < 1) return 'עכשיו';
      if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
      if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
      if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
      return '';
    } catch (_) {
      return '';
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('התנתקות', style: TextStyle(fontFamily: 'Heebo')),
        content: const Text('האם להתנתק מלוח הבקרה?', style: TextStyle(fontFamily: 'Heebo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (!ctx.mounted) return;
              ctx.read<AppState>().logout();
              Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A3A3)),
            child: const Text('התנתק', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Combined stream of all pending content for approvals badge
  Stream<List<Map<String, dynamic>>> _combinedPendingStream(FirestoreService fs) {
    return fs.eventsStream.asyncExpand((events) {
      final pendingEvents = events.where((e) => (e['status'] ?? 'pending') == 'pending').toList();
      return fs.postsStream.asyncExpand((posts) {
        final pendingPosts = posts.where((p) => (p['status'] ?? 'pending') == 'pending').toList();
        return fs.marketplaceStream.map((items) {
          final pendingItems = items.where((i) => (i['status'] ?? 'pending') == 'pending').toList();
          return [...pendingEvents, ...pendingPosts, ...pendingItems];
        });
      });
    });
  }
}
