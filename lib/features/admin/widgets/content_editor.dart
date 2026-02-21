import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

/// Widget for editing or creating content items within a section.
/// Provides real-time content editing capabilities.
class ContentEditor extends StatefulWidget {
  final String sectionId;
  final ContentItem? contentItem;
  final VoidCallback? onBack;
  final Function(ContentItem)? onSave;

  const ContentEditor({
    super.key,
    required this.sectionId,
    this.contentItem,
    this.onBack,
    this.onSave,
  });

  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _mediaUrlCtrl;
  late final TextEditingController _linkUrlCtrl;
  late final TextEditingController _linkTextCtrl;
  late final TextEditingController _orderCtrl;
  
  late ContentType _selectedType;
  late bool _isPublished;
  Map<String, dynamic> _metadata = {};
  
  bool _isLoading = false;
  bool _isCreating = false;
  String? _selectedContentId;

  @override
  void initState() {
    super.initState();
    _isCreating = widget.contentItem == null && widget.onSave != null;
    _initControllers();
  }

  void _initControllers() {
    final content = widget.contentItem;
    _titleCtrl = TextEditingController(text: content?.title ?? '');
    _subtitleCtrl = TextEditingController(text: content?.subtitle ?? '');
    _bodyCtrl = TextEditingController(text: content?.body ?? '');
    _mediaUrlCtrl = TextEditingController(text: content?.mediaUrl ?? '');
    _linkUrlCtrl = TextEditingController(text: content?.linkUrl ?? '');
    _linkTextCtrl = TextEditingController(text: content?.linkText ?? 'למידע נוסף');
    _orderCtrl = TextEditingController(text: (content?.order ?? 0).toString());
    _selectedType = content?.type ?? ContentType.text;
    _isPublished = content?.isPublished ?? true;
    _metadata = Map<String, dynamic>.from(content?.metadata ?? {});
    _selectedContentId = content?.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _bodyCtrl.dispose();
    _mediaUrlCtrl.dispose();
    _linkUrlCtrl.dispose();
    _linkTextCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return _buildEditorView();
    }

