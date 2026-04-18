import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/language_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/api_services/catalog_api_service.dart';

/// CategoryScreen - Category products screen
///
/// Equivalent to Vue's Category.vue page.
/// Displays category information and products grid.
///
/// Features:
/// - Category header with name and description
/// - Products grid (responsive: 1-4 columns)
/// - Loading state
/// - Category not found state
/// - Empty products state
/// - Dark mode support
/// - Responsive design
class CategoryScreen extends ConsumerStatefulWidget {
  /// Category ID
  final String categoryId;

  /// Mock category data
  final CategoryData? category;

  /// Mock products data
  final List<ProductData>? products;

  /// Loading state
  final bool loadingCategory;
  final bool loadingProducts;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when add to cart is tapped
  final void Function(String productId)? onAddToCart;

  /// Callback when go to dashboard is tapped
  final VoidCallback? onGoToDashboard;

  /// Callback when login is tapped
  final VoidCallback? onLoginTap;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Price formatter function
  final String Function(double)? formatPrice;

  /// Labels for localization
  final CategoryScreenLabels? labels;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    this.category,
    this.products,
    this.loadingCategory = false,
    this.loadingProducts = false,
    this.onProductTap,
    this.onAddToCart,
    this.onLoginTap,
    this.onGoToDashboard,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<ProductData> _products = [];

  bool _loading = false;
  final _catalogApi = CatalogApiService();

  @override
  void initState() {
    super.initState();
    if (widget.products != null) {
      _products = widget.products!;
    } else {
      _loadFromApi();
    }
  }

  Future<void> _loadFromApi() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final productsRaw = await _catalogApi.fetchProducts();
      final parsed = <ProductData>[];

      for (final item in productsRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        // Filter by category
        final categoryId = map['category_id']?.toString();
        if (categoryId != widget.categoryId) continue;

        final priceStr = map['price']?.toString();
        final price = double.tryParse(priceStr ?? '') ?? 0.0;
        final stock = map['stock'] is int
            ? map['stock'] as int
            : int.tryParse(map['stock']?.toString() ?? '');

        final imageUrl = map['image_url']?.toString();
        final imageUrls = map['image_urls'];
        final resolvedImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
            ? imageUrl
            : (imageUrls is List && imageUrls.isNotEmpty)
            ? imageUrls.first?.toString()
            : null;

        final adminRating = map['admin_rating'];
        AdminRating? rating;
        if (adminRating != null) {
          final ratingValue = adminRating is num
              ? adminRating.toDouble()
              : double.tryParse(adminRating.toString());
          if (ratingValue != null) {
            rating = AdminRating(rating: ratingValue);
          }
        }

        parsed.add(
          ProductData(
            id: id,
            name: (map['name'] ?? '').toString(),
            description: map['description']?.toString(),
            price: price,
            imageUrl: resolvedImageUrl,
            stock: stock,
            adminRating: rating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _products = parsed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (kDebugMode) {
          debugPrint('Category products load failed: $e');
        }
        final l10n = AppLocalizations.of(context);
        NotificationToastService.instance.showError(
          '${l10n.translate('failed_to_load_products')}: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? CategoryScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      child: Container(
        color: isDark
            ? const Color(0xFF111827) // gray-900
            : const Color(0xFFF9FAFB), // gray-50
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingXXL * 2,
          ), // py-8
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG,
            ), // px-4
            child: _buildContent(isDark, labels),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, CategoryScreenLabels labels) {
    // Loading State
    if (widget.loadingCategory || widget.loadingProducts || _loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingXXL * 3,
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
      );
    }

    // Category Not Found
    if (widget.category == null) {
      return _buildCategoryNotFound(isDark, labels);
    }

    // Category Content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        _buildCategoryHeader(isDark, labels),

        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        // Products Section
        _buildProductsSection(isDark, labels),
      ],
    );
  }

  Widget _buildCategoryNotFound(bool isDark, CategoryScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingXXL * 3,
        ), // py-12
        child: Column(
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 64, // w-16 h-16
              color: isDark
                  ? const Color(0xFF4B5563) // gray-600
                  : const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              labels.categoryNotFound,
              style:
                  AppTextStyles.titleLargeStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-800
                    fontWeight: AppTextStyles.medium,
                  ).copyWith(
                    fontSize: 20, // text-xl
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            WoodButton(
              onPressed: widget.onGoToDashboard,
              size: WoodButtonSize.md,
              child: Text(labels.goToDashboard),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(bool isDark, CategoryScreenLabels labels) {
    final category = widget.category!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.getLocalizedName?.call(category) ?? category.name} ${labels.category}',
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-900
                // font-weight: regular (default)
              ).copyWith(
                fontSize: 30, // text-3xl
              ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        Text(
          widget.getLocalizedDescription?.call(category) ??
              labels.exploreCuratedCollection,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(bool isDark, CategoryScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.products,
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-900
                // font-weight: regular (default)
              ).copyWith(
                fontSize: 24, // text-2xl
              ),
        ),
        const SizedBox(height: AppTheme.spacingLG), // mb-4
        // Empty State
        if (_products.isEmpty)
          _buildEmptyProductsState(isDark, labels)
        else
          // Products Grid
          _buildProductsGrid(isDark, labels),
      ],
    );
  }

  Widget _buildEmptyProductsState(bool isDark, CategoryScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingXXL * 3,
        ), // py-12
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64, // w-16 h-16
              color: isDark
                  ? const Color(0xFF4B5563) // gray-600
                  : const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              labels.noProductsInCategory,
              style:
                  AppTextStyles.titleMediumStyle(
                    fontWeight: AppTextStyles.medium,
                  ).copyWith(
                    fontSize: 18, // text-lg
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            Text(
              labels.checkBackLater,
              style: AppTextStyles.bodySmallStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(bool isDark, CategoryScreenLabels labels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1; // grid-cols-1
        if (constraints.maxWidth >= 1024) {
          crossAxisCount = 4; // lg:grid-cols-4
        } else if (constraints.maxWidth >= 768) {
          crossAxisCount = 3; // md:grid-cols-3
        } else if (constraints.maxWidth >= 640) {
          crossAxisCount = 2; // sm:grid-cols-2
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingLG, // gap-4
            mainAxisSpacing: AppTheme.spacingLG, // gap-4
            childAspectRatio: 0.75,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];

            // Watch wishlist items to react to heart clicks
            final wishlistItems = ref.watch(wishlistStoreProvider).items;
            final isInWishlist = wishlistItems.any(
              (item) => item.productId == product.id,
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
                final l10n = AppLocalizations.of(context);
                final success = await ref
                    .read(cartStoreProvider.notifier)
                    .addProduct(id);

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
              },
              onToggleWishlist: (id) async {
                final success = await ref
                    .read(wishlistStoreProvider.notifier)
                    .toggleProduct(id);
                if (!success) {
                  if (!context.mounted) return;
                  final l10n = AppLocalizations.of(context);
                  NotificationToastService.instance.showError(
                    ref.read(wishlistStoreProvider).error ??
                        l10n.translate('failed_to_update_wishlist'),
                  );
                }
              },
              getLocalizedName: (p) => p.name,
              getLocalizedDescription: (p) => p.description ?? '',
            );
          },
        );
      },
    );
  }
}

