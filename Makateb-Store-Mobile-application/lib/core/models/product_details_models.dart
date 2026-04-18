class ProductDetailsData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String>? imageUrls;
  final int? stock;
  final ProductCategory? category;
  final String? nameAr;
  final String? descriptionAr;

  const ProductDetailsData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imageUrls,
    this.stock,
    this.category,
    this.nameAr,
    this.descriptionAr,
  });

  factory ProductDetailsData.fromJson(Map<String, dynamic> json) {
    return ProductDetailsData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      description: json['description'],
      descriptionAr: json['description_ar'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0'),
      imageUrl: json['image_url'] ?? json['image'],
      imageUrls: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'])
          : null,
    );
  }
}

class ProductCategory {
  final String id;
  final String name;
  final String? nameAr;

  const ProductCategory({required this.id, required this.name, this.nameAr});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
    );
  }
}

class ProductCommentData {
  final String id;
  final String? userId;
  final ProductUserData? user;
  final String comment;
  final DateTime createdAt;
  final int rating;

  const ProductCommentData({
    required this.id,
    this.userId,
    this.user,
    required this.comment,
    required this.createdAt,
    this.rating = 5,
  });
}

class ProductRatingData {
  final double averageRating;
  final int totalRatings;
  final ProductUserRating? userRating;

  const ProductRatingData({
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.userRating,
  });
}

class ProductUserRating {
  final String userId;
  final int rating;
  const ProductUserRating({required this.userId, required this.rating});
}

class ProductUserData {
  final String id;
  final String name;
  const ProductUserData({required this.id, required this.name});
}

class ProductReviewFormData {
  final int rating;
  final String comment;
  const ProductReviewFormData({this.rating = 5, this.comment = ''});
}


