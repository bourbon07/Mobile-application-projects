import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import '../theme/responsive.dart';
import 'wood_button.dart';
import '../../router/app_router.dart';
import '../stores/language_store.dart';

/// ProductCard - Product card widget
///
/// Equivalent to Vue's ProductCard.vue component.
/// Displays a product card with image, category, rating, name, description, price, and action buttons.
///
/// Features:
/// - Amber background (amber-50 / amber-950/20)
/// - Size variants (small, default, large)
/// - Responsive padding and text sizes
/// - Wishlist toggle button
/// - Stock status badges
/// - Admin rating display
/// - Add to cart button with loading state
/// - RTL support for button content
/// - Hover effects (scale image, shadow)
class ProductCard extends ConsumerStatefulWidget {
  /// Product data
  final ProductData product;

  /// Card size variant
  final ProductCardSize size;

  /// Whether to hide the wishlist button
  final bool hideWishlistButton;

  /// Whether product is in wishlist
  final bool isInWishlist;

  /// Whether add to cart is in progress
  final bool addingToCart;

  /// Whether toggle wishlist is in progress
  final bool addingToWishlist;

  /// Callback when card is tapped (view details)
  final void Function(String productId)? onViewDetails;

  /// Callback when add to cart is tapped
  final void Function(String productId)? onAddToCart;

  /// Callback when wishlist button is tapped
  final void Function(String productId)? onToggleWishlist;

  /// Localized name getter function
  final String Function(ProductData)? getLocalizedName;

  /// Localized description getter function
  final String Function(ProductData)? getLocalizedDescription;

  /// Product category name getter function
  final String Function(ProductData)? getProductCategoryName;

  /// Price formatter function
  final String Function(double)? formatPrice;

  /// Labels for localization
  final ProductCardLabels? labels;

  const ProductCard({
    super.key,
    required this.product,
    this.size = ProductCardSize.defaultSize,
    this.hideWishlistButton = false,
    this.isInWishlist = false,
    this.addingToCart = false,
    this.addingToWishlist = false,
    this.onViewDetails,
    this.onAddToCart,
    this.onToggleWishlist,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.getProductCategoryName,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? ProductCardLabels.forLanguage(currentLanguage);

    // Background color
    // amber-50: #FFFBEB, amber-950/20: #451A03 with 0.2 opacity
    final bgColor = isDark
        ? const Color(0xFF451A03).withValues(alpha: 0.2) // amber-950/20
        : const Color(0xFFFFFBEB); // amber-50

    // Border color
    // amber-200: #FDE68A, amber-800/50: #92400E with 0.5 opacity
    final borderColor = isDark
        ? const Color(0xFF92400E).withValues(alpha: 0.5) // amber-800/50
        : const Color(0xFFFDE68A); // amber-200

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          if (widget.onViewDetails != null) {
            widget.onViewDetails!.call(widget.product.id);
          } else {
            context.pushNamed(
              AppRouteNames.product,
              pathParameters: {'id': widget.product.id},
            );
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
              border: Border.all(color: borderColor, width: 1), // border
              boxShadow: [
                // shadow-sm → shadow-md on hover
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered ? 0.1 : 0.05,
                  ),
                  blurRadius: _isHovered ? 6 : 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section (aspect-[4/3])
                AspectRatio(
                  aspectRatio: 4 / 3, // aspect-[4/3]
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image or placeholder
                      Container(
                        color: Colors.white, // bg-white
                        child:
                            widget.product.imageUrl != null &&
                                widget.product.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10), // rounded-lg top
                                ),
                                child: AnimatedScale(
                                  scale: _isHovered
                                      ? 1.05
                                      : 1.0, // group-hover:scale-105
                                  duration: const Duration(milliseconds: 300),
                                  child: Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholder(isDark),
                                  ),
                                ),
                              )
                            : _buildPlaceholder(isDark),
                      ),

