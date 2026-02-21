import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';

/// Widget for editing or creating a dynamic section.
/// Provides a form for all section properties including type, settings, and metadata.
class SectionEditor extends StatefulWidget {
  final DynamicSection? section;
  final Function(DynamicSection) onSave;

  const SectionEditor({
    super.key,
    this.section,
    required this.onSave,
  });

  @override
  State<SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<SectionEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _routeCtrl;
  
  late SectionType _selectedType;
  late String _selectedIconName;
  late bool _isActive;
  late Map<String, dynamic> _settings;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final section = widget.section;
    _nameCtrl = TextEditingController(text: section?.name ?? '');
    _keyCtrl = TextEditingController(text: section?.key ?? '');
    _descCtrl = TextEditingController(text: section?.description ?? '');
    _orderCtrl = TextEditingController(text: (section?.order ?? 0).toString());
    _routeCtrl = TextEditingController(text: section?.route ?? '');
    _selectedType = section?.type ?? SectionType.custom;
    _selectedIconName = section?.iconName ?? 'dashboard_customize';
    _isActive = section?.isActive ?? true;
    _settings = Map<String, dynamic>.from(section?.settings ?? {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.section != null;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF43363A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1C2D3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'עריכת סקשן' : 'סקשן חדש',
                          style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isEditing ? widget.section!.key : 'הגדרת אזור דינמי באפליקציה',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Basic Info
                    _buildSectionTitle('מידע בסיסי', Icons.info_outline_rounded),
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'שם הסקשן',
                      hint: 'למשל: כותרת ראשית, תכונות עיקריות',
                      icon: Icons.title_rounded,
                    ),
                    _buildTextField(
                      controller: _keyCtrl,
                      label: 'מזהה ייחודי (key)',
                      hint: 'hero, features, tips וכו',
                      icon: Icons.key_rounded,
                      enabled: !isEditing,
                      helpText: 'מזהה זה משמש לגישה programmatic',
                    ),
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'תיאור',
                      hint: 'תיאור קצר של תפקיד הסקשן',
                      icon: Icons.description_rounded,
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Type
                    _buildSectionTitle('סוג הסקשן', Icons.category_rounded),
                    _buildTypeSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Icon
                    _buildSectionTitle('אייקון', Icons.image_rounded),
                    _buildIconSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Route
                    _buildSectionTitle('ניתוב', Icons.route_rounded),
                    _buildTextField(
                      controller: _routeCtrl,
                      label: 'נתיב ניווט (route)',
                      hint: '/home, /profile, /chat וכו',
                      icon: Icons.link_rounded,
                      helpText: 'הנתיב לניווט כאשר לוחצים על הסקשן',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Settings
                    _buildSectionTitle('הגדרות', Icons.settings_rounded),
                    _buildTextField(
                      controller: _orderCtrl,
                      label: 'מיקום (order)',
                      hint: '0, 1, 2...',
                      icon: Icons.format_list_numbered_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    _buildSwitchTile(
                      title: 'סקשן פעיל',
                      subtitle: 'הצג באפליקציה',
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Custom Settings
                    _buildSectionTitle('הגדרות מותאמות', Icons.tune_rounded),
                    _buildSettingsEditor(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF43363A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'ביטול',
                          style: TextStyle(fontFamily: 'Heebo', color: Color(0xFF43363A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
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
                            : Text(
                                isEditing ? 'עדכן סקשן' : 'צור סקשן',
                                style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD1C2D3)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF43363A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
    String? helpText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: enabled,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFFD1C2D3)) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1C2D3), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (helpText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Text(
                helpText,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: SectionType.values.map((type) {
          final isSelected = _selectedType == type;
          return RadioListTile<SectionType>(
            title: Row(
              children: [
                Icon(type.icon, size: 20, color: isSelected ? const Color(0xFFD1C2D3) : Colors.grey),
                const SizedBox(width: 12),
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            value: type,
            groupValue: _selectedType,
            activeColor: const Color(0xFFD1C2D3),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  // Available icons for sections
  static const Map<String, IconData> _availableIcons = {
    'dashboard_customize': Icons.dashboard_customize_rounded,
    'home': Icons.home_rounded,
    'person': Icons.person_rounded,
    'chat': Icons.chat_rounded,
    'event': Icons.event_rounded,
    'favorite': Icons.favorite_rounded,
    'info': Icons.info_rounded,
    'settings': Icons.settings_rounded,
    'notifications': Icons.notifications_rounded,
    'search': Icons.search_rounded,
    'menu': Icons.menu_rounded,
    'dashboard': Icons.dashboard_rounded,
    'article': Icons.article_rounded,
    'image': Icons.image_rounded,
    'video': Icons.video_library_rounded,
    'music': Icons.music_note_rounded,
    'map': Icons.map_rounded,
    'phone': Icons.phone_rounded,
    'email': Icons.email_rounded,
    'share': Icons.share_rounded,
    'star': Icons.star_rounded,
    'bookmark': Icons.bookmark_rounded,
    'help': Icons.help_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'payment': Icons.payment_rounded,
    'schedule': Icons.schedule_rounded,
    'calendar': Icons.calendar_today_rounded,
    'camera': Icons.camera_alt_rounded,
    'location': Icons.location_on_rounded,
    'groups': Icons.groups_rounded,
    'work': Icons.work_rounded,
    'school': Icons.school_rounded,
    'health': Icons.favorite_border_rounded,
    'child_care': Icons.child_care_rounded,
    'family': Icons.family_restroom_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'store': Icons.store_rounded,
    'support': Icons.support_agent_rounded,
    'tips': Icons.lightbulb_rounded,
    'news': Icons.newspaper_rounded,
    'forum': Icons.forum_rounded,
    'list': Icons.list_rounded,
    'grid': Icons.grid_view_rounded,
    'view_day': Icons.view_day_rounded,
    'touch_app': Icons.touch_app_rounded,
    'view_carousel': Icons.view_carousel_rounded,
    'grid_on': Icons.grid_on_rounded,
  };

  Widget _buildIconSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Selected icon preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD1C2D3).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _availableIcons[_selectedIconName] ?? Icons.dashboard_customize_rounded,
                  size: 48,
                  color: const Color(0xFFD1C2D3),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedIconName,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Icon grid
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (context, index) {
                final entry = _availableIcons.entries.elementAt(index);
                final isSelected = _selectedIconName == entry.key;
                return InkWell(
                  onTap: () => setState(() => _selectedIconName = entry.key),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD1C2D3).withValues(alpha: 0.2) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD1C2D3) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 24,
                      color: isSelected ? const Color(0xFFD1C2D3) : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? const Color(0xFFD1C2D3).withValues(alpha: 0.3) : Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey[600]))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFD1C2D3),
      ),
    );
  }

  Widget _buildSettingsEditor() {
    final defaultSettings = _getDefaultSettingsForType(_selectedType);
    
    // Merge with existing settings
    for (final entry in defaultSettings.entries) {
      if (!_settings.containsKey(entry.key)) {
        _settings[entry.key] = entry.value;
      }
    }

    return Column(
      children: _settings.entries.map((entry) {
        return _buildSettingRow(entry.key, entry.value);
      }).toList(),
    );
  }

  Map<String, dynamic> _getDefaultSettingsForType(SectionType type) {
    switch (type) {
      case SectionType.hero:
        return {
          'backgroundImage': '',
          'textAlign': 'center',
          'showOverlay': true,
          'minHeight': 300,
        };
      case SectionType.features:
        return {
          'columns': 3,
          'showIcons': true,
          'iconSize': 48.0,
        };
      case SectionType.content:
        return {
          'itemsToShow': 3,
          'autoRotate': false,
          'showDate': true,
        };
      case SectionType.community:
        return {
          'showStats': true,
          'showRecentActivity': true,
        };
      case SectionType.cta:
        return {
          'buttons': 2,
          'buttonStyle': 'filled',
        };
      case SectionType.carousel:
        return {
          'autoPlay': true,
          'interval': 5,
          'showIndicators': true,
        };
      case SectionType.grid:
        return {
          'columns': 2,
          'spacing': 16.0,
          'aspectRatio': 1.0,
        };
      case SectionType.custom:
        return {
          'customClass': '',
          'customStyle': '',
        };
    }
  }

  Widget _buildSettingRow(String key, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: () => _editSetting(key, value),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            onPressed: () {
              setState(() => _settings.remove(key));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editSetting(String key, dynamic currentValue) async {
    final ctrl = TextEditingController(text: currentValue.toString());
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ערוך: $key', style: const TextStyle(fontFamily: 'Heebo')),
        content: TextField(
          controller: ctrl,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD1C2D3)),
            child: const Text('שמור', style: TextStyle(fontFamily: 'Heebo')),
          ),
        ],
      ),
    );
    
    ctrl.dispose();
    
    if (result != null) {
      setState(() {
        // Try to parse as number/bool, otherwise keep as string
        if (result == 'true') {
          _settings[key] = true;
        } else if (result == 'false') {
          _settings[key] = false;
        } else if (int.tryParse(result) != null) {
          _settings[key] = int.parse(result);
        } else if (double.tryParse(result) != null) {
          _settings[key] = double.parse(result);
        } else {
          _settings[key] = result;
        }
      });
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('שם הסקשן הוא שדה חובה');
      return;
    }
    if (_keyCtrl.text.trim().isEmpty) {
      _showError('מזהה הסקשן הוא שדה חובה');
      return;
    }

    final section = DynamicSection(
      id: widget.section?.id ?? '',
      key: _keyCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _selectedType,
      iconName: _selectedIconName,
      route: _routeCtrl.text.trim(),
      order: int.tryParse(_orderCtrl.text) ?? 0,
      isActive: _isActive,
      settings: _settings,
    );

    setState(() => _isLoading = true);
    widget.onSave(section);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Heebo')),
        backgroundColor: Colors.red[400],
      ),
    );
  }
}
