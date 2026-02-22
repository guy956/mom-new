import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Daily Tips Screen - Real-time Firestore powered
/// Shows tips/articles with category filters, search, and file links.
class DailyTipsScreen extends StatefulWidget {
  const DailyTipsScreen({super.key});

  @override
  State<DailyTipsScreen> createState() => _DailyTipsScreenState();
}

class _DailyTipsScreenState extends State<DailyTipsScreen> {
  String _selectedCategory = 'הכל';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  // Color mapping for categories
  final Map<String, Color> _categoryColors = {
    'הכל': AppColors.primary,
    'שינה': AppColors.info,
    'האכלה': AppColors.secondary,
    'התפתחות': AppColors.success,
    'בריאות': const Color(0xFFD4A3A3),
    'כושר': AppColors.accent,
    'רווחה נפשית': const Color(0xFFD1C2D3),
    'טיפול בתינוק': AppColors.warning,
    'תזונה': const Color(0xFFB5C8B9),
  };

  // Icon mapping for categories
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'שינה':
        return Icons.bedtime_outlined;
      case 'האכלה':
        return Icons.restaurant_outlined;
      case 'התפתחות':
        return Icons.child_friendly_outlined;
      case 'בריאות':
        return Icons.favorite_outlined;
      case 'כושר':
        return Icons.fitness_center_outlined;
      case 'רווחה נפשית':
        return Icons.spa_outlined;
      case 'טיפול בתינוק':
        return Icons.baby_changing_station_outlined;
      case 'תזונה':
        return Icons.local_dining_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Color _colorForCategory(String category) {
    return _categoryColors[category] ?? AppColors.primary;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter tips list by active status, approval status, category, and search query
  List<Map<String, dynamic>> _filterTips(List<Map<String, dynamic>> allTips) {
    return allTips.where((tip) {
      // Only show active tips (check both 'active' and legacy 'isActive' fields)
      final isActive = tip['active'] ?? tip['isActive'];
      if (isActive == false) return false;

      // Only show approved tips (default to 'approved' for backward compat with existing tips)
      final status = (tip['status'] ?? 'approved').toString();
      if (status != 'approved') return false;

      // Category filter
      if (_selectedCategory != 'הכל') {
        final tipCategory = (tip['category'] ?? '').toString();
        if (tipCategory != _selectedCategory) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = (tip['title'] ?? '').toString().toLowerCase();
        final content = (tip['content'] ?? '').toString().toLowerCase();
        final author = (tip['author'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) &&
            !content.contains(query) &&
            !author.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _openFileUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא ניתן לפתוח את הקישור',
                style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.tipsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allTips = snapshot.data ?? [];
          final filteredTips = _filterTips(allTips);

          return Column(
            children: [
              // Search bar (animated)
              if (_showSearch) _buildSearchBar(),
              // Category filters
              _buildCategoryFilters(),
              const SizedBox(height: 4),
              // Results count
              if (_searchQuery.isNotEmpty || _selectedCategory != 'הכל')
                _buildResultsCount(filteredTips.length),
              // Tips list
              Expanded(
                child: filteredTips.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredTips.length,
                        itemBuilder: (context, index) =>
                            _buildTipCard(filteredTips[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════ App Bar ═══════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'טיפים ומאמרים',
        style: TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.search_off : Icons.search,
            color: _showSearch ? AppColors.primary : AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          tooltip: 'חיפוש',
        ),
        IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: 'מסך ראשי',
        ),
      ],
    );
  }

  // ═══════════ Search Bar ═══════════
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Heebo', fontSize: 15),
        decoration: InputDecoration(
          hintText: 'חפשי טיפ, נושא או מחבר/ת...',
          hintStyle: const TextStyle(
            fontFamily: 'Heebo',
            color: AppColors.textHint,
            fontSize: 14,
          ),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textHint, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textHint, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
      ),
    );
  }

  // ═══════════ Category Filters (Dynamic from AppState) ═══════════
  Widget _buildCategoryFilters() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final dynamicCategories = appState.tipCategories;
        final categories = [
          'הכל',
          ...dynamicCategories,
        ];

        return Container(
          height: 48,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              final color = _colorForCategory(cat);
              final icon = _getCategoryIcon(cat);

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : AppColors.border.withValues(alpha: 0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ═══════════ Results Count ═══════════
  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded,
              size: 16, color: AppColors.textHint.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            '$count תוצאות',
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              'עבור "$_searchQuery"',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 12,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          if (_selectedCategory != 'הכל' || _searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'הכל';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'נקה הכל',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════ Tip Card ═══════════
  Widget _buildTipCard(Map<String, dynamic> tip) {
    final title = (tip['title'] ?? '').toString();
    final content = (tip['content'] ?? '').toString();
    final category = (tip['category'] ?? '').toString();
    final author = (tip['author'] ?? '').toString();
    final fileUrl = (tip['attachmentUrl'] ?? tip['fileUrl'] ?? '').toString();
    final fileName = (tip['attachmentName'] ?? '').toString();
    final createdAt = tip['createdAt'];
    final catColor = _colorForCategory(category);
    final catIcon = _getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with category badge ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(catIcon, size: 22, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag + date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category.isNotEmpty ? category : 'כללי',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: catColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // ── Author info ──
          if (author.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: catColor.withValues(alpha: 0.15),
                      child: Icon(Icons.person, color: catColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        author,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── File URL button ──
          if (fileUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _openFileUrl(fileUrl),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.open_in_new_rounded,
                            color: AppColors.info, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName.isNotEmpty ? fileName : 'קובץ מצורף',
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.info,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'לחצי לצפייה או הורדה',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_rounded,
                            color: AppColors.info, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ═══════════ Empty State ═══════════
  Widget _buildEmptyState() {
    final isFiltered =
        _selectedCategory != 'הכל' || _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryMist.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.article_outlined,
                size: 52,
                color: AppColors.textHint.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'לא נמצאו טיפים' : 'עדיין אין טיפים',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'נסי לשנות את הקטגוריה או את מילות החיפוש'
                  : 'טיפים ומאמרים חדשים יופיעו כאן בקרוב',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 14,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'הכל';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'הצג הכל',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════ Error State ═══════════
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'שגיאה בטעינת הטיפים',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 12,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
