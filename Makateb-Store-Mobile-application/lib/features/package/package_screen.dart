import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/cart_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_client.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/widgets/product_card.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/api_services/catalog_api_service.dart';

/// PackageScreen - Package details screen
///
/// Equivalent to Vue's Package.vue page.
/// Displays package details, included products, and reviews.
///
/// Features:
/// - Package image with discount badge
/// - Package name, rating, pricing
/// - Quantity selector
/// - Add to cart and wishlist buttons
/// - Package contents grid
/// - Reviews section with add review form
/// - Dark mode support
/// - Responsive design
class PackageScreen extends ConsumerStatefulWidget {
  /// Package ID from route
  final String? packageId;

  /// Mock package data
  final PackageScreenData? packageData;

  /// Mock products data (included in package)
  final List<PackageProductData>? products;

  /// Mock comments/reviews data
  final List<PackageCommentData>? comments;

  /// Mock rating data
  final PackageRatingData? ratingData;

  /// Loading states
  final bool loading;
  final bool loadingProducts;
  final bool commentsLoading;

  /// Adding to cart state
  final bool addingToCart;

  /// Whether package is in wishlist
  final bool isInWishlist;

  /// Adding to wishlist state
  final bool addingToWishlist;

  /// Uploading comment state
  final bool uploadingComment;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when add to cart is tapped
  final void Function(String packageId, int quantity)? onAddToCart;

  /// Callback when wishlist toggle is tapped
  final void Function(String packageId)? onToggleWishlist;

  /// Callback when review is submitted
  final void Function(String packageId, int rating, String comment)?
  onSubmitReview;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Date formatter function
  final String Function(DateTime date)? formatDate;

  /// Labels for localization
  final PackageScreenLabels? labels;

  const PackageScreen({
    super.key,
    this.packageId,
    this.packageData,
    this.products,
    this.comments,
    this.ratingData,
    this.loading = false,
    this.loadingProducts = false,
    this.commentsLoading = false,
    this.addingToCart = false,
    this.isInWishlist = false,
    this.addingToWishlist = false,
    this.uploadingComment = false,
    this.onProductTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.onSubmitReview,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.formatPrice,
    this.formatDate,
    this.labels,
  });

