/// מודל מוצר למרקטפלייס
class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String title;
  final String description;
  final List<String> imageUrls;
  final double price;
  final ProductCondition condition;
  final ProductCategory category;
  final AgeRangeProduct? ageRange;
  final String? brand;
  final String location;
  final DateTime createdAt;
  final ProductStatus status;
  final int viewsCount;
  final int likesCount;
  final bool isLiked;
  final bool isSaved;
  final List<String> tags;
  final bool isNegotiable;
  final bool includesShipping;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.price,
    this.condition = ProductCondition.good,
    this.category = ProductCategory.other,
    this.ageRange,
    this.brand,
    required this.location,
    DateTime? createdAt,
    this.status = ProductStatus.available,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.tags = const [],
    this.isNegotiable = true,
    this.includesShipping = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFree => price == 0;
  String get priceDisplay => isFree ? 'למסירה חינם' : '₪${price.toStringAsFixed(0)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhotoUrl': sellerPhotoUrl,
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        'price': price,
        'condition': condition.name,
        'category': category.name,
        'ageRange': ageRange?.toJson(),
        'brand': brand,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'viewsCount': viewsCount,
        'likesCount': likesCount,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'tags': tags,
        'isNegotiable': isNegotiable,
        'includesShipping': includesShipping,
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] ?? '',
        sellerId: json['sellerId'] ?? '',
        sellerName: json['sellerName'] ?? '',
        sellerPhotoUrl: json['sellerPhotoUrl'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        price: (json['price'] ?? 0).toDouble(),
        condition: ProductCondition.values.firstWhere(
          (c) => c.name == json['condition'],
          orElse: () => ProductCondition.good,
        ),
        category: ProductCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ProductCategory.other,
        ),
        ageRange: json['ageRange'] != null ? AgeRangeProduct.fromJson(json['ageRange']) : null,
        brand: json['brand'],
        location: json['location'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        status: ProductStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ProductStatus.available,
        ),
        viewsCount: json['viewsCount'] ?? 0,
        likesCount: json['likesCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        isSaved: json['isSaved'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        isNegotiable: json['isNegotiable'] ?? true,
        includesShipping: json['includesShipping'] ?? false,
      );

}

/// מצב מוצר
enum ProductCondition { new_, likeNew, good, used }

extension ProductConditionExtension on ProductCondition {
  String get displayName {
    switch (this) {
      case ProductCondition.new_:
        return 'חדש';
      case ProductCondition.likeNew:
        return 'כמו חדש';
      case ProductCondition.good:
        return 'מצב טוב';
      case ProductCondition.used:
        return 'משומש';
    }
  }
}

/// קטגוריית מוצר
enum ProductCategory {
  strollers,
  carSeats,
  furniture,
  clothes,
  toys,
  feeding,
  bathing,
  safety,
  health,
  other,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.strollers:
        return 'עגלות';
      case ProductCategory.carSeats:
        return 'כיסאות בטיחות';
      case ProductCategory.furniture:
        return 'ריהוט';
      case ProductCategory.clothes:
        return 'בגדים';
      case ProductCategory.toys:
        return 'צעצועים';
      case ProductCategory.feeding:
        return 'האכלה';
      case ProductCategory.bathing:
        return 'רחצה';
      case ProductCategory.safety:
        return 'בטיחות';
      case ProductCategory.health:
        return 'בריאות';
      case ProductCategory.other:
        return 'אחר';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.strollers:
        return '🛒';
      case ProductCategory.carSeats:
        return '🚗';
      case ProductCategory.furniture:
        return '🪑';
      case ProductCategory.clothes:
        return '👶';
      case ProductCategory.toys:
        return '🧸';
      case ProductCategory.feeding:
        return '🍼';
      case ProductCategory.bathing:
        return '🛁';
      case ProductCategory.safety:
        return '🔒';
      case ProductCategory.health:
        return '🏥';
      case ProductCategory.other:
        return '📦';
    }
  }
}

/// סטטוס מוצר
enum ProductStatus { available, reserved, sold, deleted }

/// טווח גילאים למוצר
class AgeRangeProduct {
  final int minMonths;
  final int maxMonths;

  AgeRangeProduct({
    required this.minMonths,
    required this.maxMonths,
  });

  String get displayText {
    String formatAge(int months) {
      if (months < 12) return '$months חודשים';
      final years = months ~/ 12;
      return '$years ${years == 1 ? "שנה" : "שנים"}';
    }

    return '${formatAge(minMonths)} - ${formatAge(maxMonths)}';
  }

  Map<String, dynamic> toJson() => {
        'minMonths': minMonths,
        'maxMonths': maxMonths,
      };

  factory AgeRangeProduct.fromJson(Map<String, dynamic> json) => AgeRangeProduct(
        minMonths: json['minMonths'] ?? 0,
        maxMonths: json['maxMonths'] ?? 120,
      );
}
