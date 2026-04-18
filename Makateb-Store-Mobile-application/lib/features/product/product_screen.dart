import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import 'dart:async';
import '../../core/services/api_services/catalog_api_service.dart';
import '../../core/models/product_details_models.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/localization/app_localizations.dart';

/// ProductScreen - Product details screen
///
/// Equivalent to Vue's Product.vue page.
/// Displays detailed product information with image carousel, reviews, and purchase options.
class ProductScreen extends ConsumerStatefulWidget {
  /// Product ID
  final String? productId;

  /// Optional: pass product data directly (if available)
  final ProductDetailsData? initialProduct;

  /// Callback when add to cart is tapped
  final VoidCallback? onAddToCart;

  /// Callback when wishlist toggle is tapped
  final VoidCallback? onToggleWishlist;

  const ProductScreen({
    super.key,
    this.productId,
    this.initialProduct,
    this.onAddToCart,
    this.onToggleWishlist,
  });

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  // State
  bool _loading = false;
  ProductDetailsData? _product;
  List<ProductCommentData> _comments = [];
  ProductRatingData _ratingData = const ProductRatingData();

  bool _commentsLoading = false;
  bool _uploadingComment = false;

  int _currentImageIndex = 0;
  int _quantity = 1;

  ProductReviewFormData _newReview = const ProductReviewFormData();

  // Mock Date
  final _mockProductData = const ProductDetailsData(
    id: '1',
    name: 'Elegant Oak Dining Chair',
    nameAr: 'كرسي طعام من خشب البلوط الأنيق',
    description:
        'Experience the perfect blend of style and comfort with our Elegant Oak Dining Chair. CRAFTED from premium solid oak, this chair features a timeless design that complements any dining room decor. The ergonomic backrest provides excellent support, while the cushioned seat ensures hours of comfortable seating. Finished with a durable, water-resistant varnish to protect against spills and scratches.',
    descriptionAr:
        'جرب المزيج المثالي من الأناقة والراحة مع كرسي الطعام المصنوع من خشب البلوط الأنيق. مصنوع من خشب البلوط الصلب الفاخر، ويتميز هذا الكرسي بتصميم خالد يكمل أي ديكور لغرفة الطعام. يوفر مسند الظهر المريح دعمًا ممتازًا، بينما يضمن المقعد المبطن ساعات من الجلوس المريح. تم الانتهاء منه بطلاء متين ومقاوم للماء للحماية من الانسكابات والخدوش.',
    price: 129.99,
    stock: 8,
    category: ProductCategory(id: 'c1', name: 'Furniture', nameAr: 'أثاث'),
    imageUrls: [
      'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&q=80&w=1000',
      'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?auto=format&fit=crop&q=80&w=1000',
      'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&q=80&w=1000',
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      if (widget.initialProduct != null) {
        _product = widget.initialProduct;
      } else if (widget.productId != null) {
        final api = CatalogApiService();
        final data = await api.fetchProductById(widget.productId!);
        _product = ProductDetailsData.fromJson(data);
      } else {
        // Fallback or dev mode
        _product = _mockProductData;
      }
    } catch (e) {
      debugPrint('Error loading product: $e');
    }

    if (mounted) {
      setState(() {
        _loading = false;

        // Load comments
        _loadComments();

        // Fetch real rating data
        _loadRating();
      });
    }
  }

