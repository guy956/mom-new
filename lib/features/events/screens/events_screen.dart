import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/features/home/screens/main_screen.dart';
import 'package:mom_connect/core/widgets/empty_state_widgets.dart';
import 'package:mom_connect/core/widgets/loading_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _showOnlineOnly = false;
  bool _showFreeOnly = false;

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'name': 'הכל', 'icon': Icons.auto_awesome_outlined},
    {'id': 'playMeetup', 'name': 'מפגשי משחק', 'icon': Icons.toys_outlined},
    {'id': 'workshop', 'name': 'סדנאות', 'icon': Icons.palette_outlined},
    {'id': 'webinar', 'name': 'וובינרים', 'icon': Icons.laptop_outlined},
    {'id': 'womensEvening', 'name': 'ערבי נשים', 'icon': Icons.wine_bar_outlined},
    {'id': 'supportGroup', 'name': 'קבוצות תמיכה', 'icon': Icons.favorite_outline_rounded},
    {'id': 'other', 'name': 'אחר', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Filter events from raw Firestore list: only approved, matching category/search/quick-filters.
  List<Map<String, dynamic>> _filterEvents(List<Map<String, dynamic>> allEvents) {
    final query = _searchController.text.trim().toLowerCase();

    return allEvents.where((event) {
      // Only show approved events to regular users
      final status = event['status'] as String? ?? 'pending';
      if (status != 'approved') return false;

      // Category filter
      if (_selectedFilter != 'all') {
        final eventType = event['type'] as String? ?? '';
        if (eventType != _selectedFilter) return false;
      }

      // Online-only filter
      if (_showOnlineOnly) {
        final isOnline = event['isOnline'] == true;
        if (!isOnline) return false;
      }

      // Free-only filter
      if (_showFreeOnly) {
        final price = (event['price'] as num?)?.toDouble() ?? 0;
        if (price > 0) return false;
      }

      // Text search
      if (query.isNotEmpty) {
        final title = (event['title'] as String? ?? '').toLowerCase();
        final description = (event['description'] as String? ?? '').toLowerCase();
        final location = (event['location'] as String? ?? '').toLowerCase();
        final organizer = (event['organizer'] as String? ?? '').toLowerCase();
        if (!title.contains(query) &&
            !description.contains(query) &&
            !location.contains(query) &&
            !organizer.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Parse a Firestore date field (Timestamp, DateTime, or String) to DateTime.
  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Format a date for display.
  String _formatDate(dynamic date) {
    final dt = _parseDate(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dt.year, dt.month, dt.day);

    if (eventDate == today) return 'היום';
    if (eventDate == tomorrow) return 'מחר';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Format time string (either from 'time' field or derived from 'date').
  String _formatTime(Map<String, dynamic> event) {
    final timeStr = event['time'] as String?;
    if (timeStr != null && timeStr.isNotEmpty) return timeStr;
    final dt = _parseDate(event['date']);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.eventsStream,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildAppBar(),
                _buildSearchAndFilter(),
                _buildTabBar(),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(snapshot),
                  _buildCalendarView(snapshot),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateEventSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'יצירת אירוע',
            style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Consumer<AppState>(
                    builder: (context, appState, _) => Text(
                      TextConfig.eventsAndMeetups,
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<AppState>(
                    builder: (context, appState, _) => Text(
                      TextConfig.eventsDescription,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded),
          color: Colors.white,
          tooltip: 'בית',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          color: Colors.white,
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: TextConfig.searchEvents,
                hintStyle: const TextStyle(fontFamily: 'Heebo'),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter['id'];

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter['id']);
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(filter['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              filter['name'],
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Filters
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickFilter(
                  label: 'מקוון',
                  icon: Icons.videocam_rounded,
                  isSelected: _showOnlineOnly,
                  onTap: () => setState(() => _showOnlineOnly = !_showOnlineOnly),
                ),
                const SizedBox(width: 8),
                _buildQuickFilter(
                  label: 'חינם',
                  icon: Icons.money_off_rounded,
                  isSelected: _showFreeOnly,
                  onTap: () => setState(() => _showFreeOnly = !_showFreeOnly),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Heebo'),
          tabs: const [
            Tab(text: 'רשימה'),
            Tab(text: 'לוח שנה'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const ShimmerList(itemCount: 5);
    }

    if (snapshot.hasError) {
      return EnhancedEmptyState.error(
        message: 'לא הצלחנו לטעון את האירועים. בדקי את החיבור ונסי שוב.',
        onRetry: () => setState(() {}),
      );
    }

    final allEvents = snapshot.data ?? [];
    final events = _filterEvents(allEvents);

    if (events.isEmpty) {
      return _searchController.text.isNotEmpty
          ? EnhancedEmptyState.search(
              query: _searchController.text,
              onClearSearch: () {
                setState(() {
                  _searchController.clear();
                });
              },
            )
          : EnhancedEmptyState.events(
              onCreateEvent: () => _showCreateEventSheet(),
            );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _EventCard(
          event: events[index],
          parseDate: _parseDate,
          formatDate: _formatDate,
          formatTime: _formatTime,
        );
      },
    );
  }

  Widget _buildCalendarView(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final hebrewMonths = ['', 'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

    final allEvents = snapshot.data ?? [];
    final approvedEvents = allEvents.where((e) => (e['status'] ?? 'pending') == 'approved').toList();

    // Find event dates
    final eventDays = <int>{};
    for (final event in approvedEvents) {
      final dt = _parseDate(event['date']);
      if (dt.month == now.month && dt.year == now.year) {
        eventDays.add(dt.day);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text(
                  '${hebrewMonths[now.month]} ${now.year}',
                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Weekday headers
                Row(
                  children: ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'].map((d) => Expanded(
                    child: Center(child: Text(d, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w600))),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                  itemCount: daysInMonth + (firstWeekday % 7),
                  itemBuilder: (context, index) {
                    final dayOffset = firstWeekday % 7;
                    if (index < dayOffset) return const SizedBox();
                    final day = index - dayOffset + 1;
                    if (day > daysInMonth) return const SizedBox();
                    final isToday = day == now.day;
                    final hasEvent = eventDays.contains(day);

                    return GestureDetector(
                      onTap: hasEvent ? () {
                        final dayEvents = approvedEvents.where((e) {
                          final dt = _parseDate(e['date']);
                          return dt.day == day && dt.month == now.month;
                        }).toList();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${dayEvents.length} אירועים ב-$day/${now.month}', style: const TextStyle(fontFamily: 'Heebo')),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : (hasEvent ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 14,
                                  fontWeight: isToday || hasEvent ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? Colors.white : (hasEvent ? AppColors.primary : AppColors.textPrimary),
                                ),
                              ),
                              if (hasEvent && !isToday)
                                Container(
                                  width: 5, height: 5,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Upcoming events
          Align(
            alignment: Alignment.centerRight,
            child: Text('אירועים קרובים', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          if (approvedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'אין אירועים קרובים',
                style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textHint),
              ),
            )
          else
            ...approvedEvents.take(3).map((event) {
              final dt = _parseDate(event['date']);
              final eventType = event['type'] as String? ?? '';
              final typeLabel = _typeDisplayName(eventType);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${dt.day}', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                          Text('/${dt.month}', style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['title'] ?? '', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                          Text(_formatTime(event), style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(typeLabel, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.primary)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Map event type key to Hebrew display name.
  String _typeDisplayName(String type) {
    switch (type) {
      case 'playMeetup': return 'מפגש משחק';
      case 'workshop': return 'סדנה';
      case 'webinar': return 'וובינר';
      case 'womensEvening': return 'ערב נשים';
      case 'supportGroup': return 'קבוצת תמיכה';
      case 'classes': return 'חוג';
      default: return 'אחר';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'סינון אירועים',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('בקרוב - אפשרויות סינון מתקדמות...'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showCreateEventSheet() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final emailCtrl = TextEditingController(text: appState.currentUser?.email ?? '');
    final phoneCtrl = TextEditingController(text: appState.currentUser?.phone ?? '');
    String selectedType = 'workshop';
    final otherTypeCtrl = TextEditingController();
    DateTime? selectedEventDate;
    TimeOfDay? selectedEventTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('יצירת אירוע חדש', style: TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(child: Text('האירוע יישלח לאישור מנהל לפני פרסום', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.accent))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text('פרטי הקשר שלך (מייל וטלפון) ישמרו למנהלת בלבד לצורך אימות ויצירת קשר במידת הצורך', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.primary))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: titleCtrl,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontFamily: 'Heebo'),
                          decoration: InputDecoration(
                            labelText: 'שם האירוע *',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            prefixIcon: const Icon(Icons.event),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          textDirection: TextDirection.rtl,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'Heebo'),
                          decoration: InputDecoration(
                            labelText: 'תיאור האירוע',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            prefixIcon: const Icon(Icons.description_outlined),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: locationCtrl,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontFamily: 'Heebo'),
                          decoration: InputDecoration(
                            labelText: 'מיקום',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('תאריך ושעה *', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: selectedEventDate ?? DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    locale: const Locale('he'),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedEventDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedEventDate != null
                                            ? '${selectedEventDate!.day.toString().padLeft(2, '0')}/${selectedEventDate!.month.toString().padLeft(2, '0')}/${selectedEventDate!.year}'
                                            : 'בחר תאריך',
                                        style: TextStyle(fontFamily: 'Heebo', color: selectedEventDate != null ? AppColors.textPrimary : AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: selectedEventTime ?? const TimeOfDay(hour: 10, minute: 0),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedEventTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedEventTime != null
                                            ? '${selectedEventTime!.hour.toString().padLeft(2, '0')}:${selectedEventTime!.minute.toString().padLeft(2, '0')}'
                                            : 'בחר שעה',
                                        style: TextStyle(fontFamily: 'Heebo', color: selectedEventTime != null ? AppColors.textPrimary : AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('סוג אירוע', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filters.skip(1).map((f) {
                            final isSelected = selectedType == f['id'];
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedType = f['id'] as String),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(f['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(f['name'] as String, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (selectedType == 'other') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: otherTypeCtrl,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'Heebo'),
                            decoration: InputDecoration(
                              labelText: 'פרטי סוג האירוע *',
                              labelStyle: const TextStyle(fontFamily: 'Heebo'),
                              hintText: 'למשל: פיקניק משפחתי, מסיבת פורים...',
                              hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text('פרטי קשר ליצירת קשר מהמנהלת', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailCtrl,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontFamily: 'Heebo'),
                          decoration: InputDecoration(
                            labelText: 'אימייל *',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneCtrl,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontFamily: 'Heebo'),
                          decoration: InputDecoration(
                            labelText: 'טלפון *',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            hintText: '05X-XXXXXXX',
                            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('נא להזין שם אירוע', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                                );
                                return;
                              }
                              if (selectedType == 'other' && otherTypeCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('נא לפרט את סוג האירוע', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                                );
                                return;
                              }

                              // Validate email
                              final emailValue = emailCtrl.text.trim();
                              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (emailValue.isEmpty || !emailRegex.hasMatch(emailValue)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('נא להזין כתובת אימייל תקינה', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                                );
                                return;
                              }

                              // Validate Israeli phone number
                              final phoneValue = phoneCtrl.text.trim();
                              final phoneRegex = RegExp(r'^0(5[0-9])[- ]?\d{3}[- ]?\d{4}$');
                              if (phoneValue.isEmpty || !phoneRegex.hasMatch(phoneValue)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('נא להזין מספר טלפון ישראלי תקין (05X-XXXXXXX)', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                                );
                                return;
                              }

                              // Validate date
                              if (selectedEventDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('נא לבחור תאריך לאירוע', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error),
                                );
                                return;
                              }

                              // Get current user info for organizer
                              final user = appState.currentUser;
                              final userName = user?.fullName ?? '';
                              final userId = user?.id ?? '';

                              // Create event in Firestore
                              await fs.createEvent({
                                'title': titleCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'location': locationCtrl.text.trim(),
                                'type': selectedType == 'other' ? otherTypeCtrl.text.trim() : selectedType,
                                'organizer': userName,
                                'creatorEmail': emailValue,
                                'creatorPhone': phoneValue,
                                'creatorId': userId,
                                'creatorName': userName,
                                'status': 'pending',
                                'attendees': 0,
                                'maxAttendees': 50,
                                'date': DateTime(
                                  selectedEventDate!.year,
                                  selectedEventDate!.month,
                                  selectedEventDate!.day,
                                  selectedEventTime?.hour ?? 10,
                                  selectedEventTime?.minute ?? 0,
                                ),
                                'time': selectedEventTime != null
                                    ? '${selectedEventTime!.hour.toString().padLeft(2, '0')}:${selectedEventTime!.minute.toString().padLeft(2, '0')}'
                                    : '',
                              });

                              if (ctx.mounted) Navigator.pop(ctx);

                              // Show pending approval dialog
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 80, height: 80,
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.hourglass_top_rounded, size: 40, color: AppColors.accent),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text('האירוע נשלח לאישור!', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        Text('האירוע "${titleCtrl.text}" נשלח למנהל לאישור. תקבלי הודעה כשהאירוע יאושר.', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: const Text('הבנתי', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('שלחי לאישור', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show event detail bottom sheet from Firestore data.
  void _showEventDetailSheet(BuildContext context, Map<String, dynamic> event) {
    final attendees = (event['attendees'] as num?)?.toInt() ?? 0;
    final maxAttendees = (event['maxAttendees'] as num?)?.toInt() ?? 0;
    final hasAvailableSpots = maxAttendees == 0 || attendees < maxAttendees;
    final spotsLeft = maxAttendees == 0 ? 999 : maxAttendees - attendees;
    final price = (event['price'] as num?)?.toDouble() ?? 0;
    final isFree = price == 0;
    final isOnline = event['isOnline'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event['title'] ?? '',
                      style: const TextStyle(fontFamily: 'Heebo', fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(event['date']), style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(_formatTime(event), style: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint, fontSize: 13)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFree ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFree ? 'חינם' : '${price.toInt()} ש"ח',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.bold,
                              color: isFree ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    if ((event['location'] as String? ?? '').isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(isOnline ? Icons.videocam_rounded : Icons.location_on_outlined, size: 18, color: AppColors.textHint),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOnline ? 'אירוע מקוון' : (event['location'] ?? ''),
                              style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Organizer
                    if ((event['organizer'] as String? ?? '').isNotEmpty) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryLight,
                            child: const Icon(Icons.person, size: 16, color: AppColors.primaryDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'מארגנת: ${event['organizer']}',
                              style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Attendees
                    if (maxAttendees > 0) ...[
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 18, color: AppColors.textHint),
                          const SizedBox(width: 6),
                          Text(
                            '$attendees/$maxAttendees משתתפות',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 13,
                              color: spotsLeft < 5 ? AppColors.secondary : AppColors.textHint,
                              fontWeight: spotsLeft < 5 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (spotsLeft < 5 && spotsLeft > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'נותרו $spotsLeft מקומות!',
                              style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: maxAttendees > 0 ? (attendees / maxAttendees).clamp(0.0, 1.0) : 0,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    if ((event['description'] as String? ?? '').isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        event['description'],
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Register/Unregister button
                    Builder(
                      builder: (btnContext) {
                        final appState = Provider.of<AppState>(context, listen: false);
                        final currentUserId = appState.currentUser?.id ?? '';
                        final participantIds = List<String>.from(event['participantIds'] ?? []);
                        final isRegistered = participantIds.contains(currentUserId);

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isRegistered || hasAvailableSpots)
                                ? () async {
                                    HapticFeedback.mediumImpact();
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final fs = Provider.of<FirestoreService>(context, listen: false);

                                      if (isRegistered) {
                                        // Unregister
                                        await fs.updateEvent(event['id'], {
                                          'attendees': FieldValue.increment(-1),
                                          'participantIds': FieldValue.arrayRemove([currentUserId]),
                                        });
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('ביטלת הרשמה לאירוע "${event['title']}"', style: const TextStyle(fontFamily: 'Heebo')),
                                            backgroundColor: AppColors.info,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      } else {
                                        // Register
                                        await fs.updateEvent(event['id'], {
                                          'attendees': FieldValue.increment(1),
                                          'participantIds': FieldValue.arrayUnion([currentUserId]),
                                        });
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('נרשמת לאירוע "${event['title']}" בהצלחה!', style: const TextStyle(fontFamily: 'Heebo')),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('שגיאה: ${e.toString()}', style: const TextStyle(fontFamily: 'Heebo')),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRegistered ? AppColors.error : AppColors.primary,
                              disabledBackgroundColor: AppColors.surfaceVariant,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              isRegistered ? 'ביטול הרשמה' : (hasAvailableSpots ? 'הרשמה לאירוע' : 'האירוע מלא'),
                              style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
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
}

/// Event card widget for the list view - works with raw Firestore map data.
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final DateTime Function(dynamic) parseDate;
  final String Function(dynamic) formatDate;
  final String Function(Map<String, dynamic>) formatTime;

  const _EventCard({
    required this.event,
    required this.parseDate,
    required this.formatDate,
    required this.formatTime,
  });

  String _typeDisplayName(String type) {
    switch (type) {
      case 'playMeetup': return 'מפגש משחק';
      case 'workshop': return 'סדנה';
      case 'webinar': return 'וובינר';
      case 'womensEvening': return 'ערב נשים';
      case 'supportGroup': return 'קבוצת תמיכה';
      case 'classes': return 'חוג';
      default: return 'אחר';
    }
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'playMeetup': return '🧸';
      case 'workshop': return '🎨';
      case 'webinar': return '💻';
      case 'womensEvening': return '🍷';
      case 'supportGroup': return '💕';
      case 'classes': return '📚';
      default: return '📌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = event['title'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final organizer = event['organizer'] as String? ?? '';
    final description = event['description'] as String? ?? '';
    final imageUrl = event['imageUrl'] as String?;
    final eventType = event['type'] as String? ?? '';
    final isOnline = event['isOnline'] == true;
    final price = (event['price'] as num?)?.toDouble() ?? 0;
    final isFree = price == 0;
    final attendees = (event['attendees'] as num?)?.toInt() ?? 0;
    final maxAttendees = (event['maxAttendees'] as num?)?.toInt() ?? 0;
    final hasAvailableSpots = maxAttendees == 0 || attendees < maxAttendees;
    final spotsLeft = maxAttendees == 0 ? 999 : maxAttendees - attendees;

    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_EventsScreenState>();
        state?._showEventDetailSheet(context, event);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.event, size: 50),
                      ),
                    ),
                  ),
                  // Type Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_typeIcon(eventType), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            _typeDisplayName(eventType),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Online Badge
                  if (isOnline)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'מקוון',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip (shown when no image)
                  if (imageUrl == null || imageUrl.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_typeIcon(eventType), style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  _typeDisplayName(eventType),
                                  style: const TextStyle(fontFamily: 'Heebo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          if (isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('מקוון', style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date & Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(event['date']),
                            style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            formatTime(event),
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFree
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFree ? 'חינם' : '${price.toInt()} ש"ח',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontWeight: FontWeight.bold,
                            color: isFree ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location
                  if (!isOnline && location.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Host & Participants
                  Row(
                    children: [
                      // Host
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.person, size: 16, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          organizer.isNotEmpty ? 'מארגנת: $organizer' : '',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Participants
                      if (maxAttendees > 0) ...[
                        Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$attendees/$maxAttendees',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: spotsLeft < 5
                                ? AppColors.secondary
                                : AppColors.textHint,
                            fontWeight: spotsLeft < 5 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  Builder(
                    builder: (btnContext) {
                      final appState = Provider.of<AppState>(context, listen: false);
                      final currentUserId = appState.currentUser?.id ?? '';
                      final participantIds = List<String>.from(event['participantIds'] ?? []);
                      final isRegistered = participantIds.contains(currentUserId);

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isRegistered || hasAvailableSpots)
                              ? () async {
                                  HapticFeedback.mediumImpact();
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    final fs = Provider.of<FirestoreService>(context, listen: false);

                                    if (isRegistered) {
                                      await fs.updateEvent(event['id'], {
                                        'attendees': FieldValue.increment(-1),
                                        'participantIds': FieldValue.arrayRemove([currentUserId]),
                                      });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('ביטלת הרשמה לאירוע "$title"', style: const TextStyle(fontFamily: 'Heebo')),
                                          backgroundColor: AppColors.info,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    } else {
                                      await fs.updateEvent(event['id'], {
                                        'attendees': FieldValue.increment(1),
                                        'participantIds': FieldValue.arrayUnion([currentUserId]),
                                      });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('נרשמת לאירוע "$title" בהצלחה!', style: const TextStyle(fontFamily: 'Heebo')),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('שגיאה: ${e.toString()}', style: const TextStyle(fontFamily: 'Heebo')),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered ? AppColors.error : AppColors.primary,
                            disabledBackgroundColor: AppColors.surfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isRegistered ? 'ביטול הרשמה' : (hasAvailableSpots ? 'הרשמה לאירוע' : 'האירוע מלא'),
                            style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
