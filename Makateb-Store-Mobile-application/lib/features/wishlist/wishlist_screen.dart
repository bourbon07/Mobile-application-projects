import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/stores/language_store.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/stores/cart_store.dart';

/// WishlistScreen - Wishlist screen
///
/// Equivalent to Vue's Wishlist.vue page.
/// Displays user's wishlist items (products and packages).
///
/// Features:
/// - Empty state with heart icon
/// - Header with item count
/// - Products grid using ProductCard
/// - Packages grid with custom cards
/// - Remove buttons on each item
/// - Loading state
/// - Dark mode support
/// - Responsive design
class WishlistScreen extends ConsumerStatefulWidget {
  /// Mock wishlist items data
  final List<WishlistItemData>? wishlistItems;

  /// Loading state
  final bool loading;

  /// Callback when browse products is tapped
  final VoidCallback? onBrowseProducts;

  /// Callback when product is removed
  final void Function(String wishlistItemId, String? productId)?
  onRemoveProduct;

  /// Callback when package is removed
  final void Function(String wishlistItemId, String? packageId)?
  onRemovePackage;

  /// Callback when product is viewed
  final void Function(String productId)? onViewProduct;

  /// Callback when package is viewed
  final void Function(String packageId)? onViewPackage;

  /// Callback when product is added to cart
  final void Function(String productId)? onAddProductToCart;

  /// Callback when package is added to cart
  final void Function(String packageId)? onAddPackageToCart;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Labels for localization
  final WishlistScreenLabels? labels;

