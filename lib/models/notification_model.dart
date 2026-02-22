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
