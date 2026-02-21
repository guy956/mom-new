import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/app_strings.dart';
import 'package:mom_connect/models/notification_model.dart';
import 'package:mom_connect/features/chat/screens/chat_screen.dart';
import 'package:mom_connect/features/events/screens/events_screen.dart';
import 'package:mom_connect/features/tracking/screens/tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'name': 'הכל'},
    {'id': 'social', 'name': 'חברתי'},
    {'id': 'messages', 'name': 'הודעות'},
    {'id': 'events', 'name': 'אירועים'},
    {'id': 'tracking', 'name': 'מעקב'},
  ];

  @override
  void initState() {
    super.initState();
    _notifications = NotificationModel.demoList();
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case 'social':
          return [
            NotificationType.like,
            NotificationType.comment,
            NotificationType.mention,
            NotificationType.share,
            NotificationType.follow,
          ].contains(n.type);
        case 'messages':
          return [
            NotificationType.message,
            NotificationType.groupMessage,
          ].contains(n.type);
        case 'events':
          return [
            NotificationType.eventReminder,
            NotificationType.eventUpdate,
            NotificationType.eventCancelled,
          ].contains(n.type);
        case 'tracking':
          return [
            NotificationType.milestone,
            NotificationType.vaccineReminder,
            NotificationType.growthReminder,
          ].contains(n.type);
        default:
          return true;
      }
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text(
            AppStrings.notifications,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'סמני הכל כנקרא',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 12,
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'settings', child: Text('הגדרות התראות')),
            const PopupMenuItem(value: 'clear', child: Text('נקה הכל')),
          ],
          onSelected: (value) {
            if (value == 'clear') {
              _showClearConfirmation();
            } else if (value == 'settings') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הגדרות התראות', style: TextStyle(fontFamily: 'Heebo')),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter['id'];
            final filterNotifs = filter['id'] == 'all'
                ? _notifications
                : _filteredNotifications;
            final unread = filterNotifs.where((n) => !n.isRead).length;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = filter['id']);
              },
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      filter['name'],
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (unread > 0 && filter['id'] == 'all') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread.toString(),
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'אין התראות',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'כשיהיו לך התראות חדשות,\nהן יופיעו כאן',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 14,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Group notifications by date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayNotifs = _filteredNotifications.where((n) =>
        n.createdAt.day == today.day &&
        n.createdAt.month == today.month &&
        n.createdAt.year == today.year).toList();

    final yesterdayNotifs = _filteredNotifications.where((n) =>
        n.createdAt.day == yesterday.day &&
        n.createdAt.month == yesterday.month &&
        n.createdAt.year == yesterday.year).toList();

    final olderNotifs = _filteredNotifications.where((n) =>
        !todayNotifs.contains(n) && !yesterdayNotifs.contains(n)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (todayNotifs.isNotEmpty) ...[
          _buildSectionHeader('היום'),
          ...todayNotifs.map((n) => NotificationTile(
                notification: n,
                onTap: () => _handleNotificationTap(n),
                onDismiss: () => _removeNotification(n),
              )),
        ],
        if (yesterdayNotifs.isNotEmpty) ...[
          _buildSectionHeader('אתמול'),
          ...yesterdayNotifs.map((n) => NotificationTile(
                notification: n,
                onTap: () => _handleNotificationTap(n),
                onDismiss: () => _removeNotification(n),
              )),
        ],
        if (olderNotifs.isNotEmpty) ...[
          _buildSectionHeader('קודם לכן'),
          ...olderNotifs.map((n) => NotificationTile(
                notification: n,
                onTap: () => _handleNotificationTap(n),
                onDismiss: () => _removeNotification(n),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    setState(() {
      final index = _notifications.indexOf(notification);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
      case NotificationType.share:
      case NotificationType.follow:
        // Social notifications - navigate to feed (go back to main)
        Navigator.pop(context);
        break;
      case NotificationType.message:
      case NotificationType.groupMessage:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
        break;
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventCancelled:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
        break;
      case NotificationType.milestone:
      case NotificationType.vaccineReminder:
      case NotificationType.growthReminder:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingScreen()));
        break;
      default:
        break;
    }
  }

  void _removeNotification(NotificationModel notification) {
    HapticFeedback.mediumImpact();
    setState(() {
      _notifications.remove(notification);
    });
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('כל ההתראות סומנו כנקראו'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת כל ההתראות'),
        content: const Text('האם את בטוחה שברצונך למחוק את כל ההתראות?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _notifications.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('מחיקה'),
          ),
        ],
      ),
    );
  }
}

/// פריט התראה
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Image
              _buildAvatar(),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 14,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (notification.imageUrl != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(notification.imageUrl!),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          notification.type.icon,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type.category) {
      case 'חברתי':
        return AppColors.secondary;
      case 'הודעות':
        return AppColors.primary;
      case 'אירועים':
        return Colors.orange;
      case 'מעקב':
        return Colors.green;
      default:
        return AppColors.textHint;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'עכשיו';
    } else if (difference.inMinutes < 60) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inHours < 24) {
      return 'לפני ${difference.inHours} שעות';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
