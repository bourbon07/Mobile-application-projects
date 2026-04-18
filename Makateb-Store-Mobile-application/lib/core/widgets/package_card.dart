import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import '../theme/responsive.dart';
import 'wood_button.dart';
import '../../router/app_router.dart';
import '../stores/language_store.dart';

/// PackageCard - Package card widget
///
/// Equivalent to Vue's PackageCard.vue component.
/// Displays a package card with image, title, description, price, and action buttons.
///
/// Features:
/// - Gradient background (amber-50 to amber-100)
/// - Hover effects (scale, shadow)
/// - Discount badge
/// - Items count badge
/// - Price with savings display
/// - Add to cart button with loading state
/// - View details button
class PackageCard extends ConsumerStatefulWidget {
  /// Package data
  final PackageData package;

  /// Card size
  final PackageCardSize size;

  /// Callback when card is tapped (view details)
  final void Function(String packageId)? onViewDetails;

  /// Callback when add to cart is tapped
  final void Function(String packageId)? onAddToCart;

  /// Whether add to cart is in progress
  final bool addingToCart;

  /// Whether package is in wishlist
  final bool? isInWishlist;

  /// Whether toggle wishlist is in progress
  final bool? addingToWishlist;

  /// Callback when wishlist button is tapped
  final void Function(String packageId)? onToggleWishlist;

  /// Localized name getter function
  final String Function(PackageData)? getLocalizedName;

  /// Localized description getter function
  final String Function(PackageData)? getLocalizedDescription;

  /// Labels for localization
  final PackageCardLabels? labels;

  const PackageCard({
    super.key,
    required this.package,
    this.size = PackageCardSize.defaultSize,
    this.onViewDetails,
    this.onAddToCart,
    this.addingToCart = false,
    this.isInWishlist = false,
    this.addingToWishlist = false,
    this.onToggleWishlist,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.labels,
  });

  @override
  ConsumerState<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends ConsumerState<PackageCard>
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
        widget.labels ?? PackageCardLabels.forLanguage(currentLanguage);

    // Background color - Match product card (solid, not gradient)
    // amber-50: #FFFBEB, amber-950/20: #451A03 with 0.2 opacity
    final bgColor = isDark
        ? const Color(0xFF451A03).withValues(alpha: 0.2) // amber-950/20
        : const Color(0xFFFFFBEB); // amber-50

