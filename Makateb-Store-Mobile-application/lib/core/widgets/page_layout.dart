import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PageLayout - Page content layout widget
///
/// Equivalent to Vue's AppLayout.vue component.
/// Provides a full-screen layout with scrollable content and optional mobile cart button.
///
/// Features:
/// - Full screen height with overflow handling
/// - Dark/light mode support
/// - Scrollable main content area
/// - Mobile-only cart button (fixed bottom)
/// - RTL/LTR support
class PageLayout extends StatelessWidget {
  /// Child content to display (equivalent to Vue's `<slot />`)
  final Widget child;

  /// Cart item count to display on button badge
  final int cartCount;

  /// Callback when cart button is tapped
  final VoidCallback? onCartTap;

  /// Whether to show the cart button (default: true)
  /// Set to false to hide (equivalent to route.name === 'cart')
  final bool showCartButton;

  /// Whether this is a cart page (hides cart button)
  final bool isCartPage;

  /// Whether the content should be wrapped in a scroll view.
  ///
  /// Set to `false` for screens that manage their own internal scrolling
  /// (e.g., chat layouts that are full-height with internal scroll areas).
  final bool scrollable;

  const PageLayout({
    super.key,
    required this.child,
    this.cartCount = 0,
    this.onCartTap,
    this.showCartButton = true,
    this.isCartPage = false,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Background colors matching Vue: bg-gray-50 (light) or bg-gray-900 (dark)
    // gray-50: #F9FAFB, gray-900: #111827
    final backgroundColor = isDark
        ? const Color(0xFF111827) // gray-900
        : const Color(0xFFF9FAFB); // gray-50

    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      color: backgroundColor,
      child: SafeArea(
        // Allow content to go behind the bottom navbar if it's the fixed cart button
        bottom: false,
        child: Stack(
          children: [
            // Main Content Area
            // Equivalent to: <div class="flex-1 flex flex-col overflow-hidden min-w-0">
            Column(
              children: [
                // Page Content
                // Equivalent to: <main class="flex-1 overflow-y-auto w-full">
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: backgroundColor,
                    child: scrollable
                        ? SingleChildScrollView(
                            // Equivalent to: <div class="w-full min-h-full">
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height -
                                    MediaQuery.of(context).padding.top -
                                    MediaQuery.of(context).padding.bottom,
                              ),
                              child: Container(
                                width: double.infinity,
                                color: backgroundColor,
                                child: child,
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            color: backgroundColor,
                            child: child,
                          ),
                  ),
                ),
              ],
            ),

            // Mobile Cart Button - Floating Circular Icon, Mobile Only
            // Hide on cart and wishlist pages
            if (showCartButton &&
                !isCartPage &&
                MediaQuery.of(context).size.width < 768)
              Builder(
                builder: (context) {
                  // Check route to hide on cart/wishlist pages
                  final route = GoRouterState.of(context).uri.path;
                  if (route == '/cart' || route == '/wishlist') {
                    return const SizedBox.shrink();
                  }

                  // Floating circular icon button
                  // Position: bottom left for LTR, bottom right for RTL
                  return Positioned(
                    bottom: 0, // At the bottom of the screen
                    left: isRTL ? null : 20, // 20px from left for LTR
                    right: isRTL ? 20 : null, // 20px from right for RTL
                    child: _MobileCartButton(
                      cartCount: cartCount,
                      onTap: onCartTap,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// MobileCartButton - Mobile cart button widget
///
/// Displays a circular cart icon button with wood texture and badge count.
/// Always visible when scrolling (fixed position at bottom left).
class _MobileCartButton extends StatefulWidget {
  final int cartCount;
  final VoidCallback? onTap;

  const _MobileCartButton({required this.cartCount, required this.onTap});

  @override
  State<_MobileCartButton> createState() => _MobileCartButtonState();
}

class _MobileCartButtonState extends State<_MobileCartButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
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
    // Wood texture path (same as WoodButton)
    const woodTexturePath =
        'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png';

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
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            context.go('/cart');
          }
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: ScaleTransition(
          scale: _isPressed
              ? Tween<double>(begin: 1.0, end: 0.95).animate(
                  CurvedAnimation(
                    parent: _scaleController,
                    curve: Curves.easeInOut,
                  ),
                )
              : _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap ?? () => context.go('/cart'),
              borderRadius: BorderRadius.circular(30), // Circular shape
              child: Container(
                width: 60, // Fixed width for circular button
                height: 60, // Fixed height for circular button
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Circular shape
                  // Wood texture background (like WoodButton)
                  image: const DecorationImage(
                    image: AssetImage(woodTexturePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    onError: null,
                  ),
                  // Fallback color if image fails to load
                  color: const Color(0xFF8B4513), // Fallback wood color
                  // Shadow effects: shadow-lg, hover:shadow-xl (like WoodButton)
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isHovered ? 0.25 : 0.15,
                      ),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Cart icon centered
                    Center(
                      child: Icon(
                        Icons.shopping_cart,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    // Badge count (top-right)
                    if (widget.cartCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              widget.cartCount > 99
                                  ? '99+'
                                  : widget.cartCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
