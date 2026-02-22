import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל התראה
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUrl;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      createdAt: _parseDateTime(json['createdAt']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? actionUrl,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// התראות לדוגמה
  static List<NotificationModel> demoList() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif_1',
        type: NotificationType.like,
        title: 'מיכל לוי אהבה את הפוסט שלך',
        body: '"בנות, מישהי יכולה להמליץ על גן..."',
        imageUrl: 'https://i.pravatar.cc/150?img=5',
        referenceId: 'post_1',
        referenceType: 'post',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_2',
        type: NotificationType.comment,
        title: 'יעל אברהם הגיבה לפוסט שלך',
        body: '"ממליצה בחום על גן שושנים!"',
        imageUrl: 'https://i.pravatar.cc/150?img=15',
        referenceId: 'post_1',
        referenceType: 'post',
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_3',
        type: NotificationType.message,
        title: 'הודעה חדשה מדנה כהן',
        body: 'היי! ראיתי שאת מחפשת גן...',
        imageUrl: 'https://i.pravatar.cc/150?img=10',
        referenceId: 'chat_4',
        referenceType: 'chat',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif_4',
        type: NotificationType.eventReminder,
        title: 'תזכורת: מפגש משחק מחר!',
        body: 'מפגש משחק לפעוטות - מחר ב-10:00',
        imageUrl: 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=100',
        referenceId: 'event_1',
        referenceType: 'event',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif_5',
        type: NotificationType.follow,
        title: 'נועה שמיר עוקבת אחרייך',
        body: 'עכשיו תוכלי לראות את הפוסטים שלה',
        imageUrl: 'https://i.pravatar.cc/150?img=20',
        referenceId: 'user_4',
        referenceType: 'user',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif_6',
        type: NotificationType.milestone,
        title: '🎉 יונתן הגיע לאבן דרך חדשה!',
        body: 'זחילה - סמני כהושג ושתפי את הרגע',
        referenceId: 'child_1',
        referenceType: 'milestone',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_7',
        type: NotificationType.system,
        title: 'ברוכה הבאה לMOMIT! 🌸',
        body: 'השלימי את הפרופיל שלך כדי להתחיל',
        createdAt: now.subtract(const Duration(days: 7)),
        isRead: true,
      ),
    ];
  }
}

/// סוגי התראות
enum NotificationType {
  // חברתיות
  like,
  comment,
  mention,
  share,
  follow,

  // הודעות
  message,
  groupMessage,

  // אירועים
  eventReminder,
  eventUpdate,
  eventCancelled,

  // מעקב ילדים
  milestone,
  vaccineReminder,
  growthReminder,

  // מערכת
  system,
  accountVerified,
  reportHandled,
}

extension NotificationTypeExtension on NotificationType {
  String get icon {
    switch (this) {
      case NotificationType.like:
        return '❤️';
      case NotificationType.comment:
        return '💬';
      case NotificationType.mention:
        return '@';
      case NotificationType.share:
        return '🔄';
      case NotificationType.follow:
        return '👤';
      case NotificationType.message:
        return '✉️';
      case NotificationType.groupMessage:
        return '👥';
      case NotificationType.eventReminder:
        return '📅';
      case NotificationType.eventUpdate:
        return '🔔';
      case NotificationType.eventCancelled:
        return '❌';
      case NotificationType.milestone:
        return '🎉';
      case NotificationType.vaccineReminder:
        return '💉';
      case NotificationType.growthReminder:
        return '📏';
      case NotificationType.system:
        return '🔔';
      case NotificationType.accountVerified:
        return '✅';
      case NotificationType.reportHandled:
        return '📋';
    }
  }

  String get category {
    switch (this) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
      case NotificationType.share:
      case NotificationType.follow:
        return 'חברתי';
      case NotificationType.message:
      case NotificationType.groupMessage:
        return 'הודעות';
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventCancelled:
        return 'אירועים';
      case NotificationType.milestone:
      case NotificationType.vaccineReminder:
      case NotificationType.growthReminder:
        return 'מעקב';
      case NotificationType.system:
      case NotificationType.accountVerified:
      case NotificationType.reportHandled:
        return 'מערכת';
    }
  }
}
