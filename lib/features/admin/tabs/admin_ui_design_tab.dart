import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminUIDesignTab extends StatefulWidget {
  const AdminUIDesignTab({super.key});

  @override
  State<AdminUIDesignTab> createState() => _AdminUIDesignTabState();
}

class _AdminUIDesignTabState extends State<AdminUIDesignTab> {
  String _primaryColor = '#D4A1AC';
  String _secondaryColor = '#EDD3D8';
  String _accentColor = '#DBC8B0';

  List<String> _menuOrder = ['בית', 'צ\'אט', 'קהילה', 'מומחים', 'פרופיל'];

  List<String> _expertCategories = [
    'רופאת ילדים',
    'יועצת שינה',
    'יועצת הנקה',
    'דיאטנית',
    'פסיכולוגית',
    'מטפלת רגשית',
    'פיזיותרפיסטית',
    'אחר',
  ];

  List<String> _tipCategories = [
    'שינה',
    'האכלה',
    'התפתחות',
    'בריאות',
    'כושר',
    'רווחה נפשית',
    'טיפול בתינוק',
    'תזונה',
  ];

  List<String> _marketplaceCategories = [
    'ציוד לתינוק',
    'עגלות',
    'ריהוט',
    'ביגוד',
    'צעצועים',
    'ספרים',
    'אחר',
  ];

  bool _initialized = false;
  bool _saving = false;

  final TextEditingController _newExpertCategoryController =
      TextEditingController();
  final TextEditingController _newTipCategoryController =
      TextEditingController();
  final TextEditingController _newMarketplaceCategoryController =
      TextEditingController();

  static const List<String> _colorPresets = [
    '#D4A1AC',
    '#EDD3D8',
    '#DBC8B0',
    '#B5C8B9',
    '#D1C2D3',
    '#7986CB',
    '#FF8A65',
    '#81C784',
  ];

