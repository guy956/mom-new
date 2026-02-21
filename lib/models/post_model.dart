/// מודל פוסט
class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final PostType type;
  final PostCategory category;
  final List<String> tags;
  final bool isAnonymous;
  final String? location;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final bool isLiked;
  final bool isSaved;
  final bool commentsEnabled;
  final PollData? pollData;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.type = PostType.text,
    this.category = PostCategory.general,
    this.tags = const [],
    this.isAnonymous = false,
    this.location,
    DateTime? createdAt,
    this.editedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.commentsEnabled = true,
    this.pollData,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => isAnonymous ? 'אנונימית' : authorName;
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoUrl != null;
  bool get isPoll => type == PostType.poll && pollData != null;
  bool get isHelpRequest => type == PostType.helpRequest;

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'type': type.name,
        'category': category.name,
        'tags': tags,
        'isAnonymous': isAnonymous,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'savesCount': savesCount,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'commentsEnabled': commentsEnabled,
        'pollData': pollData?.toJson(),
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] ?? '',
        authorId: json['authorId'] ?? '',
        authorName: json['authorName'] ?? '',
        authorPhotoUrl: json['authorPhotoUrl'],
        content: json['content'] ?? '',
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        videoUrl: json['videoUrl'],
        type: PostType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PostType.text,
        ),
        category: PostCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => PostCategory.general,
        ),
        tags: List<String>.from(json['tags'] ?? []),
        isAnonymous: json['isAnonymous'] ?? false,
        location: json['location'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
        likesCount: json['likesCount'] ?? 0,
        commentsCount: json['commentsCount'] ?? 0,
        sharesCount: json['sharesCount'] ?? 0,
        savesCount: json['savesCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        isSaved: json['isSaved'] ?? false,
        commentsEnabled: json['commentsEnabled'] ?? true,
        pollData: json['pollData'] != null ? PollData.fromJson(json['pollData']) : null,
      );

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    PostType? type,
    PostCategory? category,
    List<String>? tags,
    bool? isAnonymous,
    String? location,
    DateTime? createdAt,
    DateTime? editedAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    bool? isLiked,
    bool? isSaved,
    bool? commentsEnabled,
    PollData? pollData,
  }) =>
      PostModel(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
        content: content ?? this.content,
        imageUrls: imageUrls ?? this.imageUrls,
        videoUrl: videoUrl ?? this.videoUrl,
        type: type ?? this.type,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        location: location ?? this.location,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        savesCount: savesCount ?? this.savesCount,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
        pollData: pollData ?? this.pollData,
      );

  /// Demo posts for testing
  static List<PostModel> getDemoPosts() => [
        PostModel(
          id: 'post_1',
          authorId: 'user_1',
          authorName: 'מיכל לוין',
          content: 'היי אמהות! 💕 מישהי יכולה להמליץ על גן ילדים באזור רמת גן? התינוק שלי בן 10 חודשים ואני מתחילה לחפש. מה חשוב לבדוק?',
          type: PostType.helpRequest,
          category: PostCategory.education,
          tags: ['גן_ילדים', 'רמת_גן', 'המלצות'],
          location: 'רמת גן',
          likesCount: 23,
          commentsCount: 15,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostModel(
          id: 'post_2',
          authorId: 'user_2',
          authorName: 'נועה ישראלי',
          content: 'סיפור הצלחה! 🎉 אחרי חודשיים של לילות קשים, סוף סוף התינוק ישן לילה שלם! השיטה שעבדה לנו: שגרה קבועה, אמבטיה חמימה, ושיר ערש. אל תוותרי אמהות!',
          type: PostType.text,
          category: PostCategory.sleep,
          tags: ['שינה', 'תינוקות', 'טיפים'],
          likesCount: 156,
          commentsCount: 42,
          sharesCount: 18,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        PostModel(
          id: 'post_3',
          authorId: 'user_3',
          authorName: 'רחל כהן',
          content: 'מתלבטת לגבי התחלת מזון מוצק. הרופאה אמרה מ-6 חודשים אבל התינוק מראה סימני מוכנות כבר עכשיו (5.5 חודשים). מה עשיתן?',
          type: PostType.poll,
          category: PostCategory.feeding,
          tags: ['מזון_מוצק', 'תזונה', 'תינוקות'],
          likesCount: 45,
          commentsCount: 28,
          pollData: PollData(
            question: 'באיזה גיל התחלתן מזון מוצק?',
            options: [
              PollOption(id: '1', text: '4 חודשים', votes: 12),
              PollOption(id: '2', text: '5-6 חודשים', votes: 67),
              PollOption(id: '3', text: '6 חודשים בדיוק', votes: 45),
              PollOption(id: '4', text: 'אחרי 6 חודשים', votes: 23),
            ],
            totalVotes: 147,
            endsAt: DateTime.now().add(const Duration(days: 3)),
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        PostModel(
          id: 'post_4',
          authorId: 'user_4',
          authorName: 'אנונימית',
          content: 'צריכה לשתף... 😔 מרגישה מאוד בודדה כאמא חדשה. כל החברות שלי עדיין בלי ילדים ולא מבינות אותי. האם זה נורמלי להרגיש ככה?',
          type: PostType.text,
          category: PostCategory.emotional,
          isAnonymous: true,
          likesCount: 234,
          commentsCount: 89,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        PostModel(
          id: 'post_5',
          authorId: 'user_5',
          authorName: 'דנה אברהם',
          content: 'יום ראשון של הבת בגן! 🥹💪 התרגשתי יותר ממנה נראה לי... מי עוד עוברת את זה השבוע?',
          type: PostType.image,
          category: PostCategory.moments,
          imageUrls: ['https://picsum.photos/seed/kindergarten/400/300'],
          tags: ['גן', 'יום_ראשון', 'רגע_מרגש'],
          likesCount: 312,
          commentsCount: 56,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PostModel(
          id: 'post_6',
          authorId: 'user_6',
          authorName: 'שירה מזרחי',
          content: 'טיפ זהב שקיבלתי מהאמא שלי וחייבת לשתף: 🌟\n\nלפני השינה, במקום מסכים - ספר אחד ושיר אחד. תוך שבועיים הילד התרגל להירדם לבד!\n\nמה הטיפ הכי טוב שקיבלתן?',
          type: PostType.text,
          category: PostCategory.tips,
          tags: ['טיפים', 'שינה', 'הורות'],
          likesCount: 189,
          commentsCount: 67,
          sharesCount: 34,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        ),
      ];
}

enum PostType { text, image, video, poll, helpRequest }

enum PostCategory {
  general,
  feeding,
  sleep,
  health,
  development,
  education,
  tips,
  emotional,
  moments,
  questions,
  marketplace,
}

extension PostCategoryExtension on PostCategory {
  String get displayName {
    switch (this) {
      case PostCategory.general:
        return 'כללי';
      case PostCategory.feeding:
        return 'האכלה ותזונה';
      case PostCategory.sleep:
        return 'שינה';
      case PostCategory.health:
        return 'בריאות';
      case PostCategory.development:
        return 'התפתחות';
      case PostCategory.education:
        return 'חינוך';
      case PostCategory.tips:
        return 'טיפים';
      case PostCategory.emotional:
        return 'רגשי';
      case PostCategory.moments:
        return 'רגעים מיוחדים';
      case PostCategory.questions:
        return 'שאלות';
      case PostCategory.marketplace:
        return 'קניה/מכירה';
    }
  }

  String get emoji {
    switch (this) {
      case PostCategory.general:
        return '📝';
      case PostCategory.feeding:
        return '🍼';
      case PostCategory.sleep:
        return '😴';
      case PostCategory.health:
        return '🏥';
      case PostCategory.development:
        return '📈';
      case PostCategory.education:
        return '📚';
      case PostCategory.tips:
        return '💡';
      case PostCategory.emotional:
        return '💕';
      case PostCategory.moments:
        return '📸';
      case PostCategory.questions:
        return '❓';
      case PostCategory.marketplace:
        return '🛒';
    }
  }
}

/// נתוני סקר
class PollData {
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final DateTime? endsAt;
  final String? votedOptionId;

  PollData({
    required this.question,
    required this.options,
    this.totalVotes = 0,
    this.endsAt,
    this.votedOptionId,
  });

  bool get isExpired => endsAt != null && endsAt!.isBefore(DateTime.now());
  bool get hasVoted => votedOptionId != null;

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'totalVotes': totalVotes,
        'endsAt': endsAt?.toIso8601String(),
        'votedOptionId': votedOptionId,
      };

  factory PollData.fromJson(Map<String, dynamic> json) => PollData(
        question: json['question'] ?? '',
        options: (json['options'] as List?)?.map((o) => PollOption.fromJson(o)).toList() ?? [],
        totalVotes: json['totalVotes'] ?? 0,
        endsAt: json['endsAt'] != null ? DateTime.parse(json['endsAt']) : null,
        votedOptionId: json['votedOptionId'],
      );
}

/// אפשרות בסקר
class PollOption {
  final String id;
  final String text;
  final int votes;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'votes': votes,
      };

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        votes: json['votes'] ?? 0,
      );
}

/// מודל תגובה
class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
  final String? parentCommentId;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    DateTime? createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentCommentId,
    this.replies = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'isLiked': isLiked,
        'parentCommentId': parentCommentId,
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] ?? '',
        postId: json['postId'] ?? '',
        authorId: json['authorId'] ?? '',
        authorName: json['authorName'] ?? '',
        authorPhotoUrl: json['authorPhotoUrl'],
        content: json['content'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        likesCount: json['likesCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        parentCommentId: json['parentCommentId'],
        replies: (json['replies'] as List?)?.map((r) => CommentModel.fromJson(r)).toList() ?? [],
      );
}
