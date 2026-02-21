import 'package:flutter/material.dart';
import 'package:mom_connect/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Admin notification bell widget with badge and dropdown
/// Shows real-time unread count and list of recent notifications
class AdminNotificationBell extends StatefulWidget {
  const AdminNotificationBell({super.key});

  @override
  State<AdminNotificationBell> createState() => _AdminNotificationBellState();
}

class _AdminNotificationBellState extends State<AdminNotificationBell> {
  final NotificationService _notificationService = NotificationService();
  final OverlayPortalController _tooltipController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    // Configure timeago for Hebrew
    timeago.setLocaleMessages('he', timeago.HeMessages());
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _tooltipController,
      overlayChildBuilder: (BuildContext context) {
        return Positioned(
          top: 60,
          left: 20,
          child: _NotificationDropdown(
            onClose: () => _tooltipController.hide(),
          ),
        );
      },
      child: StreamBuilder<int>(
        stream: _notificationService.getUnreadCountStream(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                iconSize: 28,
                tooltip: 'התראות',
                onPressed: () {
                  if (_tooltipController.isShowing) {
                    _tooltipController.hide();
                  } else {
                    _tooltipController.show();
                  }
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Notification dropdown panel
class _NotificationDropdown extends StatelessWidget {
  final VoidCallback onClose;

  const _NotificationDropdown({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 420,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A1AC).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Color(0xFFD4A1AC)),
                  const SizedBox(width: 12),
                  const Text(
                    'התראות מנהל',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4A1AC),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await notificationService.markAllAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('כל ההתראות סומנו כנקראו', style: TextStyle(fontFamily: 'Heebo')),
                            backgroundColor: const Color(0xFFB5C8B9),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: const Text('סמן הכל כנקרא'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: StreamBuilder<List<AdminNotification>>(
                stream: notificationService.getNotificationsStream(limit: 20),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('שגיאה: ${snapshot.error}'),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'אין התראות חדשות',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () async {
                          await notificationService.markAsRead(notification.id);
                          if (notification.actionUrl != null) {
                            // Navigate to the relevant tab
                            // You can use your app's navigation logic here
                          }
                          onClose();
                        },
                        onDelete: () async {
                          await notificationService.deleteNotification(notification.id);
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
}

/// Individual notification item
class _NotificationItem extends StatefulWidget {
  final AdminNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isUnread = widget.notification.isUnread;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFFD4A1AC).withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(widget.notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.notification.type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
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
                            widget.notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4A1AC),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(widget.notification.createdAt, locale: 'he'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(widget.notification.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.notification.type.hebrewLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTypeColor(widget.notification.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button (on hover)
              if (_isHovered)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.newEvent:
        return const Color(0xFF4CAF50);
      case AdminNotificationType.newPost:
        return const Color(0xFF2196F3);
      case AdminNotificationType.newMarketplaceItem:
        return const Color(0xFFFF9800);
      case AdminNotificationType.newExpert:
        return const Color(0xFF9C27B0);
      case AdminNotificationType.newUser:
        return const Color(0xFF00BCD4);
      case AdminNotificationType.newReport:
        return const Color(0xFFF44336);
      case AdminNotificationType.approvalRequired:
        return const Color(0xFFFFB800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