  @override
  void dispose() {
    _newExpertCategoryController.dispose();
    _newTipCategoryController.dispose();
    _newMarketplaceCategoryController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _initFromData(Map<String, dynamic> data) {
    if (_initialized) return;
    setState(() {
      _primaryColor = data['primaryColor'] ?? _primaryColor;
      _secondaryColor = data['secondaryColor'] ?? _secondaryColor;
      _accentColor = data['accentColor'] ?? _accentColor;
      _menuOrder = List<String>.from(data['menuOrder'] ?? _menuOrder);
      _expertCategories =
          List<String>.from(data['expertCategories'] ?? _expertCategories);
      _tipCategories =
          List<String>.from(data['tipCategories'] ?? _tipCategories);
      _marketplaceCategories =
          List<String>.from(data['marketplaceCategories'] ?? _marketplaceCategories);
      _initialized = true;
    });
  }

  Future<void> _showColorPickerDialog(
    String label,
    String currentColor,
    ValueChanged<String> onSelected,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'בחרי $label',
              style: const TextStyle(fontFamily: 'Heebo', fontSize: 18),
            ),
            content: SizedBox(
              width: 280,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _colorPresets.map((hex) {
                  final isSelected = hex == currentColor;
                  return GestureDetector(
                    onTap: () {
                      onSelected(hex);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.grey[300]!,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _hexToColor(hex).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    setState(() => _saving = true);

    try {
      final config = {
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
        'accentColor': _accentColor,
        'menuOrder': _menuOrder,
        'expertCategories': _expertCategories,
        'tipCategories': _tipCategories,
        'marketplaceCategories': _marketplaceCategories,
      };

      await fs.updateUIConfig(config);
      await fs.logActivity(
        action: 'עדכון עיצוב',
        user: 'מנהלת',
        type: 'config',
      );

      if (mounted) {
        AdminWidgets.snack(context, 'העיצוב עודכן!');
      }
    } catch (e) {
      if (mounted) {
        AdminWidgets.snack(context, 'שגיאה בשמירה: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    return Container(
      decoration: AdminWidgets.cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('צבעי אפליקציה'),
          AdminWidgets.colorRow(
            label: 'צבע ראשי',
            color: _hexToColor(_primaryColor),
            onTap: () => _showColorPickerDialog(
              'צבע ראשי',
              _primaryColor,
              (c) => setState(() => _primaryColor = c),
            ),
          ),
          const SizedBox(height: 12),
          AdminWidgets.colorRow(
            label: 'צבע משני',
            color: _hexToColor(_secondaryColor),
            onTap: () => _showColorPickerDialog(
              'צבע משני',
              _secondaryColor,
              (c) => setState(() => _secondaryColor = c),
            ),
          ),
          const SizedBox(height: 12),
          AdminWidgets.colorRow(
            label: 'צבע הדגשה',
            color: _hexToColor(_accentColor),
            onTap: () => _showColorPickerDialog(
              'צבע הדגשה',
              _accentColor,
              (c) => setState(() => _accentColor = c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOrderSection() {
    return Container(
      decoration: AdminWidgets.cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('סדר תפריט'),
          SizedBox(
            height: _menuOrder.length * 56.0,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _menuOrder.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _menuOrder.removeAt(oldIndex);
                  _menuOrder.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return ListTile(
                  key: ValueKey(_menuOrder[index]),
                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                  title: Text(
                    _menuOrder[index],
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 15),
                  ),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipListSection({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required ValueChanged<int> onDelete,
  }) {
    return Container(
      decoration: AdminWidgets.cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (index) {
              return Chip(
                label: Text(
                  items[index],
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 13),
                ),
                deleteIcon:
                    const Icon(Icons.close, size: 18, color: Colors.red),
                onDeleted: () => onDelete(index),
                backgroundColor: const Color(0xFFF5EEF0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'הוסיפי קטגוריה...',
                    hintStyle: TextStyle(
                      fontFamily: 'Heebo',
                      color: Colors.grey[400],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: Color(0xFFD4A1AC)),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      decoration: AdminWidgets.cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('תצוגה מקדימה'),
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _hexToColor(_primaryColor),
                  _hexToColor(_secondaryColor),
                  _hexToColor(_accentColor),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorBox('ראשי', _primaryColor),
              _buildColorBox('משני', _secondaryColor),
              _buildColorBox('הדגשה', _accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(String label, String hex) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _hexToColor(hex),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: _hexToColor(hex).withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 12,
            color: Color(0xFF6B6B6B),
          ),
        ),
        Text(
          hex,
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: fs.uiConfigStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              _initFromData(snapshot.data!);
            }

            if (!_initialized && snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4A1AC),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colors section
                  _buildColorsSection(),
                  const SizedBox(height: 16),

                  // Menu order section
                  _buildMenuOrderSection(),
                  const SizedBox(height: 16),

                  // Expert categories section
                  _buildChipListSection(
                    title: 'קטגוריות מומחים',
                    items: _expertCategories,
                    controller: _newExpertCategoryController,
                    onAdd: () {
                      final text = _newExpertCategoryController.text.trim();
                      if (text.isNotEmpty &&
                          !_expertCategories.contains(text)) {
                        setState(() => _expertCategories.add(text));
                        _newExpertCategoryController.clear();
                      }
                    },
                    onDelete: (index) {
                      setState(() => _expertCategories.removeAt(index));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tip categories section
                  _buildChipListSection(
                    title: 'קטגוריות טיפים',
                    items: _tipCategories,
                    controller: _newTipCategoryController,
                    onAdd: () {
                      final text = _newTipCategoryController.text.trim();
                      if (text.isNotEmpty && !_tipCategories.contains(text)) {
                        setState(() => _tipCategories.add(text));
                        _newTipCategoryController.clear();
                      }
                    },
                    onDelete: (index) {
                      setState(() => _tipCategories.removeAt(index));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Marketplace categories section
                  _buildChipListSection(
                    title: 'קטגוריות שוק יד שניה',
                    items: _marketplaceCategories,
                    controller: _newMarketplaceCategoryController,
                    onAdd: () {
                      final text = _newMarketplaceCategoryController.text.trim();
                      if (text.isNotEmpty && !_marketplaceCategories.contains(text)) {
                        setState(() => _marketplaceCategories.add(text));
                        _newMarketplaceCategoryController.clear();
                      }
                    },
                    onDelete: (index) {
                      setState(() => _marketplaceCategories.removeAt(index));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Live preview section
                  _buildLivePreview(),
                  const SizedBox(height: 24),

                  // Save button
                  AdminWidgets.saveButton(
                    loading: _saving,
                    onPressed: _saveConfig,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
