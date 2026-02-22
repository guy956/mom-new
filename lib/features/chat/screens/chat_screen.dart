import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/widgets/empty_state_widgets.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';

/// Chat screen with DMs, groups, and search - all connected to Firestore
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

  String get _currentUserId {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.currentUser?.id ?? '';
  }

  String get _currentUserName {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.currentUser?.fullName ?? 'משתמשת';
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final msg = (item['lastMessage'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || msg.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
        tabs: const [
          Tab(text: 'הכל'),
          Tab(text: 'קבוצות'),
          Tab(text: 'פרטי'),
        ],
      ),
    );
  }

  // ── All Tab: merges DMs + Groups from Firestore ──

  Widget _buildAllTab() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final userId = _currentUserId;
    if (userId.isEmpty) return _buildEmptyState();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.dmConversationsStream(userId),
      builder: (context, dmSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: fs.chatGroupsStream,
          builder: (context, groupSnap) {
            if (dmSnap.connectionState == ConnectionState.waiting &&
                groupSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final dms = (dmSnap.data ?? []).map((dm) {
              final names = Map<String, dynamic>.from(dm['participantNames'] ?? {});
              final avatars = Map<String, dynamic>.from(dm['participantAvatars'] ?? {});
              final otherUserId = (List<String>.from(dm['participants'] ?? []))
                  .firstWhere((p) => p != userId, orElse: () => '');
              return <String, dynamic>{
                'id': dm['id'],
                'name': names[otherUserId] ?? 'משתמשת',
                'avatar': avatars[otherUserId],
                'lastMessage': dm['lastMessage'] ?? '',
                'time': _formatTimestamp(dm['lastMessageAt']),
                'unread': 0,
                'isOnline': false,
                'isGroup': false,
                'conversationId': dm['id'],
              };
            }).toList();

            final groups = (groupSnap.data ?? [])
                .where((g) => g['status'] == 'approved')
                .where((g) {
                  final members = g['members'];
                  if (members is List) return members.contains(userId);
                  return true; // Show if no members list (legacy)
                })
                .map((g) => <String, dynamic>{
                      'id': g['id'] ?? '',
                      'name': g['name'] ?? 'קבוצה',
                      'avatar': null,
                      'emoji': g['emoji'] ?? '👥',
                      'lastMessage': g['lastMessage'] ?? g['description'] ?? '',
                      'time': _formatTimestamp(g['lastMessageAt'] ?? g['updatedAt']),
                      'unread': 0,
                      'members': g['memberCount'] ?? 0,
                      'isGroup': true,
                    })
                .toList();

            final all = [...dms, ...groups];
            final filtered = _filterList(all);

            if (filtered.isEmpty && _searchQuery.isNotEmpty) {
              return _buildNoResults();
            }
            if (all.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildChatTile(filtered[index]),
            );
          },
        );
      },
    );
  }

  // ── Groups Tab: from Firestore ──

  Widget _buildGroupsTab() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final userId = _currentUserId;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.chatGroupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = (snapshot.data ?? [])
            .where((g) => g['status'] == 'approved')
            .where((g) {
              final members = g['members'];
              if (members is List) return members.contains(userId);
              return true;
            })
            .map((g) => <String, dynamic>{
                  'id': g['id'] ?? '',
                  'name': g['name'] ?? 'קבוצה',
                  'avatar': null,
                  'emoji': g['emoji'] ?? '👥',
                  'lastMessage': g['lastMessage'] ?? g['description'] ?? '',
                  'time': _formatTimestamp(g['lastMessageAt'] ?? g['updatedAt']),
                  'unread': 0,
                  'members': g['memberCount'] ?? 0,
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

  // ── Private Tab: DMs from Firestore ──

  Widget _buildPrivateTab() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final userId = _currentUserId;
    if (userId.isEmpty) return _buildEmptyState(isPrivate: true);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.dmConversationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final conversations = (snapshot.data ?? []).map((dm) {
          final names = Map<String, dynamic>.from(dm['participantNames'] ?? {});
          final avatars = Map<String, dynamic>.from(dm['participantAvatars'] ?? {});
          final otherUserId = (List<String>.from(dm['participants'] ?? []))
              .firstWhere((p) => p != userId, orElse: () => '');
          return <String, dynamic>{
            'id': dm['id'],
            'name': names[otherUserId] ?? 'משתמשת',
            'avatar': avatars[otherUserId],
            'lastMessage': dm['lastMessage'] ?? '',
            'time': _formatTimestamp(dm['lastMessageAt']),
            'unread': 0,
            'isOnline': false,
            'isGroup': false,
            'conversationId': dm['id'],
          };
        }).toList();

        final filtered = _filterList(conversations);
        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResults();
        }
        if (conversations.isEmpty) {
          return _buildEmptyState(isPrivate: true);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildChatTile(filtered[index]),
        );
      },
    );
  }

  // ── Shared tile builder ──

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final isGroup = chat['isGroup'] == true;
    final unread = (chat['unread'] ?? 0) as int;

    return Dismissible(
      key: Key(chat['id'] ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await context.showConfirmDialog(
          title: isGroup ? 'עזיבת קבוצה' : 'מחיקת שיחה',
          message: isGroup
              ? 'לעזוב את הקבוצה ${chat['name']}?'
              : 'למחוק את השיחה עם ${chat['name']}?',
          confirmText: isGroup ? 'עזוב' : 'מחק',
          cancelText: 'ביטול',
          icon: isGroup ? Icons.exit_to_app_rounded : Icons.delete_outline_rounded,
          isDestructive: true,
        );
      },
      onDismissed: (_) {
        final fs = Provider.of<FirestoreService>(context, listen: false);
        if (isGroup) {
          // Leave group instead of deleting for everyone
          fs.leaveChatGroup(chat['id'], _currentUserId);
        } else {
          fs.deleteDirectMessage(chat['id']);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isGroup ? 'עזבת את הקבוצה ${chat['name']}' : 'השיחה עם ${chat['name']} נמחקה',
                style: const TextStyle(fontFamily: 'Heebo')),
          ),
        );
      },
      child: InkWell(
        onTap: () => _openChat(chat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: unread > 0
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  if (isGroup)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(chat['emoji'] ?? '👥',
                              style: const TextStyle(fontSize: 24))),
                    )
                  else
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: chat['avatar'] != null
                          ? NetworkImage(chat['avatar'])
                          : null,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: chat['avatar'] == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                  if (!isGroup && chat['isOnline'] == true)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
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
                            chat['name'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: unread > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          chat['time'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: unread > 0
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 13,
                              color: unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  unread > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        if (isGroup) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${chat['members'] ?? 0}',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 11,
                                color: AppColors.textHint),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatConversationSheet(
        chat: chat,
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
      ),
    );
  }

  Widget _buildEmptyState({bool isGroups = false, bool isPrivate = false}) {
    if (isGroups) {
      return EnhancedEmptyState(
        icon: Icons.group_outlined,
        title: 'אין קבוצות עדיין',
        subtitle:
            'הצטרפי לקבוצות באפליקציה או צרי קבוצה חדשה כדי להתחיל לשוחח',
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

  // ── New chat sheet ──

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
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('שיחה חדשה',
                style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.person_add, color: AppColors.primary),
              ),
              title: const Text('שיחה פרטית',
                  style: TextStyle(
                      fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
              subtitle: const Text('שלחי הודעה לאמא מהקהילה',
                  style: TextStyle(fontFamily: 'Heebo')),
              onTap: () {
                Navigator.pop(context);
                _startNewPrivateChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.group_add, color: AppColors.accent),
              ),
              title: const Text('קבוצה חדשה',
                  style: TextStyle(
                      fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
              subtitle: const Text('צרי קבוצת שיחה עם מספר אמהות',
                  style: TextStyle(fontFamily: 'Heebo')),
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

  // ── Start new private chat (pick a user from Firestore) ──

  void _startNewPrivateChat() {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final userId = _currentUserId;
    final userName = _currentUserName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('בחרי משתמשת',
                      style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = (snapshot.data ?? [])
                      .where((u) =>
                          u['id'] != userId &&
                          (u['status'] == 'active' || u['status'] == 'approved'))
                      .toList();
                  if (users.isEmpty) {
                    return const Center(
                        child: Text('אין משתמשות זמינות',
                            style: TextStyle(fontFamily: 'Heebo')));
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImage'] != null &&
                                  (user['profileImage'] as String).isNotEmpty
                              ? NetworkImage(user['profileImage'])
                              : null,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: user['profileImage'] == null ||
                                  (user['profileImage'] as String).isEmpty
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        title: Text(
                          user['fullName'] ?? user['email'] ?? 'משתמשת',
                          style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user['city'] ?? '',
                          style: TextStyle(
                              fontFamily: 'Heebo',
                              color: AppColors.textSecondary),
                        ),
                        onTap: () async {
                          Navigator.pop(sheetCtx);
                          try {
                            final fromAvatar = context.read<AppState>().currentUser?.profileImage;
                            final convId = await fs.createDirectMessage(
                              fromUserId: userId,
                              fromUserName: userName,
                              toUserId: user['id'],
                              toUserName:
                                  user['fullName'] ?? user['email'] ?? 'משתמשת',
                              fromAvatar: fromAvatar,
                              toAvatar: user['profileImage'],
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'שיחה עם ${user['fullName'] ?? 'משתמשת'} נוצרה',
                                      style:
                                          const TextStyle(fontFamily: 'Heebo')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              // Open the conversation
                              _openChat({
                                'id': convId,
                                'name':
                                    user['fullName'] ?? user['email'] ?? 'משתמשת',
                                'avatar': user['profileImage'],
                                'lastMessage': '',
                                'time': 'עכשיו',
                                'unread': 0,
                                'isOnline': false,
                                'isGroup': false,
                                'conversationId': convId,
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackbar.error(
                                  context, 'שגיאה ביצירת שיחה: $e');
                            }
                          }
                        },
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

  // ── Create new group (writes to Firestore) ──

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('יצירת קבוצה חדשה',
              style: TextStyle(
                  fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'שם הקבוצה',
                    hintText: 'למשל: אמהות תל אביב',
                    hintStyle: TextStyle(
                        fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'תיאור הקבוצה',
                    hintText: 'על מה הקבוצה?',
                    hintStyle: TextStyle(
                        fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'פרטי יצירת הקבוצה',
                              style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'נדרש לאימות מנהל בלבד - לא יוצג למשתמשות',
                        style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'אימייל ליצירת קשר',
                    hintText: 'name@example.com',
                    hintStyle: TextStyle(
                        fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'טלפון ליצירת קשר',
                    hintText: '05X-XXXXXXX',
                    hintStyle: TextStyle(
                        fontFamily: 'Heebo', color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('ביטול',
                  style: TextStyle(fontFamily: 'Heebo')),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        AppSnackbar.error(context, 'נא להזין שם קבוצה');
                        return;
                      }
                      if (descriptionController.text.trim().isEmpty) {
                        AppSnackbar.error(context, 'נא להזין תיאור קבוצה');
                        return;
                      }
                      if (emailController.text.trim().isEmpty) {
                        AppSnackbar.error(
                            context, 'נא להזין אימייל ליצירת קשר');
                        return;
                      }
                      if (phoneController.text.trim().isEmpty) {
                        AppSnackbar.error(
                            context, 'נא להזין טלפון ליצירת קשר');
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final appState =
                            Provider.of<AppState>(context, listen: false);
                        final currentUser = appState.currentUser;

                        if (currentUser == null) {
                          AppSnackbar.error(context, 'משתמש לא מחובר');
                          setDialogState(() => isLoading = false);
                          return;
                        }

                        final firestoreService =
                            Provider.of<FirestoreService>(context,
                                listen: false);

                        await firestoreService.createChatGroup(
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          creatorId: currentUser.id,
                          creatorName: currentUser.fullName ?? 'משתמש',
                          creatorEmail: emailController.text.trim(),
                          creatorPhone: phoneController.text.trim(),
                        );

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(this.context).showSnackBar(
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
                        AppSnackbar.error(
                            context, 'שגיאה ביצירת הקבוצה: ${e.toString()}');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('יצירת קבוצה',
                      style: TextStyle(
                          fontFamily: 'Heebo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק\'';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 2) return 'אתמול';
    return '${dt.day}/${dt.month}';
  }
}

/// Chat conversation sheet - connected to Firestore messages
class _ChatConversationSheet extends StatefulWidget {
  final Map<String, dynamic> chat;
  final String currentUserId;
  final String currentUserName;

  const _ChatConversationSheet({
    required this.chat,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_ChatConversationSheet> createState() => _ChatConversationSheetState();
}

class _ChatConversationSheetState extends State<_ChatConversationSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool get _isGroup => widget.chat['isGroup'] == true;
  String get _chatId => widget.chat['id'] ?? '';

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
    final fs = Provider.of<FirestoreService>(context, listen: false);

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                if (_isGroup)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(widget.chat['emoji'] ?? '👥',
                            style: const TextStyle(fontSize: 20))),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.chat['avatar'] != null
                        ? NetworkImage(widget.chat['avatar'])
                        : null,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.2),
                    child: widget.chat['avatar'] == null
                        ? const Icon(Icons.person,
                            color: AppColors.primary, size: 20)
                        : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.chat['name'] ?? '',
                          style: const TextStyle(
                              fontFamily: 'Heebo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (_isGroup)
                        Text('${widget.chat['members'] ?? 0} חברות',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                color: AppColors.textSecondary))
                      else if (widget.chat['isOnline'] == true)
                        const Text('מחוברת',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Messages from Firestore
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _isGroup
                  ? fs.groupMessagesStream(_chatId)
                  : fs.dmMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textHint.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('אין הודעות עדיין',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                color: AppColors.textHint)),
                        const SizedBox(height: 4),
                        Text('שלחי הודעה ראשונה!',
                            style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 13,
                                color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMe = msg['senderId'] == widget.currentUserId;
                    final time = _formatMsgTime(msg['createdAt']);
                    return Align(
                      alignment:
                          isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
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
                            if (_isGroup && !isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg['senderName'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Heebo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 15,
                                color: isMe
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        hintStyle: TextStyle(
                            fontFamily: 'Heebo',
                            color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    final text = _messageController.text.trim();
    _messageController.clear();

    final fs = Provider.of<FirestoreService>(context, listen: false);
    try {
      if (_isGroup) {
        await fs.sendGroupMessage(
          groupId: _chatId,
          senderId: widget.currentUserId,
          senderName: widget.currentUserName,
          text: text,
        );
      } else {
        await fs.sendDirectMessage(
          conversationId: _chatId,
          senderId: widget.currentUserId,
          text: text,
        );
      }
      _scrollToBottom();
    } catch (e) {
      // Restore the text so user doesn't lose their message
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שליחת ההודעה נכשלה. נסי שנית.', style: TextStyle(fontFamily: 'Heebo'))),
        );
      }
    }
  }

  String _formatMsgTime(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    } else {
      return '';
    }
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