                      // Wishlist Button (top-right)
                      if (!widget.hideWishlistButton)
                        Positioned(
                          top: _getHeartButtonTop(),
                          right: _getHeartButtonRight(),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onToggleWishlist?.call(
                                widget.product.id,
                              ),
                              borderRadius: BorderRadius.circular(
                                999,
                              ), // rounded-full
                              child: Container(
                                padding: EdgeInsets.all(
                                  Responsive.scale(
                                    context,
                                    _getHeartButtonPadding(),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isInWishlist
                                      ? const Color(0xFFEF4444) // red-500
                                      : Colors.white.withValues(
                                          alpha: 0.9,
                                        ), // white/90
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isInWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: Responsive.scale(
                                    context,
                                    _getHeartIconSize(),
                                  ),
                                  color: widget.isInWishlist
                                      ? Colors.white
                                      : const Color(0xFF374151), // gray-700
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Stock Badges (top-left)
                      if (widget.product.stock != null)
                        Positioned(
                          top: Responsive.scale(
                            context,
                            AppTheme.spacingSM,
                          ), // top-2
                          left: Responsive.scale(
                            context,
                            AppTheme.spacingSM,
                          ), // left-2
                          child: _buildStockBadge(isDark, labels),
                        ),
                    ],
                  ),
                ),

                // Content Section - Expanded to fill remaining space
                Expanded(
                  child: Container(
                    padding: _getPadding(),
                    color: bgColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _getCategoryBottomMargin(),
                          ),
                          child: Text(
                            widget.getProductCategoryName?.call(
                                  widget.product,
                                ) ??
                                labels.general,
                            style:
                                AppTextStyles.labelSmallStyle(
                                  color: isDark
                                      ? const Color(0xFFFCD34D) // amber-300
                                      : const Color(0xFF92400E), // amber-800
                                  fontWeight: FontWeight.bold, // Make it bold
                                ).copyWith(
                                  fontSize: Responsive.font(
                                    context,
                                    _getCategoryFontSize(),
                                  ),
                                  letterSpacing: 0.5, // tracking-wide
                                ),
                          ),
                        ),

                        // Admin Rating
                        if (widget.product.adminRating != null)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: _getRatingBottomMargin(),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: Responsive.scale(
                                    context,
                                    _getRatingIconSize(),
                                  ),
                                  color: const Color(0xFFEAB308), // yellow-500
                                ),
                                const SizedBox(
                                  width: AppTheme.spacingXS,
                                ), // gap-1
                                Text(
                                  '${widget.product.adminRating!.rating ?? 0}',
                                  style:
                                      AppTextStyles.bodySmallStyle(
                                        color: isDark
                                            ? const Color(
                                                0xFFD1D5DB,
                                              ) // gray-300
                                            : const Color(
                                                0xFF374151,
                                              ), // gray-700
                                        fontWeight: AppTextStyles.medium,
                                      ).copyWith(
                                        fontSize: Responsive.font(
                                          context,
                                          _getRatingFontSize(),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),

                        // Title
                        Text(
                          () {
                            // Use provided function or language store function
                            if (widget.getLocalizedName != null) {
                              return widget.getLocalizedName!(widget.product);
                            }
                            // Fallback to product name
                            return widget.product.name;
                          }(),
                          style:
                              AppTextStyles.titleMediumStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827), // gray-900
                                fontWeight: FontWeight.bold, // Make it bold
                              ).copyWith(
                                fontSize: Responsive.font(
                                  context,
                                  _getTitleFontSize(),
                                ),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: _getTitleBottomMargin()),

                        Text(
                          () {
                            // Use provided function or language store function
                            if (widget.getLocalizedDescription != null) {
                              return widget.getLocalizedDescription!(
                                widget.product,
                              );
                            }
                            // Fallback to product description
                            return widget.product.description ?? '';
                          }(),
                          style:
                              AppTextStyles.bodySmallStyle(
                                color: isDark
                                    ? const Color(0xFF9CA3AF) // gray-400
                                    : const Color(0xFF4B5563), // gray-600
                              ).copyWith(
                                fontSize: Responsive.font(
                                  context,
                                  _getDescriptionFontSize(),
                                ),
                                height: 1.625, // leading-relaxed
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Spacer to push price and button to bottom
                        const Spacer(),

                        // Price and Add to Cart
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallCard = constraints.maxWidth < 200;

                            if (isSmallCard) {
                              // Very small cards: Stack vertically
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price
                                  Text(
                                    widget.formatPrice?.call(
                                          widget.product.price,
                                        ) ??
                                        '${widget.product.price.toStringAsFixed(2)} JD',
                                    style:
                                        AppTextStyles.titleLargeStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(
                                                  0xFF111827,
                                                ), // gray-900
                                          // font-weight: regular (default)
                                        ).copyWith(
                                          fontSize: Responsive.font(
                                            context,
                                            _getPriceFontSize(),
                                          ),
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: AppTheme.spacingSM),
                                  // Add to Cart Button or Out of Stock
                                  if (widget.product.stock != null &&
                                      widget.product.stock! > 0)
                                    SizedBox(
                                      width: double.infinity,
                                      child: WoodButton(
                                        onPressed: widget.addingToCart
                                            ? null
                                            : () => widget.onAddToCart?.call(
                                                widget.product.id,
                                              ),
                                        size: WoodButtonSize.sm,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          textDirection: isRTL
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          children: [
                                            if (isRTL) ...[
                                              Flexible(
                                                child: Text(
                                                  widget.addingToCart
                                                      ? labels.adding
                                                      : labels.add,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            widget.addingToCart
                                                ? SizedBox(
                                                    width: _getIconSize(),
                                                    height: _getIconSize(),
                                                    child: const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    size: _getIconSize(),
                                                    color: Colors.white,
                                                  ),
                                            if (!isRTL) ...[
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  widget.addingToCart
                                                      ? labels.adding
                                                      : labels.add,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: _getOutOfStockPadding(),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(
                                                0xFF374151,
                                              ) // gray-700
                                            : const Color(
                                                0xFFE5E7EB,
                                              ), // gray-200
                                        borderRadius:
                                            AppTheme.borderRadiusLargeValue,
                                      ),
                                      child: Text(
                                        labels.outOfStock,
                                        style:
                                            AppTextStyles.labelSmallStyle(
                                              color: isDark
                                                  ? const Color(
                                                      0xFF9CA3AF,
                                                    ) // gray-400
                                                  : const Color(
                                                      0xFF4B5563,
                                                    ), // gray-600
                                              fontWeight: AppTextStyles.medium,
                                            ).copyWith(
                                              fontSize:
                                                  _getOutOfStockFontSize(),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              // Normal cards: Horizontal layout
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Price
                                  Flexible(
                                    child: Text(
                                      widget.formatPrice?.call(
                                            widget.product.price,
                                          ) ??
                                          '${widget.product.price.toStringAsFixed(2)} JD',
                                      style:
                                          AppTextStyles.titleLargeStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(
                                                    0xFF111827,
                                                  ), // gray-900
                                            // font-weight: regular (default)
                                          ).copyWith(
                                            fontSize: Responsive.font(
                                              context,
                                              _getPriceFontSize(),
                                            ),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSM),
                                  // Add to Cart Button or Out of Stock Badge
                                  if (widget.product.stock != null &&
                                      widget.product.stock! > 0)
                                    Flexible(
                                      child: WoodButton(
                                        onPressed: widget.addingToCart
                                            ? null
                                            : () => widget.onAddToCart?.call(
                                                widget.product.id,
                                              ),
                                        size: WoodButtonSize.sm,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          textDirection: isRTL
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          children: [
                                            if (isRTL) ...[
                                              Flexible(
                                                child: Text(
                                                  widget.addingToCart
                                                      ? labels.adding
                                                      : labels.add,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            widget.addingToCart
                                                ? SizedBox(
                                                    width: _getIconSize(),
                                                    height: _getIconSize(),
                                                    child: const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    size: _getIconSize(),
                                                    color: Colors.white,
                                                  ),
                                            if (!isRTL) ...[
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  widget.addingToCart
                                                      ? labels.adding
                                                      : labels.add,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Flexible(
                                      child: Container(
                                        padding: _getOutOfStockPadding(),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF374151,
                                                ) // gray-700
                                              : const Color(
                                                  0xFFE5E7EB,
                                                ), // gray-200
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                        ),
                                        child: Text(
                                          labels.outOfStock,
                                          style:
                                              AppTextStyles.labelSmallStyle(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF9CA3AF,
                                                      ) // gray-400
                                                    : const Color(
                                                        0xFF4B5563,
                                                      ), // gray-600
                                                fontWeight:
                                                    AppTextStyles.medium,
                                              ).copyWith(
                                                fontSize:
                                                    _getOutOfStockFontSize(),
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF374151) // gray-700
            : const Color(0xFFE5E7EB), // gray-200
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2,
          size: 64, // w-16 h-16
          color: const Color(0xFF9CA3AF), // gray-400
        ),
      ),
    );
  }

  Widget _buildStockBadge(bool isDark, ProductCardLabels labels) {
    final stock = widget.product.stock ?? 0;
    if (stock == 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 8),
          vertical: Responsive.scale(context, 4),
        ), // px-2 py-1
        decoration: BoxDecoration(
          color: const Color(0xFF4B5563), // gray-600
          borderRadius: BorderRadius.circular(
            Responsive.scale(context, 4),
          ), // rounded
        ),
        child: Text(
          labels.outOfStock,
          style:
              AppTextStyles.labelSmallStyle(
                color: Colors.white,
                fontWeight: AppTextStyles.medium,
              ).copyWith(
                fontSize: Responsive.font(context, _getStockBadgeFontSize()),
              ),
        ),
      );
    } else if (stock < 10) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 8),
          vertical: Responsive.scale(context, 4),
        ), // px-2 py-1
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444), // red-500
          borderRadius: BorderRadius.circular(
            Responsive.scale(context, 4),
          ), // rounded
        ),
        child: Text(
          '${labels.onlyLeft} $stock!',
          style:
              AppTextStyles.labelSmallStyle(
                color: Colors.white,
                fontWeight: AppTextStyles.medium,
              ).copyWith(
                fontSize: Responsive.font(context, _getStockBadgeFontSize()),
              ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Size-based getters
  EdgeInsets _getPadding() {
    double padding;
    switch (widget.size) {
      case ProductCardSize.small:
        padding = 8; // p-2 on mobile
        break;
      case ProductCardSize.large:
        padding = 16; // p-4 on mobile
        break;
      case ProductCardSize.defaultSize:
        padding = 12; // p-3 on mobile
        break;
    }
    return EdgeInsets.all(Responsive.scale(context, padding));
  }

  double _getCategoryFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 12.0; // Increased from 10.0
      case ProductCardSize.large:
        return 14.0; // Increased from 12.0
      case ProductCardSize.defaultSize:
        return 12.0; // Increased from 10.0
    }
  }

  double _getRatingIconSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 12.0; // w-3 h-3
      case ProductCardSize.large:
        return 16.0; // w-4 h-4
      case ProductCardSize.defaultSize:
        return 12.0; // w-3 h-3
    }
  }

  double _getRatingFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 12.0; // text-xs
      case ProductCardSize.large:
        return 14.0; // text-sm
      case ProductCardSize.defaultSize:
        return 12.0; // text-xs
    }
  }

  double _getTitleFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 16.0; // Increased from 14.0
      case ProductCardSize.large:
        return 18.0; // Increased from 16.0
      case ProductCardSize.defaultSize:
        return 16.0; // Increased from 14.0
    }
  }

  double _getDescriptionFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 12.0; // text-xs
      case ProductCardSize.large:
        return 14.0; // text-sm
      case ProductCardSize.defaultSize:
        return 12.0; // text-xs
    }
  }

  double _getPriceFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 16.0; // text-base
      case ProductCardSize.large:
        return 18.0; // text-lg
      case ProductCardSize.defaultSize:
        return 16.0; // text-base
    }
  }