/// CategoryData - Category data model
class CategoryData {
  final String id;
  final String name;
  final String? description;
  final String? descriptionAr;
  final String? descriptionEn;

  const CategoryData({
    required this.id,
    required this.name,
    this.description,
    this.descriptionAr,
    this.descriptionEn,
  });
}

/// CategoryScreenLabels - Localization labels
class CategoryScreenLabels {
  final String loading;
  final String categoryNotFound;
  final String goToDashboard;
  final String category;
  final String exploreCuratedCollection;
  final String products;
  final String noProductsInCategory;
  final String checkBackLater;
  final String addToCart;
  final String adding;
  final String outOfStock;

  const CategoryScreenLabels({
    required this.loading,
    required this.categoryNotFound,
    required this.goToDashboard,
    required this.category,
    required this.exploreCuratedCollection,
    required this.products,
    required this.noProductsInCategory,
    required this.checkBackLater,
    required this.addToCart,
    required this.adding,
    required this.outOfStock,
  });

  factory CategoryScreenLabels.defaultLabels() {
    return CategoryScreenLabels.forLanguage('en');
  }

  factory CategoryScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return CategoryScreenLabels(
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      categoryNotFound: isArabic ? 'الفئة غير موجودة' : 'Category not found',
      goToDashboard: isArabic ? 'انتقل إلى الصفحة الرئيسية' : 'Go to Dashboard',
      category: isArabic ? 'الفئة' : 'Category',
      exploreCuratedCollection: isArabic
          ? 'استكشف مجموعتنا المختارة'
          : 'Explore our curated collection',
      products: isArabic ? 'المنتجات' : 'Products',
      noProductsInCategory: isArabic
          ? 'لا توجد منتجات في هذه الفئة'
          : 'No products in this category',
      checkBackLater: isArabic
          ? 'تحقق لاحقاً للمنتجات الجديدة'
          : 'Check back later for new products',
      addToCart: isArabic ? 'أضف إلى السلة' : 'Add to Cart',
      adding: isArabic ? 'جاري الإضافة...' : 'Adding...',
      outOfStock: isArabic ? 'نفدت الكمية' : 'Out of Stock',
    );
  }
}
