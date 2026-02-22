import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminContentTipsTab extends StatefulWidget {
  const AdminContentTipsTab({super.key});

  @override
  State<AdminContentTipsTab> createState() => _AdminContentTipsTabState();
}

class _AdminContentTipsTabState extends State<AdminContentTipsTab>
    with SingleTickerProviderStateMixin {
  late TabController _sectionTab;
  String _selectedCategory = 'הכל';

  static const List<String> _fallbackCategories = [
    'שינה', 'האכלה', 'התפתחות', 'בריאות',
    'כושר', 'רווחה נפשית', 'טיפול בתינוק', 'תזונה',
  ];

  Color _categoryColor(String category) {
    switch (category) {
      case 'שינה': return const Color(0xFF7986CB);
      case 'האכלה': return const Color(0xFFFF8A65);
      case 'התפתחות': return const Color(0xFF81C784);
      case 'בריאות': return const Color(0xFFE57373);
      case 'כושר': return const Color(0xFF4FC3F7);
      case 'רווחה נפשית': return const Color(0xFFBA68C8);
      case 'טיפול בתינוק': return const Color(0xFFFFD54F);
      case 'תזונה': return const Color(0xFFA1887F);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _sectionTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sectionTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _sectionTab,
                labelColor: const Color(0xFF43363A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD1C2D3),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'טיפים'),
                  Tab(text: 'פוסטים'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _sectionTab,
                children: [
                  _buildTipsSection(fs),
                  _buildPostsSection(fs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TIPS SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildTipsSection(FirestoreService fs) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fs.uiConfigStream,
      builder: (context, uiSnap) {
        final uiConfig = uiSnap.data ?? {};
        final dynamicCategories = (uiConfig['tipCategories'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? _fallbackCategories;
        final filterCategories = ['הכל', ...dynamicCategories];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text('טיפים', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.upload_file_rounded),
                    tooltip: 'העלאה מרובה',
                    onPressed: () => _showBulkUploadDialog(context, fs, dynamicCategories),
                    style: IconButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange.shade700),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'addTipFab',
                    onPressed: () => _showTipDialog(context, fs, dynamicCategories),
                    backgroundColor: const Color(0xFF7986CB),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = filterCategories[index];
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: cat == 'הכל' ? Colors.blueGrey : _categoryColor(cat),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.tipsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('שגיאה בטעינת הטיפים: ${snapshot.error}', style: const TextStyle(fontFamily: 'Heebo')));
                  }

                  final allTips = snapshot.data ?? [];
                  final tips = _selectedCategory == 'הכל'
                      ? allTips
                      : allTips.where((t) => t['category'] == _selectedCategory).toList();

                  if (tips.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == 'הכל' ? 'אין טיפים עדיין' : 'אין טיפים בקטגוריה "$_selectedCategory"',
                          style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ]),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tips.length,
                    itemBuilder: (context, index) => _buildTipCard(context, fs, tips[index], dynamicCategories),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipCard(BuildContext context, FirestoreService fs, Map<String, dynamic> tip, List<String> categories) {
    final id = tip['id'] as String;
    final isActive = tip['active'] as bool? ?? true;
    final category = tip['category'] as String? ?? '';
    final color = _categoryColor(category);
    final attachmentUrl = tip['attachmentUrl'] as String?;
    final attachmentName = tip['attachmentName'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? Colors.white : Colors.grey[100],
      elevation: isActive ? 2 : 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(right: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(tip['title'] ?? '', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey))),
                Switch(value: isActive, activeColor: const Color(0xFF81C784), onChanged: (value) => fs.toggleTipActive(id, value)),
              ]),
              const SizedBox(height: 8),
              Text(tip['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: isActive ? Colors.black54 : Colors.grey.shade400, height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Text(category, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ),
                if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(attachmentUrl);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      } catch (e) {
                        debugPrint('Failed to launch URL: $e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.attach_file, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(attachmentName ?? 'קובץ', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.blue.shade700)),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(tip['author'] ?? 'מנהלת', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey.shade500)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_outlined), iconSize: 20, color: Colors.blueGrey, tooltip: 'עריכה', onPressed: () => _showTipDialog(context, fs, categories, existingTip: tip)),
                IconButton(icon: const Icon(Icons.delete_outline), iconSize: 20, color: Colors.red.shade300, tooltip: 'מחיקה', onPressed: () => _confirmDeleteTip(context, fs, id, tip['title'] ?? '')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  POSTS SECTION (with pin/unpin)
  // ════════════════════════════════════════════════════════════════

  Widget _buildPostsSection(FirestoreService fs) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('שגיאה בטעינת פוסטים: ${snapshot.error}', style: const TextStyle(fontFamily: 'Heebo')));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return AdminWidgets.emptyState('אין פוסטים עדיין', icon: Icons.article_outlined);
        }

        // Sort pinned posts first
        final sorted = List<Map<String, dynamic>>.from(posts);
        sorted.sort((a, b) {
          final aPinned = a['pinned'] == true ? 0 : 1;
          final bPinned = b['pinned'] == true ? 0 : 1;
          return aPinned.compareTo(bPinned);
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('פוסטים', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD1C2D3).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                  child: Text('${posts.length} פוסטים', style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final post = sorted[index];
                  final id = post['id'] as String? ?? '';
                  final content = post['content'] as String? ?? '';
                  final authorName = post['authorName'] as String? ?? post['author'] as String? ?? 'לא ידוע';
                  final likes = post['likes'] as int? ?? 0;
                  final comments = post['comments'] as int? ?? 0;
                  final reports = post['reports'] as int? ?? 0;
                  final isPinned = post['pinned'] == true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      decoration: isPinned ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBC8B0), width: 2),
                      ) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFD1C2D3),
                                child: Text(authorName.isNotEmpty ? authorName[0] : '?', style: const TextStyle(fontFamily: 'Heebo', color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(authorName, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14))),
                              if (isPinned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFDBC8B0).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.push_pin, size: 14, color: Color(0xFFDBC8B0)),
                                    SizedBox(width: 2),
                                    Text('מוצמד', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Color(0xFFDBC8B0), fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              if (reports > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.flag, size: 14, color: Colors.red.shade400),
                                    const SizedBox(width: 2),
                                    Text('$reports', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 10),
                            Text(content, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, height: 1.5)),
                            const SizedBox(height: 10),
                            Row(children: [
                              Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('$likes', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(width: 16),
                              Icon(Icons.comment_outlined, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('$comments', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey.shade600)),
                              const Spacer(),
                              // Pin/unpin toggle
                              IconButton(
                                icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 20, color: isPinned ? const Color(0xFFDBC8B0) : Colors.grey),
                                tooltip: isPinned ? 'בטל הצמדה' : 'הצמד',
                                onPressed: () async {
                                  await fs.updatePost(id, {'pinned': !isPinned});
                                  await fs.logActivity(action: isPinned ? 'ביטול הצמדת פוסט' : 'הצמדת פוסט', user: AdminWidgets.adminName(context), type: 'content');
                                  if (context.mounted) AdminWidgets.snack(context, isPinned ? 'ההצמדה בוטלה' : 'הפוסט הוצמד');
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                                tooltip: 'מחק פוסט',
                                onPressed: () async {
                                  final confirmed = await AdminWidgets.confirmDelete(context, 'הפוסט');
                                  if (confirmed) {
                                    await fs.deletePost(id);
                                    await fs.logActivity(action: 'מחיקת פוסט', user: AdminWidgets.adminName(context), type: 'content');
                                    if (context.mounted) AdminWidgets.snack(context, 'הפוסט נמחק');
                                  }
                                },
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════
  //  TIP DIALOG (with file upload)
  // ════════════════════════════════════════════════════════════════

  Future<void> _showTipDialog(
    BuildContext context,
    FirestoreService fs,
    List<String> categories, {
    Map<String, dynamic>? existingTip,
  }) async {
    final isEditing = existingTip != null;
    final titleController = TextEditingController(text: existingTip?['title'] ?? '');
    final contentController = TextEditingController(text: existingTip?['content'] ?? '');
    final authorController = TextEditingController(text: existingTip?['author'] ?? 'מנהלת');
    String selectedCategory = existingTip?['category'] ?? categories.first;
    if (!categories.contains(selectedCategory)) selectedCategory = categories.first;

    String? attachmentUrl = existingTip?['attachmentUrl'];
    String? attachmentName = existingTip?['attachmentName'];
    bool uploading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(isEditing ? 'עריכת טיפ' : 'טיפ חדש', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 400,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(controller: titleController, decoration: const InputDecoration(labelText: 'כותרת', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                      const SizedBox(height: 16),
                      TextField(controller: contentController, maxLines: 5, decoration: const InputDecoration(labelText: 'תוכן', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder(), alignLabelWithHint: true), style: const TextStyle(fontFamily: 'Heebo')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'קטגוריה', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                        items: categories.map((cat) => DropdownMenuItem(value: cat, child: Row(children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _categoryColor(cat), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(cat, style: const TextStyle(fontFamily: 'Heebo')),
                        ]))).toList(),
                        onChanged: (value) { if (value != null) setDialogState(() => selectedCategory = value); },
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: authorController, decoration: const InputDecoration(labelText: 'מחבר/ת', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                      const SizedBox(height: 16),

                      // File attachment section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('קובץ מצורף', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            if (attachmentName != null)
                              Row(children: [
                                const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Expanded(child: Text(attachmentName!, style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.blue), overflow: TextOverflow.ellipsis)),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => setDialogState(() { attachmentUrl = null; attachmentName = null; }),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ]),
                            if (attachmentName == null)
                              OutlinedButton.icon(
                                onPressed: uploading ? null : () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'xlsx', 'xls', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
                                    withData: true,
                                  );
                                  if (result == null || result.files.isEmpty) return;
                                  final file = result.files.first;
                                  if (file.bytes == null) return;

                                  setDialogState(() => uploading = true);
                                  try {
                                    final ref = FirebaseStorage.instance.ref('tips/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
                                    await ref.putData(file.bytes!);
                                    final url = await ref.getDownloadURL();
                                    setDialogState(() {
                                      attachmentUrl = url;
                                      attachmentName = file.name;
                                      uploading = false;
                                    });
                                  } catch (e) {
                                    setDialogState(() => uploading = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('שגיאה בהעלאה: $e')));
                                    }
                                  }
                                },
                                icon: uploading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.upload_file, size: 18),
                                label: Text(uploading ? 'מעלה...' : 'העלה קובץ', style: const TextStyle(fontFamily: 'Heebo', fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isEmpty || content.isEmpty) return;
                      final tipData = {
                        'title': title,
                        'content': content,
                        'category': selectedCategory,
                        'author': authorController.text.trim().isEmpty ? 'מנהלת' : authorController.text.trim(),
                        'active': existingTip?['active'] ?? true,
                        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
                        if (attachmentName != null) 'attachmentName': attachmentName,
                      };
                      if (isEditing) {
                        await fs.updateTip(existingTip['id'], tipData);
                        await fs.logActivity(action: 'עריכת טיפ', user: AdminWidgets.adminName(context), type: 'content');
                      } else {
                        await fs.addTip(tipData);
                        await fs.logActivity(action: 'הוספת טיפ', user: AdminWidgets.adminName(context), type: 'content');
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) AdminWidgets.snack(context, isEditing ? 'הטיפ עודכן בהצלחה' : 'הטיפ נוסף בהצלחה');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7986CB), foregroundColor: Colors.white),
                    child: Text(isEditing ? 'עדכון' : 'הוספה', style: const TextStyle(fontFamily: 'Heebo')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    titleController.dispose();
    contentController.dispose();
    authorController.dispose();
  }

  Future<void> _confirmDeleteTip(BuildContext context, FirestoreService fs, String id, String title) async {
    final confirmed = await AdminWidgets.confirmDelete(context, 'הטיפ "$title"');
    if (confirmed) {
      await fs.deleteTip(id);
      await fs.logActivity(action: 'מחיקת טיפ', user: AdminWidgets.adminName(context), type: 'content');
      if (context.mounted) AdminWidgets.snack(context, 'הטיפ "$title" נמחק', color: Colors.red.shade400);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  BULK UPLOAD (with CSV file picker option)
  // ════════════════════════════════════════════════════════════════

  Future<void> _showBulkUploadDialog(BuildContext context, FirestoreService fs, List<String> categories) async {
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('העלאה מרובה של טיפים', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('הדביקו טיפים, כל שורה בפורמט:\nכותרת|תוכן|קטגוריה', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: Colors.blueGrey))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('קטגוריות זמינות: ${categories.join(", ")}', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),

                  // CSV file picker button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv', 'txt'],
                        withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      final file = result.files.first;
                      if (file.bytes != null) {
                        textController.text = String.fromCharCodes(file.bytes!);
                      }
                    },
                    icon: const Icon(Icons.file_open, size: 18),
                    label: const Text('או טען מקובץ CSV', style: TextStyle(fontFamily: 'Heebo', fontSize: 12)),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: textController,
                    maxLines: 10,
                    decoration: const InputDecoration(hintText: 'הדביקו כאן...', hintStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 13),
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('העלאה', style: TextStyle(fontFamily: 'Heebo')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white),
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
                  final tips = <Map<String, dynamic>>[];
                  int errorCount = 0;
                  for (final line in lines) {
                    final parts = line.split('|');
                    if (parts.length >= 3) {
                      tips.add({'title': parts[0].trim(), 'content': parts[1].trim(), 'category': parts[2].trim(), 'author': 'מנהלת', 'active': true});
                    } else {
                      errorCount++;
                    }
                  }
                  if (tips.isNotEmpty) {
                    await fs.batchAddTips(tips);
                    await fs.logActivity(action: 'העלאה מרובה: ${tips.length} טיפים', user: AdminWidgets.adminName(context), type: 'content');
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    AdminWidgets.snack(context, errorCount > 0 ? 'נוספו ${tips.length} טיפים ($errorCount שורות לא תקינות)' : 'נוספו ${tips.length} טיפים בהצלחה');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    textController.dispose();
  }
}