    return _buildContentListView();
  }

  // ════════════════════════════════════════════════════════════════
  //  CONTENT LIST VIEW
  // ════════════════════════════════════════════════════════════════

  Widget _buildContentListView() {
    return Column(
      children: [
        // Header with section info
        _buildContentListHeader(),
        
        // Content list
        Expanded(
          child: StreamBuilder<List<ContentItem>>(
            stream: context.read<DynamicConfigService>().getContentForSectionStream(widget.sectionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data ?? [];
              
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'אין תוכן בסקשן זה',
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'לחצי על + כדי להוסיף תוכן חדש',
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) => _handleReorder(items, oldIndex, newIndex),
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildContentCard(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (widget.onBack != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: widget.onBack,
              ),
            Expanded(
              child: StreamBuilder<DynamicSection?>(
                stream: context.read<DynamicConfigService>().getSectionStream(widget.sectionId),
                builder: (context, snapshot) {
                  final section = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'עריכת תוכן',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        section?.name ?? 'טוען...',
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFD1C2D3)),
              onPressed: () => _showCreateContentSheet(),
              tooltip: 'תוכן חדש',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    final isSelected = _selectedContentId == item.id;
    
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: isSelected ? Border.all(color: const Color(0xFFD1C2D3), width: 2) : null,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.isPublished
                    ? const Color(0xFFD1C2D3).withValues(alpha: 0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForType(item.type),
                color: item.isPublished ? const Color(0xFFD1C2D3) : Colors.grey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title.isNotEmpty ? item.title : '(ללא כותרת)',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: item.title.isNotEmpty ? null : Colors.grey,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isPublished
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isPublished ? 'מפורסם' : 'טיוטה',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: item.isPublished
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      item.type.displayName,
                      style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.format_list_numbered, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'מיקום: ${item.order + 1}',
                      style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _editContent(item),
                ),
                IconButton(
                  icon: Icon(
                    item.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () => _togglePublish(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                  onPressed: () => _deleteContent(item),
                ),
                const Icon(Icons.drag_handle_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => _editContent(item),
          ),
          if (item.mediaUrl != null && item.mediaUrl!.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(item.mediaUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  EDITOR VIEW
  // ════════════════════════════════════════════════════════════════

  Widget _buildEditorView() {
    final isEditing = widget.contentItem != null || _selectedContentId != null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildEditorHeader(isEditing),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Preview
                  _buildLivePreview(),
                  const SizedBox(height: 24),
                  
                  // Content Type
                  _buildSectionTitle('סוג התוכן', Icons.category_rounded),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  
                  // Basic Content
                  _buildSectionTitle('תוכן', Icons.text_fields_rounded),
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'כותרת',
                    hint: 'הכותרת הראשית',
                    icon: Icons.title_rounded,
                  ),
                  _buildTextField(
                    controller: _subtitleCtrl,
                    label: 'כותרת משנה',
                    hint: 'תיאור קצר',
                    icon: Icons.short_text_rounded,
                  ),
                  _buildTextField(
                    controller: _bodyCtrl,
                    label: 'תוכן מלא',
                    hint: 'הטקסט המלא...',
                    icon: Icons.article_rounded,
                    maxLines: 5,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Media
                  _buildSectionTitle('מדיה', Icons.image_rounded),
                  _buildTextField(
                    controller: _mediaUrlCtrl,
                    label: 'קישור לתמונה/וידאו',
                    hint: 'https://...',
                    icon: Icons.link_rounded,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Link
                  _buildSectionTitle('קישור', Icons.link_rounded),
                  _buildTextField(
                    controller: _linkUrlCtrl,
                    label: 'כתובת קישור',
                    hint: 'https://...',
                    icon: Icons.language_rounded,
                  ),
                  _buildTextField(
                    controller: _linkTextCtrl,
                    label: 'טקסט הכפתור',
                    hint: 'למידע נוסף',
                    icon: Icons.smart_button_rounded,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Settings
                  _buildSectionTitle('הגדרות', Icons.settings_rounded),
                  _buildTextField(
                    controller: _orderCtrl,
                    label: 'מיקום (order)',
                    hint: '0, 1, 2...',
                    icon: Icons.format_list_numbered_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  _buildSwitchTile(
                    title: 'מפורסם',
                    subtitle: 'הצג באפליקציה',
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildEditorFooter(isEditing),
        ],
      ),
    );
  }

  Widget _buildEditorHeader(bool isEditing) {
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
            child: Icon(
              isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'עריכת תוכן' : 'תוכן חדש',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'עריכה בזמן אמת - השינויים יוצגו מיד',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha:0.7),
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
    );
  }

  Widget _buildLivePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1C2D3).withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'תצוגה מקדימה חיה',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_mediaUrlCtrl.text.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_mediaUrlCtrl.text),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
            ),
          if (_titleCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _titleCtrl.text,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (_subtitleCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _subtitleCtrl.text,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (_bodyCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _bodyCtrl.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (_linkUrlCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1C2D3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _linkTextCtrl.text.isNotEmpty ? _linkTextCtrl.text : 'למידע נוסף',
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorFooter(bool isEditing) {
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
                onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                onPressed: _isLoading ? null : _saveContent,
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
                        isEditing ? 'שמור שינויים' : 'צור תוכן',
                        style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════

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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        onChanged: (_) => setState(() {}), // Trigger live preview update
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
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      children: ContentType.values.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(type.displayName, style: const TextStyle(fontFamily: 'Heebo')),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedType = type),
          selectedColor: const Color(0xFFD1C2D3),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontFamily: 'Heebo',
            color: isSelected ? Colors.white : null,
          ),
        );
      }).toList(),
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
        border: Border.all(color: value ? const Color(0xFFD1C2D3).withValues(alpha:0.3) : Colors.grey[300]!),
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

  IconData _getIconForType(ContentType type) {
    switch (type) {
      case ContentType.text: return Icons.text_fields_rounded;
      case ContentType.image: return Icons.image_rounded;
      case ContentType.video: return Icons.videocam_rounded;
      case ContentType.link: return Icons.link_rounded;
      case ContentType.button: return Icons.smart_button_rounded;
      case ContentType.card: return Icons.view_agenda_rounded;
      case ContentType.banner: return Icons.view_day_rounded;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════════════

  void _showCreateContentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditor(
        sectionId: widget.sectionId,
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

  void _editContent(ContentItem item) {
    _selectedContentId = item.id;
    _titleCtrl.text = item.title;
    _subtitleCtrl.text = item.subtitle;
    _bodyCtrl.text = item.body;
    _mediaUrlCtrl.text = item.mediaUrl ?? '';
    _linkUrlCtrl.text = item.linkUrl ?? '';
    _linkTextCtrl.text = item.linkText ?? '';
    _orderCtrl.text = item.order.toString();
    _selectedType = item.type;
    _isPublished = item.isPublished;
    _metadata = Map<String, dynamic>.from(item.metadata);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditorView(),
    );
  }

  Future<void> _togglePublish(ContentItem item) async {
    await context.read<DynamicConfigService>().toggleContentPublished(
      item.id,
      !item.isPublished,
    );
    if (mounted) {
      AdminWidgets.snack(
        context,
        item.isPublished ? 'התוכן הוסר מפרסום' : 'התוכן פורסם',
      );
    }
  }

  Future<void> _deleteContent(ContentItem item) async {
    final confirmed = await AdminWidgets.confirmDelete(context, item.title);
    if (!confirmed) return;

    await context.read<DynamicConfigService>().deleteContent(item.id);
    if (mounted) {
      AdminWidgets.snack(context, 'התוכן נמחק');
    }
  }

  Future<void> _handleReorder(List<ContentItem> items, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    
    final reordered = List<ContentItem>.from(items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final ids = reordered.map((i) => i.id).toList();
    await context.read<DynamicConfigService>().reorderContent(widget.sectionId, ids);
  }

  void _saveContent() {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('כותרת היא שדה חובה');
      return;
    }

    final content = ContentItem(
      id: _selectedContentId ?? '',
      sectionId: widget.sectionId,
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      type: _selectedType,
      mediaUrl: _mediaUrlCtrl.text.trim().isNotEmpty ? _mediaUrlCtrl.text.trim() : null,
      linkUrl: _linkUrlCtrl.text.trim().isNotEmpty ? _linkUrlCtrl.text.trim() : null,
      linkText: _linkTextCtrl.text.trim().isNotEmpty ? _linkTextCtrl.text.trim() : null,
      order: int.tryParse(_orderCtrl.text) ?? 0,
      isPublished: _isPublished,
      metadata: _metadata,
    );

    setState(() => _isLoading = true);

    if (widget.onSave != null) {
      widget.onSave!(content);
    } else if (_selectedContentId != null) {
      context.read<DynamicConfigService>().updateContent(_selectedContentId!, content.toMap());
      AdminWidgets.snack(context, 'התוכן עודכן בהצלחה!');
      Navigator.pop(context);
    }
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
