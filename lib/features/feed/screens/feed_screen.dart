import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/storage_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/core/widgets/empty_state_widgets.dart';
import 'package:mom_connect/core/widgets/loading_widgets.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';

/// Feed screen with real-time Firestore data
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  final Set<String> _savedPostIds = {};
  final Set<String> _hiddenPostIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    timeago.setLocaleMessages('he', timeago.HeMessages());
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final userId = context.read<AppState>().currentUser?.id;
    if (userId == null) return;
    final fs = context.read<FirestoreService>();
    final ids = await fs.getSavedItemIds(userId);
    if (mounted) setState(() => _savedPostIds.addAll(ids));
  }

  Future<void> _toggleSavePost(String postId) async {
    final userId = context.read<AppState>().currentUser?.id;
    if (userId == null) return;
    final fs = context.read<FirestoreService>();
    final isSaved = _savedPostIds.contains(postId);
    setState(() {
      if (isSaved) { _savedPostIds.remove(postId); } else { _savedPostIds.add(postId); }
    });
    try {
      if (isSaved) { await fs.unsaveItem(userId, postId); } else { await fs.saveItem(userId, postId); }
    } catch (e) {
      if (mounted) setState(() {
        if (isSaved) { _savedPostIds.add(postId); } else { _savedPostIds.remove(postId); }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Parse a Firestore Timestamp or ISO string to DateTime
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Sort posts: pinned first, then by createdAt descending. Only show approved posts.
  List<Map<String, dynamic>> _sortAndFilter(List<Map<String, dynamic>> posts) {
    var filtered = List<Map<String, dynamic>>.from(posts);

    // Filter hidden posts
    filtered = filtered.where((p) => !_hiddenPostIds.contains(p['id'])).toList();

    // Status filter: only show approved posts to regular users
    filtered = filtered.where((p) {
      final status = (p['status'] ?? 'pending').toString().toLowerCase();
      return status == 'approved';
    }).toList();

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((p) {
        final cat = (p['category'] ?? '').toString().toLowerCase();
        return cat == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final content = (p['content'] ?? '').toString().toLowerCase();
        final author = (p['authorName'] ?? '').toString().toLowerCase();
        final category = (p['category'] ?? '').toString().toLowerCase();
        return content.contains(q) || author.contains(q) || category.contains(q);
      }).toList();
    }

    // Tab-based sorting: 0=Popular, 1=New, 2=Local, 3=Following
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      // Popular: sort by likes descending, then date
      filtered.sort((a, b) {
        final aPinned = a['isPinned'] == true ? 1 : 0;
        final bPinned = b['isPinned'] == true ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);
        final aLikes = ((a['likes'] ?? 0) is int) ? (a['likes'] ?? 0) as int : (a['likes'] ?? 0).toInt();
        final bLikes = ((b['likes'] ?? 0) is int) ? (b['likes'] ?? 0) as int : (b['likes'] ?? 0).toInt();
        if (aLikes != bLikes) return bLikes.compareTo(aLikes);
        return _parseTimestamp(b['createdAt']).compareTo(_parseTimestamp(a['createdAt']));
      });
    } else {
      // New (1), Local (2), Following (3): sort by date descending
      filtered.sort((a, b) {
        final aPinned = a['isPinned'] == true ? 1 : 0;
        final bPinned = b['isPinned'] == true ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);
        return _parseTimestamp(b['createdAt']).compareTo(_parseTimestamp(a['createdAt']));
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.postsStream,
      builder: (context, snapshot) {
        return RefreshIndicator(
          onRefresh: () async {
            // Force a rebuild; the stream will provide new data
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Announcement banner
              if (appState.hasActiveAnnouncement)
                SliverToBoxAdapter(child: _buildAnnouncementBanner(appState)),
              // Home button + search toggle
              SliverToBoxAdapter(child: _buildTopBar()),
              // Search bar (if visible)
              if (_showSearch) SliverToBoxAdapter(child: _buildSearchBar()),
              // Header with create post
              SliverToBoxAdapter(child: _buildHeader()),
              // Category chips
              SliverToBoxAdapter(child: _buildCategoryChips()),
              // Feed tabs
              SliverToBoxAdapter(child: _buildFeedTabs()),
              // Posts list
              _buildPostsList(snapshot),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementBanner(AppState appState) {
    final ann = appState.announcement;
    final text = (ann['text'] ?? '').toString();
    final colorHex = (ann['color'] ?? '#D1C2D3').toString();
    final bgColor = AppColors.fromHex(colorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: bgColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, color: bgColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Home button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // Return to main screen tab 0 (already on feed as tab 0)
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          const Expanded(
            child: Text(
              'הקהילה',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Search toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showSearch ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  color: _showSearch ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Semantics(
        label: 'חיפוש בפוסטים',
        textField: true,
        child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'חיפוש בפוסטים...',
          hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'נקה',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showCreatePostSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.momGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'מה על הלב? שתפי...',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        color: AppColors.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(Icons.image_rounded, AppColors.success, () {
            _showCreatePostSheet(context, initialType: 'image');
          }),
          const SizedBox(width: 6),
          _buildQuickActionButton(Icons.poll_rounded, AppColors.accent, () {
            _showCreatePostSheet(context, initialType: 'poll');
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <Map<String, String>>[
      {'id': '', 'label': 'הכל', 'emoji': ''},
      {'id': 'questions', 'label': 'שאלות', 'emoji': '?'},
      {'id': 'tips', 'label': 'טיפים', 'emoji': ''},
      {'id': 'emotional', 'label': 'רגשי', 'emoji': ''},
      {'id': 'feeding', 'label': 'האכלה', 'emoji': ''},
      {'id': 'sleep', 'label': 'שינה', 'emoji': ''},
      {'id': 'health', 'label': 'בריאות', 'emoji': ''},
      {'id': 'moments', 'label': 'רגעים', 'emoji': ''},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isAll = cat['id']!.isEmpty;
          final isSelected = isAll
              ? (_selectedCategory == null || _selectedCategory!.isEmpty)
              : _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                cat['label']!,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected && !isAll ? cat['id'] : null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(child: Text('פופולרי')),
          Tab(child: Text('חדש')),
          Tab(child: Text('באזורי')),
          Tab(child: Text('עוקבות')),
        ],
      ),
    );
  }

  Widget _buildPostsList(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        child: ShimmerCard(itemCount: 4),
      );
    }

    if (snapshot.hasError) {
      return SliverFillRemaining(
        child: EnhancedEmptyState.error(
          message: 'לא הצלחנו לטעון את הפוסטים. בדקי את החיבור ונסי שוב.',
          onRetry: () => setState(() {}),
        ),
      );
    }

    final allPosts = snapshot.data ?? [];
    final posts = _sortAndFilter(allPosts);

    if (posts.isEmpty) {
      return SliverFillRemaining(
        child: _searchQuery.isNotEmpty
            ? EnhancedEmptyState.search(
                query: _searchQuery,
                onClearSearch: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : EnhancedEmptyState.posts(
                onCreatePost: () => _showCreatePostSheet(context),
              ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostCard(posts[index]),
          childCount: posts.length,
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isPinned = post['isPinned'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isPinned ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4), spreadRadius: -2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned indicator
          if (isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'פוסט מוצמד',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          // Header
          _buildPostHeader(post),
          // Content
          _buildPostContent(post),
          // Stats and Actions
          _buildPostActions(post),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> post) {
    final authorName = (post['authorName'] ?? 'אנונימית').toString();
    final authorImage = (post['authorImage'] ?? '').toString();
    final createdAt = _parseTimestamp(post['createdAt']);
    final category = (post['category'] ?? '').toString();
    final reportCount = (post['reportCount'] ?? 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: authorImage.isNotEmpty ? NetworkImage(authorImage) : null,
            child: authorImage.isEmpty
                ? Icon(Icons.person, color: AppColors.primary, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      timeago.format(createdAt, locale: 'he'),
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                    if (reportCount is int && reportCount > 0) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.flag_rounded, size: 12, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        '$reportCount',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          color: AppColors.warning,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Menu
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textHint),
            tooltip: 'אפשרויות',
            onPressed: () => _showPostMenu(post),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(Map<String, dynamic> post) {
    final content = (post['content'] ?? '').toString();
    final images = post['images'];
    final hasImages = images is List && images.isNotEmpty;

    if (content.isEmpty && !hasImages) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        if (hasImages) ...[
          const SizedBox(height: 8),
          if (images.length == 1)
            Image.network(
              images[0].toString(),
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[index].toString(),
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post) {
    final likes = (post['likes'] ?? 0) is int ? (post['likes'] ?? 0) as int : 0;
    final comments = (post['comments'] ?? 0) is int ? (post['comments'] ?? 0) as int : 0;
    final likedBy = List<String>.from(post['likedBy'] ?? []);
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUserId = appState.currentUser?.id ?? '';
    final isLiked = likedBy.contains(currentUserId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
          if (likes > 0 || comments > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (likes > 0) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: AppColors.momGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  if (comments > 0)
                    Text(
                      '$comments תגובות',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          // Divider
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'אהבתי',
                color: isLiked ? AppColors.secondary : AppColors.textSecondary,
                onTap: () => _toggleLike(post),
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'תגובה',
                color: AppColors.textSecondary,
                onTap: () => _showComments(post),
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'שיתוף',
                color: AppColors.textSecondary,
                onTap: () => _sharePost(post),
              ),
              _buildActionButton(
                icon: _savedPostIds.contains(post['id']) ? Icons.bookmark : Icons.bookmark_border,
                label: _savedPostIds.contains(post['id']) ? 'נשמר' : 'שמירה',
                color: _savedPostIds.contains(post['id']) ? AppColors.primary : AppColors.textSecondary,
                onTap: () {
                  final postId = post['id'];
                  if (postId != null) _toggleSavePost(postId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLike(Map<String, dynamic> post) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final postId = post['id'];
    if (postId == null) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final currentUserId = appState.currentUser?.id ?? '';
    if (currentUserId.isEmpty) return;

    final likedBy = List<String>.from(post['likedBy'] ?? []);
    final alreadyLiked = likedBy.contains(currentUserId);

    if (alreadyLiked) {
      // Unlike: remove user from likedBy, decrement likes
      fs.updatePost(postId, {
        'likedBy': FieldValue.arrayRemove([currentUserId]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      // Like: add user to likedBy, increment likes
      fs.updatePost(postId, {
        'likedBy': FieldValue.arrayUnion([currentUserId]),
        'likes': FieldValue.increment(1),
      });
    }
  }

  void _showComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('שיתוף', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, 'העתק קישור', () {
                  final text = '${post['title'] ?? ''}\n${post['content'] ?? ''}';
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('הטקסט הועתק!', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.success),
                  );
                }),
                _buildShareOption(Icons.chat, 'WhatsApp', () {
                  final text = '${post['title'] ?? ''}\n${post['content'] ?? ''}\n\n- MOMIT';
                  SharePlus.instance.share(ShareParams(text: text));
                  Navigator.pop(context);
                }),
                _buildShareOption(Icons.send, 'שלחי לחברה', () {
                  final text = '${post['title'] ?? ''}\n${post['content'] ?? ''}\n\n- MOMIT';
                  SharePlus.instance.share(ShareParams(text: text));
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'Heebo', fontSize: 12)),
        ],
      ),
    );
  }

  void _showPostMenu(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_savedPostIds.contains(post['id']) ? Icons.bookmark : Icons.bookmark_border),
              title: Text(_savedPostIds.contains(post['id']) ? 'הסר שמירה' : 'שמור פוסט', style: const TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(context);
                final postId = post['id'];
                if (postId != null) _toggleSavePost(postId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('הסתר פוסט', style: TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(context);
                final postId = post['id'];
                if (postId != null) {
                  setState(() => _hiddenPostIds.add(postId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('הפוסט הוסתר', style: TextStyle(fontFamily: 'Heebo')),
                      backgroundColor: AppColors.info,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(label: 'בטל', textColor: Colors.white, onPressed: () => setState(() => _hiddenPostIds.remove(postId))),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text('דווח', style: TextStyle(fontFamily: 'Heebo', color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                final postId = post['id'];
                if (postId != null) {
                  final fs = Provider.of<FirestoreService>(context, listen: false);
                  final userId = context.read<AppState>().currentUser?.id ?? '';
                  fs.addReport({
                    'postId': postId,
                    'reporterId': userId,
                    'reason': 'user_report',
                    'status': 'pending',
                  });
                  fs.updatePost(postId, {'reports': FieldValue.increment(1)});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('הדיווח נשלח, תודה!', style: TextStyle(fontFamily: 'Heebo')),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context, {String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(initialType: initialType),
    );
  }
}

/// Comments bottom sheet
class _CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postId = widget.post['id'];
    if (postId == null) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;
    final fs = Provider.of<FirestoreService>(context, listen: false);

    fs.addComment(postId, {
      'text': text,
      'userId': currentUser?.id ?? '',
      'userName': currentUser?.fullName ?? 'אנונימית',
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
  }

  DateTime _parseCommentTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'] as String?;
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('תגובות', style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: postId == null
                ? Center(child: Text('שגיאה: לא נמצא פוסט', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fs.getCommentsStream(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('אין תגובות עדיין', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('היי הראשונה להגיב!', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final userName = (comment['userName'] ?? 'אנונימית').toString();
                          final text = (comment['text'] ?? '').toString();
                          final createdAt = _parseCommentTimestamp(comment['createdAt']);
                          final commentId = comment['id'] as String?;
                          final commentUserId = (comment['userId'] ?? '').toString();
                          final appState = Provider.of<AppState>(context, listen: false);
                          final currentUserId = appState.currentUser?.id ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                      child: Icon(Icons.person, color: AppColors.primary, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            timeago.format(createdAt, locale: 'he'),
                                            style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (commentUserId == currentUserId && commentId != null)
                                      GestureDetector(
                                        onTap: () => fs.deleteComment(postId, commentId),
                                        child: Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  text,
                                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 14, height: 1.4),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          // Comment input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Heebo'),
                      decoration: InputDecoration(
                        hintText: 'כתבי תגובה...',
                        hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create post bottom sheet - writes to Firestore
class _CreatePostSheet extends StatefulWidget {
  final String? initialType;
  const _CreatePostSheet({this.initialType});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  String _selectedCategory = 'general';
  String? _selectedImagePath;
  String? _selectedImageName;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userName = appState.currentUser?.fullName ?? 'אורחת';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint))),
                const Text('פוסט חדש', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _contentController.text.isNotEmpty || _selectedImagePath != null ? () => _publishPost(userName) : null,
                  child: Text(
                    'פרסום',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontWeight: FontWeight.bold,
                      color: _contentController.text.isNotEmpty || _selectedImagePath != null ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User header
                  Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.2), child: const Icon(Icons.person, color: AppColors.primary, size: 20)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isAnonymous ? 'אנונימית' : userName, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                            child: Row(
                              children: [
                                Icon(_isAnonymous ? Icons.visibility_off : Icons.public, size: 12, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(_isAnonymous ? 'פרסום אנונימי' : 'ציבורי', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Text input
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 4,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'מה על הלב? שתפי את הקהילה...',
                      hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Category chips
                  const Text('קטגוריה:', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildCatChipIcon('general', Icons.chat_bubble_outline_rounded, 'כללי'),
                      _buildCatChipIcon('questions', Icons.help_outline_rounded, 'שאלות'),
                      _buildCatChipIcon('tips', Icons.lightbulb_outline_rounded, 'טיפים'),
                      _buildCatChipIcon('emotional', Icons.favorite_outline_rounded, 'רגשי'),
                      _buildCatChipIcon('feeding', Icons.restaurant_rounded, 'האכלה'),
                      _buildCatChipIcon('sleep', Icons.bedtime_outlined, 'שינה'),
                      _buildCatChipIcon('health', Icons.health_and_safety_outlined, 'בריאות'),
                      _buildCatChipIcon('moments', Icons.camera_alt_outlined, 'רגעים'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image picker option
                  _buildOptionChip(Icons.photo_library_outlined, _selectedImagePath != null ? 'תמונה נבחרה' : 'תמונה', _selectedImagePath != null, () async {
                    try {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          _selectedImagePath = image.path;
                          _selectedImageName = image.name;
                        });
                      }
                    } catch (e) {
                      debugPrint('Error picking image: $e');
                    }
                  }),
                  if (_selectedImagePath != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('תמונה צורפה: ${_selectedImageName ?? 'image'}', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.success))),
                          GestureDetector(
                            onTap: () => setState(() { _selectedImagePath = null; _selectedImageName = null; }),
                            child: Icon(Icons.close, size: 18, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _publishPost(String userName) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImagePath == null) return;

    try {
      // Upload image to Firebase Storage if selected
      String? imageUrl;
      if (_selectedImagePath != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadImage(
          filePath: _selectedImagePath!,
          folder: 'posts/${currentUser?.id ?? 'anonymous'}',
          customFileName: _selectedImageName,
        );
      }

      // Prepare post data
      final postData = {
        'content': content,
        'authorId': currentUser?.id ?? '',
        'authorName': _isAnonymous ? 'אנונימית' : userName,
        'authorImage': _isAnonymous ? '' : (currentUser?.profileImage ?? ''),
        'category': _selectedCategory,
        'isAnonymous': _isAnonymous,
        'likes': 0,
        'comments': 0,
        'likedBy': <String>[],
        'isPinned': false,
        'reportCount': 0,
      };

      // Add uploaded image URL if available
      if (imageUrl != null) {
        postData['images'] = [imageUrl];
        postData['imageName'] = _selectedImageName ?? '';
      }

      await fs.addPost(postData);

      if (!mounted) return;
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('הפוסט נשלח לאישור ויפורסם בקרוב! 🎉', style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בפרסום הפוסט: ${e.toString()}', style: const TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildCatChipIcon(String id, IconData icon, String name) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(name, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