  const WishlistScreen({
    super.key,
    this.wishlistItems,
    this.loading = false,
    this.onBrowseProducts,
    this.onRemoveProduct,
    this.onRemovePackage,
    this.onViewProduct,
    this.onViewPackage,
    this.onAddProductToCart,
    this.onAddPackageToCart,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh wishlist when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistStoreProvider.notifier).loadWishlist();
    });
  }

  String? _getItemImage(WishlistItemData item) {
    return item.product?.imageUrl ?? item.package?.imageUrl;
  }

  String _getItemName(WishlistItemData item) {
    if (item.product != null) {
      return widget.getLocalizedName?.call(item.product) ?? item.product!.name;
    }
    if (item.package != null) {
      return widget.getLocalizedName?.call(item.package) ?? item.package!.name;
    }
    return AppLocalizations.of(context).translate('unknown_item');
  }

  String _getItemDescription(WishlistItemData item) {
    if (item.product != null) {
      return widget.getLocalizedDescription?.call(item.product) ??
          (item.product!.description ?? '');
    }
    if (item.package != null) {
      return widget.getLocalizedDescription?.call(item.package) ??
          (item.package!.description ?? '');
    }
    return '';
  }

  double _getItemPrice(WishlistItemData item) {
    return item.product?.price ?? item.package?.price ?? 0.0;
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? WishlistScreenLabels.forLanguage(currentLanguage);

    // Watch wishlist state from store
    final wishlistState = ref.watch(wishlistStoreProvider);
    final items = wishlistState.items;
    final isLoading = wishlistState.isLoading;
    final error = wishlistState.error;

    return PageLayout(
      scrollable: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF1F2937)]
                : [const Color(0xFFFEF3C7), Colors.white],
          ),
        ),
        child: _buildBody(isLoading, items, error, isDark, labels),
      ),
    );
  }

  Widget _buildBody(
    bool isLoading,
    List<WishlistItemData> items,
    String? error,
    bool isDark,
    WishlistScreenLabels labels,
  ) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).translate('something_went_wrong'),
                style: AppTextStyles.titleLargeStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMediumStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              WoodButton(
                onPressed: () =>
                    ref.read(wishlistStoreProvider.notifier).loadWishlist(),
                child: Text(
                  AppLocalizations.of(context).translate('try_again'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              labels.loading,
              style: AppTextStyles.bodyLargeStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Stack(
        children: [
          _buildEmptyState(isDark, labels),
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      );
    }

    return Stack(
      children: [
        _buildWishlistContent(items, isDark, labels),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, WishlistScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart Icon
            Icon(
              Icons.favorite_border,
              size: 96, // w-24 h-24
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
            // Title
            Text(
              labels.wishlistEmpty,
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
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            // Subtitle
            Text(
              labels.saveFavoriteProducts,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
            // Browse Products Button
            WoodButton(
              onPressed: widget.onBrowseProducts,
              size: WoodButtonSize.lg,
              child: Text(
                labels.browseProducts,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(
    List<WishlistItemData> items,
    bool isDark,
    WishlistScreenLabels labels,
  ) {
    final productItems = items.where((item) => item.product != null).toList();
    final packageItems = items.where((item) => item.package != null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG * 2, // px-4 sm:px-6 lg:px-8
        vertical: AppTheme.spacingXXL * 2, // py-8
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 32, // w-8 h-8
                  color: const Color(0xFFEF4444), // red-500
                ),
                const SizedBox(width: AppTheme.spacingMD), // space-x-3
                Text(
                  labels.myWishlist,
                  style:
                      AppTextStyles.titleLargeStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        // font-weight: regular (default)
                      ).copyWith(
                        fontSize: 36, // text-4xl
                      ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Consumer(
                  builder: (context, ref, _) {
                    final itemCount = ref
                        .watch(wishlistStoreProvider)
                        .itemCount;
                    return Text(
                      '($itemCount ${labels.items})',
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ).copyWith(
                            fontSize: 20, // text-xl
                          ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
            // Items Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1024
                      ? 4
                      : constraints.maxWidth >= 640
                      ? 2
                      : 2;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                      mainAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                      childAspectRatio: 0.7,
                    ),
                    itemCount: productItems.length + packageItems.length,
                    itemBuilder: (context, index) {
                      if (index < productItems.length) {
                        // Product item
                        final item = productItems[index];
                        return _buildProductItem(item, isDark, labels);
                      } else {
                        // Package item
                        final item = packageItems[index - productItems.length];
                        return _buildPackageItem(item, isDark, labels);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    WishlistItemData item,
    bool isDark,
    WishlistScreenLabels labels,
  ) {
    // Convert WishlistProductData to ProductData
    final productData = ProductData(
      id: item.product!.id,
      name: item.product!.name,
      description: item.product!.description,
      price: item.product!.price,
      imageUrl: item.product!.imageUrl,
      stock: item.product!.stock,
    );

    return Stack(
      children: [
        // Product Card
        ProductCard(
          product: productData,
          size: ProductCardSize.small,
          hideWishlistButton: true,
          onViewDetails: widget.onViewProduct,
          onAddToCart: (productId) => _addProductToCart(productId),
        ),

        // Remove Button
        Positioned(
          top: 6, // top-1.5
          right: 6, // right-1.5
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeProduct(item),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(4), // p-1
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9), // bg-white/90
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 16, // w-4 h-4
                  color: const Color(0xFF374151), // gray-700
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageItem(
    WishlistItemData item,
    bool isDark,
    WishlistScreenLabels labels,
  ) {
    final imageUrl = _getItemImage(item);
    final name = _getItemName(item);
    final description = _getItemDescription(item);
    final price = _getItemPrice(item);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        widget.onViewPackage?.call(item.packageId ?? ''),
                    child: Container(
                      color: isDark
                          ? const Color(0xFF374151) // gray-700
                          : const Color(0xFFE5E7EB), // gray-200
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderIcon(isDark),
                            )
                          : _buildPlaceholderIcon(isDark),
                    ),
                  ),
                ),
              ),

              // Info Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onViewPackage?.call(
                              item.packageId ?? '',
                            ),
                            child: Text(
                              name,
                              style:
                                  AppTextStyles.titleSmallStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827), // gray-900
                                    fontWeight: AppTextStyles.medium,
                                  ).copyWith(
                                    fontSize: 18, // text-lg
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Description
                      Text(
                        description.isEmpty
                            ? labels.noDescriptionAvailable
                            : description,
                        style: AppTextStyles.bodySmallStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppTheme.spacingMD), // mb-3
                      // Price and Add Button
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isVerySmall = constraints.maxWidth < 320;

                          if (isVerySmall) {
                            // Very small screens: Stack vertically
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatPrice(price),
                                  style:
                                      AppTextStyles.titleMediumStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF111827,
                                              ), // gray-900
                                        // font-weight: regular (default)
                                      ).copyWith(
                                        fontSize: 18, // text-lg
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                WoodButton(
                                  onPressed: () => _addPackageToCart(item),
                                  size: WoodButtonSize.sm,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart,
                                        size: 16,
                                        color: Colors.white,
                                      ), // w-4 h-4
                                      const SizedBox(width: AppTheme.spacingSM),
                                      Flexible(
                                        child: Text(
                                          labels.add,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Normal screens: Horizontal layout
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _formatPrice(price),
                                    style:
                                        AppTextStyles.titleMediumStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(
                                                  0xFF111827,
                                                ), // gray-900
                                          // font-weight: regular (default)
                                        ).copyWith(
                                          fontSize: 18, // text-lg
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSM),
                                WoodButton(
                                  onPressed: () => _addPackageToCart(item),
                                  size: WoodButtonSize.sm,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart,
                                        size: 16,
                                        color: Colors.white,
                                      ), // w-4 h-4
                                      const SizedBox(width: AppTheme.spacingSM),
                                      Flexible(
                                        child: Text(
                                          labels.add,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Remove Button
          Positioned(
            top: 6, // top-1.5
            right: 6, // right-1.5
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removePackage(item),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(4), // p-1
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9), // bg-white/90
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16, // w-4 h-4
                    color: const Color(0xFF374151), // gray-700
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 128, // w-32 h-32
        color: isDark
            ? const Color(0xFF9CA3AF) // gray-400
            : const Color(0xFF6B7280), // gray-500
      ),
    );
  }

  Future<void> _removeProduct(WishlistItemData item) async {
    if (item.productId == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(wishlistStoreProvider.notifier)
        .removeProduct(item.productId!);

    if (success) {
      widget.onRemoveProduct?.call(item.id, item.productId);
      NotificationToastService.instance.showSuccess(
        l10n.translate('removed_from_wishlist'),
      );
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_remove_from_wishlist'),
      );
    }
  }

  Future<void> _removePackage(WishlistItemData item) async {
    if (item.packageId == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(wishlistStoreProvider.notifier)
        .removePackage(item.packageId!);

    if (success) {
      widget.onRemovePackage?.call(item.id, item.packageId);
      NotificationToastService.instance.showSuccess(
        l10n.translate('removed_from_wishlist'),
      );
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_remove_from_wishlist'),
      );
    }
  }

  Future<void> _addProductToCart(String productId) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .addProduct(productId);

    if (success) {
      widget.onAddProductToCart?.call(productId);
      NotificationToastService.instance.showSuccess(
        l10n.translate('product_added_to_cart'),
      );
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_add_to_cart'),
      );
    }
  }

  Future<void> _addPackageToCart(WishlistItemData item) async {
    if (item.packageId == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .addPackage(item.packageId!);

    if (success) {
      widget.onAddPackageToCart?.call(item.packageId!);
      NotificationToastService.instance.showSuccess(
        l10n.translate('package_added_to_cart'),
      );
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_add_to_cart'),
      );
    }
  }
}

// WishlistItemData, WishlistProductData, and WishlistPackageData are now imported from wishlist_store.dart

/// WishlistScreenLabels - Localization labels
class WishlistScreenLabels {
  final String wishlistEmpty;
  final String saveFavoriteProducts;
  final String browseProducts;
  final String myWishlist;
  final String items;
  final String loading;
  final String add;
  final String noDescriptionAvailable;

  const WishlistScreenLabels({
    required this.wishlistEmpty,
    required this.saveFavoriteProducts,
    required this.browseProducts,
    required this.myWishlist,
    required this.items,
    required this.loading,
    required this.add,
    required this.noDescriptionAvailable,
  });

  factory WishlistScreenLabels.defaultLabels() {
    return WishlistScreenLabels.forLanguage('en');
  }

  factory WishlistScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return WishlistScreenLabels(
      wishlistEmpty: isArabic ? 'قائمة الأمنيات فارغة' : 'Wishlist Empty',
      saveFavoriteProducts: isArabic
          ? 'احفظ منتجاتك المفضلة هنا'
          : 'Save your favorite products here',
      browseProducts: isArabic ? 'تصفح المنتجات' : 'Browse Products',
      myWishlist: isArabic ? 'قائمة الأمنيات الخاصة بي' : 'My Wishlist',
      items: isArabic ? 'عناصر' : 'items',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      add: isArabic ? 'أضف' : 'Add',
      noDescriptionAvailable: isArabic
          ? 'لا يوجد وصف متاح'
          : 'No description available',
    );
  }
}


