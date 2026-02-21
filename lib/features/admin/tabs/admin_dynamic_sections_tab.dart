import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';
import 'package:mom_connect/features/admin/widgets/section_editor.dart';
import 'package:mom_connect/features/admin/widgets/content_editor.dart';
import 'package:mom_connect/features/admin/widgets/navigation_editor.dart';

/// Admin tab for managing dynamic app sections and their content.
/// Allows creating, editing, reordering, and toggling sections.
class AdminDynamicSectionsTab extends StatefulWidget {
  const AdminDynamicSectionsTab({super.key});

  @override
  State<AdminDynamicSectionsTab> createState() => _AdminDynamicSectionsTabState();
}

class _AdminDynamicSectionsTabState extends State<AdminDynamicSectionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _seedDefaults();
  }

  Future<void> _seedDefaults() async {
    final service = context.read<DynamicConfigService>();
    await service.seedDefaultSections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSectionsView(),
                  _buildContentView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF43363A),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: const Color(0xFFD1C2D3),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_customize_rounded), text: 'סקשנים'),
          Tab(icon: Icon(Icons.edit_note_rounded), text: 'תוכן'),
        ],
      ),
    );
  }

  Widget _buildSectionsView() {
    return StreamBuilder<List<DynamicSection>>(
      stream: context.read<DynamicConfigService>().dynamicSectionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sections = snapshot.data ?? [];
        if (sections.isEmpty) {
          return AdminWidgets.emptyState('אין סקשנים עדיין');
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          onReorder: (oldIndex, newIndex) => _handleReorder(sections, oldIndex, newIndex),
          proxyDecorator: (child, index, animation) => Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionCard(section, index);
          },
        );
      },
    );
  }

  Widget _buildSectionCard(DynamicSection section, int index) {
    final isSelected = _selectedSectionId == section.id;
    
    return Container(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AdminWidgets.cardDecor().copyWith(
        border: isSelected
            ? Border.all(color: const Color(0xFFD1C2D3), width: 2)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: section.isActive
                    ? const Color(0xFFD1C2D3).withValues(alpha: 0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.iconData,
                color: section.isActive ? const Color(0xFFD1C2D3) : Colors.grey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    section.name,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: section.isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.isActive ? 'פעיל' : 'מושבת',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: section.isActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.description,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'מיקום: ${section.order + 1}',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.category_outlined, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      section.type.displayName,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (section.route.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.route, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'נתיב: ${section.route}',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.tag, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'key: ${section.key}',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _editSection(section),
                  tooltip: 'ערוך',
                ),
                IconButton(
                  icon: Icon(
                    section.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () => _toggleSection(section),
                  tooltip: section.isActive ? 'השבת' : 'הפעל',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                  onPressed: () => _deleteSection(section),
                  tooltip: 'מחק',
                ),
                const Icon(Icons.drag_handle_rounded, color: Colors.grey),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedSectionId = section.id;
                _tabController.animateTo(1);
              });
            },
          ),
          if (section.settings.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Wrap(
                spacing: 8,
                children: section.settings.entries.map((e) {
                  return Chip(
                    label: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 10),
                    ),
                    backgroundColor: const Color(0xFFF9F5F4),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    if (_selectedSectionId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'בחרי סקשן כדי לערוך תוכן',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('לבחירת סקשן', style: TextStyle(fontFamily: 'Heebo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1C2D3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ContentEditor(
      sectionId: _selectedSectionId!,
      onBack: () {
        setState(() {
          _selectedSectionId = null;
        });
      },
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tabController.index == 0) ...[
          FloatingActionButton.small(
            heroTag: 'nav_editor',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NavigationEditor(),
              );
            },
            backgroundColor: const Color(0xFF43363A),
            child: const Icon(Icons.navigation_rounded),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.extended(
          heroTag: 'add_section',
          onPressed: _tabController.index == 0 ? _addNewSection : _addNewContent,
          backgroundColor: const Color(0xFFD1C2D3),
          icon: Icon(_tabController.index == 0 ? Icons.add_rounded : Icons.post_add_rounded),
          label: Text(
            _tabController.index == 0 ? 'סקשן חדש' : 'תוכן חדש',
            style: const TextStyle(fontFamily: 'Heebo'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReorder(List<DynamicSection> sections, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    
    final reordered = List<DynamicSection>.from(sections);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final ids = reordered.map((s) => s.id).toList();
    await context.read<DynamicConfigService>().reorderSections(ids);
  }

  void _editSection(DynamicSection section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SectionEditor(
        section: section,
        onSave: (updated) async {
          await context.read<DynamicConfigService>().updateSection(
            section.id,
            updated.toMap(),
          );
          if (mounted) {
            AdminWidgets.snack(context, 'הסקשן עודכן בהצלחה!');
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Future<void> _toggleSection(DynamicSection section) async {
    await context.read<DynamicConfigService>().toggleSectionActive(
      section.id,
      !section.isActive,
    );
    if (mounted) {
      AdminWidgets.snack(
        context,
        section.isActive ? 'הסקשן הושבת' : 'הסקשן הופעל',
      );
    }
  }

  Future<void> _deleteSection(DynamicSection section) async {
    final confirmed = await AdminWidgets.confirmDelete(context, section.name);
    if (!confirmed) return;

    await context.read<DynamicConfigService>().deleteSection(section.id);
    if (mounted) {
      AdminWidgets.snack(context, 'הסקשן נמחק');
      if (_selectedSectionId == section.id) {
        setState(() => _selectedSectionId = null);
      }
    }
  }

  void _addNewSection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SectionEditor(
        onSave: (section) async {
          await context.read<DynamicConfigService>().createSection(section);
          if (mounted) {
            AdminWidgets.snack(context, 'הסקשן נוצר בהצלחה!');
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _addNewContent() {
    if (_selectedSectionId == null) {
      AdminWidgets.snack(context, 'קודם בחרי סקשן', color: Colors.orange);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditor(
        sectionId: _selectedSectionId!,
        contentItem: null,
        onSave: (content) async {
          await context.read<DynamicConfigService>().createContent(content);
          if (mounted) {
            AdminWidgets.snack(context, 'התוכן נוצר בהצלחה!');
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
