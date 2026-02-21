/// מודל משתמש מלא
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? profileImage;
  final String? bio;
  final String? city;
  final String? maritalStatus;
  final String? profession;
  final List<ChildModel> children;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final bool isOnline;
  final PrivacySettings privacy;
  final UserStats stats;
  final List<String> interests;
  final List<String> savedPosts;
  final List<String> blockedUsers;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.profileImage,
    this.bio,
    this.city,
    this.maritalStatus,
    this.profession,
    this.children = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.isOnline = false,
    PrivacySettings? privacy,
    UserStats? stats,
    this.interests = const [],
    this.savedPosts = const [],
    this.blockedUsers = const [],
  })  : privacy = privacy ?? PrivacySettings(),
        stats = stats ?? UserStats();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      fullName: json['fullName'] ?? '',
      profileImage: json['profileImage'],
      bio: json['bio'],
      city: json['city'],
      maritalStatus: json['maritalStatus'],
      profession: json['profession'],
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ChildModel.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      isOnline: json['isOnline'] ?? false,
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'])
          : null,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      interests: List<String>.from(json['interests'] ?? []),
      savedPosts: List<String>.from(json['savedPosts'] ?? []),
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'profileImage': profileImage,
      'bio': bio,
      'city': city,
      'maritalStatus': maritalStatus,
      'profession': profession,
      'children': children.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isVerified': isVerified,
      'isOnline': isOnline,
      'privacy': privacy.toJson(),
      'stats': stats.toJson(),
      'interests': interests,
      'savedPosts': savedPosts,
      'blockedUsers': blockedUsers,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? profileImage,
    String? bio,
    String? city,
    String? maritalStatus,
    String? profession,
    List<ChildModel>? children,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    bool? isOnline,
    PrivacySettings? privacy,
    UserStats? stats,
    List<String>? interests,
    List<String>? savedPosts,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      profession: profession ?? this.profession,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      privacy: privacy ?? this.privacy,
      stats: stats ?? this.stats,
      interests: interests ?? this.interests,
      savedPosts: savedPosts ?? this.savedPosts,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  /// פרופיל דמו לבדיקות
  static UserModel demo() {
    return UserModel(
      id: 'demo_user_1',
      email: 'demo@example.com',
      phone: '050-1234567',
      fullName: 'שרה כהן',
      profileImage: 'https://i.pravatar.cc/150?img=1',
      bio: 'אמא לשני ילדים מקסימים 💕 אוהבת לבלות, לבשל ולקרוא',
      city: 'תל אביב',
      maritalStatus: 'נשואה',
      profession: 'מעצבת גרפית',
      children: [
        ChildModel.demo(),
        ChildModel(
          id: 'child_2',
          name: 'נועה',
          birthDate: DateTime(2022, 3, 15),
          gender: Gender.female,
        ),
      ],
      createdAt: DateTime(2023, 1, 15),
      lastLoginAt: DateTime.now(),
      isVerified: true,
      isOnline: true,
      stats: UserStats(
        postsCount: 45,
        commentsCount: 156,
        likesReceived: 892,
        rating: 4.8,
        followersCount: 234,
        followingCount: 156,
      ),
      interests: ['הנקה', 'שינה', 'מתכונים', 'טיולים', 'יצירה'],
    );
  }
}

