/// מודל הודעה
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? mediaThumbnail;
  final int? mediaDuration;
  final LocationData? location;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDeleted;
  final String? replyToId;
  final MessageModel? replyTo;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.mediaThumbnail,
    this.mediaDuration,
    this.location,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.isDeleted = false,
    this.replyToId,
    this.replyTo,
  });

  bool get isRead => readAt != null;
  bool get isDelivered => deliveredAt != null;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderImage: json['senderImage'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      mediaThumbnail: json['mediaThumbnail'],
      mediaDuration: json['mediaDuration'],
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
      sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      readAt:
          json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      replyToId: json['replyToId'],
      replyTo: json['replyTo'] != null
          ? MessageModel.fromJson(json['replyTo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaThumbnail': mediaThumbnail,
      'mediaDuration': mediaDuration,
      'location': location?.toJson(),
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'replyToId': replyToId,
      'replyTo': replyTo?.toJson(),
    };
  }
}

/// סוגי הודעות
enum MessageType {
  text,
  image,
  voice,
  video,
  location,
  sticker,
  system,
}

/// מודל מיקום
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }
}

/// מודל צ'אט/שיחה
class ChatModel {
  final String id;
  final ChatType type;
  final String? name;
  final String? image;
  final List<ChatParticipant> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isMuted;
  final bool isPinned;

  ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.image,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isMuted = false,
    this.isPinned = false,
  });

  /// קבלת השם להצגה (עבור צ'אט פרטי - שם הצד השני)
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name ?? 'קבוצה';
    }
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.name;
  }

  /// קבלת התמונה להצגה
  String? getDisplayImage(String currentUserId) {
    if (type == ChatType.group) {
      return image;
    }
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.image;
  }

  /// בדיקה האם הצד השני מחובר
  bool isOtherOnline(String currentUserId) {
    if (type == ChatType.group) return false;
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.isOnline;
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.private,
      ),
      name: json['name'],
      image: json['image'],
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ChatParticipant.fromJson(e))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'image': image,
      'participants': participants.map((e) => e.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isMuted': isMuted,
      'isPinned': isPinned,
    };
  }

}

/// סוגי צ'אט
enum ChatType {
  private,
  group,
  sale, // שיחת מכירה
}

/// משתתף בצ'אט
class ChatParticipant {
  final String userId;
  final String name;
  final String? image;
  final bool isOnline;
  final bool isTyping;
  final bool isAdmin;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.image,
    this.isOnline = false,
    this.isTyping = false,
    this.isAdmin = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      isOnline: json['isOnline'] ?? false,
      isTyping: json['isTyping'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'image': image,
      'isOnline': isOnline,
      'isTyping': isTyping,
      'isAdmin': isAdmin,
    };
  }
}
