import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/widgets/empty_state_widgets.dart';
import 'package:mom_connect/core/widgets/loading_widgets.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';

/// מסך צ'אט - עם שיחות, קבוצות וחיפוש פונקציונלי
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Demo conversations
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'מיכל לוין',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'lastMessage': 'תודה רבה על העצה, עזרת לי מאוד',
      'time': 'לפני 5 דק\'',
      'unread': 2,
      'isOnline': true,
      'isGroup': false,
    },
    {
      'id': '2',
      'name': 'נועה ישראלי',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'lastMessage': 'את יכולה לשלוח לי את הלינק?',
      'time': 'לפני 15 דק\'',
      'unread': 0,
      'isOnline': true,
      'isGroup': false,
    },
    {
      'id': '3',
      'name': 'שרה כהן',
      'avatar': 'https://i.pravatar.cc/150?img=16',
      'lastMessage': 'נתראה מחר באירוע! 🎉',
      'time': 'לפני שעה',
      'unread': 1,
      'isOnline': false,
      'isGroup': false,
    },
    {
      'id': '4',
      'name': 'רחלי אברהם',
      'avatar': 'https://i.pravatar.cc/150?img=20',
      'lastMessage': 'הגעתי עכשיו עם התינוק, תבואי!',
      'time': 'לפני 2 שעות',
      'unread': 0,
      'isOnline': false,
      'isGroup': false,
    },
  ];

  final List<Map<String, dynamic>> _groups = [
    {
      'id': 'g1',
      'name': 'אמהות ת"א מרכז',
      'avatar': null,
      'emoji': '🏙️',
      'lastMessage': 'מיכל: מישהי מכירה גן טוב בקרבת כיכר רבין?',
      'time': 'לפני 10 דק\'',
      'unread': 5,
      'members': 48,
      'isGroup': true,
    },
    {
      'id': 'g2',
      'name': 'הריון ולידה',
      'avatar': null,
      'emoji': '🤰',
      'lastMessage': 'נועה: בהצלחה מחר! מחכות לבשורות טובות',
      'time': 'לפני 30 דק\'',
      'unread': 12,
      'members': 156,
      'isGroup': true,
    },
    {
      'id': 'g3',
      'name': 'מתכונים לתינוקות',
      'avatar': null,
      'emoji': '🍼',
      'lastMessage': 'שרה: ניסיתי את המרק דלעת - מעולה!',
      'time': 'לפני 3 שעות',
      'unread': 0,
      'members': 89,
      'isGroup': true,
    },
    {
      'id': 'g4',
      'name': 'טיולים עם ילדים',
      'avatar': null,
      'emoji': '🌳',
      'lastMessage': 'רחלי: מישהי הייתה בשמורת עין גדי עם תינוק?',
      'time': 'אתמול',
      'unread': 0,
      'members': 67,
      'isGroup': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allChats =>
      [..._conversations, ..._groups]..sort((a, b) => 
        (b['unread'] as int).compareTo(a['unread'] as int));

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) {
      final name = (item['name'] as String).toLowerCase();
      final msg = (item['lastMessage'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || msg.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh - in real app would refresh from server
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {});
          AppSnackbar.success(context, 'הרשימה עודכנה');
        },
        color: AppColors.primary,
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearching) _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildGroupsTab(),
                  _buildPrivateTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'הודעות',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Heebo'),
        decoration: InputDecoration(
          hintText: 'חיפוש שיחות...',
          hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('הכל'),
                if (_allChats.where((c) => (c['unread'] as int) > 0).isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_allChats.fold<int>(0, (sum, c) => sum + (c['unread'] as int))}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'קבוצות'),
          const Tab(text: 'פרטי'),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    final filtered = _filterList(_allChats);
    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResults();
    }
    if (_allChats.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildChatTile(filtered[index]),
    );
  }

  Widget _buildGroupsTab() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.chatGroupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = (snapshot.data ?? [])
            .where((g) => g['status'] == 'approved')
            .map((g) => {
                  'id': g['id'] ?? '',
                  'name': g['name'] ?? 'קבוצה',
                  'avatar': null,
                  'emoji': g['emoji'] ?? '👥',
                  'lastMessage': g['description'] ?? '',
                  'time': '',
                  'unread': 0,
                  'members': g['membersCount'] ?? 0,
                  'isGroup': true,
                })
            .toList();
        final filtered = _searchQuery.isEmpty
            ? groups
            : groups.where((g) {
                final name = (g['name'] as String).toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();
        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResults();
        }
        if (groups.isEmpty) {
          return _buildEmptyState(isGroups: true);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildChatTile(filtered[index]),
        );
      },
    );
  }

  Widget _buildPrivateTab() {
    final filtered = _filterList(_conversations);
    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResults();
    }
    if (_conversations.isEmpty) {
      return _buildEmptyState(isPrivate: true);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildChatTile(filtered[index]),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final isGroup = chat['isGroup'] as bool;
    final unread = chat['unread'] as int;

    return Dismissible(
      key: Key(chat['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await context.showConfirmDialog(
          title: 'מחיקת שיחה',
          message: 'למחוק את השיחה עם ${chat['name']}?',
          confirmText: 'מחק',
          cancelText: 'ביטול',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        );
      },
      onDismissed: (_) {
        setState(() {
          if (isGroup) {
            _groups.removeWhere((g) => g['id'] == chat['id']);
          } else {
            _conversations.removeWhere((c) => c['id'] == chat['id']);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('השיחה עם ${chat['name']} נמחקה', style: const TextStyle(fontFamily: 'Heebo')),
            action: SnackBarAction(label: 'ביטול', onPressed: () {
              setState(() {
                if (isGroup) {
                  _groups.add(chat);
                } else {
                  _conversations.add(chat);
                }
              });
            }),
          ),
        );
      },
      child: InkWell(
        onTap: () => _openChat(chat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: unread > 0 ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  if (isGroup)
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(chat['emoji'] ?? '👥', style: const TextStyle(fontSize: 24))),
                    )
                  else
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: chat['avatar'] != null ? NetworkImage(chat['avatar']) : null,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: chat['avatar'] == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                    ),
                  if (!isGroup && chat['isOnline'] == true)
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'],
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: unread > 0 ? AppColors.primary : AppColors.textHint,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 13,
                              color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        if (isGroup) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${chat['members']}',
                            style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.people, size: 12, color: AppColors.textHint),
                        ],
                      ],
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

  void _openChat(Map<String, dynamic> chat) {
    // Mark as read
    setState(() {
      chat['unread'] = 0;
    });

    // Open chat conversation sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatConversationSheet(chat: chat),
    );
  }

  Widget _buildEmptyState({bool isGroups = false, bool isPrivate = false}) {
    if (isGroups) {
      return EnhancedEmptyState(
        icon: Icons.group_outlined,
        title: 'אין קבוצות עדיין',
        subtitle: 'הצטרפי לקבוצות באפליקציה או צרי קבוצה חדשה כדי להתחיל לשוחח',
        buttonText: 'צרי קבוצה',
        onButtonPressed: () => _showNewChatSheet(),
        iconColor: AppColors.accent,
      );
    } else if (isPrivate) {
      return EnhancedEmptyState(
        icon: Icons.person_outline,
        title: 'אין שיחות פרטיות',
        subtitle: 'שלחי הודעה לאמא מהקהילה כדי להתחיל שיחה',
        buttonText: 'התחילי שיחה',
        onButtonPressed: () => _showNewChatSheet(),
        iconColor: AppColors.primary,
      );
    }
    
    return EnhancedEmptyState.messages(
      onStartChat: () => _showNewChatSheet(),
    );
  }

  Widget _buildNoResults() {
    return EnhancedEmptyState.search(
      query: _searchQuery,
      onClearSearch: () {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
      },
    );
  }

  void _showNewChatSheet() {
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
            const Text('שיחה חדשה', style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person_add, color: AppColors.primary),
              ),
              title: const Text('שיחה פרטית', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
              subtitle: const Text('שלחי הודעה לאמא מהקהילה', style: TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(context);
                _startNewPrivateChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.group_add, color: AppColors.accent),
              ),
              title: const Text('קבוצה חדשה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
              subtitle: const Text('צרי קבוצת שיחה עם מספר אמהות', style: TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(context);
                _createNewGroup();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startNewPrivateChat() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('שיחה פרטית חדשה', style: TextStyle(fontFamily: 'Heebo')),
        content: TextField(
          controller: nameController,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            hintText: 'הקלידי שם של אמא מהקהילה',
            hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _conversations.insert(0, {
                    'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameController.text,
                    'avatar': null,
                    'lastMessage': 'שיחה חדשה - שלחי הודעה ראשונה!',
                    'time': 'עכשיו',
                    'unread': 0,
                    'isOnline': false,
                    'isGroup': false,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('שיחה עם ${nameController.text} נוצרה', style: const TextStyle(fontFamily: 'Heebo')),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('התחלת שיחה', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _createNewGroup() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('יצירת קבוצה חדשה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'שם הקבוצה',
                    hintText: 'למשל: אמהות תל אביב',
                    hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Group Description
                TextField(
                  controller: descriptionController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'תיאור הקבוצה',
                    hintText: 'על מה הקבוצה?',
                    hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Admin verification info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'פרטי יצירת הקבוצה',
                              style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'נדרש לאימות מנהל בלבד - לא יוצג למשתמשות',
                        style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextField(
                  controller: emailController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'אימייל ליצירת קשר',
                    hintText: 'your@email.com',
                    hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'טלפון ליצירת קשר',
                    hintText: '050-1234567',
                    hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                // Validate fields
                if (nameController.text.trim().isEmpty) {
                  AppSnackbar.error(context, 'נא להזין שם קבוצה');
                  return;
                }
                if (descriptionController.text.trim().isEmpty) {
                  AppSnackbar.error(context, 'נא להזין תיאור קבוצה');
                  return;
                }
                if (emailController.text.trim().isEmpty) {
                  AppSnackbar.error(context, 'נא להזין אימייל ליצירת קשר');
                  return;
                }
                if (phoneController.text.trim().isEmpty) {
                  AppSnackbar.error(context, 'נא להזין טלפון ליצירת קשר');
                  return;
                }

                // Show loading
                setDialogState(() => isLoading = true);

                try {
                  // Get current user info
                  final appState = Provider.of<AppState>(context, listen: false);
                  final currentUser = appState.currentUser;

                  if (currentUser == null) {
                    AppSnackbar.error(context, 'משתמש לא מחובר');
                    setDialogState(() => isLoading = false);
                    return;
                  }

                  // Get FirestoreService
                  final firestoreService = Provider.of<FirestoreService>(context, listen: false);

                  // Create chat group in Firestore
                  final groupId = await firestoreService.createChatGroup(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    creatorId: currentUser.id,
                    creatorName: currentUser.fullName ?? 'משתמש',
                    creatorEmail: emailController.text.trim(),
                    creatorPhone: phoneController.text.trim(),
                  );

                  // Add to local list for immediate UI update
                  setState(() {
                    _groups.insert(0, {
                      'id': groupId,
                      'name': nameController.text.trim(),
                      'avatar': null,
                      'emoji': '💬',
                      'lastMessage': 'קבוצה חדשה נוצרה! ממתינה לאישור מנהל',
                      'time': 'עכשיו',
                      'unread': 0,
                      'members': 1,
                      'isGroup': true,
                    });
                  });

                  // Close dialog
                  Navigator.pop(ctx);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'הקבוצה "${nameController.text}" נוצרה בהצלחה!\nהקבוצה ממתינה לאישור מנהל ותהיה זמינה בקרוב.',
                        style: const TextStyle(fontFamily: 'Heebo'),
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  AppSnackbar.error(context, 'שגיאה ביצירת הקבוצה: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('יצירת קבוצה', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat conversation sheet - simulated chat interface
class _ChatConversationSheet extends StatefulWidget {
  final Map<String, dynamic> chat;
  const _ChatConversationSheet({required this.chat});

  @override
  State<_ChatConversationSheet> createState() => _ChatConversationSheetState();
}

class _ChatConversationSheetState extends State<_ChatConversationSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Demo messages
    _messages.addAll([
      {'text': 'היי! מה שלומך?', 'isMe': false, 'time': '10:30'},
      {'text': 'היי! הכל טוב תודה, ואצלך?', 'isMe': true, 'time': '10:31'},
      {'text': widget.chat['lastMessage'], 'isMe': false, 'time': '10:35'},
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                if (widget.chat['isGroup'] == true)
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(widget.chat['emoji'] ?? '👥', style: const TextStyle(fontSize: 20))),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.chat['avatar'] != null ? NetworkImage(widget.chat['avatar']) : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: widget.chat['avatar'] == null ? const Icon(Icons.person, color: AppColors.primary, size: 20) : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.chat['name'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                      if (widget.chat['isGroup'] == true)
                        Text('${widget.chat['members']} חברות', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary))
                      else if (widget.chat['isOnline'] == true)
                        const Text('מחוברת', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 4 : 16),
                        bottomRight: Radius.circular(isMe ? 16 : 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 15,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 10,
                            color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Heebo'),
                      decoration: InputDecoration(
                        hintText: 'כתבי הודעה...',
                        hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isMe': true,
        'time': '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      });
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate reply after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final replies = [
          'מעניין, ספרי עוד',
          'לגמרי מסכימה!',
          'תודה על השיתוף',
          'איזה כיף! 🎉',
          'אני גם חושבת ככה',
          'מעולה! 👏',
        ];
        setState(() {
          _messages.add({
            'text': replies[DateTime.now().second % replies.length],
            'isMe': false,
            'time': '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
          });
        });
        _scrollToBottom();
      }
    });
  }
}
