/// INTEGRATION EXAMPLE: How to add notification bell to your admin dashboard
///
/// This file shows you how to integrate the AdminNotificationBell widget
/// into your existing admin dashboard AppBar or header.

import 'package:flutter/material.dart';
import 'package:mom_connect/features/admin/widgets/admin_notification_bell.dart';

/// Example 1: Adding to AppBar
class AdminDashboardWithNotifications extends StatelessWidget {
  const AdminDashboardWithNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOMIT Admin Dashboard'),
        backgroundColor: const Color(0xFFD4A1AC),
        actions: [
          // Add notification bell here
          const AdminNotificationBell(),
          const SizedBox(width: 16),

          // Other action buttons
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings action
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const AdminDashboardContent(),
    );
  }
}

/// Example 2: Adding to custom header
class AdminDashboardCustomHeader extends StatelessWidget {
  const AdminDashboardCustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4A1AC),
                const Color(0xFFEDD3D8),
              ],
            ),
          ),
          child: Row(
            children: [
              const Text(
                'MOMIT Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),

              // Add notification bell here
              const AdminNotificationBell(),

              const SizedBox(width: 16),
              CircleAvatar(
                child: const Icon(Icons.person),
              ),
            ],
          ),
        ),

        // Dashboard content
        Expanded(
          child: const AdminDashboardContent(),
        ),
      ],
    );
  }
}

/// Example 3: Testing notifications programmatically
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        actions: const [
          AdminNotificationBell(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Test notification service
                final NotificationService =
                    (await import('package:mom_connect/services/notification_service.dart'))
                        .NotificationService();

                await NotificationService.sendTestNotification();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('בדיקת התראה נשלחה!')),
                  );
                }
              },
              child: const Text('שלח התראת בדיקה'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Test email service
                final EmailService =
                    (await import('package:mom_connect/services/email_service.dart'))
                        .EmailService();

                final success = await EmailService.sendTestEmail();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                          ? 'אימייל נשלח בהצלחה!'
                          : 'שגיאה בשליחת אימייל - בדוק את ה-API key',
                      ),
                    ),
                  );
                }
              },
              child: const Text('שלח אימייל בדיקה'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Simulate creating content that triggers notification
                final FirestoreService =
                    (await import('package:mom_connect/services/firestore_service.dart'))
                        .FirestoreService();

                await FirestoreService.createEvent({
                  'title': 'אירוע בדיקה',
                  'description': 'זהו אירוע בדיקה אוטומטי',
                  'location': 'תל אביב',
                  'eventDate': DateTime.now().add(const Duration(days: 7)),
                  'createdBy': 'מערכת בדיקות',
                  'status': 'pending', // This triggers notification
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('אירוע נוצר - התראה נשלחה למנהל!'),
                    ),
                  );
                }
              },
              child: const Text('צור אירוע בדיקה (שולח התראה)'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dummy content widget
class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 64, color: Color(0xFFD4A1AC)),
          const SizedBox(height: 16),
          const Text(
            'Admin Dashboard Content',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Your dashboard content goes here'),
        ],
      ),
    );
  }
}

/// QUICK START GUIDE:
///
/// 1. Find your admin dashboard file (probably in lib/features/admin/screens/)
///
/// 2. Import the notification bell widget:
///    import 'package:mom_connect/features/admin/widgets/admin_notification_bell.dart';
///
/// 3. Add it to your AppBar actions:
///    AppBar(
///      actions: [
///        const AdminNotificationBell(),
///      ],
///    )
///
/// 4. Done! The bell will automatically:
///    - Show unread notification count
///    - Display notifications in dropdown
///    - Mark as read when clicked
///    - Update in real-time
///
/// 5. Test it by creating an event/post/marketplace item with status='pending'
///
/// 6. Check that email is sent to ola.cos85@gmail.com
///
/// That's it! The notification system is now fully integrated.