  Future<void> _loadRating() async {
    final productId = widget.productId ?? _product?.id;
    if (productId == null) return;

    try {
      final api = CatalogApiService();
      final ratingDataRaw = await api.fetchProductRating(productId);
      if (mounted) {
        setState(() {
          _ratingData = ProductRatingData(
            averageRating:
                double.tryParse(
                  ratingDataRaw['average_rating']?.toString() ?? '0',
                ) ??
                0,
            totalRatings:
                int.tryParse(
                  ratingDataRaw['total_ratings']?.toString() ?? '0',
                ) ??
                0,
            userRating: ratingDataRaw['user_rating'] != null
                ? ProductUserRating(
                    userId: ratingDataRaw['user_rating']['user_id'].toString(),
                    rating:
                        int.tryParse(
                          ratingDataRaw['user_rating']['rating']?.toString() ??
                              '0',
                        ) ??
                        0,
                  )
                : null,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading product rating: $e');
    }
  }

  Future<void> _loadComments() async {
    if (widget.productId == null && widget.initialProduct == null) return;
    final productId = widget.productId ?? widget.initialProduct?.id;
    if (productId == null) return;

    setState(() => _commentsLoading = true);
    try {
      final api = CatalogApiService();
      final data = await api.fetchProductComments(productId);

      if (mounted) {
        setState(() {
          _comments = data.map((item) {
            final map = Map<String, dynamic>.from(item);
            final userMap = map['user'] != null
                ? Map<String, dynamic>.from(map['user'])
                : null;

            return ProductCommentData(
              id: (map['id'] ?? '').toString(),
              userId: (map['user_id'] ?? '').toString(),
              user: userMap != null
                  ? ProductUserData(
                      id: (userMap['id'] ?? '').toString(),
                      name: (userMap['name'] ?? 'User').toString(),
                    )
                  : null,
              comment: (map['comment'] ?? '').toString(),
              createdAt:
                  DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
              rating: int.tryParse(map['rating']?.toString() ?? '0') ?? 0,
            );
          }).toList();
          _commentsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  // Getters & Helpers
  List<String> get _productImages {
    final images = <String>[];
    if (_product?.imageUrls != null && _product!.imageUrls!.isNotEmpty) {
      images.addAll(_product!.imageUrls!);
    } else if (_product?.imageUrl != null) {
      images.add(_product!.imageUrl!);
    }

    // Fallback if no images
    if (images.isEmpty) {
      return ['https://via.placeholder.com/600x600?text=No+Image'];
    }
    return images;
  }

  String get _currentImage => _productImages.isNotEmpty
      ? _productImages[_currentImageIndex % _productImages.length]
      : '';

  String _getLocalizedName(dynamic item) {
    if (item == null) return '';
    final isArabic = ref.read(currentLanguageProvider) == 'ar';
    if (isArabic && item.nameAr != null && item.nameAr.isNotEmpty) {
      return item.nameAr;
    }
    return item.name;
  }

  String _getLocalizedDescription(dynamic item) {
    if (item == null) return '';
    final isArabic = ref.read(currentLanguageProvider) == 'ar';
    if (isArabic &&
        item.descriptionAr != null &&
        item.descriptionAr.isNotEmpty) {
      return item.descriptionAr;
    }
    return item.description ?? '';
  }

  void _nextImage() {
    if (_productImages.length > 1) {
      setState(
        () => _currentImageIndex =
            (_currentImageIndex + 1) % _productImages.length,
      );
    }
  }

  void _previousImage() {
    if (_productImages.length > 1) {
      setState(() {
        _currentImageIndex = _currentImageIndex == 0
            ? _productImages.length - 1
            : _currentImageIndex - 1;
      });
    }
  }

  void _submitReview() async {
    if (_newReview.comment.isEmpty) return;
    final productId = widget.productId ?? widget.initialProduct?.id;
    if (productId == null) return;

    setState(() => _uploadingComment = true);

    try {
      final api = CatalogApiService();
      await api.postProductComment(
        productId,
        _newReview.comment,
        _newReview.rating,
      );

      // Reload comments to show the new one
      await _loadComments();

      if (mounted) {
        setState(() {
          _newReview = const ProductReviewFormData(rating: 5, comment: '');
          _uploadingComment = false;
        });

        final l10n = AppLocalizations.of(context);
        NotificationToastService.instance.showSuccess(
          l10n.translate('review_submitted_successfully'),
        );
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      if (mounted) {
        setState(() => _uploadingComment = false);
        final l10n = AppLocalizations.of(context);
        NotificationToastService.instance.showError(
          l10n.translate('failed_to_submit_review'),
        );
      }
    }
  }

  // bool get _isArabic => ref.watch(currentLanguageProvider) == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels = ProductScreenLabels.forLanguage(currentLanguage);

    // Watch wishlist items to react to heart clicks
    final wishlistItems = ref.watch(wishlistStoreProvider).items;
    final isInWishlist =
        widget.productId != null &&
        wishlistItems.any((item) => item.productId == widget.productId);

    return PageLayout(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF111827), // gray-900
                    const Color(0xFF1F2937), // gray-800
                  ]
                : [
                    const Color(0xFFFEF3C7), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: _loading
            ? _buildLoadingState(isDark)
            : _product == null
            ? _buildNotFoundState(isDark, labels)
            : SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1280,
                    ), // max-w-7xl
                    child: Padding(
                      // Responsive padding
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLG,
                        vertical: AppTheme.spacingXXL * 2, // py-8
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductContent(isDark, labels, isInWishlist),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? Colors.white : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNotFoundState(bool isDark, ProductScreenLabels labels) {
    return Center(
      child: Text(
        labels.productNotFound,
        style: AppTextStyles.titleMediumStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProductContent(
    bool isDark,
    ProductScreenLabels labels,
    bool isInWishlist,
  ) {
    return Column(
      children: [
        // Main Grid: Image + Details
        LayoutBuilder(
          builder: (context, constraints) {
            // md:grid-cols-2 equivalent
            if (constraints.maxWidth >= 768) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildImageSection(isDark, labels)),
                  const SizedBox(width: 32), // gap-8
                  Expanded(
                    child: _buildDetailsSection(isDark, labels, isInWishlist),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildImageSection(isDark, labels),
                  const SizedBox(height: 32),
                  _buildDetailsSection(isDark, labels, isInWishlist),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 48), // mb-12
        // Reviews Section
        _buildReviewsSection(isDark, labels),
      ],
    );
  }

  Widget _buildImageSection(bool isDark, ProductScreenLabels labels) {
    final stock = _product?.stock ?? 0;

    return Column(
      children: [
        // Main Image
        Stack(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 400),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF3F4F6), // bg-gray-100/800
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _currentImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),

            // Navigation Arrows
            if (_productImages.length > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: _previousImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: _nextImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Counter
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${_productImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // Stock Badge
            if (stock < 10 && stock > 0)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${labels.onlyLeftInStock} $stock ${labels.leftInStock}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Thumbnails
        if (_productImages.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _productImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.amber.shade500
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF9FAFB),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _productImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection(
    bool isDark,
    ProductScreenLabels labels,
    bool isInWishlist,
  ) {
    if (_product == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category
        Text(
          _product!.category != null
              ? _getLocalizedName(_product!.category)
              : labels.uncategorized,
          style: TextStyle(
            color: isDark ? Colors.amber.shade500 : Colors.amber.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Name
        const SizedBox(height: 8),
        Text(
          _getLocalizedName(_product),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),

        // Rating
        const SizedBox(height: 16),
        Row(
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 20,
                  color: index < _ratingData.averageRating.floor()
                      ? Colors.amber.shade500
                      : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _ratingData.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_ratingData.totalRatings} ${labels.reviews})',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),

        // Price
        const SizedBox(height: 24),
        Text(
          '\$${_product!.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.amber.shade500 : Colors.amber.shade900,
          ),
        ),

        // Description
        const SizedBox(height: 32),
        Text(
          _getLocalizedDescription(_product).isNotEmpty
              ? _getLocalizedDescription(_product)
              : labels.noDescriptionAvailable,
          style: TextStyle(
            fontSize: 18,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
            height: 1.5,
          ),
        ),

        // Quantity
        const SizedBox(height: 24),
        Text(
          labels.quantity,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: _decreaseQuantity,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.shade900.withValues(alpha: 0.3)
                      : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 30,
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: _increaseQuantity,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.shade900.withValues(alpha: 0.3)
                      : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),

        // Buttons
        const SizedBox(height: 24),
        Row(
          children: [
            WoodButton(
              onPressed: (_product!.stock ?? 0) < _quantity ? null : _addToCart,
              size: WoodButtonSize.lg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (_product!.stock ?? 0) <= 0
                        ? labels.outOfStock
                        : labels.addToCart,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            WoodButton(
              onPressed: _toggleWishlist,
              variant: isInWishlist
                  ? WoodButtonVariant.primary
                  : WoodButtonVariant.outline,
              size: WoodButtonSize.lg,
              child: Icon(
                Icons.favorite,
                color: isInWishlist
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isDark, ProductScreenLabels labels) {
    return Container(
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.amber.shade900 : Colors.amber.shade200,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            labels.customerReviews,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),

          // Comments List
          if (_commentsLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  labels.loading,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else if (_comments.isNotEmpty)
            ..._comments.map(
              (comment) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark
                                  ? Colors.amber.shade900
                                  : Colors.amber.shade200,
                              child: Text(
                                comment.user?.name
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.amber.shade100
                                      : Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.user?.name ?? labels.anonymous,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '2 days ago',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              Icons.star,
                              size: 16,
                              color: idx < comment.rating
                                  ? Colors.amber.shade500
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comment.comment,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                labels.noReviewsYet,
                style: const TextStyle(color: Colors.grey),
              ),
            ),

          // Add Review Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.amber.shade900.withValues(alpha: 0.2)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.writeReview,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  labels.rating,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF374151),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (idx) => IconButton(
                      onPressed: () => setState(
                        () => _newReview = ProductReviewFormData(
                          rating: idx + 1,
                          comment: _newReview.comment,
                        ),
                      ),
                      icon: Icon(
                        Icons.star,
                        color: idx < _newReview.rating
                            ? Colors.amber.shade500
                            : Colors.grey.shade300,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  labels.yourReview,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: labels.shareThoughts,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.amber.shade900
                            : Colors.amber.shade200,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.amber.shade900
                            : Colors.amber.shade200,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (val) => _newReview = ProductReviewFormData(
                    rating: _newReview.rating,
                    comment: val,
                  ),
                ),
                const SizedBox(height: 16),
                WoodButton(
                  onPressed: _uploadingComment ? null : _submitReview,
                  child: Text(
                    _uploadingComment ? labels.submitting : labels.submitReview,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _increaseQuantity() {
    if (_product != null && _quantity < (_product!.stock ?? 0)) {
      setState(() => _quantity++);
    }
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .addProduct(product.id, quantity: _quantity);

    if (success) {
      NotificationToastService.instance.showSuccess(
        l10n.translate('product_added_to_cart'),
      );
    } else {
      NotificationToastService.instance.showError(
        ref.read(cartStoreProvider).error ??
            l10n.translate('failed_to_add_to_cart'),
      );
    }
  }

  Future<void> _toggleWishlist() async {
    final product = _product;
    if (product == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(wishlistStoreProvider.notifier)
        .toggleProduct(product.id);

    if (success) {
      NotificationToastService.instance.showSuccess(
        l10n.translate('wishlist_updated'),
      );
    } else {
      NotificationToastService.instance.showError(
        ref.read(wishlistStoreProvider).error ??
            l10n.translate('failed_to_update_wishlist'),
      );
    }
  }
}

// ---------------- Data Models and Helpers ----------------

class ProductScreenLabels {
  final String loading;
  final String productNotFound;
  final String uncategorized;
  final String reviews;
  final String noDescriptionAvailable;
  final String quantity;
  final String outOfStock;
  final String addToCart;
  final String onlyLeftInStock;
  final String leftInStock;
  final String customerReviews;
  final String noReviewsYet;
  final String writeReview;
  final String rating;
  final String yourReview;
  final String shareThoughts;
  final String submitting;
  final String submitReview;
  final String anonymous;

  const ProductScreenLabels({
    required this.loading,
    required this.productNotFound,
    required this.uncategorized,
    required this.reviews,
    required this.noDescriptionAvailable,
    required this.quantity,
    required this.outOfStock,
    required this.addToCart,
    required this.onlyLeftInStock,
    required this.leftInStock,
    required this.customerReviews,
    required this.noReviewsYet,
    required this.writeReview,
    required this.rating,
    required this.yourReview,
    required this.shareThoughts,
    required this.submitting,
    required this.submitReview,
    required this.anonymous,
  });

  factory ProductScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ProductScreenLabels(
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      productNotFound: isArabic ? 'المنتج غير موجود' : 'Product not found',
      uncategorized: isArabic ? 'غير مصنف' : 'Uncategorized',
      reviews: isArabic ? 'تقييمات' : 'reviews',
      noDescriptionAvailable: isArabic
          ? 'لا يوجد وصف متاح.'
          : 'No description available.',
      quantity: isArabic ? 'الكمية' : 'Quantity',
      outOfStock: isArabic ? 'نفدت الكمية' : 'Out of Stock',
      addToCart: isArabic ? 'أضف إلى السلة' : 'Add to Cart',
      onlyLeftInStock: isArabic ? 'بقي فقط' : 'Only',
      leftInStock: isArabic ? 'في المخزون' : 'left in stock',
      customerReviews: isArabic ? 'تقييمات العملاء' : 'Customer Reviews',
      noReviewsYet: isArabic ? 'لا توجد تقييمات بعد.' : 'No reviews yet.',
      writeReview: isArabic ? 'اكتب تقييماً' : 'Write a Review',
      rating: isArabic ? 'التقييم' : 'Rating',
      yourReview: isArabic ? 'تقييمك' : 'Your Review',
      shareThoughts: isArabic
          ? 'شارك أفكارك حول هذا المنتج...'
          : 'Share your thoughts on this product...',
      submitting: isArabic ? 'جاري الإرسال...' : 'Submitting...',
      submitReview: isArabic ? 'إرسال التقييم' : 'Submit Review',
      anonymous: isArabic ? 'مجهول' : 'Anonymous',
    );
  }
}