/// מודל ילד
class ChildModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? profileImage;
  final double? birthWeight;
  final double? birthHeight;
  final List<GrowthRecord> growthRecords;
  final List<MilestoneRecord> milestones;

  ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.profileImage,
    this.birthWeight,
    this.birthHeight,
    this.growthRecords = const [],
    this.milestones = const [],
  });

  /// חישוב גיל בחודשים
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    return months;
  }

  /// חישוב גיל מעוצב
  String get formattedAge {
    final months = ageInMonths;
    if (months < 1) {
      final days = DateTime.now().difference(birthDate).inDays;
      return '$days ימים';
    } else if (months < 12) {
      return months == 1 ? 'חודש' : '$months חודשים';
    } else {
      final years = months ~/ 12;
      final rem = months % 12;
      final yearsStr = years == 1 ? 'שנה' : (years == 2 ? 'שנתיים' : '$years שנים');
      if (rem == 0) return yearsStr;
      final monthsStr = rem == 1 ? 'חודש' : '$rem חודשים';
      return '$yearsStr ו-$monthsStr';
    }
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: DateTime.tryParse(json['birthDate'] ?? '') ?? DateTime.now(),
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.unknown,
      ),
      profileImage: json['profileImage'],
      birthWeight: json['birthWeight']?.toDouble(),
      birthHeight: json['birthHeight']?.toDouble(),
      growthRecords: (json['growthRecords'] as List<dynamic>?)
              ?.map((e) => GrowthRecord.fromJson(e))
              .toList() ??
          [],
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((e) => MilestoneRecord.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender.name,
      'profileImage': profileImage,
      'birthWeight': birthWeight,
      'birthHeight': birthHeight,
      'growthRecords': growthRecords.map((e) => e.toJson()).toList(),
      'milestones': milestones.map((e) => e.toJson()).toList(),
    };
  }

  ChildModel copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? profileImage,
    double? birthWeight,
    double? birthHeight,
    List<GrowthRecord>? growthRecords,
    List<MilestoneRecord>? milestones,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      birthWeight: birthWeight ?? this.birthWeight,
      birthHeight: birthHeight ?? this.birthHeight,
      growthRecords: growthRecords ?? this.growthRecords,
      milestones: milestones ?? this.milestones,
    );
  }

  static ChildModel demo() {
    return ChildModel(
      id: 'child_1',
      name: 'יונתן',
      birthDate: DateTime(2024, 1, 10),
      gender: Gender.male,
      profileImage: 'https://i.pravatar.cc/100?img=50',
      birthWeight: 3.2,
      birthHeight: 50,
      growthRecords: [
        GrowthRecord(
          date: DateTime(2024, 2, 10),
          weight: 4.5,
          height: 54,
          headCircumference: 38,
        ),
        GrowthRecord(
          date: DateTime(2024, 3, 10),
          weight: 5.8,
          height: 58,
          headCircumference: 40,
        ),
      ],
    );
  }
}

/// מין הילד
enum Gender {
  male,
  female,
  unknown,
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'זכר';
      case Gender.female:
        return 'נקבה';
      case Gender.unknown:
        return 'לא צוין';
    }
  }

  String get emoji {
    switch (this) {
      case Gender.male:
        return '👦';
      case Gender.female:
        return '👧';
      case Gender.unknown:
        return '👶';
    }
  }
}

/// רשומת צמיחה
class GrowthRecord {
  final DateTime date;
  final double? weight;
  final double? height;
  final double? headCircumference;
  final String? notes;

  GrowthRecord({
    required this.date,
    this.weight,
    this.height,
    this.headCircumference,
    this.notes,
  });

  factory GrowthRecord.fromJson(Map<String, dynamic> json) {
    return GrowthRecord(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      headCircumference: json['headCircumference']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'headCircumference': headCircumference,
      'notes': notes,
    };
  }
}

/// רשומת אבני דרך
class MilestoneRecord {
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime? achievedDate;
  final bool isAchieved;
  final String? photoUrl;
  final String? videoUrl;
  final int expectedAgeMonths;

  MilestoneRecord({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.achievedDate,
    this.isAchieved = false,
    this.photoUrl,
    this.videoUrl,
    required this.expectedAgeMonths,
  });

  factory MilestoneRecord.fromJson(Map<String, dynamic> json) {
    return MilestoneRecord(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      achievedDate: json['achievedDate'] != null
          ? DateTime.tryParse(json['achievedDate'])
          : null,
      isAchieved: json['isAchieved'] ?? false,
      photoUrl: json['photoUrl'],
      videoUrl: json['videoUrl'],
      expectedAgeMonths: json['expectedAgeMonths'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'achievedDate': achievedDate?.toIso8601String(),
      'isAchieved': isAchieved,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'expectedAgeMonths': expectedAgeMonths,
    };
  }
}

/// הגדרות פרטיות
class PrivacySettings {
  final String profileVisibility;
  final String childrenVisibility;
  final String postsVisibility;
  final bool allowMessages;
  final bool showOnlineStatus;

  PrivacySettings({
    this.profileVisibility = 'public',
    this.childrenVisibility = 'private',
    this.postsVisibility = 'public',
    this.allowMessages = true,
    this.showOnlineStatus = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: json['profileVisibility'] ?? 'public',
      childrenVisibility: json['childrenVisibility'] ?? 'private',
      postsVisibility: json['postsVisibility'] ?? 'public',
      allowMessages: json['allowMessages'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'childrenVisibility': childrenVisibility,
      'postsVisibility': postsVisibility,
      'allowMessages': allowMessages,
      'showOnlineStatus': showOnlineStatus,
    };
  }
}

/// סטטיסטיקות משתמש
class UserStats {
  final int postsCount;
  final int commentsCount;
  final int likesReceived;
  final double rating;
  final int followersCount;
  final int followingCount;

  UserStats({
    this.postsCount = 0,
    this.commentsCount = 0,
    this.likesReceived = 0,
    this.rating = 0.0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      postsCount: json['postsCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likesReceived: json['likesReceived'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postsCount': postsCount,
      'commentsCount': commentsCount,
      'likesReceived': likesReceived,
      'rating': rating,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }
}
