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
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt'].toString()) : null,
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
        endsAt: json['endsAt'] != null ? DateTime.tryParse(json['endsAt'].toString()) : null,
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
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        likesCount: json['likesCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        parentCommentId: json['parentCommentId'],
        replies: (json['replies'] as List?)?.map((r) => CommentModel.fromJson(r)).toList() ?? [],
      );
}
