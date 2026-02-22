import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminMediaVaultTab extends StatefulWidget {
  const AdminMediaVaultTab({super.key});

  @override
  State<AdminMediaVaultTab> createState() => _AdminMediaVaultTabState();
}

class _AdminMediaVaultTabState extends State<AdminMediaVaultTab> {
  String _typeFilter = 'הכל';
  String _searchQuery = '';
  bool _uploading = false;
  double _uploadProgress = 0;
  String _uploadFileName = '';

  static const _typeFilters = ['הכל', 'תמונה', 'PDF', 'Excel', 'Word'];
  static const _typeMap = {
    'תמונה': 'image',
    'PDF': 'pdf',
    'Excel': 'excel',
    'Word': 'word',
  };

  IconData _fileIcon(String? type) {
    switch (type) {
      case 'image': return Icons.image_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'excel': return Icons.table_chart_rounded;
      case 'word': return Icons.description_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String? type) {
    switch (type) {
      case 'image': return const Color(0xFF7986CB);
      case 'pdf': return const Color(0xFFE57373);
      case 'excel': return const Color(0xFF81C784);
      case 'word': return const Color(0xFF64B5F6);
      default: return Colors.grey;
    }
  }

  String _detectFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) return 'image';
    if (ext == 'pdf') return 'pdf';
    if (['xlsx', 'xls', 'csv'].contains(ext)) return 'excel';
    if (['doc', 'docx'].contains(ext)) return 'word';
    return 'other';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _uploadFile(FirestoreService fs) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _uploadFileName = file.name;
    });

    try {
      final ref = FirebaseStorage.instance.ref('media_vault/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final uploadTask = ref.putData(file.bytes!);

      uploadTask.snapshotEvents.listen((event) {
        if (mounted) {
          setState(() {
            _uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        }
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      final fileType = _detectFileType(file.name);

      await fs.addMediaItem({
        'name': file.name,
        'url': url,
        'type': fileType,
        'size': file.size,
        'storagePath': ref.fullPath,
        'uploadedBy': 'מנהלת',
      });

      await fs.logActivity(action: 'העלאת קובץ: ${file.name}', user: AdminWidgets.adminName(context), type: 'media');
      if (mounted) AdminWidgets.snack(context, 'הקובץ הועלה בהצלחה');
    } catch (e) {
      if (mounted) AdminWidgets.snack(context, 'שגיאה בהעלאה: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; _uploadFileName = ''; });
    }
  }

  Future<void> _deleteFile(FirestoreService fs, Map<String, dynamic> item) async {
    final confirmed = await AdminWidgets.confirmDelete(context, item['name'] ?? 'הקובץ');
    if (!confirmed) return;

    try {
      final storagePath = item['storagePath'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        await FirebaseStorage.instance.ref(storagePath).delete();
      }
      await fs.deleteMediaItem(item['id']);
      await fs.logActivity(action: 'מחיקת קובץ: ${item['name']}', user: AdminWidgets.adminName(context), type: 'media');
      if (mounted) AdminWidgets.snack(context, 'הקובץ נמחק');
    } catch (e) {
      if (mounted) AdminWidgets.snack(context, 'שגיאה במחיקה: $e', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF9F5F4),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('מאגר מדיה', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _uploading ? null : () => _uploadFile(fs),
                    icon: _uploading
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white, value: _uploadProgress > 0 ? _uploadProgress : null))
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(_uploading ? 'מעלה...' : 'העלאת קובץ', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1C2D3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Upload progress bar
            if (_uploading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('מעלה: $_uploadFileName', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD1C2D3)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Heebo'),
                decoration: InputDecoration(
                  hintText: 'חיפוש קבצים...',
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

            // Type filter chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _typeFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _typeFilters[index];
                  final isSelected = _typeFilter == f;
                  return FilterChip(
                    label: Text(f, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD1C2D3),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    onSelected: (_) => setState(() => _typeFilter = f),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // File list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.mediaLibraryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allFiles = snapshot.data ?? [];
                  final filtered = allFiles.where((f) {
                    if (_typeFilter != 'הכל' && f['type'] != _typeMap[_typeFilter]) return false;
                    if (_searchQuery.isNotEmpty) {
                      final name = (f['name'] ?? '').toString().toLowerCase();
                      if (!name.contains(_searchQuery.toLowerCase())) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return AdminWidgets.emptyState(
                      allFiles.isEmpty ? 'אין קבצים במאגר\nהעלו קבצים כדי להתחיל' : 'אין קבצים מתאימים לחיפוש',
                      icon: Icons.cloud_off_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildFileCard(fs, filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(FirestoreService fs, Map<String, dynamic> item) {
    final name = item['name'] ?? 'ללא שם';
    final type = item['type'] as String? ?? 'other';
    final size = item['size'] as int? ?? 0;
    final url = item['url'] as String? ?? '';
    final uploadedBy = item['uploadedBy'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _fileColor(type).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_fileIcon(type), color: _fileColor(type), size: 24),
        ),
        title: Text(name, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(_formatFileSize(size), style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade600)),
            if (uploadedBy.isNotEmpty) ...[
              Text(' \u00B7 ', style: TextStyle(color: Colors.grey.shade400)),
              Text(uploadedBy, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.grey.shade600)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: Colors.blueGrey,
              tooltip: 'העתק קישור',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                AdminWidgets.snack(context, 'הקישור הועתק');
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              color: const Color(0xFFD1C2D3),
              tooltip: 'פתח',
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade300),
              tooltip: 'מחק',
              onPressed: () => _deleteFile(fs, item),
            ),
          ],
        ),
      ),
    );
  }
}