    // Border color - Match product card
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
            widget.onViewDetails!.call(widget.package.id);
          } else {
            context.pushNamed(
              AppRouteNames.package,
              pathParameters: {'id': widget.package.id},
            );
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: bgColor, // Match product card (solid color, not gradient)
              borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
              border: Border.all(
                color: borderColor,
                width: 1,
              ), // border (match product card)
              boxShadow: [
                // shadow-sm → shadow-md on hover (match product card)
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
                // Image Section (aspect-[4/3] to match product card)
                AspectRatio(
                  aspectRatio:
                      4 /
                      3, // aspect-[4/3] (changed from 16/9 to match product card)
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image or placeholder - Match product card
                      Container(
                        color: Colors.white, // bg-white (match product card)
                        child:
                            widget.package.imageUrl != null &&
                                widget.package.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10), // rounded-lg top
                                ),
                                child: AnimatedScale(
                                  scale: _isHovered
                                      ? 1.05
                                      : 1.0, // group-hover:scale-105 (match product card)
                                  duration: const Duration(milliseconds: 300),
                                  child: Image.network(
                                    widget.package.imageUrl!,
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

                      // Wishlist Button (top-right to match ProductCard)
                      Positioned(
                        top: _getHeartButtonTop(),
                        right: isRTL ? null : _getHeartButtonSidePosition(),
                        left: isRTL ? _getHeartButtonSidePosition() : null,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onToggleWishlist?.call(
                              widget.package.id,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: EdgeInsets.all(_getHeartButtonPadding()),
                              decoration: BoxDecoration(
                                color: (widget.isInWishlist ?? false)
                                    ? const Color(0xFFEF4444)
                                    : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (widget.isInWishlist ?? false)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: _getHeartIconSize(),
                                color: (widget.isInWishlist ?? false)
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Badges Section (top-left) - Discount and Items Count
                      Positioned(
                        top: _getBadgeTop(),
                        left: isRTL ? null : _getBadgeLeft(),
                        right: isRTL ? _getBadgeLeft() : null,
                        child: Column(
                          crossAxisAlignment: isRTL
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // Discount Badge
                            if (_calculateDiscount() > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: _getBadgePadding(),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E), // green-500
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${labels.save} ${_calculateDiscount()}%',
                                  style:
                                      AppTextStyles.labelSmallStyle(
                                        color: Colors.white,
                                      ).copyWith(
                                        fontSize: Responsive.font(context, 10),
                                      ),
                                ),
                              ),

                            // Items Count Badge
                            Container(
                              padding: _getBadgePadding(),
                              decoration: BoxDecoration(
                                color: const Color(0xFF92400E), // amber-800
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: Responsive.scale(context, 12),
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.package.productsCount} ${labels.items}',
                                    style:
                                        AppTextStyles.labelSmallStyle(
                                          color: Colors.white,
                                        ).copyWith(
                                          fontSize: Responsive.font(
                                            context,
                                            10,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section (p-4) - Expanded to fill remaining space
                Expanded(
                  child: Padding(
                    padding: _getPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style:
                              AppTextStyles.titleLargeStyle(
                                fontWeight: FontWeight.bold, // Make it bold
                                color: _isHovered
                                    ? (isDark
                                          ? const Color(0xFFFBBF24) // amber-400
                                          : const Color(
                                              0xFF92400E,
                                            )) // amber-800
                                    : null,
                              ).copyWith(
                                fontSize: Responsive.font(
                                  context,
                                  _getTitleFontSize(),
                                ),
                              ),
                          child: Text(
                            widget.getLocalizedName?.call(widget.package) ??
                                widget.package.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        SizedBox(height: _getTitleBottomMargin()),

                        // Description (line-clamp-2)
                        Text(
                          widget.getLocalizedDescription?.call(
                                widget.package,
                              ) ??
                              widget.package.description ??
                              '',
                          style:
                              AppTextStyles.bodySmallStyle(
                                color: isDark
                                    ? const Color(0xFFD1D5DB) // gray-300
                                    : const Color(0xFF374151), // gray-700
                              ).copyWith(
                                fontSize: Responsive.font(
                                  context,
                                  _getDescriptionFontSize(),
                                ),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),

                        // Spacer to push price and buttons to bottom
                        const Spacer(),

                        // Price and Action Section - Match ProductCard layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallCard = constraints.maxWidth < 180;

                            if (isSmallCard) {
                              // Stacked layout for very small cards
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildPriceSection(isDark, labels),
                                  const SizedBox(height: AppTheme.spacingSM),
                                  _buildAddButton(context, isRTL, labels),
                                ],
                              );
                            } else {
                              // Horizontal layout for normal cards
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: _buildPriceSection(isDark, labels),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSM),
                                  Flexible(
                                    child: _buildAddButton(
                                      context,
                                      isRTL,
                                      labels,
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

  Widget _buildAddButton(
    BuildContext context,
    bool isRTL,
    PackageCardLabels labels,
  ) {
    return WoodButton(
      onPressed: widget.addingToCart
          ? null
          : () => widget.onAddToCart?.call(widget.package.id),
      size: WoodButtonSize.sm,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: [
          if (isRTL) ...[
            Flexible(
              child: Text(
                widget.addingToCart ? labels.adding : labels.addToCart,
                overflow: TextOverflow.ellipsis,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  Icons.shopping_cart_outlined,
                  size: _getIconSize(),
                  color: Colors.white,
                ),
          if (!isRTL) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.addingToCart ? labels.adding : labels.addToCart,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isDark, PackageCardLabels labels) {
    final originalPrice = _calculateOriginalPrice();
    final discount = _calculateDiscount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Original Price (if discount)
        if (discount > 0)
          Text(
            '${_formatPrice(originalPrice)} JD',
            style:
                AppTextStyles.bodySmallStyle(
                  color: const Color(0xFF6B7280), // gray-500
                ).copyWith(
                  decoration: TextDecoration.lineThrough,
                  fontSize: Responsive.font(context, 10),
                ),
          ),

        // Current Price
        Text(
          '${_formatPrice(widget.package.price)} JD',
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? const Color(0xFFD97706)
                    : const Color(0xFF78350F),
              ).copyWith(
                fontSize: Responsive.font(context, _getPriceFontSize()),
                fontWeight: FontWeight.bold,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
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
      child: const Center(
        child: Icon(
          Icons.inventory_2, // CubeIcon
          size: 64, // w-16 h-16
          color: Color(0xFF9CA3AF), // gray-400
        ),
      ),
    );
  }

  double _calculateOriginalPrice() {
    if (widget.package.products == null || widget.package.products!.isEmpty) {
      return widget.package.price;
    }
    return widget.package.products!.fold<double>(
      0.0,
      (sum, product) => sum + (product.price ?? 0.0),
    );
  }

  double _calculateSavings(double originalPrice) {
    return (originalPrice - widget.package.price).clamp(0.0, double.infinity);
  }

  int _calculateDiscount() {
    final originalPrice = _calculateOriginalPrice();
    final savings = _calculateSavings(originalPrice);
    if (originalPrice == 0) return 0;
    return ((savings / originalPrice) * 100).round();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  // Size-based getters to match ProductCard
  EdgeInsets _getPadding() {
    double padding;
    switch (widget.size) {
      case PackageCardSize.small:
        padding = 8;
        break;
      case PackageCardSize.large:
        padding = 16;
        break;
      case PackageCardSize.defaultSize:
        padding = 12;
        break;
    }
    return EdgeInsets.all(Responsive.scale(context, padding));
  }

  double _getTitleFontSize() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 16.0;
      case PackageCardSize.large:
        return 18.0;
      case PackageCardSize.defaultSize:
        return 16.0;
    }
  }

  double _getDescriptionFontSize() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 12.0;
      case PackageCardSize.large:
        return 14.0;
      case PackageCardSize.defaultSize:
        return 12.0;
    }
  }

  double _getPriceFontSize() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 16.0;
      case PackageCardSize.large:
        return 18.0;
      case PackageCardSize.defaultSize:
        return 16.0;
    }
  }

  double _getIconSize() {
    double size;
    switch (widget.size) {
      case PackageCardSize.small:
        size = 16.0;
        break;
      case PackageCardSize.large:
        size = 20.0;
        break;
      case PackageCardSize.defaultSize:
        size = 16.0;
        break;
    }
    return Responsive.scale(context, size);
  }

  double _getHeartIconSize() => _getIconSize();

  double _getHeartButtonTop() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 6.0;
      case PackageCardSize.large:
        return 12.0;
      case PackageCardSize.defaultSize:
        return 8.0;
    }
  }

  double _getHeartButtonSidePosition() => _getHeartButtonTop();

  double _getHeartButtonPadding() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 4.0;
      case PackageCardSize.large:
        return 8.0;
      case PackageCardSize.defaultSize:
        return 6.0;
    }
  }

  double _getTitleBottomMargin() {
    switch (widget.size) {
      case PackageCardSize.small:
        return 4.0;
      case PackageCardSize.large:
        return 8.0;
      case PackageCardSize.defaultSize:
        return 4.0;
    }
  }

  double _getBadgeTop() => AppTheme.spacingSM;
  double _getBadgeLeft() => AppTheme.spacingSM;
  EdgeInsets _getBadgePadding() => const EdgeInsets.symmetric(
    horizontal: AppTheme.spacingMD,
    vertical: AppTheme.spacingXS,
  );
}

/// PackageCardSize - Enum to match ProductCardSize
enum PackageCardSize { small, defaultSize, large }

/// PackageData - Package data model
class PackageData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int productsCount;
  final List<PackageProduct>? products;

  const PackageData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.productsCount = 0,
    this.products,
  });
}

/// PackageProduct - Product data model
class PackageProduct {
  final String id;
  final double? price;

  const PackageProduct({required this.id, this.price});
}

/// PackageCardLabels - Localization labels
class PackageCardLabels {
  final String save;
  final String items;
  final String addToCart;
  final String adding;

  const PackageCardLabels({
    required this.save,
    required this.items,
    required this.addToCart,
    required this.adding,
  });

  factory PackageCardLabels.defaultLabels() {
    return PackageCardLabels.forLanguage('en');
  }

  factory PackageCardLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return PackageCardLabels(
      save: isArabic ? 'وفر' : 'Save',
      items: isArabic ? 'عناصر' : 'items',
      addToCart: isArabic ? 'إضافة' : 'Add',
      adding: isArabic ? 'جاري الإضافة...' : 'Adding...',
    );
  }
}
