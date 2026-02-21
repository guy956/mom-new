/// מודל אירוע
class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String hostId;
  final String hostName;
  final String? hostImage;
  final EventType type;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final String? onlineLink;
  final String? targetAge;
  final double price;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final String? requirements;
  final List<String> tags;
  final DateTime createdAt;
  final bool isApproved;
  final bool isCancelled;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.hostId,
    required this.hostName,
    this.hostImage,
    required this.type,
    required this.dateTime,
    this.endDateTime,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.onlineLink,
    this.targetAge,
    this.price = 0,
    this.maxParticipants = 0,
    this.currentParticipants = 0,
    this.participantIds = const [],
    this.requirements,
    this.tags = const [],
    required this.createdAt,
    this.isApproved = true,
    this.isCancelled = false,
  });

  bool get isFree => price == 0;
  bool get hasAvailableSpots =>
      maxParticipants == 0 || currentParticipants < maxParticipants;
  int get spotsLeft =>
      maxParticipants == 0 ? 999 : maxParticipants - currentParticipants;

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) {
      return 'היום';
    } else if (eventDate == tomorrow) {
      return 'מחר';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostImage: json['hostImage'],
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.playMeetup,
      ),
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.tryParse(json['endDateTime'])
          : null,
      location: json['location'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isOnline: json['isOnline'] ?? false,
      onlineLink: json['onlineLink'],
      targetAge: json['targetAge'],
      price: (json['price'] ?? 0).toDouble(),
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      requirements: json['requirements'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isApproved: json['isApproved'] ?? true,
      isCancelled: json['isCancelled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'hostId': hostId,
      'hostName': hostName,
      'hostImage': hostImage,
      'type': type.name,
      'dateTime': dateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
      'onlineLink': onlineLink,
      'targetAge': targetAge,
      'price': price,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participantIds': participantIds,
      'requirements': requirements,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
      'isCancelled': isCancelled,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? hostId,
    String? hostName,
    String? hostImage,
    EventType? type,
    DateTime? dateTime,
    DateTime? endDateTime,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    bool? isOnline,
    String? onlineLink,
    String? targetAge,
    double? price,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? participantIds,
    String? requirements,
    List<String>? tags,
    DateTime? createdAt,
    bool? isApproved,
    bool? isCancelled,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostImage: hostImage ?? this.hostImage,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      onlineLink: onlineLink ?? this.onlineLink,
      targetAge: targetAge ?? this.targetAge,
      price: price ?? this.price,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantIds: participantIds ?? this.participantIds,
      requirements: requirements ?? this.requirements,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// אירועים לדוגמה
  static List<EventModel> demoList() {
    final now = DateTime.now();
    return [
      EventModel(
        id: 'event_1',
        title: 'מפגש משחק לפעוטות 🧸',
        description:
            'בואי עם הפעוט שלך למפגש משחק חופשי! המקום מותאם לגילאי 0-3 עם משטחים רכים, צעצועים מותאמי גיל והרבה מקום לזחילה והליכה ראשונה.\n\nמה כלול:\n• קפה ועוגיות לאמהות\n• משחק חופשי לילדים\n• הכרות עם אמהות מהאזור',
        imageUrl:
            'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400',
        hostId: 'user_1',
        hostName: 'שרה כהן',
        hostImage: 'https://i.pravatar.cc/150?img=1',
        type: EventType.playMeetup,
        dateTime: now.add(const Duration(days: 2, hours: 10)),
        endDateTime: now.add(const Duration(days: 2, hours: 12)),
        location: 'תל אביב',
        address: 'רחוב דיזנגוף 99, תל אביב',
        price: 0,
        maxParticipants: 15,
        currentParticipants: 8,
        targetAge: '0-3 שנים',
        tags: ['פעוטות', 'משחק', 'חינם'],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      EventModel(
        id: 'event_2',
        title: 'סדנת עיסוי תינוקות 👶',
        description:
            'למדי טכניקות עיסוי תינוקות שיעזרו לתינוק שלך להירגע, לישון טוב יותר ולהקל על גזים וכאבי בטן.\n\nהסדנה מועברת על ידי מעסה מוסמכת בעלת ניסיון של 10 שנים.',
        imageUrl:
            'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400',
        hostId: 'user_2',
        hostName: 'דנה לוי',
        hostImage: 'https://i.pravatar.cc/150?img=10',
        type: EventType.workshop,
        dateTime: now.add(const Duration(days: 5, hours: 16)),
        endDateTime: now.add(const Duration(days: 5, hours: 18)),
        location: 'רמת גן',
        address: 'מרכז הורים, רחוב ביאליק 15',
        price: 120,
        maxParticipants: 10,
        currentParticipants: 6,
        targetAge: '0-6 חודשים',
        tags: ['עיסוי', 'תינוקות', 'סדנה'],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      EventModel(
        id: 'event_3',
        title: 'וובינר: שינה טובה לתינוקות 😴',
        description:
            'וובינר מקוון עם יועצת שינה מוסמכת!\n\nנושאים:\n• הבנת מחזורי שינה\n• יצירת שגרת שינה\n• התמודדות עם התעוררויות לילה\n• טיפים מעשיים להרדמה',
        imageUrl:
            'https://images.unsplash.com/photo-1566004100631-35d015d6a491?w=400',
        hostId: 'user_3',
        hostName: 'מיכל שמיר',
        hostImage: 'https://i.pravatar.cc/150?img=15',
        type: EventType.webinar,
        dateTime: now.add(const Duration(days: 1, hours: 20)),
        endDateTime: now.add(const Duration(days: 1, hours: 21, minutes: 30)),
        isOnline: true,
        onlineLink: 'https://zoom.us/j/123456789',
        price: 50,
        maxParticipants: 100,
        currentParticipants: 67,
        tags: ['שינה', 'וובינר', 'מקוון'],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      EventModel(
        id: 'event_4',
        title: 'ערב נשים - יין וגבינות 🍷',
        description:
            'ערב פינוק לאמהות בלבד! 🎉\n\nבואי לערב של שיחות, צחוקים, יין משובח וגבינות טעימות. בלי ילדים, בלי לחץ, רק את וחברות חדשות.\n\nהכניסה כוללת:\n• כוס יין ראשונה\n• מגש גבינות\n• קינוח',
        imageUrl:
            'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400',
        hostId: 'user_4',
        hostName: 'רחל גולן',
        hostImage: 'https://i.pravatar.cc/150?img=20',
        type: EventType.womensEvening,
        dateTime: now.add(const Duration(days: 7, hours: 20, minutes: 30)),
        endDateTime: now.add(const Duration(days: 7, hours: 23)),
        location: 'הרצליה',
        address: 'בר ויינו, רחוב סוקולוב 42',
        price: 85,
        maxParticipants: 25,
        currentParticipants: 18,
        tags: ['ערב_נשים', 'יין', 'חברות'],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      EventModel(
        id: 'event_5',
        title: 'קבוצת תמיכה - אמהות לראשונה 💕',
        description:
            'קבוצת תמיכה שבועית לאמהות טריות!\n\nמקום בטוח לשתף, לבכות, לצחוק ולקבל תמיכה מאמהות שמבינות בדיוק מה את עוברת.\n\nהקבוצה מונחית על ידי פסיכולוגית קלינית.',
        imageUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400',
        hostId: 'user_5',
        hostName: 'ד"ר נועה ברק',
        hostImage: 'https://i.pravatar.cc/150?img=25',
        type: EventType.supportGroup,
        dateTime: now.add(const Duration(days: 3, hours: 10)),
        endDateTime: now.add(const Duration(days: 3, hours: 12)),
        location: 'פתח תקווה',
        address: 'מרכז בריאות האישה, רחוב רוטשילד 8',
        price: 0,
        maxParticipants: 12,
        currentParticipants: 9,
        targetAge: '0-6 חודשים',
        tags: ['תמיכה', 'אמהות_חדשות', 'קבוצה'],
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }
}

/// סוגי אירועים
enum EventType {
  playMeetup,
  workshop,
  webinar,
  womensEvening,
  supportGroup,
  classes,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.playMeetup:
        return 'מפגש משחק';
      case EventType.workshop:
        return 'סדנה';
      case EventType.webinar:
        return 'וובינר';
      case EventType.womensEvening:
        return 'ערב נשים';
      case EventType.supportGroup:
        return 'קבוצת תמיכה';
      case EventType.classes:
        return 'חוג';
    }
  }

  String get icon {
    switch (this) {
      case EventType.playMeetup:
        return '🧸';
      case EventType.workshop:
        return '🎨';
      case EventType.webinar:
        return '💻';
      case EventType.womensEvening:
        return '🍷';
      case EventType.supportGroup:
        return '💕';
      case EventType.classes:
        return '📚';
    }
  }
}

/// פילטר אירועים
class EventFilter {
  final EventType? type;
  final bool? isOnline;
  final bool? isFree;
  final String? location;
  final String? targetAge;
  final DateTime? fromDate;
  final DateTime? toDate;

  EventFilter({
    this.type,
    this.isOnline,
    this.isFree,
    this.location,
    this.targetAge,
    this.fromDate,
    this.toDate,
  });

  factory EventFilter.fromJson(Map<String, dynamic> json) => EventFilter(
    type: json['type'] != null 
      ? EventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EventType.playMeetup,
        )
      : null,
    isOnline: json['isOnline'],
    isFree: json['isFree'],
    location: json['location'],
    targetAge: json['targetAge'],
    fromDate: json['fromDate'] != null ? DateTime.tryParse(json['fromDate']) : null,
    toDate: json['toDate'] != null ? DateTime.tryParse(json['toDate']) : null,
  );

  Map<String, dynamic> toJson() => {
    'type': type?.name,
    'isOnline': isOnline,
    'isFree': isFree,
    'location': location,
    'targetAge': targetAge,
    'fromDate': fromDate?.toIso8601String(),
    'toDate': toDate?.toIso8601String(),
  };

  EventFilter copyWith({
    EventType? type,
    bool? isOnline,
    bool? isFree,
    String? location,
    String? targetAge,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearType = false,
    bool clearLocation = false,
    bool clearTargetAge = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) => EventFilter(
    type: clearType ? null : (type ?? this.type),
    isOnline: isOnline ?? this.isOnline,
    isFree: isFree ?? this.isFree,
    location: clearLocation ? null : (location ?? this.location),
    targetAge: clearTargetAge ? null : (targetAge ?? this.targetAge),
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate: clearToDate ? null : (toDate ?? this.toDate),
  );
}
