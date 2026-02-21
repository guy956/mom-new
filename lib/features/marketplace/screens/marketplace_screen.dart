import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';

/// Marketplace screen - real-time Firestore data with dynamic categories
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<String> _savedProductIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter items: only active/approved status for regular users, plus search and category
  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    return items.where((item) {
      // Only show active/approved items to regular users (pending and rejected are hidden)
      final status = (item['status'] ?? 'pending').toString().toLowerCase();
      if (status != 'active' && status != 'approved') return false;

      // Category filter
      if (_selectedCategory != null) {
        final itemCategory = (item['category'] ?? '').toString();
        if (itemCategory != _selectedCategory) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = (item['title'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        final seller = (item['seller'] ?? '').toString().toLowerCase();
        final brand = (item['brand'] ?? '').toString().toLowerCase();
        if (!title.contains(query) &&
            !description.contains(query) &&
            !seller.contains(query) &&
            !brand.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPremiumAppBar(),
        ],
        body: Column(
          children: [
            _buildSearchAndFilters(),
            _buildCategoryChips(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.marketplaceStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.error.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 16),
                          const Text('שגיאה בטעינת הפריטים',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('נסי שוב מאוחר יותר',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  final allItems = snapshot.data ?? [];
                  final filteredItems = _filterItems(allItems);

                  return _buildProductGrid(filteredItems);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.favorite_rounded,
            color: _savedProductIds.isNotEmpty
                ? AppColors.secondary
                : Colors.white70,
          ),
          onPressed: () => _showSavedProducts(),
          tooltip: 'פריטים שמורים',
        ),
        IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white70),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: 'מסך ראשי',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, const Color(0xFFB5C8B9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'מסירות ותרומות',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'אמהות עוזרות לאמהות - מסירה ותרומה ללא תשלום',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Heebo'),
        decoration: InputDecoration(
          hintText: 'חפשי פריטים למסירה...',
          hintStyle:
              TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textHint),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<AppState>(builder: (_, appState, __) {
      final categories = appState.marketplaceCategories;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildCategoryChip(null, 'הכל'),
            ...categories.map((cat) => _buildCategoryChip(cat, cat)),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = category);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            const Text('לא נמצאו פריטים',
                style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('נסי לשנות את הסינון',
                style: TextStyle(
                    fontFamily: 'Heebo', color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final id = item['id'] ?? '';
    final title = (item['title'] ?? '').toString();
    final price = item['price'] ?? 0;
    final condition = (item['condition'] ?? '').toString();
    final location = (item['location'] ?? '').toString();
    final category = (item['category'] ?? '').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetails(item),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area with overlay badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: Container(
                        color: AppColors.surfaceVariant,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volunteer_activism_rounded,
                                size: 36,
                                color:
                                    AppColors.primary.withValues(alpha: 0.4)),
                            const SizedBox(height: 4),
                            Text(category.isNotEmpty ? category : 'פריט',
                                style: TextStyle(
                                    fontFamily: 'Heebo',
                                    fontSize: 10,
                                    color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Price / donation badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (price == 0 || price == null)
                              ? [AppColors.success, const Color(0xFFB5C8B9)]
                              : [AppColors.primary, const Color(0xFFB5C8B9)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.3),
                              blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (price == 0 || price == null)
                                ? Icons.volunteer_activism
                                : Icons.sell_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (price == 0 || price == null)
                                ? 'למסירה'
                                : '${price is double ? price.toStringAsFixed(0) : price} ש"ח',
                            style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Save button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleSaveProduct(id, title),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6)
                            ],
                          ),
                          child: Icon(
                            _savedProductIds.contains(id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: _savedProductIds.contains(id)
                                ? AppColors.secondary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Condition badge
                  if (condition.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                    fontFamily: 'Heebo',
                                    fontSize: 11,
                                    color: AppColors.textHint),
                                overflow: TextOverflow.ellipsis,
                              ),
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
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
            colors: [AppColors.primary, const Color(0xFFB5C8B9)]),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreateProductSheet(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('פרסמי למסירה',
            style: TextStyle(
                fontFamily: 'Heebo',
                color: Colors.white,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> item) {
    final id = item['id'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailsSheet(
        item: item,
        isSaved: _savedProductIds.contains(id),
        onToggleSave: () => _toggleSaveProduct(id, item['title'] ?? ''),
      ),
    );
  }

  void _toggleSaveProduct(String id, String title) {
    if (id.isEmpty) return;
    setState(() {
      if (_savedProductIds.contains(id)) {
        _savedProductIds.remove(id);
      } else {
        _savedProductIds.add(id);
      }
    });
    final isSaved = _savedProductIds.contains(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'נשמר בהצלחה!' : 'הוסר מהשמורים',
            style: const TextStyle(fontFamily: 'Heebo')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCreateProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateDonationSheet(),
    );
  }

  void _showSavedProducts() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('פריטים שמורים',
                  style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _savedProductIds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle),
                            child: Icon(Icons.favorite_border_rounded,
                                size: 48,
                                color: AppColors.secondary
                                    .withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 16),
                          const Text('אין פריטים שמורים',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('סמני פריטים שמעניינים אותך',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: fs.marketplaceStream,
                      builder: (context, snapshot) {
                        final allItems = snapshot.data ?? [];
                        final savedItems = allItems
                            .where(
                                (i) => _savedProductIds.contains(i['id']))
                            .toList();

                        if (savedItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.08),
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.favorite_border_rounded,
                                      size: 48,
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.5)),
                                ),
                                const SizedBox(height: 16),
                                const Text('אין פריטים שמורים',
                                    style: TextStyle(
                                        fontFamily: 'Heebo',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: savedItems.length,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final item = savedItems[index];
                            final itemId = item['id'] ?? '';
                            final title =
                                (item['title'] ?? '').toString();
                            final location =
                                (item['location'] ?? '').toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                        Icons.volunteer_activism),
                                  ),
                                ),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontFamily: 'Heebo',
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(location,
                                    style: TextStyle(
                                        fontFamily: 'Heebo',
                                        color: AppColors.textHint,
                                        fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: AppColors.secondary),
                                  onPressed: () {
                                    setState(() =>
                                        _savedProductIds.remove(itemId));
                                    Navigator.pop(context);
                                    _showSavedProducts();
                                  },
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showProductDetails(item);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product details sheet - reads from Firestore map data
class _ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _ProductDetailsSheet(
      {required this.item, required this.isSaved, required this.onToggleSave});

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final price = item['price'] ?? 0;
    final seller = (item['seller'] ?? '').toString();
    final contact = (item['contact'] ?? '').toString();
    final condition = (item['condition'] ?? '').toString();
    final category = (item['category'] ?? '').toString();
    final location = (item['location'] ?? '').toString();
    final brand = (item['brand'] ?? '').toString();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image area
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Container(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volunteer_activism,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text(category.isNotEmpty ? category : 'פריט',
                                style: TextStyle(
                                    fontFamily: 'Heebo',
                                    fontSize: 14,
                                    color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + price badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(title,
                                  style: const TextStyle(
                                      fontFamily: 'Heebo',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  (price == 0 || price == null)
                                      ? AppColors.success
                                      : AppColors.primary,
                                  const Color(0xFFB5C8B9)
                                ]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (price == 0 || price == null)
                                        ? Icons.volunteer_activism
                                        : Icons.sell_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (price == 0 || price == null)
                                        ? 'למסירה'
                                        : '${price is double ? price.toStringAsFixed(0) : price} ש"ח',
                                    style: const TextStyle(
                                        fontFamily: 'Heebo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Info chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (category.isNotEmpty)
                              _buildInfoChip(
                                  Icons.category_rounded, category),
                            if (condition.isNotEmpty)
                              _buildInfoChip(
                                  Icons.star_rounded, condition),
                            if (location.isNotEmpty)
                              _buildInfoChip(
                                  Icons.location_on_rounded, location),
                            if (brand.isNotEmpty)
                              _buildInfoChip(
                                  Icons.label_rounded, brand),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('תיאור',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Seller info
                        if (seller.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.04),
                                  AppColors.primary.withValues(alpha: 0.01)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person_rounded,
                                        color: AppColors.primary, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(seller,
                                          style: const TextStyle(
                                              fontFamily: 'Heebo',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16)),
                                      if (location.isNotEmpty)
                                        Text(location,
                                            style: TextStyle(
                                                fontFamily: 'Heebo',
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 13)),
                                      if (contact.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(contact,
                                              style: TextStyle(
                                                  fontFamily: 'Heebo',
                                                  color: AppColors.primary,
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 14,
                                          color: AppColors.success),
                                      const SizedBox(width: 3),
                                      Text('תורמת מאומתת',
                                          style: TextStyle(
                                              fontFamily: 'Heebo',
                                              fontSize: 11,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('הודעה נשלחה לתורמת!',
                                style: TextStyle(fontFamily: 'Heebo')),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 20),
                      label: const Text('שליחת הודעה לתורמת',
                          style: TextStyle(
                              fontFamily: 'Heebo',
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleSave,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isSaved
                            ? AppColors.secondary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('הקישור הועתק!',
                              style: TextStyle(fontFamily: 'Heebo')),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.share_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 12,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Create donation sheet - with dynamic categories from AppState
class _CreateDonationSheet extends StatefulWidget {
  const _CreateDonationSheet();

  @override
  State<_CreateDonationSheet> createState() => _CreateDonationSheetState();
}

class _CreateDonationSheetState extends State<_CreateDonationSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = '';
  String _selectedCondition = 'מצב טוב';
  final List<String> _selectedImages = [];

  static const _conditionOptions = ['חדש', 'כמו חדש', 'מצב טוב', 'משומש'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Validate title
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('נא להזין שם לפריט',
              style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Validate category
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('נא לבחור קטגוריה',
              style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Validate location
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('נא להזין מיקום',
              style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Parse price (default to 0 for free)
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? 0 : int.tryParse(priceText) ?? 0;

    // Get current user from AppState
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;

    // Prepare data for submission
    final itemData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': price,
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'location': _locationController.text.trim(),
      'images': _selectedImages,
      'status': 'pending', // Changed to pending for admin approval
      'seller': currentUser?.fullName ?? 'משתמש',
      'contact': currentUser?.phone ?? '',
      'creatorId': currentUser?.id ?? '',
      'creatorName': currentUser?.fullName ?? '',
      'creatorEmail': currentUser?.email ?? '',
      'creatorPhone': currentUser?.phone ?? '',
    };

    // Submit to Firestore
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.addMarketplaceItem(itemData);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            price == 0
                ? 'הפריט נשלח לאישור ויפורסם בקרוב! 🎉'
                : 'הפריט נשלח לאישור ויפורסם בקרוב! 🎉',
            style: const TextStyle(fontFamily: 'Heebo'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'שגיאה בפרסום הפריט: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Heebo'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _pickImage() {
    // TODO: Implement actual image picker
    // For now, show a placeholder snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('בחירת תמונה - יישום עתידי',
            style: TextStyle(fontFamily: 'Heebo')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ביטול',
                      style: TextStyle(
                          fontFamily: 'Heebo', color: AppColors.textHint)),
                ),
                const Text('פרסום פריט למסירה',
                    style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _submitForm,
                  child: const Text('פרסום',
                      style: TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volunteer_activism_rounded,
                            color: AppColors.success, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'אמהות עוזרות לאמהות - מסירה ותרומה ללא תשלום',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'פרטי קשר נשמרים למנהלת בלבד',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Photos section
                  const Text('תמונות',
                      style: TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAddPhotoButton(),
                        ...List.generate(
                          3,
                          (index) => _buildPhotoPlaceholder(index),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title field
                  _buildTextField(
                    controller: _titleController,
                    label: 'שם הפריט *',
                    hint: 'למשל: עגלת תינוק במצב מצוין',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  _buildTextField(
                    controller: _descController,
                    label: 'תיאור',
                    hint: 'תארי את הפריט, מצבו, מה כלול...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  // Price field
                  _buildPriceField(),
                  const SizedBox(height: 20),
                  // Location field
                  _buildTextField(
                    controller: _locationController,
                    label: 'מיקום *',
                    hint: 'למשל: תל אביב, רמת גן...',
                    isRequired: true,
                    prefixIcon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 20),
                  // Category selection
                  const Text('קטגוריה *',
                      style: TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Consumer<AppState>(builder: (_, appState, __) {
                    final categories = appState.marketplaceCategories;
                    if (categories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            Text('אין קטגוריות זמינות',
                                style: TextStyle(
                                    fontFamily: 'Heebo',
                                    fontSize: 13,
                                    color: AppColors.textHint)),
                          ],
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppColors.primaryGradient
                                    : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : AppColors.border),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                      fontFamily: 'Heebo',
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500)),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 20),
                  // Condition selection
                  const Text('מצב הפריט',
                      style: TextStyle(
                          fontFamily: 'Heebo',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _conditionOptions.map((cond) {
                      final isSelected = _selectedCondition == cond;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedCondition = cond),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppColors.primaryGradient
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.border),
                            ),
                            child: Text(
                              cond,
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(height: 4),
              Text('הוספי תמונה',
                  style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Icon(Icons.image_rounded, color: AppColors.textHint, size: 32),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isRequired = false,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Heebo',
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textHint, size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('מחיר',
            style: TextStyle(
                fontFamily: 'Heebo',
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Heebo'),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'השאירי ריק למסירה חינם',
            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
            suffixText: 'ש"ח',
            suffixStyle: TextStyle(
                fontFamily: 'Heebo',
                color: AppColors.textSecondary,
                fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.attach_money_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'השאירי את השדה ריק או הזיני 0 למסירה חינם',
          style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 11,
              color: AppColors.textHint),
        ),
      ],
    );
  }
}