  double _getIconSize() {
    double size;
    switch (widget.size) {
      case ProductCardSize.small:
        size = 16.0; // w-4 h-4
        break;
      case ProductCardSize.large:
        size = 20.0; // w-5 h-5
        break;
      case ProductCardSize.defaultSize:
        size = 16.0; // w-4 h-4
        break;
    }
    return Responsive.scale(context, size);
  }

  double _getHeartIconSize() {
    return _getIconSize();
  }

  double _getHeartButtonTop() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 6.0; // top-1.5
      case ProductCardSize.large:
        return 12.0; // top-3
      case ProductCardSize.defaultSize:
        return 8.0; // top-2
    }
  }

  double _getHeartButtonRight() {
    return _getHeartButtonTop();
  }

  double _getHeartButtonPadding() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 4.0; // p-1
      case ProductCardSize.large:
        return 8.0; // p-2
      case ProductCardSize.defaultSize:
        return 6.0; // p-1.5
    }
  }

  double _getCategoryBottomMargin() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 2.0; // mb-0.5
      case ProductCardSize.large:
        return 8.0; // mb-2
      case ProductCardSize.defaultSize:
        return 4.0; // mb-1
    }
  }

  double _getRatingBottomMargin() {
    return _getCategoryBottomMargin();
  }

  double _getTitleBottomMargin() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 4.0; // mb-1
      case ProductCardSize.large:
        return 8.0; // mb-2
      case ProductCardSize.defaultSize:
        return 4.0; // mb-1
    }
  }

  EdgeInsets _getOutOfStockPadding() {
    switch (widget.size) {
      case ProductCardSize.small:
        return const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ); // px-1.5 py-0.5
      case ProductCardSize.large:
        return const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ); // px-3 py-1.5
      case ProductCardSize.defaultSize:
        return const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ); // px-2 py-1
    }
  }

  double _getOutOfStockFontSize() {
    switch (widget.size) {
      case ProductCardSize.small:
        return 9.0; // text-[9px]
      case ProductCardSize.large:
        return 12.0; // text-xs
      case ProductCardSize.defaultSize:
        return 10.0; // text-[10px]
    }
  }

  double _getStockBadgeFontSize() {
    return 12.0; // text-xs
  }
}

