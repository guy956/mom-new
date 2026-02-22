import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminMarketplaceTab extends StatefulWidget {
  const AdminMarketplaceTab({super.key});

  @override
  State<AdminMarketplaceTab> createState() => _AdminMarketplaceTabState();
}

class _AdminMarketplaceTabState extends State<AdminMarketplaceTab> {
  String _searchQuery = '';
  String _statusFilter = 'הכל';
  String _categoryFilter = 'הכל';

  static const _statusFilters = ['הכל', 'פעיל', 'נמכר', 'לא פעיל'];
  static const _statusMap = {'פעיל': 'active', 'נמכר': 'sold', 'לא פעיל': 'inactive'};
  static const _conditionOptions = ['חדש', 'כמו חדש', 'משומש - מצב טוב', 'משומש'];

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF9F5F4),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: fs.uiConfigStream,
          builder: (context, uiSnap) {
            final uiConfig = uiSnap.data ?? {};
            final dynamicCategories = (uiConfig['marketplaceCategories'] as List<dynamic>?)
                ?.map((e) => e.toString()).toList() ?? ['ציוד לתינוק', 'עגלות', 'ריהוט', 'ביגוד', 'צעצועים', 'ספרים', 'אחר'];
            final categoryFilters = ['הכל', ...dynamicCategories];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.marketplaceStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('שגיאה בטעינת נתונים', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: Colors.red.shade700)));
                }

                final allItems = snapshot.data ?? [];
                final activeCount = allItems.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'active').length;
                final soldCount = allItems.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'sold').length;
                final inactiveCount = allItems.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'inactive').length;

                final filteredItems = allItems.where((item) {
                  // Status filter
                  if (_statusFilter != 'הכל') {
                    final status = (item['status'] ?? '').toString().toLowerCase();
                    if (status != _statusMap[_statusFilter]) return false;
                  }
                  // Category filter
                  if (_categoryFilter != 'הכל') {
                    if ((item['category'] ?? '') != _categoryFilter) return false;
                  }
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final title = (item['title'] ?? '').toString().toLowerCase();
                    final seller = (item['seller'] ?? '').toString().toLowerCase();
                    final category = (item['category'] ?? '').toString().toLowerCase();
                    if (!title.contains(query) && !seller.contains(query) && !category.contains(query)) return false;
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    // Header + Add button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const Text('שוק יד שניה', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          FloatingActionButton.small(
                            heroTag: 'addMarketplaceFab',
                            onPressed: () => _showItemDialog(context, fs, dynamicCategories),
                            backgroundColor: const Color(0xFFD4A1AC),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // 4 Stat cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          AdminWidgets.statCard('סה"כ', '${allItems.length}', Icons.inventory_2_outlined, const Color(0xFF5C6BC0)),
                          const SizedBox(width: 8),
                          AdminWidgets.statCard('פעילים', '$activeCount', Icons.check_circle_outline, const Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          AdminWidgets.statCard('נמכרו', '$soldCount', Icons.sell_outlined, Colors.orange.shade700),
                          const SizedBox(width: 8),
                          AdminWidgets.statCard('לא פעיל', '$inactiveCount', Icons.pause_circle_outline, Colors.grey.shade600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status filter chips
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _statusFilters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final f = _statusFilters[index];
                          final isSelected = _statusFilter == f;
                          return FilterChip(
                            label: Text(f, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD4A1AC),
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            onSelected: (_) => setState(() => _statusFilter = f),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category filter chips
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categoryFilters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = categoryFilters[index];
                          final isSelected = _categoryFilter == cat;
                          return FilterChip(
                            label: Text(cat, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFDBC8B0),
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            onSelected: (_) => setState(() => _categoryFilter = cat),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'Heebo'),
                        decoration: InputDecoration(
                          hintText: 'חיפוש פריטים...',
                          hintStyle: const TextStyle(fontFamily: 'Heebo'),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Items list
                    Expanded(
                      child: filteredItems.isEmpty
                          ? AdminWidgets.emptyState('אין פריטים להצגה')
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return _buildItemCard(context, fs, item, item['id'] ?? '', dynamicCategories);
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, FirestoreService fs, Map<String, dynamic> item, String id, List<String> categories) {
    final title = item['title'] ?? 'ללא כותרת';
    final price = item['price'] ?? 0;
    final seller = item['seller'] ?? 'לא ידוע';
    final category = item['category'] ?? 'כללי';
    final condition = item['condition'] ?? 'לא צוין';
    final status = (item['status'] ?? 'active').toString().toLowerCase();
    final brand = item['brand'] ?? '';
    final location = item['location'] ?? '';
    final creatorEmail = item['creatorEmail'] ?? '';
    final creatorPhone = item['creatorPhone'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = const Color(0xFF2E7D32);
        statusLabel = 'פעיל';
        break;
      case 'sold':
        statusColor = Colors.orange.shade700;
        statusLabel = 'נמכר';
        break;
      case 'inactive':
        statusColor = Colors.grey.shade600;
        statusLabel = 'לא פעיל';
        break;
      default:
        statusColor = Colors.blueGrey;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Price
            Text('₪$price', style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 8),

            // Details
            _buildDetailRow(Icons.person_outline, 'מוכר/ת', seller),
            const SizedBox(height: 4),
            _buildDetailRow(Icons.category_outlined, 'קטגוריה', category),
            const SizedBox(height: 4),
            _buildDetailRow(Icons.info_outline, 'מצב', condition),
            if (brand.isNotEmpty) ...[const SizedBox(height: 4), _buildDetailRow(Icons.branding_watermark, 'מותג', brand)],
            if (location.isNotEmpty) ...[const SizedBox(height: 4), _buildDetailRow(Icons.location_on_outlined, 'מיקום', location)],
            if (creatorEmail.isNotEmpty) ...[const SizedBox(height: 4), _buildDetailRow(Icons.email_outlined, 'אימייל יוצרת', creatorEmail)],
            if (creatorPhone.isNotEmpty) ...[const SizedBox(height: 4), _buildDetailRow(Icons.phone_outlined, 'טלפון יוצרת', creatorPhone)],
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Status change buttons
                if (status == 'active') ...[
                  _statusButton('נמכר', Icons.sell, Colors.orange, () => _changeStatus(fs, id, 'sold', title)),
                  const SizedBox(width: 6),
                  _statusButton('השבת', Icons.pause, Colors.grey, () => _changeStatus(fs, id, 'inactive', title)),
                ] else if (status == 'sold') ...[
                  _statusButton('הפעל', Icons.play_arrow, Colors.green, () => _changeStatus(fs, id, 'active', title)),
                ] else if (status == 'inactive') ...[
                  _statusButton('הפעל', Icons.play_arrow, Colors.green, () => _changeStatus(fs, id, 'active', title)),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blueGrey,
                  tooltip: 'עריכה',
                  onPressed: () => _showItemDialog(context, fs, categories, existingItem: item),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                  tooltip: 'מחיקה',
                  onPressed: () => _confirmDelete(context, fs, id, title),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Future<void> _changeStatus(FirestoreService fs, String id, String newStatus, String title) async {
    await fs.updateMarketplaceItemStatus(id, newStatus);
    await fs.logActivity(action: 'שינוי סטטוס פריט "$title" ל-$newStatus', user: AdminWidgets.adminName(context), type: 'marketplace');
    if (mounted) AdminWidgets.snack(context, 'הסטטוס עודכן');
  }

  void _confirmDelete(BuildContext context, FirestoreService fs, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('מחיקת פריט', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
          content: Text('האם למחוק את "$title"?', style: const TextStyle(fontFamily: 'Heebo')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo', color: Colors.grey))),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await fs.deleteMarketplaceItem(id);
                await fs.logActivity(action: 'מחיקת פריט: $title', user: AdminWidgets.adminName(context), type: 'marketplace');
                if (context.mounted) AdminWidgets.snack(context, 'הפריט נמחק', color: Colors.red.shade400);
              },
              child: Text('מחק', style: TextStyle(fontFamily: 'Heebo', color: Colors.red.shade600, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showItemDialog(BuildContext context, FirestoreService fs, List<String> categories, {Map<String, dynamic>? existingItem}) async {
    final isEditing = existingItem != null;
    final titleCtrl = TextEditingController(text: existingItem?['title'] ?? '');
    final descCtrl = TextEditingController(text: existingItem?['description'] ?? '');
    final priceCtrl = TextEditingController(text: (existingItem?['price'] ?? '').toString());
    final sellerCtrl = TextEditingController(text: existingItem?['seller'] ?? '');
    final contactCtrl = TextEditingController(text: existingItem?['contact'] ?? '');
    final locationCtrl = TextEditingController(text: existingItem?['location'] ?? '');
    final brandCtrl = TextEditingController(text: existingItem?['brand'] ?? '');
    final creatorEmailCtrl = TextEditingController(text: existingItem?['creatorEmail'] ?? '');
    final creatorPhoneCtrl = TextEditingController(text: existingItem?['creatorPhone'] ?? '');

    String selectedCategory = existingItem?['category'] ?? categories.first;
    if (!categories.contains(selectedCategory)) selectedCategory = categories.first;
    String selectedCondition = existingItem?['condition'] ?? _conditionOptions.first;
    if (!_conditionOptions.contains(selectedCondition)) selectedCondition = _conditionOptions.first;
    String selectedStatus = existingItem?['status'] ?? 'active';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditing ? 'עריכת פריט' : 'פריט חדש', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'כותרת', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'תיאור', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder(), alignLabelWithHint: true), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'מחיר (₪)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'קטגוריה', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Heebo')))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: const InputDecoration(labelText: 'מצב המוצר', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                    items: _conditionOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Heebo')))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => selectedCondition = v); },
                  ),
                  const SizedBox(height: 12),
                  if (isEditing)
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'סטטוס', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('פעיל', style: TextStyle(fontFamily: 'Heebo'))),
                        DropdownMenuItem(value: 'sold', child: Text('נמכר', style: TextStyle(fontFamily: 'Heebo'))),
                        DropdownMenuItem(value: 'inactive', child: Text('לא פעיל', style: TextStyle(fontFamily: 'Heebo'))),
                      ],
                      onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                    ),
                  if (isEditing) const SizedBox(height: 12),
                  TextField(controller: sellerCtrl, decoration: const InputDecoration(labelText: 'מוכר/ת', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'טלפון / דרכי יצירת קשר', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'מיקום', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'מותג (אופציונלי)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: creatorEmailCtrl, decoration: const InputDecoration(labelText: 'אימייל יוצרת (אופציונלי)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                  const SizedBox(height: 12),
                  TextField(controller: creatorPhoneCtrl, decoration: const InputDecoration(labelText: 'טלפון יוצרת (אופציונלי)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final data = {
                    'title': title,
                    'description': descCtrl.text.trim(),
                    'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                    'category': selectedCategory,
                    'condition': selectedCondition,
                    'status': selectedStatus,
                    'seller': sellerCtrl.text.trim(),
                    'contact': contactCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'brand': brandCtrl.text.trim(),
                    'creatorEmail': creatorEmailCtrl.text.trim(),
                    'creatorPhone': creatorPhoneCtrl.text.trim(),
                  };
                  if (isEditing) {
                    await fs.updateMarketplaceItem(existingItem['id'], data);
                    await fs.logActivity(action: 'עריכת פריט: $title', user: AdminWidgets.adminName(context), type: 'marketplace');
                  } else {
                    await fs.addMarketplaceItem(data);
                    await fs.logActivity(action: 'הוספת פריט: $title', user: AdminWidgets.adminName(context), type: 'marketplace');
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) AdminWidgets.snack(context, isEditing ? 'הפריט עודכן' : 'הפריט נוסף');
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A1AC), foregroundColor: Colors.white),
                child: Text(isEditing ? 'עדכון' : 'הוספה', style: const TextStyle(fontFamily: 'Heebo')),
              ),
            ],
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    sellerCtrl.dispose();
    contactCtrl.dispose();
    locationCtrl.dispose();
    brandCtrl.dispose();
    creatorEmailCtrl.dispose();
    creatorPhoneCtrl.dispose();
  }
}
