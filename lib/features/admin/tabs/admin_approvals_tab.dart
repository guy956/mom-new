import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/rbac_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/services/notification_service.dart';

/// Content Approvals Tab - Shows all pending content for admin approval
class AdminApprovalsTab extends StatefulWidget {
  const AdminApprovalsTab({super.key});

  @override
  State<AdminApprovalsTab> createState() => _AdminApprovalsTabState();
}

class _AdminApprovalsTabState extends State<AdminApprovalsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedType = 'all';

  final List<Map<String, dynamic>> _contentTypes = [
    {'id': 'all', 'name': 'הכל', 'icon': Icons.dashboard_rounded},
    {'id': 'events', 'name': 'אירועים', 'icon': Icons.event_rounded},
    {'id': 'posts', 'name': 'פוסטים', 'icon': Icons.article_rounded},
    {'id': 'marketplace', 'name': 'מסירות', 'icon': Icons.store_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _approveContent(String collection, String itemId, String title, String type) async {
    // Check permission before allowing approval
    final rbac = RbacService.instance;
    if (!rbac.hasPermission(Permission.approveContent)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('אין לך הרשאות לאשר תוכן', style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get the full content data BEFORE updating
      DocumentSnapshot? contentDoc;
      try {
        contentDoc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(itemId)
            .get();
      } catch (e) {
        debugPrint('[AdminApprovalsTab] Error fetching content data: $e');
      }

      if (contentDoc == null || !contentDoc.exists) {
        throw Exception('התוכן לא נמצא במאגר');
      }

      final contentData = contentDoc.data() as Map<String, dynamic>? ?? {};

      // Update status directly in Firestore with proper field mapping
      if (collection == 'events') {
        await FirebaseFirestore.instance.collection('events').doc(itemId).update({
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        });

        // Notify all users about the new event
        try {
          final notificationService = NotificationService();
          await notificationService.notifyAllUsersNewEvent(
            eventId: itemId,
            eventTitle: title,
            eventData: contentData,
          );
        } catch (e) {
          debugPrint('[AdminApprovalsTab] Error notifying users about event: $e');
        }
      } else if (collection == 'marketplace') {
        await FirebaseFirestore.instance.collection('marketplace').doc(itemId).update({
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        });

        // Notify all users about the new marketplace item
        try {
          final notificationService = NotificationService();
          await notificationService.notifyAllUsersNewMarketplaceItem(
            itemId: itemId,
            itemTitle: title,
            itemData: contentData,
          );
        } catch (e) {
          debugPrint('[AdminApprovalsTab] Error notifying users about marketplace item: $e');
        }
      } else if (collection == 'posts') {
        await FirebaseFirestore.instance.collection('posts').doc(itemId).update({
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        });

        // Notify all users about the new post
        try {
          final notificationService = NotificationService();
          await notificationService.notifyAllUsersNewPost(
            postId: itemId,
            postContent: title,
            postData: contentData,
          );
        } catch (e) {
          debugPrint('[AdminApprovalsTab] Error notifying users about post: $e');
        }
      } else if (collection == 'chatGroups') {
        await FirebaseFirestore.instance.collection('chatGroups').doc(itemId).update({
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log activity
      final userData = await AuthService.instance.getSavedSession();
      final userName = userData?['fullName'] ?? 'Admin';
      await FirebaseFirestore.instance.collection('activity_log').add({
        'action': 'אישר $type: $title',
        'user': userName,
        'userId': userData?['id'] ?? '',
        'type': 'approval',
        'targetId': itemId,
        'targetCollection': collection,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type אושר בהצלחה ומופיע עכשיו באפליקציה ובאתר ✓', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: const Color(0xFFB5C8B9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AdminApprovalsTab] Error approving content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה באישור: ${e.toString()}', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: const Color(0xFFD4A3A3),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _rejectContent(String collection, String itemId, String title, String type) async {
    // Check permission before allowing rejection
    final rbac = RbacService.instance;
    if (!rbac.hasPermission(Permission.approveContent)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('אין לך הרשאות לדחות תוכן', style: TextStyle(fontFamily: 'Heebo')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('דחיית תוכן', style: TextStyle(fontFamily: 'Heebo')),
        content: Text('האם לדחות את $type "$title"?', style: const TextStyle(fontFamily: 'Heebo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A3A3)),
            child: const Text('דחה', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update status to rejected directly in Firestore
      if (collection == 'events') {
        await FirebaseFirestore.instance.collection('events').doc(itemId).update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      } else if (collection == 'marketplace') {
        await FirebaseFirestore.instance.collection('marketplace').doc(itemId).update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      } else if (collection == 'posts') {
        await FirebaseFirestore.instance.collection('posts').doc(itemId).update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      } else if (collection == 'chatGroups') {
        await FirebaseFirestore.instance.collection('chatGroups').doc(itemId).update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log activity
      final userData = await AuthService.instance.getSavedSession();
      final userName = userData?['fullName'] ?? 'Admin';
      await FirebaseFirestore.instance.collection('activity_log').add({
        'action': 'דחה $type: $title',
        'user': userName,
        'userId': userData?['id'] ?? '',
        'type': 'rejection',
        'targetId': itemId,
        'targetCollection': collection,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type נדחה ולא יופיע באפליקציה ובאתר ✓', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: const Color(0xFFD4A3A3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AdminApprovalsTab] Error rejecting content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בדחייה: ${e.toString()}', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: const Color(0xFFD4A3A3),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.approval_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'אישורים',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF43363A),
                          ),
                        ),
                        Text(
                          'אישור ודחייה של תוכן ממשתמשות',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Type filters
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _contentTypes.length,
                  itemBuilder: (context, index) {
                    final type = _contentTypes[index];
                    final isSelected = _selectedType == type['id'];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = type['id'] as String);
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'ממתינים לאישור'),
              Tab(text: 'טופלו'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingContent(),
              _buildProcessedContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingContent() {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      stream: _getAllPendingContent(fs),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFD4A3A3)),
                const SizedBox(height: 16),
                Text(
                  'שגיאה בטעינת התוכן',
                  style: TextStyle(fontFamily: 'Heebo', color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final allItems = _combineAndFilterItems(data);

        if (allItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5C8B9).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFFB5C8B9)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'אין תוכן ממתין לאישור',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'כל התוכן נבדק ואושר',
                  style: TextStyle(fontFamily: 'Heebo', color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              return _buildContentCard(allItems[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildProcessedContent() {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      stream: _getAllProcessedContent(fs),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFD4A3A3)),
                const SizedBox(height: 16),
                Text(
                  'שגיאה בטעינת התוכן',
                  style: TextStyle(fontFamily: 'Heebo', color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final allItems = _combineAndFilterItems(data);

        if (allItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'אין תוכן מעובד',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            return _buildContentCard(allItems[index], isProcessed: true);
          },
        );
      },
    );
  }

  Stream<Map<String, List<Map<String, dynamic>>>> _getAllPendingContent(FirestoreService fs) {
    return fs.eventsStream.map((events) {
      final pending = events.where((e) => (e['status'] ?? 'pending') == 'pending').toList();
      return {'events': pending};
    }).asyncExpand((eventData) {
      return fs.postsStream.map((posts) {
        final pending = posts.where((p) => (p['status'] ?? 'pending') == 'pending').toList();
        return {...eventData, 'posts': pending};
      });
    }).asyncExpand((combined) {
      return fs.marketplaceStream.map((items) {
        final pending = items.where((i) => (i['status'] ?? 'pending') == 'pending').toList();
        return {...combined, 'marketplace': pending};
      });
    });
  }

  Stream<Map<String, List<Map<String, dynamic>>>> _getAllProcessedContent(FirestoreService fs) {
    return fs.eventsStream.map((events) {
      final processed = events.where((e) {
        final status = (e['status'] ?? 'pending').toString();
        return status == 'approved' || status == 'rejected';
      }).toList();
      return {'events': processed};
    }).asyncExpand((eventData) {
      return fs.postsStream.map((posts) {
        final processed = posts.where((p) {
          final status = (p['status'] ?? 'pending').toString();
          return status == 'approved' || status == 'rejected';
        }).toList();
        return {...eventData, 'posts': processed};
      });
    }).asyncExpand((combined) {
      return fs.marketplaceStream.map((items) {
        final processed = items.where((i) {
          final status = (i['status'] ?? 'pending').toString();
          return status == 'active' || status == 'rejected';
        }).toList();
        return {...combined, 'marketplace': processed};
      });
    });
  }

  List<Map<String, dynamic>> _combineAndFilterItems(Map<String, List<Map<String, dynamic>>> data) {
    List<Map<String, dynamic>> allItems = [];

    if (_selectedType == 'all' || _selectedType == 'events') {
      final events = data['events'] ?? [];
      allItems.addAll(events.map((e) => {...e, '_type': 'event', '_collection': 'events'}));
    }

    if (_selectedType == 'all' || _selectedType == 'posts') {
      final posts = data['posts'] ?? [];
      allItems.addAll(posts.map((p) => {...p, '_type': 'post', '_collection': 'posts'}));
    }

    if (_selectedType == 'all' || _selectedType == 'marketplace') {
      final marketplace = data['marketplace'] ?? [];
      allItems.addAll(marketplace.map((m) => {...m, '_type': 'marketplace', '_collection': 'marketplace'}));
    }

    // Sort by creation date (newest first)
    allItems.sort((a, b) {
      final aDate = _parseDate(a['createdAt']);
      final bDate = _parseDate(b['createdAt']);
      return bDate.compareTo(aDate);
    });

    return allItems;
  }

  Widget _buildContentCard(Map<String, dynamic> item, {bool isProcessed = false}) {
    final type = item['_type'] as String;
    final collection = item['_collection'] as String;
    final itemId = item['id'] as String? ?? '';
    final status = (item['status'] ?? 'pending').toString();
    final createdAt = _parseDate(item['createdAt']);
    final creatorId = item['creatorId'] as String?;

    // Get item-specific data
    String title = '';
    String? description;
    String? creator;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'event':
        title = item['title'] ?? 'אירוע ללא שם';
        description = item['description'];
        creator = item['organizer'];
        icon = Icons.event_rounded;
        iconColor = const Color(0xFFD1C2D3);
        break;
      case 'post':
        title = (item['content'] ?? 'פוסט ללא תוכן').toString();
        if (title.length > 50) title = '${title.substring(0, 50)}...';
        creator = item['authorName'];
        icon = Icons.article_rounded;
        iconColor = const Color(0xFFEDD3D8);
        break;
      case 'marketplace':
        title = item['title'] ?? 'פריט ללא שם';
        description = item['description'];
        creator = item['seller'];
        icon = Icons.store_rounded;
        iconColor = const Color(0xFFB5C8B9);
        break;
      default:
        title = 'פריט';
        icon = Icons.help_outline;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'approved' || status == 'active'
              ? const Color(0xFFB5C8B9).withValues(alpha: 0.3)
              : status == 'rejected'
                  ? const Color(0xFFD4A3A3).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isProcessed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'approved' || status == 'active'
                                    ? const Color(0xFFB5C8B9).withValues(alpha: 0.1)
                                    : const Color(0xFFD4A3A3).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status == 'approved' || status == 'active'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 14,
                                    color: status == 'approved' || status == 'active'
                                        ? const Color(0xFFB5C8B9)
                                        : const Color(0xFFD4A3A3),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'approved' || status == 'active' ? 'אושר' : 'נדחה',
                                    style: TextStyle(
                                      fontFamily: 'Heebo',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: status == 'approved' || status == 'active'
                                          ? const Color(0xFFB5C8B9)
                                          : const Color(0xFFD4A3A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            creator ?? 'לא ידוע',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(createdAt),
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Creator contact information (admin only)
          // First try to read creatorEmail/creatorPhone directly from the content document,
          // then fall back to fetching from the users collection if not available.
          _buildCreatorContactSection(item, creatorId),
          const SizedBox(height: 12),
          if (!isProcessed)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveContent(collection, itemId, title, _getTypeLabel(type)),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('אשר', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5C8B9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectContent(collection, itemId, title, _getTypeLabel(type)),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('דחה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4A3A3),
                        side: const BorderSide(color: Color(0xFFD4A3A3)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showContentDetails(item, type),
                    icon: const Icon(Icons.visibility_outlined),
                    color: Colors.grey[600],
                    tooltip: 'פרטים',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build the creator contact info section.
  /// Reads creatorEmail/creatorPhone from the content document first,
  /// then falls back to the users collection if those fields are empty.
  Widget _buildCreatorContactSection(Map<String, dynamic> item, String? creatorId) {
    final docEmail = item['creatorEmail'] as String?;
    final docPhone = item['creatorPhone'] as String?;
    final hasDocContact = (docEmail != null && docEmail.isNotEmpty) ||
        (docPhone != null && docPhone.isNotEmpty);

    // If the content document already has contact info, use it directly
    if (hasDocContact) {
      return _buildContactInfoWidget(
        email: (docEmail != null && docEmail.isNotEmpty) ? docEmail : null,
        phone: (docPhone != null && docPhone.isNotEmpty) ? docPhone : null,
      );
    }

    // Otherwise, fall back to fetching from the users collection
    if (creatorId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(creatorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!;
        final email = userData['email'] as String?;
        final phone = userData['phone'] as String?;

        if (email == null && phone == null) {
          return const SizedBox.shrink();
        }

        return _buildContactInfoWidget(email: email, phone: phone);
      },
    );
  }

  /// Shared widget that renders the admin-only contact info box.
  Widget _buildContactInfoWidget({String? email, String? phone}) {
    if (email == null && phone == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 6),
              Text(
                'פרטי קשר - למנהלת בלבד',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          if (email != null || phone != null) ...[
            const SizedBox(height: 8),
            if (email != null)
              InkWell(
                onTap: () => _launchUrl('mailto:$email'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (phone != null)
              InkWell(
                onTap: () => _launchUrl('tel:$phone'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 13,
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'event':
        return 'אירוע';
      case 'post':
        return 'פוסט';
      case 'marketplace':
        return 'מסירה';
      default:
        return 'פריט';
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('לא ניתן לפתוח קישור: $e', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: const Color(0xFFD4A3A3),
          ),
        );
      }
    }
  }

  void _showContentDetails(Map<String, dynamic> item, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פרטי ${_getTypeLabel(type)}',
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...item.entries.map((entry) {
                      if (entry.key.startsWith('_')) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