/// ProductCardSize - Card size enum
enum ProductCardSize { small, defaultSize, large }

/// ProductData - Product data model
class ProductData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? stock;
  final AdminRating? adminRating;
  final ProductCategory? category;
  final List<ProductCategory>? categories;
  final bool isPackage;

  const ProductData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.stock,
    this.adminRating,
    this.category,
    this.categories,
    this.isPackage = false,
  });
}

/// AdminRating - Admin rating model
class AdminRating {
  final double? rating;

  const AdminRating({this.rating});
}

/// ProductCategory - Product category model
class ProductCategory {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;

  const ProductCategory({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
  });
}

/// ProductCardLabels - Localization labels
class ProductCardLabels {
  final String general;
  final String onlyLeft;
  final String outOfStock;
  final String add;
  final String adding;

  const ProductCardLabels({
    required this.general,
    required this.onlyLeft,
    required this.outOfStock,
    required this.add,
    required this.adding,
  });

  factory ProductCardLabels.defaultLabels() {
    return ProductCardLabels.forLanguage('en');
  }

  factory ProductCardLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ProductCardLabels(
      general: isArabic ? 'عام' : 'General',
      onlyLeft: isArabic ? 'بقي فقط' : 'Only',
      outOfStock: isArabic ? 'نفدت الكمية' : 'Out of Stock',
      add: isArabic ? 'أضف' : 'Add',
      adding: isArabic ? 'جاري الإضافة...' : 'Adding...',
    );
  }
}
