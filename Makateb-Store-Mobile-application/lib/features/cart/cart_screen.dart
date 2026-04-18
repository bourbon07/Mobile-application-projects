import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/confirmation_modal.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/widgets/product_card.dart' show ProductData;
import '../../core/widgets/package_card.dart' show PackageData;
import '../../core/stores/cart_store.dart';

/// CartScreen - Shopping cart screen
///
/// Equivalent to Vue's Cart.vue page.
/// Displays shopping cart items, order summary, and checkout functionality.
///
/// Features:
/// - Cart items list with quantity controls
/// - Order summary sidebar
/// - Empty cart state
/// - Package contents modal
/// - Dark mode support
/// - Responsive design
class CartScreen extends ConsumerStatefulWidget {
  /// Mock cart items data
  final List<CartItemData>? cartItems;

  /// Callback when quantity is updated
  final void Function(String itemId, int newQuantity)? onUpdateQuantity;

  /// Callback when item is removed
  final void Function(String itemId)? onRemoveItem;

  /// Callback when checkout is tapped
  final VoidCallback? onCheckout;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when package is tapped
  final void Function(String packageId)? onPackageTap;

  /// Callback when start shopping is tapped
  final VoidCallback? onStartShopping;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Price formatter function
  final String Function(double)? formatPrice;

  /// Labels for localization
  final CartScreenLabels? labels;

