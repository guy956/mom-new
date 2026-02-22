import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/storage_service.dart';

/// מסך אלבום תמונות - כל אמא יכולה ליצור אלבומים לכל ילד
class PhotoAlbumScreen extends StatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedChild = 0;

  List<Map<String, dynamic>> _children = [];

  List<Map<String, dynamic>> _albums = [];
  // Photos stored per album: albumTitle -> list of photo data
  Map<String, List<Map<String, dynamic>>> _albumPhotos = {};

  String get _currentUserName {
    try {
      final appState = context.read<AppState>();
      return appState.currentUser?.fullName ?? 'משתמשת';
    } catch (_) {
      return 'משתמשת';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChildren();
    _loadAlbums();
  }

  void _loadChildren() {
    final appState = context.read<AppState>();
    final userChildren = appState.currentUser?.children ?? [];
    final colors = [AppColors.secondary, AppColors.info, AppColors.accent, AppColors.primary];
    final emojis = ['👧', '👦', '👶', '🧒'];
    _children = userChildren.asMap().entries.map((e) => {
      'name': e.value.name,
      'emoji': emojis[e.key % emojis.length],
      'color': colors[e.key % colors.length],
    }).toList();
    if (_children.isEmpty) {
      _children = [{'name': 'ילד/ה', 'emoji': '👶', 'color': AppColors.primary}];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final albumsJson = prefs.getString('momit_albums');
      final photosJson = prefs.getString('momit_album_photos');

      if (albumsJson != null) {
        _albums = List<Map<String, dynamic>>.from(
          (jsonDecode(albumsJson) as List).map((e) => Map<String, dynamic>.from(e)),
        );
        // Restore Color objects
        for (final album in _albums) {
          album['coverColor'] = Color(album['coverColorValue'] as int? ?? AppColors.primary.toARGB32());
        }
      }

      if (photosJson != null) {
        final decoded = jsonDecode(photosJson) as Map<String, dynamic>;
        _albumPhotos = decoded.map((key, value) => MapEntry(
          key,
          List<Map<String, dynamic>>.from(
            (value as List).map((e) => Map<String, dynamic>.from(e)),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error loading albums: $e');
    }

    // No demo albums - user creates their own

    if (mounted) setState(() {});
  }

  Future<void> _saveAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Prepare albums for JSON (without Color objects)
      final albumsForJson = _albums.map((a) {
        final copy = Map<String, dynamic>.from(a);
        copy.remove('coverColor');
        return copy;
      }).toList();
      await prefs.setString('momit_albums', jsonEncode(albumsForJson));
      await prefs.setString('momit_album_photos', jsonEncode(_albumPhotos));
    } catch (e) {
      debugPrint('Error saving albums: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredAlbums {
    final childName = _children[_selectedChild]['name'];
    return _albums.where((a) => a['child'] == childName).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('אלבום תמונות', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => _showPrivacySettings(),
            tooltip: 'הגדרות פרטיות',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChildSelector(),
          _buildStats(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlbumsGrid(),
                _buildTimelineView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAlbumSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('אלבום חדש', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(_children.length, (i) {
          final child = _children[i];
          final isSelected = _selectedChild == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedChild = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? (child['color'] as Color).withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? child['color'] as Color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: (child['color'] as Color).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Row(
                children: [
                  Text(child['emoji'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'האלבום של ${child['name']}',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? child['color'] as Color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStats() {
    final albums = _filteredAlbums;
    final totalPhotos = albums.fold<int>(0, (sum, a) => sum + (a['count'] as int));
    final privateCount = albums.where((a) => a['isPrivate'] == true).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _buildStatItem(Icons.photo_library_rounded, '${albums.length}', 'אלבומים', AppColors.primary),
          _buildStatDivider(),
          _buildStatItem(Icons.photo_rounded, '$totalPhotos', 'תמונות', AppColors.accent),
          _buildStatDivider(),
          _buildStatItem(Icons.lock_rounded, '$privateCount', 'פרטיים', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: AppColors.border);
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
        tabs: const [
          Tab(text: 'אלבומים'),
          Tab(text: 'ציר זמן'),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid() {
    final albums = _filteredAlbums;
    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_album_outlined, size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('אין אלבומים עדיין', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, color: AppColors.textHint)),
            const SizedBox(height: 8),
            const Text('צרי את האלבום הראשון!', style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) => _buildAlbumCard(albums[index]),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    final color = album['coverColor'] as Color? ?? AppColors.primary;
    return GestureDetector(
      onTap: () => _showAlbumDetail(album),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Center(child: Text(album['emoji'] as String, style: const TextStyle(fontSize: 48))),
                    if (album['isPrivate'] == true)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                          child: const Icon(Icons.lock, color: Colors.white, size: 14),
                        ),
                      ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${album['count']} תמונות',
                          style: const TextStyle(fontFamily: 'Heebo', fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album['title'] as String,
                      style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // User name label
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          album['createdBy'] as String? ?? 'משתמשת',
                          style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          album['date'] as String,
                          style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
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

  Widget _buildTimelineView() {
    final albums = _filteredAlbums;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final color = album['coverColor'] as Color? ?? AppColors.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  if (index < albums.length - 1)
                    Container(width: 2, height: 100, color: AppColors.border),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAlbumDetail(album),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text(album['emoji'] as String, style: const TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(album['title'] as String, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 15))),
                                  if (album['isPrivate'] == true) Icon(Icons.lock, size: 14, color: AppColors.textHint),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 3),
                                  Text(album['createdBy'] as String? ?? 'משתמשת', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text('${album['count']} תמונות  |  ${album['date']}', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAlbumDetail(Map<String, dynamic> album) {
    HapticFeedback.lightImpact();
    final albumKey = '${album['child']}_${album['title']}';
    final photos = _albumPhotos[albumKey] ?? [];
    final color = album['coverColor'] as Color? ?? AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(album['emoji'] as String, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(album['title'] as String, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 20)),
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(album['createdBy'] as String? ?? 'משתמשת', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text('${album['count']} תמונות', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textHint)),
                              const SizedBox(width: 8),
                              if (album['isPrivate'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock, size: 12, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text('פרטי', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.secondary)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Export album button
                    IconButton(
                      icon: const Icon(Icons.save_alt_rounded),
                      color: AppColors.primary,
                      tooltip: 'ייצוא לגלריה',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _exportAlbumToGallery(album);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: photos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 60, color: AppColors.textHint.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('האלבום ריק', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: AppColors.textHint)),
                            const Text('הוסיפי תמונות מהגלריה', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textHint)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                        itemCount: photos.length,
                        itemBuilder: (_, i) {
                          final photo = photos[i];
                          return GestureDetector(
                            onLongPress: () => _showPhotoOptions(photo, albumKey, i, setSheetState, album),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1 + (i % 5) * 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  Center(child: Icon(Icons.image_rounded, color: color.withValues(alpha: 0.4), size: 30)),
                                  // Photo info overlay
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                      ),
                                      child: Text(
                                        photo['uploadedBy'] ?? 'משתמשת',
                                        style: const TextStyle(fontFamily: 'Heebo', fontSize: 9, color: Colors.white),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Actions row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Export button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _exportAlbumToGallery(album);
                          },
                          icon: const Icon(Icons.save_alt_rounded, size: 20),
                          label: const Text('ייצוא לגלריה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add photo button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                              if (image != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('מעלה תמונה...', style: TextStyle(fontFamily: 'Heebo')), duration: Duration(seconds: 3)),
                                );

                                final storageService = StorageService();
                                final appState = Provider.of<AppState>(context, listen: false);
                                final userId = appState.currentUser?.id ?? 'anonymous';
                                final imageUrl = await storageService.uploadImage(
                                  filePath: image.path,
                                  folder: 'albums/$userId/$albumKey',
                                  customFileName: image.name,
                                );

                                final photoData = {
                                  'path': image.path,
                                  'name': image.name,
                                  'url': imageUrl,
                                  'uploadedBy': _currentUserName,
                                  'uploadedAt': DateTime.now().toIso8601String(),
                                };

                                setSheetState(() {
                                  if (_albumPhotos[albumKey] == null) {
                                    _albumPhotos[albumKey] = [];
                                  }
                                  _albumPhotos[albumKey]!.add(photoData);
                                  photos.add(photoData);
                                });

                                setState(() {
                                  album['count'] = (album['count'] as int) + 1;
                                });
                                _saveAlbums();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('תמונה נוספה לאלבום "${album['title']}" בהצלחה!', style: const TextStyle(fontFamily: 'Heebo')),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error picking image: $e');
                            }
                          },
                          icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 20),
                          label: const Text('הוסיפי תמונה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions(Map<String, dynamic> photo, String albumKey, int index, StateSetter setSheetState, Map<String, dynamic> album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('תמונה מאת: ${photo['uploadedBy']}', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.save_alt, color: AppColors.primary),
              title: const Text('שמור לגלריה', style: TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('שמירה לגלריה תהיה זמינה בקרוב', style: TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('מחק תמונה', style: TextStyle(fontFamily: 'Heebo', color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                setSheetState(() {
                  _albumPhotos[albumKey]?.removeAt(index);
                });
                setState(() {
                  album['count'] = (album['count'] as int) - 1;
                  if ((album['count'] as int) < 0) album['count'] = 0;
                });
                _saveAlbums();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('התמונה נמחקה', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAlbumToGallery(Map<String, dynamic> album) {
    final albumKey = '${album['child']}_${album['title']}';
    final photos = _albumPhotos[albumKey] ?? [];

    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('האלבום ריק - אין תמונות לייצוא', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ייצוא לגלריה יהיה זמין בקרוב (${photos.length} תמונות באלבום)',
          style: const TextStyle(fontFamily: 'Heebo'),
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCreateAlbumSheet() {
    final nameCtrl = TextEditingController();
    bool isPrivate = true;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('יצירת אלבום חדש', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('עבור ${_children[_selectedChild]['name']} ${_children[_selectedChild]['emoji']}', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('נוצר ע"י: $_currentUserName', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    hintText: 'שם האלבום',
                    hintStyle: const TextStyle(fontFamily: 'Heebo'),
                    prefixIcon: const Icon(Icons.photo_album_outlined),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(isPrivate ? Icons.lock : Icons.public, color: isPrivate ? AppColors.secondary : AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isPrivate ? 'אלבום פרטי' : 'אלבום ציבורי', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                            Text(
                              isPrivate ? 'רק את יכולה לראות את התמונות' : 'נראה לחברות הקהילה',
                              style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isPrivate,
                        onChanged: (v) => setSheetState(() => isPrivate = v),
                        activeTrackColor: AppColors.secondary.withValues(alpha: 0.3),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return AppColors.secondary;
                          return AppColors.textHint;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('נא להזין שם אלבום', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      setState(() {
                        _albums.add({
                          'title': nameCtrl.text,
                          'child': _children[_selectedChild]['name'],
                          'count': 0,
                          'isPrivate': isPrivate,
                          'coverColor': AppColors.primary,
                          'coverColorValue': AppColors.primary.toARGB32(),
                          'emoji': '📷',
                          'date': 'עכשיו',
                          'createdBy': _currentUserName,
                        });
                      });
                      _saveAlbums();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('האלבום "${nameCtrl.text}" נוצר בהצלחה!', style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('צרי אלבום', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('הגדרות פרטיות אלבומים', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrivacyOption(Icons.lock, 'פרטי', 'רק את יכולה לראות', true),
            const SizedBox(height: 12),
            _buildPrivacyOption(Icons.people, 'ציבורי', 'נראה לחברות הקהילה', false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.shield, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text('נתוני הילדים תמיד מוגנים וגלויים לאמא בלבד', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.accent))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo'))),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle, bool isDefault) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDefault ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isDefault ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
          if (isDefault) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}
