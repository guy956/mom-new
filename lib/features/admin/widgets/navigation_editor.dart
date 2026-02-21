import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

/// Widget for editing app navigation order and visibility.
/// Allows drag-and-drop reordering of navigation items.
class NavigationEditor extends StatefulWidget {
  final VoidCallback? onClose;

  const NavigationEditor({
    super.key,
    this.onClose,
  });

  @override
  State<NavigationEditor> createState() => _NavigationEditorState();
}

class _NavigationEditorState extends State<NavigationEditor> {
  bool _isLoading = false;
  List<NavItem> _navItems = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<AppConfig>(
                stream: context.read<DynamicConfigService>().appConfigStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_initialized) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final config = snapshot.data;
                  if (config != null && !_initialized) {
                    _initNavItems(config);
                  }

                  return _buildContent();
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  void _initNavItems(AppConfig config) {
    final defaultNavItems = [
      NavItem(key: 'home', label: 'בית', icon: Icons.home_rounded, visible: true),
      NavItem(key: 'chat', label: 'צ׳אט', icon: Icons.chat_bubble_rounded, visible: true),
      NavItem(key: 'community', label: 'קהילה', icon: Icons.people_rounded, visible: true),
      NavItem(key: 'events', label: 'אירועים', icon: Icons.event_rounded, visible: true),
      NavItem(key: 'experts', label: 'מומחים', icon: Icons.verified_rounded, visible: true),
      NavItem(key: 'marketplace', label: 'מסירות', icon: Icons.store_rounded, visible: true),
      NavItem(key: 'tips', label: 'טיפים', icon: Icons.tips_and_updates_rounded, visible: true),
      NavItem(key: 'profile', label: 'פרופיל', icon: Icons.person_rounded, visible: true),
    ];

    final order = config.navigationOrder;
    final visibility = config.featureVisibility;

    // Sort according to saved order
    _navItems = order.map((key) {
      final defaultItem = defaultNavItems.firstWhere(
        (item) => item.key == key,
        orElse: () => NavItem(key: key, label: key, icon: Icons.circle, visible: true),
      );
      return defaultItem.copyWith(
        visible: visibility[key] ?? true,
      );
    }).toList();

    // Add any missing items
    for (final item in defaultNavItems) {
      if (!_navItems.any((n) => n.key == item.key)) {
        _navItems.add(item);
      }
    }

    _initialized = true;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF43363A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD1C2D3).withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'עריכת ניווט',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'סדרי את סדר התפריט וקבעי זמינות',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: widget.onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_navItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'גררי פריטים כדי לשנות את סדר התפריט. הסתירי פריטים על ידי כיבוי המתג.',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Reorderable list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _navItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _navItems.removeAt(oldIndex);
                _navItems.insert(newIndex, item);
              });
            },
            proxyDecorator: (child, index, animation) => Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
            itemBuilder: (context, index) {
              final item = _navItems[index];
              return _buildNavItemCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavItemCard(NavItem item, int index) {
    return Container(
      key: ValueKey(item.key),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.visible ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.visible ? const Color(0xFFD1C2D3).withValues(alpha:0.3) : Colors.grey[300]!,
        ),
        boxShadow: item.visible
            ? [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: item.visible
                ? const Color(0xFFD1C2D3).withValues(alpha:0.15)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            color: item.visible ? const Color(0xFFD1C2D3) : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontFamily: 'Heebo',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: item.visible ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          'מיקום: ${index + 1}',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 12,
            color: item.visible ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.visible,
              onChanged: (value) {
                setState(() {
                  _navItems[index] = item.copyWith(visible: value);
                });
              },
              activeColor: const Color(0xFFD1C2D3),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.drag_handle_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : (widget.onClose ?? () => Navigator.pop(context)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF43363A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo', color: Color(0xFF43363A))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1C2D3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'שמור שינויים',
                        style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNavigation() async {
    setState(() => _isLoading = true);

    try {
      final navOrder = _navItems.map((item) => item.key).toList();
      final visibility = {for (var item in _navItems) item.key: item.visible};

      final service = context.read<DynamicConfigService>();
      
      // Update app config
      final config = AppConfig(
        id: 'main',
        appName: 'MOMIT',
        slogan: 'כי רק אמא מבינה אמא',
        navigationOrder: navOrder,
        navigationItems: [],
        quickAccessItems: [],
        featureVisibility: visibility,
        themeSettings: {},
      );
      
      await service.updateAppConfig(config);

      if (mounted) {
        AdminWidgets.snack(context, 'הניווט עודכן בהצלחה!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AdminWidgets.snack(context, 'שגיאה בשמירה: $e', color: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  NAV ITEM MODEL
// ════════════════════════════════════════════════════════════════

class NavItem {
  final String key;
  final String label;
  final IconData icon;
  final bool visible;

  NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.visible,
  });

  NavItem copyWith({
    String? key,
    String? label,
    IconData? icon,
    bool? visible,
  }) => NavItem(
    key: key ?? this.key,
    label: label ?? this.label,
    icon: icon ?? this.icon,
    visible: visible ?? this.visible,
  );
}