  const CartScreen({
    super.key,
    this.cartItems,
    this.onUpdateQuantity,
    this.onRemoveItem,
    this.onCheckout,
    this.onProductTap,
    this.onPackageTap,
    this.onStartShopping,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh cart when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartStoreProvider.notifier).loadCart();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart when navigating back to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartStoreProvider.notifier).loadCart();
    });
  }

  double _getItemPrice(CartItemData item) {
    if (item.packageId != null && item.package != null) {
      if (item.package!.price > 0) {
        return item.package!.price;
      }
      if (item.package!.products != null) {
        return item.package!.products!.fold<double>(
          0.0,
          (sum, product) => sum + (product.price ?? 0.0),
        );
      }
      return 0.0;
    } else if (item.product != null) {
      return item.product!.price;
    }
    return 0.0;
  }

  double _getSubtotal(List<CartItemData> items) {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + (_getItemPrice(item) * item.quantity),
    );
  }

  Future<void> _updateQuantity(String id, int newQuantity) async {
    if (newQuantity < 1) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .updateQuantity(id, newQuantity);

    if (success) {
      widget.onUpdateQuantity?.call(id, newQuantity);
    } else {
      final error = ref.read(cartStoreProvider).error;
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_update_quantity') +
            (error != null ? ': $error' : ''),
      );
    }
  }

  void _removeItem(String id) {
    final l10n = AppLocalizations.of(context);
    final labels = widget.labels ?? CartScreenLabels.fromLocalizations(l10n);
    showDialog(
      context: context,
      builder: (context) => ConfirmationModal(
        title: labels.removeItem,
        message: labels.removeItemConfirm,
        isDestructive: true,
        onConfirm: () async {
          Navigator.of(context).pop();

          final success = await ref
              .read(cartStoreProvider.notifier)
              .removeItem(id);

          if (success) {
            widget.onRemoveItem?.call(id);
            NotificationToastService.instance.showSuccess(
              l10n.translate('item_removed_from_cart'),
            );
          } else {
            final error = ref.read(cartStoreProvider).error;
            NotificationToastService.instance.showError(
              l10n.translate('failed_to_remove_item') +
                  (error != null ? ': $error' : ''),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isVisible: true,
      ),
    );
  }

  void _viewPackageContents(PackageData package) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    _showPackageModal(
      context,
      package,
      isDark,
      widget.labels ?? CartScreenLabels.fromLocalizations(l10n),
      widget.getLocalizedName,
      widget.getLocalizedDescription,
      _formatPrice,
    );
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final labels = widget.labels ?? CartScreenLabels.fromLocalizations(l10n);

    // Watch cart state from store
    final cartState = ref.watch(cartStoreProvider);
    final cartItems = cartState.items;
    final isLoading = cartState.isLoading;

    // Convert CartItem to CartItemData for compatibility
    final cartItemsData = cartItems.map((item) {
      return CartItemData(
        id: item.id,
        productId: item.productId,
        packageId: item.packageId,
        quantity: item.quantity,
        product: item.product,
        package: item.package,
      );
    }).toList();

    return PageLayout(
      isCartPage: true, // Hide mobile cart button on cart page
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
                    const Color(0xFFFEF3C7), // amber-50 (matching wishlist)
                    Colors.white,
                  ],
          ),
        ),
        child: (isLoading && cartItemsData.isEmpty)
            ? Center(
                child: Text(
                  labels.loading,
                  style: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                  ),
                ),
              )
            : Stack(
                children: [
                  cartItemsData.isEmpty
                      ? _buildEmptyCart(isDark, labels)
                      : _buildCartContent(cartItemsData, isDark, labels),
                  if (isLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCart(bool isDark, CartScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 96, // h-24 w-24
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
            Text(
              labels.yourCartIsEmpty,
              style:
                  AppTextStyles.titleLargeStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    // font-weight: regular (default)
                  ).copyWith(
                    fontSize: AppTextStyles.text3XL, // text-3xl
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              labels.addSomeProducts,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
            WoodButton(
              onPressed:
                  widget.onStartShopping ?? () => context.go('/dashboard'),
              size: WoodButtonSize.lg,
              child: Text(
                labels.startShopping,
                style: AppTextStyles.bodyLargeStyle(
                  color: Colors.white,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
    List<CartItemData> items,
    bool isDark,
    CartScreenLabels labels,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG), // px-4 py-8
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              labels.shoppingCart,
              style:
                  AppTextStyles.titleLargeStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    // font-weight: regular (default)
                  ).copyWith(
                    fontSize: AppTextStyles.text4XL, // text-4xl
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
            // Cart Items and Summary
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1024) {
                  // Desktop: Side by side
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items (2/3 width)
                      Expanded(
                        flex: 2,
                        child: _buildCartItemsList(items, isDark, labels),
                      ),
                      const SizedBox(width: AppTheme.spacingXXL * 2), // gap-8
                      // Order Summary (1/3 width)
                      Expanded(
                        flex: 1,
                        child: _buildOrderSummary(items, isDark, labels),
                      ),
                    ],
                  );
                } else {
                  // Mobile: Stacked
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCartItemsList(items, isDark, labels),
                      const SizedBox(height: AppTheme.spacingXXL * 2),
                      _buildOrderSummary(items, isDark, labels),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(
    List<CartItemData> items,
    bool isDark,
    CartScreenLabels labels,
  ) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppTheme.spacingLG,
          ), // space-y-4
          child: _buildCartItem(item, isDark, labels),
        );
      }).toList(),
    );
  }

  Widget _buildCartItem(
    CartItemData item,
    bool isDark,
    CartScreenLabels labels,
  ) {
    final hasPackage = item.packageId != null && item.package != null;
    final hasProduct = item.productId != null && item.product != null;
    final itemPrice = _getItemPrice(item);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.3) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: hasPackage
                ? () => _viewPackageContents(item.package!)
                : () {
                    if (widget.onProductTap != null) {
                      widget.onProductTap!(item.productId!);
                    } else {
                      context.push('/product/${item.productId!}');
                    }
                  },
            child: Container(
              width: 96, // w-24
              height: 96, // h-24
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadiusLargeValue,
                color: isDark
                    ? const Color(0xFF374151) // gray-700
                    : const Color(0xFFE5E7EB), // gray-200
              ),
              child: (hasPackage && item.package!.imageUrl != null)
                  ? ClipRRect(
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      child: Image.network(
                        item.package!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(isDark),
                      ),
                    )
                  : (hasProduct && item.product!.imageUrl != null)
                  ? ClipRRect(
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      child: Image.network(
                        item.product!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(isDark),
                      ),
                    )
                  : _buildPlaceholderIcon(isDark),
            ),
          ),
          const SizedBox(width: AppTheme.spacingLG), // gap-4
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                GestureDetector(
                  onTap: hasPackage
                      ? () => _viewPackageContents(item.package!)
                      : () {
                          if (widget.onProductTap != null) {
                            widget.onProductTap!(item.productId!);
                          } else {
                            context.push('/product/${item.productId!}');
                          }
                        },
                  child: Text(
                    hasPackage
                        ? (widget.getLocalizedName?.call(item.package!) ??
                              item.package!.name)
                        : (hasProduct
                              ? (widget.getLocalizedName?.call(item.product!) ??
                                    item.product!.name)
                              : 'Item ${item.id}'),
                    style:
                        AppTextStyles.titleMediumStyle(
                          fontWeight: AppTextStyles.medium,
                        ).copyWith(
                          fontSize: AppTextStyles.textLG, // text-lg
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM), // mb-2
                // Price per item
                Text(
                  '${_formatPrice(itemPrice)} JD',
                  style: AppTextStyles.titleMediumStyle(
                    color: isDark
                        ? const Color(0xFFD97706) // amber-500
                        : const Color(0xFF78350F), // amber-900
                    // font-weight: regular (default)
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD), // mb-3
                // Quantity Controls
                LayoutBuilder(
                  builder: (context, constraints) {
                    // On very small screens, reduce spacing
                    final isVerySmall = constraints.maxWidth < 360;
                    final spacing = isVerySmall
                        ? AppTheme.spacingSM
                        : AppTheme.spacingMD;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrease Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: item.quantity <= 1
                                ? null
                                : () => _updateQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  ),
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
                                    : const Color(0xFFFEF3C7), // amber-100
                                borderRadius: AppTheme.borderRadiusLargeValue,
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16, // w-4 h-4
                                color: item.quantity <= 1
                                    ? Colors.grey
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF111827)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        SizedBox(
                          width: 40, // w-10
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.titleMediumStyle(
                                  fontWeight: AppTextStyles.medium,
                                ).copyWith(
                                  fontSize: 18, // text-lg
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: spacing),
                        // Increase Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _updateQuantity(item.id, item.quantity + 1),
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
                                    : const Color(0xFFFEF3C7), // amber-100
                                borderRadius: AppTheme.borderRadiusLargeValue,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16, // w-4 h-4
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
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
          ),

          // Remove Button and Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remove Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeItem(item.id),
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSM), // p-2
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: AppTheme.borderRadiusLargeValue,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20, // w-5 h-5
                      color: const Color(0xFFEF4444), // red-500
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              // Total Price
              Text(
                '${_formatPrice(itemPrice * item.quantity)} JD',
                style:
                    AppTextStyles.titleMediumStyle(
                      // font-weight: regular (default)
                    ).copyWith(
                      fontSize: AppTextStyles.textLG, // text-lg
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 48, // w-12 h-12
        color: isDark
            ? const Color(0xFF9CA3AF) // gray-400
            : const Color(0xFF6B7280), // gray-500
      ),
    );
  }

  Widget _buildOrderSummary(
    List<CartItemData> items,
    bool isDark,
    CartScreenLabels labels,
  ) {
    final subtotal = _getSubtotal(items);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding: p-3 sm:p-4 md:p-6
        final padding = constraints.maxWidth >= 768
            ? AppTheme.spacingLG *
                  1.5 // md:p-6
            : constraints.maxWidth >= 640
            ? AppTheme
                  .spacingLG // sm:p-4
            : AppTheme.spacingMD; // p-3

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937) // gray-800
                : Colors.white,
            borderRadius: AppTheme.borderRadiusLargeValue,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF92400E) // amber-900
                  : const Color(0xFFFDE68A), // amber-200
              width: 2,
            ),
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
              // Title
              Text(
                labels.orderSummary,
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
              const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
              // Summary Items
              Column(
                children: [
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels.subtotal,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                      ),
                      Text(
                        '${_formatPrice(subtotal)} JD',
                        style: AppTextStyles.bodyMediumStyle(
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM), // space-y-2/3
                  // Shipping
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels.shipping,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                      ),
                      Text(
                        labels.calculatedAtCheckout,
                        style: AppTextStyles.bodySmallStyle(
                          color: const Color(0xFF16A34A), // green-600
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // Divider
                  Divider(
                    thickness: 2,
                    color: isDark
                        ? const Color(0xFF92400E) // amber-800
                        : const Color(0xFFFDE68A), // amber-200
                  ),
                  const SizedBox(height: AppTheme.spacingSM), // pt-2/3
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels.total,
                        style:
                            AppTextStyles.titleLargeStyle(
                              // font-weight: regular (default)
                            ).copyWith(
                              fontSize: 20, // text-xl
                            ),
                      ),
                      Text(
                        '${_formatPrice(subtotal)} JD',
                        style:
                            AppTextStyles.titleLargeStyle(
                              color: isDark
                                  ? const Color(0xFFD97706) // amber-500
                                  : const Color(0xFF78350F), // amber-900
                              // font-weight: regular (default)
                            ).copyWith(
                              fontSize: 24, // text-2xl
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: WoodButton(
                  onPressed: widget.onCheckout ?? () => context.go('/checkout'),
                  size: WoodButtonSize.md,
                  child: Text(
                    labels.proceedToCheckout,
                    style: AppTextStyles.bodyMediumStyle(
                      color: Colors.white,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Show Package Contents Modal
void _showPackageModal(
  BuildContext context,
  PackageData package,
  bool isDark,
  CartScreenLabels labels,
  String Function(dynamic)? getLocalizedName,
  String Function(dynamic)? getLocalizedDescription,
  String Function(double)? formatPrice,
) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 672,
          maxHeight: 640,
        ), // max-w-2xl max-h-[80vh]
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937) // gray-800
              : Colors.white,
          borderRadius: AppTheme.borderRadiusLargeValue, // rounded-xl
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      getLocalizedName?.call(package) ?? package.name,
                      style:
                          AppTextStyles.titleLargeStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            // font-weight: regular (default)
                          ).copyWith(
                            fontSize: 24, // text-2xl
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? const Color(0xFF9CA3AF) // gray-400
                          : const Color(0xFF4B5563), // gray-600
                    ),
                  ),
                ],
              ),
            ),

            // Description
            if (getLocalizedDescription?.call(package) != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG * 1.5,
                ),
                child: Text(
                  getLocalizedDescription!.call(package),
                  style: AppTextStyles.bodySmallStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                  ),
                ),
              ),

            const SizedBox(height: AppTheme.spacingLG),

            // Products List
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG * 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).translate('package_contents')} (${package.products?.length ?? 0})',
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            fontWeight: AppTextStyles.medium,
                          ).copyWith(
                            fontSize: 18, // text-lg
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    if (package.products != null &&
                        package.products!.isNotEmpty)
                      ...package.products!.map((product) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingSM,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMD),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151) // gray-700
                                  : const Color(0xFFF9FAFB), // gray-50
                              borderRadius: AppTheme.borderRadiusLargeValue,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, // w-12
                                  height: 48, // h-12
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF4B5563) // gray-600
                                        : const Color(0xFFE5E7EB), // gray-200
                                    borderRadius:
                                        AppTheme.borderRadiusLargeValue,
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    size: 24,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF) // gray-400
                                        : const Color(0xFF6B7280), // gray-500
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('products'),
                                        style: AppTextStyles.bodyMediumStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                          fontWeight: AppTextStyles.medium,
                                        ),
                                      ),
                                      Text(
                                        '${formatPrice?.call(product.price ?? 0.0) ?? (product.price ?? 0.0).toStringAsFixed(2)} JD',
                                        style: AppTextStyles.bodySmallStyle(
                                          color: const Color(0xFF6D4C41),
                                          fontWeight: AppTextStyles.medium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingLG),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_products_in_package'),
                            style: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? const Color(0xFF9CA3AF) // gray-400
                                  : const Color(0xFF4B5563), // gray-600
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Close Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLG,
                        vertical: AppTheme.spacingSM,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF374151) // gray-700
                          : const Color(0xFFE5E7EB), // gray-200
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF374151), // gray-700
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusLargeValue,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('close'),
                      style: AppTextStyles.bodyMediumStyle(
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// CartItemData - Cart item data model
class CartItemData {
  final String id;
  final String? productId;
  final String? packageId;
  final int quantity;
  final ProductData? product;
  final PackageData? package;

  const CartItemData({
    required this.id,
    this.productId,
    this.packageId,
    required this.quantity,
    this.product,
    this.package,
  });
}

// ProductData and PackageData are imported from product_card.dart and package_card.dart

// PackageProduct is imported from package_card.dart

/// CartScreenLabels - Localization labels
class CartScreenLabels {
  final String loading;
  final String yourCartIsEmpty;
  final String addSomeProducts;
  final String startShopping;
  final String shoppingCart;
  final String orderSummary;
  final String subtotal;
  final String shipping;
  final String calculatedAtCheckout;
  final String total;
  final String proceedToCheckout;
  final String removeItem;
  final String removeItemConfirm;

  const CartScreenLabels({
    required this.loading,
    required this.yourCartIsEmpty,
    required this.addSomeProducts,
    required this.startShopping,
    required this.shoppingCart,
    required this.orderSummary,
    required this.subtotal,
    required this.shipping,
    required this.calculatedAtCheckout,
    required this.total,
    required this.proceedToCheckout,
    required this.removeItem,
    required this.removeItemConfirm,
  });

  factory CartScreenLabels.defaultLabels() {
    return CartScreenLabels.forLanguage('en');
  }

  factory CartScreenLabels.forLanguage(String language) {
    // Note: This factory is used when AppLocalizations is not available in context
    // In most cases, use AppLocalizations.of(context) directly
    final isArabic = language == 'ar';
    return CartScreenLabels(
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      yourCartIsEmpty: isArabic ? 'سلة التسوق فارغة' : 'Your cart is empty',
      addSomeProducts: isArabic
          ? 'أضف بعض المنتجات الجميلة للبدء'
          : 'Add some beautiful products to get started!',
      startShopping: isArabic ? 'ابدأ التسوق' : 'Start Shopping',
      shoppingCart: isArabic ? 'سلة التسوق' : 'Shopping Cart',
      orderSummary: isArabic ? 'ملخص الطلب' : 'Order Summary',
      subtotal: isArabic ? 'المجموع الفرعي' : 'Subtotal',
      shipping: isArabic ? 'الشحن' : 'Shipping',
      calculatedAtCheckout: isArabic
          ? 'يتم حسابه عند الدفع'
          : 'Calculated at checkout',
      total: isArabic ? 'المجموع' : 'Total',
      proceedToCheckout: isArabic
          ? 'المتابعة إلى الدفع'
          : 'Proceed to Checkout',
      removeItem: isArabic ? 'إزالة' : 'Remove',
      removeItemConfirm: isArabic
          ? 'هل أنت متأكد أنك تريد إزالة هذا العنصر؟'
          : 'Are you sure you want to remove this item?',
    );
  }

  /// Create labels from AppLocalizations (preferred method)
  factory CartScreenLabels.fromLocalizations(AppLocalizations l10n) {
    return CartScreenLabels(
      loading: l10n.translate('loading'),
      yourCartIsEmpty: l10n.translate('your_cart_is_empty'),
      addSomeProducts: l10n.translate('add_some_products'),
      startShopping: l10n.translate('start_shopping'),
      shoppingCart: l10n.translate('shopping_cart'),
      orderSummary: l10n.translate('order_summary'),
      subtotal: l10n.translate('subtotal'),
      shipping: l10n.translate('shipping'),
      calculatedAtCheckout: l10n.translate('calculated_at_checkout'),
      total: l10n.translate('total'),
      proceedToCheckout: l10n.translate('proceed_to_checkout'),
      removeItem: l10n.translate('remove'),
      removeItemConfirm: l10n.translate('are_you_sure_you_want_to', {
        'action': l10n.translate('remove'),
      }),
    );
  }
}