  @override
  ConsumerState<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends ConsumerState<PackageScreen> {
  PackageScreenData? _packageData;
  List<PackageProductData> _products = [];
  List<PackageCommentData> _comments = [];
  PackageRatingData? _ratingData;
  int _quantity = 1;
  int _newReviewRating = 5;
  final TextEditingController _newReviewCommentController =
      TextEditingController();

  final _api = ApiClient.instance;

  @override
  void initState() {
    super.initState();
    if (widget.packageData != null && widget.products != null) {
      _packageData = widget.packageData;
      _products = widget.products!;
      _comments = widget.comments ?? [];
      _ratingData = widget.ratingData;
    } else if (widget.packageId != null) {
      _loadFromApi();
    }
  }

  @override
  void dispose() {
    _newReviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadFromApi() async {
    if (widget.packageId == null) return;

    try {
      // Fetch package details
      final packageRes = await _api.getJson('/packages/${widget.packageId}');
      if (packageRes is Map) {
        final map = Map<String, dynamic>.from(packageRes);
        final id = (map['id'] ?? '').toString();
        final priceStr = map['price']?.toString();
        final price = double.tryParse(priceStr ?? '') ?? 0.0;

        _packageData = PackageScreenData(
          id: id,
          name: (map['name'] ?? '').toString(),
          description: map['description']?.toString(),
          price: price,
          imageUrl: map['image_url']?.toString(),
        );

        // Load products in package
        final productsRaw = map['products'];
        if (productsRaw is List) {
          _products = productsRaw
              .map((p) {
                if (p is! Map) return null;
                final pMap = Map<String, dynamic>.from(p);
                final pId = (pMap['id'] ?? '').toString();
                final pPriceStr = pMap['price']?.toString();
                final pPrice = double.tryParse(pPriceStr ?? '') ?? 0.0;

                final categoryMap = pMap['category'];
                PackageCategoryData? category;
                if (categoryMap is Map) {
                  final catMap = Map<String, dynamic>.from(categoryMap);
                  category = PackageCategoryData(
                    id: (catMap['id'] ?? '').toString(),
                    name: (catMap['name'] ?? '').toString(),
                  );
                }

                return PackageProductData(
                  id: pId,
                  name: (pMap['name'] ?? '').toString(),
                  description: pMap['description']?.toString(),
                  price: pPrice,
                  imageUrl: pMap['image_url']?.toString(),
                  category: category,
                );
              })
              .whereType<PackageProductData>()
              .toList();
        }
      }

      // Load comments
      await _loadComments();

      // Load ratings
      await _loadRating();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Package load failed: $e');
      }
    }
  }

  Future<void> _loadRating() async {
    final packageId = widget.packageId ?? _packageData?.id;
    if (packageId == null) return;

    try {
      final catalogApi = CatalogApiService();
      final ratingDataRaw = await catalogApi.fetchPackageRating(packageId);
      if (mounted) {
        setState(() {
          _ratingData = PackageRatingData(
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
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading package rating: $e');
    }
  }

  Future<void> _loadComments() async {
    if (widget.packageId == null) return;
    try {
      final catalogApi = CatalogApiService();
      final data = await catalogApi.fetchPackageComments(widget.packageId!);

      if (mounted) {
        setState(() {
          _comments = data.map((item) {
            final map = Map<String, dynamic>.from(item);
            final userMap = map['user'] != null
                ? Map<String, dynamic>.from(map['user'])
                : null;

            return PackageCommentData(
              id: (map['id'] ?? '').toString(),
              userId: (map['user_id'] ?? '').toString(),
              user: userMap != null
                  ? PackageUserData(
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
        });
      }
    } catch (e) {
      debugPrint('Error loading package comments: $e');
    }
  }

  double get _packagePrice {
    return _packageData?.price ?? 0.0;
  }

  double get _originalPrice {
    if (_products.isEmpty) return _packagePrice;
    return _products.fold(0.0, (sum, product) => sum + product.price);
  }

  double get _savingsAmount {
    return (_originalPrice - _packagePrice).clamp(0.0, double.infinity);
  }

  int get _discountPercentage {
    if (_originalPrice == 0) return 0;
    return ((_savingsAmount / _originalPrice) * 100).round();
  }

  double get _averageRating {
    return widget.ratingData?.averageRating ??
        _ratingData?.averageRating ??
        0.0;
  }

  int get _totalRatings {
    return widget.ratingData?.totalRatings ?? _ratingData?.totalRatings ?? 0;
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? '\$${price.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return widget.formatDate?.call(date) ??
        '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _getLocalizedName(dynamic item) {
    return widget.getLocalizedName?.call(item) ?? (item?.name ?? '');
  }

  String _getLocalizedDescription(dynamic item) {
    return widget.getLocalizedDescription?.call(item) ??
        (item?.description ?? '');
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _handleSubmitReview() async {
    if (_newReviewCommentController.text.trim().isEmpty) {
      return;
    }
    if (widget.packageId == null && _packageData?.id == null) return;

    final packageId = widget.packageId ?? _packageData!.id;

    try {
      final catalogApi = CatalogApiService();
      await catalogApi.postPackageComment(
        packageId,
        _newReviewCommentController.text.trim(),
        _newReviewRating,
      );

      // Reload comments
      await _loadComments();

      if (mounted) {
        setState(() {
          _newReviewRating = 5;
          _newReviewCommentController.clear();
        });

        // Show success snackbar
      }
    } catch (e) {
      debugPrint('Error submitting package review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Watch language changes to update labels
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? PackageScreenLabels.forLanguage(currentLanguage);

    // Watch wishlist items for both package and included products
    final wishlistItems = ref.watch(wishlistStoreProvider).items;
    final isPackageInWishlist = wishlistItems.any(
      (item) => item.packageId == widget.packageId,
    );

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
                    const Color(0xFFFFFBEB), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            child: widget.loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingXXL * 3,
                      ), // py-12
                      child: Text(
                        labels.loading,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                      ),
                    ),
                  )
                : _packageData == null
                ? Center(
                    child: Text(
                      labels.packageNotFound,
                      style: AppTextStyles.bodyMediumStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    ),
                  )
                : _buildPackageDetails(
                    isDark,
                    labels,
                    isPackageInWishlist,
                    wishlistItems,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageDetails(
    bool isDark,
    PackageScreenLabels labels,
    bool isPackageInWishlist,
    List<WishlistItemData> wishlistItems,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Details Section
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 768) {
                // Desktop: Side by side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPackageImage(isDark, labels)),
                    const SizedBox(width: AppTheme.spacingXXL * 2), // gap-8
                    Expanded(
                      child: _buildPackageInfo(
                        isDark,
                        labels,
                        isPackageInWishlist,
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile: Stacked
                return Column(
                  children: [
                    _buildPackageImage(isDark, labels),
                    const SizedBox(height: AppTheme.spacingXXL * 2), // gap-8
                    _buildPackageInfo(isDark, labels, isPackageInWishlist),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: AppTheme.spacingXXL * 3), // mb-12
          // Package Contents Section
          _buildPackageContents(isDark, labels, wishlistItems),

          const SizedBox(height: AppTheme.spacingXXL * 3), // mt-12
          // Reviews Section
          _buildReviewsSection(isDark, labels),
        ],
      ),
    );
  }

  Widget _buildPackageImage(bool isDark, PackageScreenLabels labels) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.borderRadiusLargeValue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppTheme.borderRadiusLargeValue,
              child: _packageData?.imageUrl != null
                  ? Image.network(
                      _packageData!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark
                            ? const Color(0xFF374151) // gray-700
                            : const Color(0xFFE5E7EB), // gray-200
                        child: Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? const Color(0xFF374151) // gray-700
                          : const Color(0xFFE5E7EB), // gray-200
                      child: Icon(
                        Icons.inventory_2,
                        size: 64,
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF6B7280), // gray-500
                      ),
                    ),
            ),
          ),
          // Discount Badge
          if (_discountPercentage > 0)
            Positioned(
              top: AppTheme.spacingLG, // top-4
              left: AppTheme.spacingLG, // left-4
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG, // px-4
                  vertical: AppTheme.spacingSM, // py-2
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E), // green-500
                  borderRadius: AppTheme.borderRadiusLargeValue,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 20,
                      color: Colors.white,
                    ), // w-5 h-5
                    const SizedBox(width: AppTheme.spacingSM), // space-x-2
                    Text(
                      '${labels.save} $_discountPercentage%',
                      style: AppTextStyles.bodyMediumStyle(
                        color: Colors.white,
                        // font-weight: regular (default)
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo(
    bool isDark,
    PackageScreenLabels labels,
    bool isPackageInWishlist,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package Badge
        Row(
          children: [
            Icon(
              Icons.inventory_2,
              size: 20, // w-5 h-5
              color: isDark
                  ? const Color(0xFFD97706) // amber-500
                  : const Color(0xFF92400E), // amber-700
            ),
            const SizedBox(width: 8), // space-x-2
            Text(
              labels.specialPackageDeal,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFFD97706) // amber-500
                    : const Color(0xFF92400E), // amber-700
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        // Package Name
        Text(
          _getLocalizedName(_packageData),
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-900
                fontWeight: FontWeight.bold, // Make it bold
              ).copyWith(
                fontSize: 36, // text-4xl
              ),
        ),
        const SizedBox(height: AppTheme.spacingLG), // mb-4
        // Rating
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFilled = starIndex <= _averageRating.floor();
                return Icon(
                  Icons.star,
                  size: 20, // w-5 h-5
                  color: isFilled
                      ? const Color(0xFFEAB308) // yellow-500
                      : const Color(0xFFD1D5DB), // gray-300
                );
              }),
            ),
            const SizedBox(width: AppTheme.spacingLG), // space-x-4
            Text(
              _averageRating.toStringAsFixed(1),
              style:
                  AppTextStyles.titleSmallStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    fontWeight: AppTextStyles.medium,
                  ).copyWith(
                    fontSize: 18, // text-lg
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '($_totalRatings ${labels.reviews})',
              style: AppTextStyles.bodyMediumStyle(
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        // Pricing
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_originalPrice > _packagePrice)
              Padding(
                padding: const EdgeInsets.only(bottom: 4), // mb-1
                child: Text(
                  _formatPrice(_originalPrice),
                  style:
                      AppTextStyles.titleMediumStyle(
                        color: const Color(0xFF6B7280), // gray-500
                      ).copyWith(
                        fontSize: 20, // text-xl
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatPrice(_packagePrice),
                  style:
                      AppTextStyles.titleLargeStyle(
                        color: isDark
                            ? const Color(0xFFD97706) // amber-500
                            : const Color(0xFF78350F), // amber-900
                        // font-weight: regular (default)
                      ).copyWith(
                        fontSize: 36, // text-4xl
                      ),
                ),
                if (_savingsAmount > 0) ...[
                  const SizedBox(width: AppTheme.spacingMD), // space-x-3
                  Text(
                    '${labels.save} ${_formatPrice(_savingsAmount)}!',
                    style:
                        AppTextStyles.titleMediumStyle(
                          color: isDark
                              ? const Color(0xFF4ADE80) // green-400
                              : const Color(0xFF16A34A), // green-600
                          // font-weight: regular (default)
                        ).copyWith(
                          fontSize: 20, // text-xl
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        // Description
        Text(
          _getLocalizedDescription(_packageData).isEmpty
              ? labels.noDescriptionAvailable
              : _getLocalizedDescription(_packageData),
          style:
              AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFFD1D5DB) // gray-300
                    : const Color(0xFF374151), // gray-700
              ).copyWith(
                fontSize: 18, // text-lg
              ),
        ),
        const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
        // Quantity Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels.quantity,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFFD1D5DB) // gray-300
                    : const Color(0xFF374151), // gray-700
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            LayoutBuilder(
              builder: (context, constraints) {
                // On very small screens, reduce spacing
                final isVerySmall = constraints.maxWidth < 360;
                final spacing = isVerySmall
                    ? AppTheme.spacingSM
                    : AppTheme.spacingLG;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _decreaseQuantity,
                        borderRadius: AppTheme.borderRadiusLargeValue,
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppTheme.spacingSM,
                          ), // p-2
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF78350F).withValues(
                                    alpha: 0.3,
                                  ) // amber-900/30
                                : const Color(0xFFFFFBEB), // amber-100
                            borderRadius: AppTheme.borderRadiusLargeValue,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 20, // w-5 h-5
                            color: isDark
                                ? const Color(0xFFD97706) // amber-500
                                : const Color(0xFF92400E), // amber-800
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing), // space-x-4 (responsive)
                    SizedBox(
                      width: 48, // w-12
                      child: Text(
                        _quantity.toString(),
                        style:
                            AppTextStyles.titleLargeStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827), // gray-900
                              // font-weight: regular (default)
                            ).copyWith(
                              fontSize: 24, // text-2xl
                            ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: spacing), // space-x-4 (responsive)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _increaseQuantity,
                        borderRadius: AppTheme.borderRadiusLargeValue,
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppTheme.spacingSM,
                          ), // p-2
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF78350F).withValues(
                                    alpha: 0.3,
                                  ) // amber-900/30
                                : const Color(0xFFFFFBEB), // amber-100
                            borderRadius: AppTheme.borderRadiusLargeValue,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20, // w-5 h-5
                            color: isDark
                                ? const Color(0xFFD97706) // amber-500
                                : const Color(0xFF92400E), // amber-800
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        // Action Buttons - Always side by side for all screen sizes
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add Package to Cart Button - Minimized width
            IntrinsicWidth(
              child: CartButton(
                text: labels.addPackageToCart,
                onPressed: widget.addingToCart
                    ? null
                    : () =>
                          widget.onAddToCart?.call(_packageData!.id, _quantity),
                isLoading: widget.addingToCart,
                loadingText: labels.adding,
                size: WoodButtonSize.lg,
              ),
            ),
            const SizedBox(width: AppTheme.spacingLG), // gap-4
            // Wishlist button - Custom outlined button
            WoodButton(
              onPressed: () {
                if (widget.packageId != null) {
                  ref
                      .read(wishlistStoreProvider.notifier)
                      .togglePackage(widget.packageId!);
                }
              },
              variant: isPackageInWishlist
                  ? WoodButtonVariant.primary
                  : WoodButtonVariant.outline,
              size: WoodButtonSize.lg,
              child: Icon(
                Icons.favorite,
                color: isPackageInWishlist
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

  Widget _buildPackageContents(
    bool isDark,
    PackageScreenLabels labels,
    List<WishlistItemData> wishlistItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: AppTheme.spacingXXL * 2), // pt-8
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${labels.whatsIncluded} (${_products.length} ${labels.items})',
                style:
                    AppTextStyles.titleLargeStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.bold, // Make it bold
                    ).copyWith(
                      fontSize: 30, // text-3xl
                      fontWeight: FontWeight
                          .bold, // Ensure boldness even after copyWith
                    ),
              ),
              const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
              widget.loadingProducts
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppTheme.spacingXXL * 3,
                        ), // py-12
                        child: Text(
                          labels.loading,
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ),
                        ),
                      ),
                    )
                  : _products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppTheme.spacingXXL * 3,
                        ), // py-12
                        child: Text(
                          labels.noProductsInPackage,
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Always show 2 products per row (same as regular product cards)
                        final crossAxisCount = 2;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing:
                                    AppTheme.spacingLG * 1.5, // gap-6
                                mainAxisSpacing:
                                    AppTheme.spacingLG * 1.5, // gap-6
                                childAspectRatio:
                                    0.75, // Same as regular product cards
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final packageProduct = _products[index];
                            final isInWishlist = wishlistItems.any(
                              (item) => item.productId == packageProduct.id,
                            );

                            // Map PackageProductData to ProductData for ProductCard
                            final product = ProductData(
                              id: packageProduct.id,
                              name: packageProduct.name,
                              description: packageProduct.description,
                              price: packageProduct.price,
                              imageUrl: packageProduct.imageUrl,
                            );

                            return ProductCard(
                              product: product,
                              size: ProductCardSize.small,
                              isInWishlist: isInWishlist,
                              onViewDetails: (id) {
                                if (widget.onProductTap != null) {
                                  widget.onProductTap!(id);
                                } else {
                                  context.push('/product/$id');
                                }
                              },
                              onAddToCart: (id) async {
                                final success = await ref
                                    .read(cartStoreProvider.notifier)
                                    .addProduct(id);
                                if (success) {
                                  if (!context.mounted) return;
                                  final l10n = AppLocalizations.of(context);
                                  NotificationToastService.instance.showSuccess(
                                    l10n.translate('product_added_to_cart'),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  final l10n = AppLocalizations.of(context);
                                  NotificationToastService.instance.showError(
                                    ref.read(cartStoreProvider).error ??
                                        l10n.translate('failed_to_add_to_cart'),
                                  );
                                }
                              },
                              onToggleWishlist: (id) => ref
                                  .read(wishlistStoreProvider.notifier)
                                  .toggleProduct(id),
                              getLocalizedName: (p) => p.name,
                              getLocalizedDescription: (p) =>
                                  p.description ?? '',
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isDark, PackageScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(top: AppTheme.spacingXXL * 2), // pt-8
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels.customerReviews,
                style:
                    AppTextStyles.titleLargeStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.bold, // Make it bold
                    ).copyWith(
                      fontSize: 30, // text-3xl
                      fontWeight: FontWeight.bold, // Reinforce bold in copyWith
                    ),
              ),
              const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
              // Existing Reviews
              widget.commentsLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppTheme.spacingXXL * 2,
                        ), // py-8
                        child: Text(
                          labels.loading,
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ),
                        ),
                      ),
                    )
                  : _comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXXL * 2,
                      ), // mb-8
                      child: Text(
                        labels.noReviewsYet,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    )
                  : Column(
                      children: _comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingLG * 1.5,
                          ), // space-y-6
                          child: _buildReviewCard(comment, isDark, labels),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
              // Add Review Form
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF78350F).withValues(
                          alpha: 0.2,
                        ) // amber-900/20
                      : const Color(0xFFFFFBEB), // amber-50
                  borderRadius: AppTheme.borderRadiusLargeValue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.writeReview,
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-900
                            // font-weight: regular (default)
                          ).copyWith(
                            fontSize: 20, // text-xl
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // mb-4
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating
                        Text(
                          labels.rating,
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFFD1D5DB) // gray-300
                                : const Color(0xFF374151), // gray-700
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM), // mb-2
                        Row(
                          children: List.generate(5, (index) {
                            final rating = index + 1;
                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  _newReviewRating = rating;
                                });
                              },
                              icon: Icon(
                                Icons.star,
                                size: 32, // w-8 h-8
                                color: rating <= _newReviewRating
                                    ? const Color(0xFFEAB308) // yellow-500
                                    : const Color(0xFFD1D5DB), // gray-300
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppTheme.spacingLG), // space-y-4
                        // Comment
                        Text(
                          labels.yourReview,
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFFD1D5DB) // gray-300
                                : const Color(0xFF374151), // gray-700
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM), // mb-2
                        TextField(
                          controller: _newReviewCommentController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: labels.shareThoughts,
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1F2937) // gray-800
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF92400E) // amber-800
                                    : const Color(0xFFFDE68A), // amber-200
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF92400E) // amber-800
                                    : const Color(0xFFFDE68A), // amber-200
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: const BorderSide(
                                color: Color(0xFFD97706), // amber-500
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(
                              AppTheme.spacingLG,
                            ), // px-4 py-2
                            hintStyle: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? const Color(0xFF6B7280) // gray-500
                                  : const Color(0xFF9CA3AF), // gray-400
                            ),
                          ),
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-900
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLG), // space-y-4
                        // Submit Button
                        WoodButton(
                          onPressed: widget.uploadingComment
                              ? null
                              : _handleSubmitReview,
                          size: WoodButtonSize.md,
                          child: Text(
                            widget.uploadingComment
                                ? labels.submitting
                                : labels.submitReview,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    PackageCommentData comment,
    bool isDark,
    PackageScreenLabels labels,
  ) {
    final userName = comment.user?.name ?? labels.anonymous;
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    // Unused userRating removed to fix lint error

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 40, // w-10
                    height: 40, // h-10
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF92400E) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userInitial,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFFFCD34D) // amber-100
                              : const Color(0xFF78350F), // amber-900
                          // font-weight: regular (default)
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD), // space-x-3
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827), // gray-900
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: AppTextStyles.bodySmallStyle(
                          color: const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Rating Stars
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= comment.rating;
                  return Icon(
                    Icons.star,
                    size: 16, // w-4 h-4
                    color: isFilled
                        ? const Color(0xFFEAB308) // yellow-500
                        : const Color(0xFFD1D5DB), // gray-300
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD), // mb-3
          // Comment Text
          Text(
            comment.comment,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? const Color(0xFFD1D5DB) // gray-300
                  : const Color(0xFF374151), // gray-700
            ),
          ),

          // Comment Image
          if (comment.imageUrl != null) ...[
            const SizedBox(height: AppTheme.spacingMD), // mt-3
            LayoutBuilder(
              builder: (context, constraints) {
                final maxImageWidth =
                    (constraints.maxWidth > 448
                            ? 384.0
                            : constraints.maxWidth - 32.0)
                        .toDouble(); // Responsive width
                return ClipRRect(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  child: Image.network(
                    comment.imageUrl!,
                    width: maxImageWidth,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: maxImageWidth,
                      height: 200,
                      color: Colors.grey,
                      child: const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// PackageScreenData - Package data model
class PackageScreenData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  const PackageScreenData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });
}

/// PackageProductData - Product data model
class PackageProductData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final PackageCategoryData? category;

  const PackageProductData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
  });
}

