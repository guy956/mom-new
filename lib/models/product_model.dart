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
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
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

  /// Demo products
  static List<ProductModel> getDemoProducts() => [
        ProductModel(
          id: 'prod_1',
          sellerId: 'user_1',
          sellerName: 'רחל כהן',
          title: 'עגלת בייבי ג\'וגר',
          description: 'עגלה במצב מצוין! כמעט לא השתמשנו. כוללת גגון שמש, סל קניות גדול וגלגלים מתנפחים.',
          imageUrls: ['https://picsum.photos/seed/stroller1/400/400'],
          price: 1200,
          condition: ProductCondition.likeNew,
          category: ProductCategory.strollers,
          brand: 'Baby Jogger',
          location: 'תל אביב',
          viewsCount: 45,
          likesCount: 12,
          tags: ['עגלה', 'Baby Jogger', 'מצב_מצוין'],
        ),
        ProductModel(
          id: 'prod_2',
          sellerId: 'user_2',
          sellerName: 'נועה ברק',
          title: 'ערסל לתינוק 4moms',
          description: 'ערסל חשמלי עם 5 מהירויות, מוזיקה מובנית ו-Bluetooth. עובד מצוין, התינוק גדל.',
          imageUrls: ['https://picsum.photos/seed/swing1/400/400'],
          price: 800,
          condition: ProductCondition.good,
          category: ProductCategory.furniture,
          brand: '4moms',
          location: 'רמת גן',
          viewsCount: 32,
          likesCount: 8,
          tags: ['ערסל', '4moms', 'חשמלי'],
          isNegotiable: true,
        ),
        ProductModel(
          id: 'prod_3',
          sellerId: 'user_3',
          sellerName: 'מיכל לוי',
          title: 'בגדי תינוק 0-3 חודשים - חבילה',
          description: 'חבילה של 20 פריטי בגדים: 10 בגדי גוף, 5 חליפות שינה, 5 מכנסיים. מותגים: Carter\'s, H&M, Zara.',
          imageUrls: ['https://picsum.photos/seed/clothes1/400/400'],
          price: 150,
          condition: ProductCondition.good,
          category: ProductCategory.clothes,
          ageRange: AgeRangeProduct(minMonths: 0, maxMonths: 3),
          location: 'הרצליה',
          viewsCount: 89,
          likesCount: 23,
          tags: ['בגדים', 'חבילה', '0-3_חודשים'],
        ),
        ProductModel(
          id: 'prod_4',
          sellerId: 'user_4',
          sellerName: 'דנה אברהם',
          title: 'צעצועי התפתחות - חינם!',
          description: 'מגוון צעצועי התפתחות לגילאי 6-12 חודשים. מעדיפה למסור למי שבאמת צריך 💕',
          imageUrls: ['https://picsum.photos/seed/toys1/400/400'],
          price: 0,
          condition: ProductCondition.used,
          category: ProductCategory.toys,
          ageRange: AgeRangeProduct(minMonths: 6, maxMonths: 12),
          location: 'רעננה',
          viewsCount: 156,
          likesCount: 45,
          tags: ['צעצועים', 'חינם', 'תרומה'],
        ),
        ProductModel(
          id: 'prod_5',
          sellerId: 'user_5',
          sellerName: 'שירה מזרחי',
          title: 'כיסא בטיחות לרכב Cybex',
          description: 'כיסא בטיחות מ-0 עד 4 שנים, מסתובב 360 מעלות. עבר את כל בדיקות הבטיחות.',
          imageUrls: ['https://picsum.photos/seed/carseat1/400/400'],
          price: 950,
          condition: ProductCondition.likeNew,
          category: ProductCategory.carSeats,
          brand: 'Cybex',
          location: 'נתניה',
          viewsCount: 67,
          likesCount: 19,
          tags: ['כיסא_בטיחות', 'Cybex', '360_מעלות'],
        ),
        ProductModel(
          id: 'prod_6',
          sellerId: 'user_6',
          sellerName: 'יעל גולן',
          title: 'משאבת חלב Medela',
          description: 'משאבה כפולה חשמלית, כמעט לא בשימוש. כוללת שקיות אחסון ובקבוקים.',
          imageUrls: ['https://picsum.photos/seed/pump1/400/400'],
          price: 400,
          condition: ProductCondition.likeNew,
          category: ProductCategory.feeding,
          brand: 'Medela',
          location: 'פתח תקווה',
          viewsCount: 43,
          likesCount: 11,
          tags: ['משאבת_חלב', 'Medela', 'הנקה'],
        ),
      ];
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