/// _WishlistButton - Custom outlined wishlist button widget
/// Matches the design from the screenshot with hover effects
class _WishlistButton extends StatefulWidget {
  final bool isDark;
  final bool isInWishlist;
  final VoidCallback onTap;

  const _WishlistButton({
    required this.isDark,
    required this.isInWishlist,
    required this.onTap,
  });

  @override
  State<_WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<_WishlistButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on hover and dark mode
    final borderColor = widget.isDark
        ? const Color(0xFFD97706) // amber-600
        : const Color(0xFF78350F); // amber-800

    final backgroundColor = _isHovered
        ? (widget.isDark
              ? const Color(0xFFD97706) // amber-600
              : const Color(0xFF78350F)) // amber-800
        : Colors.transparent;

    final iconColor = _isHovered
        ? Colors.white
        : (widget.isDark
              ? const Color(0xFFFEF3C7) // amber-100
              : const Color(0xFF78350F)); // amber-900

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppTheme.borderRadiusLargeValue,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24, // px-6
              vertical: 12, // py-3
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppTheme.borderRadiusLargeValue,
              border: Border.all(width: 2, color: borderColor),
            ),
            child: Icon(
              widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
              size: 20, // w-5 h-5
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// PackageCategoryData - Category data model
class PackageCategoryData {
  final String id;
  final String name;

  const PackageCategoryData({required this.id, required this.name});
}

/// PackageCommentData - Comment/review data model
class PackageCommentData {
  final String id;
  final String comment;
  final String? imageUrl;
  final DateTime createdAt;
  final String userId;
  final PackageUserData? user;
  final int rating;

  const PackageCommentData({
    required this.id,
    required this.comment,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
    this.user,
    this.rating = 0,
  });
}

/// PackageUserData - User data model
class PackageUserData {
  final String id;
  final String name;

  const PackageUserData({required this.id, required this.name});
}

/// PackageRatingData - Rating data model
class PackageRatingData {
  final double averageRating;
  final int totalRatings;

  const PackageRatingData({
    required this.averageRating,
    required this.totalRatings,
  });
}

/// PackageScreenLabels - Localization labels
class PackageScreenLabels {
  final String loading;
  final String packageNotFound;
  final String save;
  final String specialPackageDeal;
  final String reviews;
  final String noDescriptionAvailable;
  final String quantity;
  final String adding;
  final String addPackageToCart;
  final String whatsIncluded;
  final String items;
  final String noProductsInPackage;
  final String customerReviews;
  final String noReviewsYet;
  final String writeReview;
  final String rating;
  final String yourReview;
  final String shareThoughts;
  final String submitting;
  final String submitReview;
  final String anonymous;
  final String general;

  const PackageScreenLabels({
    required this.loading,
    required this.packageNotFound,
    required this.save,
    required this.specialPackageDeal,
    required this.reviews,
    required this.noDescriptionAvailable,
    required this.quantity,
    required this.adding,
    required this.addPackageToCart,
    required this.whatsIncluded,
    required this.items,
    required this.noProductsInPackage,
    required this.customerReviews,
    required this.noReviewsYet,
    required this.writeReview,
    required this.rating,
    required this.yourReview,
    required this.shareThoughts,
    required this.submitting,
    required this.submitReview,
    required this.anonymous,
    required this.general,
  });

  factory PackageScreenLabels.defaultLabels() {
    return PackageScreenLabels.forLanguage('en');
  }

  factory PackageScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return PackageScreenLabels(
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      packageNotFound: isArabic ? 'الباقة غير موجودة' : 'Package not found',
      save: isArabic ? 'حفظ' : 'Save',
      specialPackageDeal: isArabic ? 'عرض باقة خاص' : 'Special Package Deal',
      reviews: isArabic ? 'تقييمات' : 'reviews',
      noDescriptionAvailable: isArabic
          ? 'لا يوجد وصف متاح'
          : 'No description available',
      quantity: isArabic ? 'الكمية' : 'Quantity',
      adding: isArabic ? 'جاري الإضافة...' : 'Adding...',
      addPackageToCart: isArabic
          ? 'أضف الباقة إلى السلة'
          : 'Add Package to Cart',
      whatsIncluded: isArabic ? 'ما المضمن' : "What's Included",
      items: isArabic ? 'عناصر' : 'items',
      noProductsInPackage: isArabic
          ? 'لا توجد منتجات في هذه الباقة'
          : 'No products in package',
      customerReviews: isArabic ? 'تقييمات العملاء' : 'Customer Reviews',
      noReviewsYet: isArabic ? 'لا توجد تقييمات بعد' : 'No reviews yet',
      writeReview: isArabic ? 'اكتب تقييماً' : 'Write a Review',
      rating: isArabic ? 'التقييم' : 'Rating',
      yourReview: isArabic ? 'تقييمك' : 'Your Review',
      shareThoughts: isArabic ? 'شارك أفكارك...' : 'Share your thoughts...',
      submitting: isArabic ? 'جاري الإرسال...' : 'Submitting...',
      submitReview: isArabic ? 'إرسال التقييم' : 'Submit Review',
      anonymous: isArabic ? 'مجهول' : 'Anonymous',
      general: isArabic ? 'عام' : 'General',
    );
  }
}
