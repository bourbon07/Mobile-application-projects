import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import '../theme/responsive.dart';
import 'wood_button.dart';
import '../services/overlay_manager.dart';
import '../stores/language_store.dart';

/// Navbar - Application navigation bar
///
/// Equivalent to Vue's Navbar.vue component.
/// Displays a sticky navigation bar with wood texture background, search, and navigation items.
///
/// Features:
/// - Sticky positioning with shadow
/// - Wood texture background with gradient overlay
/// - Responsive design (mobile/desktop)
/// - Search bar (desktop only)
/// - Navigation items with badges
/// - User menu dropdown
/// - Mobile menu
class Navbar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  /// Logo text
  final String logoText;

  /// Current user (null if guest)
  final NavbarUser? user;

  /// Cart item count
  final int cartCount;

  /// Wishlist item count
  final int wishlistCount;

  /// Unread message count
  final int unreadMessageCount;

  /// Current language code ('ar' or 'en')
  final String currentLanguage;

  /// Whether dark mode is enabled
  final bool isDarkMode;

  /// Path to wood texture image
  final String? woodTexturePath;

  /// Callbacks
  final VoidCallback? onLogoTap;
  final void Function(String query)? onSearch;
  final VoidCallback? onLanguageToggle;
  final VoidCallback? onDarkModeToggle;
  final VoidCallback? onChatTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onContactSupportTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onLoginTap;

  /// Labels for localization
  final NavbarLabels? labels;

  const Navbar({
    super.key,
    this.logoText = 'Makateb Store',
    this.user,
    this.cartCount = 0,
    this.wishlistCount = 0,
    this.unreadMessageCount = 0,
    this.currentLanguage = 'ar',
    this.isDarkMode = false,
    this.woodTexturePath,
    this.onLogoTap,
    this.onSearch,
    this.onLanguageToggle,
    this.onDarkModeToggle,
    this.onChatTap,
    this.onWishlistTap,
    this.onCartTap,
    this.onProfileTap,
    this.onOrdersTap,
    this.onContactSupportTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onLoginTap,
    this.labels,
  });

  @override
  Size get preferredSize {
    // Return a base height that is sufficient for the navbar
    // The actual layout is handled in build
    return const Size.fromHeight(100);
  }

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  bool _mobileMenuOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch?.call(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch language changes to update labels
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels = widget.labels ?? NavbarLabels.forLanguage(currentLanguage);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Additional top padding for device notification panel/status bar safety
    // even with SafeArea, some devices have deep notches or rounded corners
    final extraTopPadding = MediaQuery.of(context).padding.top > 0 ? 8.0 : 4.0;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          // shadow-lg
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow mobile menu to expand
        children: [
          // Background image (wood texture)
          if (widget.woodTexturePath != null)
            Positioned.fill(
              child: Image.asset(
                widget.woodTexturePath!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF78350F), // amber-900 fallback
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: const Color(0xFF78350F), // amber-900
              ),
            ),

          // Gradient overlay (from-amber-900/90 to-amber-950/90)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft, // from-r
                  end: Alignment.centerRight, // to-r
                  colors: [
                    const Color(
                      0xFF78350F,
                    ).withValues(alpha: 0.9), // amber-900/90
                    const Color(
                      0xFF451A03,
                    ).withValues(alpha: 0.9), // amber-950/90
                  ],
                ),
              ),
            ),
          ),

          // Content: div.relative max-w-7xl mx-auto px-3 sm:px-4 md:px-6 lg:px-8
          Container(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            margin: EdgeInsets.symmetric(
              horizontal: _getResponsivePadding(
                context,
              ), // px-3 sm:px-4 md:px-6 lg:px-8
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Allow column to size to content
              children: [
                // Spacer for status bar/rounded corners safety
                SizedBox(height: extraTopPadding),

                // Main navbar row: div.flex items-center justify-between h-14 sm:h-16
                SizedBox(
                  height: _getResponsiveHeight(context), // h-14 sm:h-16
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // justify-between
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // items-center
                    children: [
                      // First item: Menu button for RTL (left), Logo for LTR (left)
                      if (isRTL) ...[
                        // Mobile menu button - Left side for RTL (Arabic)
                        if (MediaQuery.of(context).size.width < 768)
                          _buildMobileMenuButton(),
                        // Desktop Navigation (hidden on mobile) - Left side for RTL
                        if (MediaQuery.of(context).size.width >= 768)
                          _buildDesktopNavigation(labels, isRTL),
                      ] else ...[
                        // Logo button - Left side for LTR (English)
                        _buildLogo(labels, isRTL),
                      ],

                      // Desktop Search (hidden on mobile) - Center
                      // Vue: hidden md:flex flex-1 max-w-md mx-8
                      if (MediaQuery.of(context).size.width >= 768)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXXL, // mx-8
                            ),
                            child: Center(child: _buildDesktopSearch(labels)),
                          ),
                        ),

                      // Last item: Logo for RTL (right), Menu button for LTR (right)
                      if (isRTL) ...[
                        // Logo button for RTL - Right side (Arabic)
                        _buildLogo(labels, isRTL),
                      ] else ...[
                        // Desktop Navigation (hidden on mobile) - Right side for LTR
                        if (MediaQuery.of(context).size.width >= 768)
                          _buildDesktopNavigation(labels, isRTL),
                        // Mobile menu button - Right side for LTR (English)
                        if (MediaQuery.of(context).size.width < 768)
                          _buildMobileMenuButton(),
                      ],
                    ],
                  ),
                ),

                // Mobile Menu - Expandable section within navbar (md:hidden py-4 space-y-4)
                // Vue: This expands below the navbar row and ends with the last option
                if (_mobileMenuOpen && MediaQuery.of(context).size.width < 768)
                  Flexible(child: _buildMobileMenuExpandable(labels, isRTL)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(NavbarLabels labels, bool isRTL) {
    // Vue: button.flex items-center space-x-1 sm:space-x-2 text-white hover:text-amber-200 transition-colors
    // Icon should be on the left for LTR, on the right for RTL
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Pointer cursor
      child: _HoverableButton(
        onPressed: widget.onLogoTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // flex items-center
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Package icon - Left for LTR, Right for RTL
            if (!isRTL) ...[
              Icon(
                Icons.inventory_2, // Package icon
                color: Colors.white,
                size: _getResponsiveIconSize(context), // w-6 sm:w-7 md:w-8
              ),
              SizedBox(
                width: _getResponsiveSpacing(context), // space-x-1 sm:space-x-2
              ),
            ],
            Text(
              // Use translated logo text based on language
              labels.makatebStore,
              style:
                  AppTextStyles.titleMediumStyle(
                    color: Colors.white, // text-white
                    fontWeight: FontWeight.bold, // Make it bold
                  ).copyWith(
                    fontSize: _getResponsiveFontSize(
                      context,
                    ), // text-base sm:text-lg md:text-xl
                  ),
            ),
            // Icon on the right for RTL
            if (isRTL) ...[
              SizedBox(
                width: _getResponsiveSpacing(context), // space-x-1 sm:space-x-2
              ),
              Icon(
                Icons.inventory_2, // Package icon
                color: Colors.white,
                size: _getResponsiveIconSize(context), // w-6 sm:w-7 md:w-8
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton() {
    return _HoverableButton(
      onPressed: () {
        // Close other menus before toggling mobile menu
        if (!_mobileMenuOpen) {
          OverlayManager.instance.closeAllOfType(OverlayType.menu);
        }
        setState(() {
          _mobileMenuOpen = !_mobileMenuOpen;
        });
      },
      padding: const EdgeInsets.all(AppTheme.spacingSM), // p-2
      child: Icon(
        _mobileMenuOpen ? Icons.close : Icons.menu,
        color: Colors.white, // text-white
        size: 24, // w-6 h-6
      ),
    );
  }

  double _getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 640
        ? AppTheme.spacingSM * 2
        : AppTheme.spacingSM; // sm:space-x-2, space-x-1
  }

  Widget _buildDesktopSearch(NavbarLabels labels) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1F2937).withValues(alpha: 0.9) // gray-800/90
        : Colors.white.withValues(alpha: 0.9); // white/90

    // Vue: flex-1 max-w-md mx-8
    return Container(
      constraints: const BoxConstraints(maxWidth: 448), // max-w-md
      child: Stack(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: labels.searchProducts,
              filled: true,
              fillColor: bgColor,
              contentPadding: EdgeInsets.only(
                left: 40, // pl-10
                right: AppTheme.spacingLG, // px-4
                top: AppTheme.spacingSM, // py-2
                bottom: AppTheme.spacingSM,
              ),
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusLargeValue,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusLargeValue,
                borderSide: const BorderSide(
                  color: Color(0xFFD97706), // amber-500
                  width: 2,
                ),
              ),
              hintStyle: AppTextStyles.bodyMediumStyle(
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
            style: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF111827), // gray-900
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
          // Search icon (absolute left-3 top-1/2)
          Positioned(
            left: 12, // left-3 = 12px
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.search,
                size: 16, // w-4 h-4
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavigation(NavbarLabels labels, bool isRTL) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Switcher
        _IconButtonWithTooltip(
          icon: Text(
            widget.currentLanguage == 'ar' ? 'EN' : 'AR',
            style: AppTextStyles.labelSmallStyle(
              color: Colors.white,
              fontWeight: AppTextStyles.medium,
            ),
          ),
          onPressed: widget.onLanguageToggle,
          tooltip: labels.toggleLanguage,
        ),

        const SizedBox(width: AppTheme.spacingLG), // space-x-4
        // Dark Mode Toggle
        _IconButtonWithTooltip(
          icon: Icon(
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
            size: 20, // w-4 h-4 sm:w-5 sm:h-5
          ),
          onPressed: widget.onDarkModeToggle,
          tooltip: labels.toggleTheme,
        ),

        // Chat Button
        const SizedBox(width: AppTheme.spacingLG),
        _IconButtonWithBadge(
          icon: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 20,
          ),
          badgeCount: widget.unreadMessageCount,
          onPressed: widget.onChatTap,
          tooltip: labels.supportChat,
        ),

        // Wishlist Button
        const SizedBox(width: AppTheme.spacingLG),
        _IconButtonWithBadge(
          icon: const Icon(
            Icons.favorite_border,
            color: Colors.white,
            size: 20,
          ),
          badgeCount: widget.wishlistCount,
          onPressed: widget.onWishlistTap,
          tooltip: labels.wishlist,
        ),

        // Cart Button
        const SizedBox(width: AppTheme.spacingLG),
        _IconButtonWithBadge(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 20,
          ),
          badgeCount: widget.cartCount,
          onPressed: widget.onCartTap,
          tooltip: labels.shoppingCart,
        ),

        // User Menu or Sign In Button
        const SizedBox(width: AppTheme.spacingLG),
        if (widget.user != null)
          _UserMenuButton(
            user: widget.user!,
            labels: labels,
            onProfileTap: widget.onProfileTap,
            onOrdersTap: widget.onOrdersTap,
            onContactSupportTap: widget.user?.role == 'customer'
                ? widget.onContactSupportTap
                : null,
            onSettingsTap: widget.onSettingsTap,
            onLogoutTap: widget.onLogoutTap,
          )
        else
          WoodButton(
            onPressed: widget.onLoginTap,
            size: WoodButtonSize.sm,
            child: Text(labels.signIn),
          ),
      ],
    );
  }

  // Vue: md:hidden py-4 space-y-4 - Expandable section within navbar
  // This expands below the navbar row and ends with the last option
  Widget _buildMobileMenuExpandable(NavbarLabels labels, bool isRTL) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF78350F), // amber-900 backup
          gradient: LinearGradient(
            begin: Alignment.centerLeft, // from-r
            end: Alignment.centerRight, // to-r
            colors: [
              const Color(0xFF78350F).withValues(alpha: 0.95), // amber-900/95
              const Color(0xFF451A03).withValues(alpha: 0.95), // amber-950/95
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingLG, // py-4
            horizontal: AppTheme.spacingLG, // px-4
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mobile Search
              _buildMobileSearch(labels),

              const SizedBox(height: AppTheme.spacingLG), // space-y-4
              // Menu Items
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cart
                  _MobileMenuButton(
                    label: '${labels.cart} (${widget.cartCount})',
                    onTap: () {
                      if (widget.onCartTap != null) {
                        widget.onCartTap!.call();
                      } else {
                        context.go('/cart');
                      }
                      setState(() => _mobileMenuOpen = false);
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  // Wishlist
                  _MobileMenuButton(
                    label: '${labels.wishlist} (${widget.wishlistCount})',
                    onTap: () {
                      if (widget.onWishlistTap != null) {
                        widget.onWishlistTap!.call();
                      } else {
                        context.go('/wishlist');
                      }
                      setState(() => _mobileMenuOpen = false);
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  // Chat
                  _MobileMenuButton(
                    label: labels.supportChat,
                    onTap: () {
                      if (widget.onChatTap != null) {
                        widget.onChatTap!.call();
                      } else {
                        context.go('/chat');
                      }
                      setState(() => _mobileMenuOpen = false);
                    },
                  ),

                  // Orders (if logged in)
                  if (widget.user != null) ...[
                    const SizedBox(height: AppTheme.spacingSM),
                    _MobileMenuButton(
                      label: labels.orders,
                      onTap: () {
                        if (widget.onOrdersTap != null) {
                          widget.onOrdersTap!.call();
                        } else {
                          context.go('/orders');
                        }
                        setState(() => _mobileMenuOpen = false);
                      },
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingLG),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: AppTheme.spacingLG),

                  // Dark Mode
                  _MobileMenuButton(
                    label: widget.isDarkMode
                        ? labels.lightMode
                        : labels.darkMode,
                    icon: Icon(
                      widget.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onTap: widget.onDarkModeToggle,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),

                  // Language
                  _MobileMenuButton(
                    label:
                        '${labels.language}: ${widget.currentLanguage == 'ar' ? 'English' : 'العربية'}',
                    onTap: widget.onLanguageToggle,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),

                  // Settings
                  _MobileMenuButton(
                    label: labels.settings,
                    onTap: () {
                      if (widget.onSettingsTap != null) {
                        widget.onSettingsTap!.call();
                      } else {
                        context.go('/settings');
                      }
                      setState(() => _mobileMenuOpen = false);
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingLG),

                  // Login/Logout
                  if (widget.user != null)
                    _MobileMenuButton(
                      label: labels.logout,
                      textColor: const Color(0xFFF87171), // red-400
                      onTap: () {
                        widget.onLogoutTap?.call();
                        setState(() => _mobileMenuOpen = false);
                      },
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton(
                        onPressed: () {
                          if (widget.onLoginTap != null) {
                            widget.onLoginTap!.call();
                          } else {
                            context.go('/login');
                          }
                          setState(() => _mobileMenuOpen = false);
                        },
                        size: WoodButtonSize.md,
                        child: Text(labels.signIn),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearch(NavbarLabels labels) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1F2937).withValues(alpha: 0.9) // dark:bg-gray-800/90
        : Colors.white.withValues(alpha: 0.9); // bg-white/90

    return SizedBox(
      width: double.infinity, // w-full
      height: 40, // Fixed height: 40px
      child: Stack(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: labels.searchProducts,
              filled: true,
              fillColor: bgColor,
              contentPadding: EdgeInsets.only(
                left: 40, // pl-10
                right: AppTheme.spacingLG, // px-4
                top: AppTheme.spacingSM, // py-2
                bottom: AppTheme.spacingSM, // py-2
              ),
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
                borderSide: BorderSide.none,
              ),
              hintStyle: AppTextStyles.bodyMediumStyle(
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
            style: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF111827), // text-gray-900 dark:text-white
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
          // Search icon
          Positioned(
            left: 12, // left-3 = 12px (pl-10 = 40px, icon at 12px from left)
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.search,
                size: 16, // w-4 h-4
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double padding;
    if (width >= 1024)
      padding = 32; // lg:px-8
    else if (width >= 768)
      padding = 24; // md:px-6
    else if (width >= 640)
      padding = 16; // sm:px-4
    else
      padding = 12; // px-3
    return Responsive.scale(context, padding);
  }

  double _getResponsiveHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Increased heights for better touch targets and notification panel safety
    double height = width >= 640 ? 80 : 72; // Increased from 64/56 to 80/72
    return Responsive.scale(context, height);
  }

  double _getResponsiveIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double size;
    if (width >= 768)
      size = 32; // md:w-8
    else if (width >= 640)
      size = 28; // sm:w-7
    else
      size = 24; // w-6
    return Responsive.scale(context, size);
  }

  double _getResponsiveFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double size;
    if (width >= 768)
      size = 20; // md:text-xl
    else if (width >= 640)
      size = 18; // sm:text-lg
    else
      size = 16; // text-base
    return Responsive.font(context, size);
  }
}

/// Icon Button with Badge
class _IconButtonWithBadge extends StatelessWidget {
  final Widget icon;
  final int badgeCount;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _IconButtonWithBadge({
    required this.icon,
    required this.badgeCount,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Pointer cursor
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: icon,
              onPressed: onPressed,
              padding: const EdgeInsets.all(
                AppTheme.spacingMD / 2,
              ), // p-1.5 sm:p-2
              constraints: const BoxConstraints(),
              // Remove ripple/splash effect
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2, // -top-0.5 sm:-top-1
                right: -2, // -right-0.5 sm:-right-1
                child: _Badge(
                  count: badgeCount > 99 ? '99+' : badgeCount.toString(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Icon Button with Tooltip
class _IconButtonWithTooltip extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _IconButtonWithTooltip({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // Pointer cursor
        child: IconButton(
          icon: icon,
          onPressed: onPressed,
          padding: const EdgeInsets.all(AppTheme.spacingMD / 2), // p-1.5 sm:p-2
          constraints: const BoxConstraints(),
          // Remove ripple/splash effect
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// Badge Widget
class _Badge extends StatelessWidget {
  final String count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Vue: absolute -top-0.5 -right-0.5 sm:-top-1 sm:-right-1 bg-red-500 text-white text-[10px] sm:text-xs font-semibold rounded-full min-w-[16px] sm:min-w-[20px] h-4 sm:h-5 px-1 sm:px-1.5
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width >= 640
            ? 20
            : 16, // sm:min-w-[20px], min-w-[16px]
        minHeight: MediaQuery.of(context).size.width >= 640
            ? 20
            : 16, // sm:h-5, h-4
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width >= 640
            ? 6
            : 4, // sm:px-1.5, px-1
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444), // bg-red-500
        borderRadius: AppTheme.borderRadiusCircularValue, // rounded-full
      ),
      child: Text(
        count,
        style:
            AppTextStyles.labelSmallStyle(
              color: Colors.white, // text-white
              // font-weight: regular (default)
            ).copyWith(
              fontSize: MediaQuery.of(context).size.width >= 640
                  ? 12
                  : 10, // sm:text-xs, text-[10px]
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// User Menu Button with Dropdown
class _UserMenuButton extends StatefulWidget {
  final NavbarUser user;
  final NavbarLabels labels;
  final VoidCallback? onProfileTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onContactSupportTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  const _UserMenuButton({
    required this.user,
    required this.labels,
    this.onProfileTap,
    this.onOrdersTap,
    this.onContactSupportTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  @override
  State<_UserMenuButton> createState() => _UserMenuButtonState();
}

class _UserMenuButtonState extends State<_UserMenuButton> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1F2937)
        : Colors.white; // gray-800/white
    final hoverColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF3F4F6); // gray-700/gray-100

    String userDisplayName = widget.user.name;
    if (widget.user.role == 'admin') {
      userDisplayName = widget.labels.admin;
    } else if (widget.user.role == 'customer') {
      userDisplayName = widget.labels.customer;
    }

    // Vue: group-hover - hover-based dropdown (invisible group-hover:visible opacity-0 group-hover:opacity-100)
    return MouseRegion(
      onEnter: (_) {
        // Close other menus before opening this one
        OverlayManager.instance.closeAllOfType(OverlayType.menu);
        setState(() => _isMenuOpen = true);
      },
      onExit: (_) {
        setState(() => _isMenuOpen = false);
      },
      child: Stack(
        children: [
          TextButton(
            onPressed: null, // Disable click, use hover only (group-hover)
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20, // w-5 h-5
                ),
                if (MediaQuery.of(context).size.width >= 1024) ...[
                  const SizedBox(width: AppTheme.spacingSM), // space-x-2
                  Text(
                    userDisplayName,
                    style: AppTextStyles.bodyMediumStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          // Vue: absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-xl py-2 invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-all z-50
          if (_isMenuOpen)
            Positioned(
              right: 0,
              top: 40, // mt-2
              child: Material(
                color: Colors.transparent,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isMenuOpen = true),
                  onExit: (_) => setState(() => _isMenuOpen = false),
                  child: Container(
                    width: 192, // w-48
                    decoration: BoxDecoration(
                      color: bgColor, // bg-white dark:bg-gray-800
                      borderRadius:
                          AppTheme.borderRadiusLargeValue, // rounded-lg
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.2,
                          ), // shadow-xl
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingSM,
                    ), // py-2
                    child: Column(
                      children: [
                        _UserMenuItem(
                          label: widget.labels.profile,
                          onTap: () {
                            if (widget.onProfileTap != null) {
                              widget.onProfileTap!.call();
                            } else {
                              context.go('/profile');
                            }
                            setState(() => _isMenuOpen = false);
                          },
                          hoverColor: hoverColor,
                        ),
                        _UserMenuItem(
                          label: widget.labels.orders,
                          onTap: () {
                            if (widget.onOrdersTap != null) {
                              widget.onOrdersTap!.call();
                            } else {
                              context.go('/orders');
                            }
                            setState(() => _isMenuOpen = false);
                          },
                          hoverColor: hoverColor,
                        ),
                        if (widget.onContactSupportTap != null)
                          _UserMenuItem(
                            label: widget.labels.contactSupport,
                            onTap: () {
                              widget.onContactSupportTap?.call();
                              setState(() => _isMenuOpen = false);
                            },
                            hoverColor: hoverColor,
                          ),
                        _UserMenuItem(
                          label: widget.labels.settings,
                          onTap: () {
                            if (widget.onSettingsTap != null) {
                              widget.onSettingsTap!.call();
                            } else {
                              context.go('/settings');
                            }
                            setState(() => _isMenuOpen = false);
                          },
                          hoverColor: hoverColor,
                        ),
                        _UserMenuItem(
                          label: widget.labels.logout,
                          textColor: const Color(0xFFDC2626), // red-600
                          onTap: () {
                            widget.onLogoutTap?.call();
                            setState(() => _isMenuOpen = false);
                          },
                          hoverColor: hoverColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// User Menu Item
class _UserMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color hoverColor;

  const _UserMenuItem({
    required this.label,
    required this.onTap,
    this.textColor,
    required this.hoverColor,
  });

  @override
  State<_UserMenuItem> createState() => _UserMenuItemState();
}

class _UserMenuItemState extends State<_UserMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        widget.textColor ??
        (isDark ? Colors.white : const Color(0xFF111827)); // gray-900

    return MouseRegion(
      cursor: SystemMouseCursors.click, // Pointer cursor
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        // Remove ripple/splash effect
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG, // px-4
            vertical: AppTheme.spacingSM, // py-2
          ),
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              widget.label,
              style: AppTextStyles.bodyMediumStyle(color: textColor),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile Menu Item
// Vue: button.text-white hover:text-amber-200 py-2 text-left
class _MobileMenuButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? textColor;
  final Widget? icon;

  const _MobileMenuButton({
    required this.label,
    required this.onTap,
    this.textColor,
    this.icon,
  });

  @override
  State<_MobileMenuButton> createState() => _MobileMenuButtonState();
}

class _MobileMenuButtonState extends State<_MobileMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        width: double.infinity, // Full width to match container
        height: 40, // Fixed height: 40px
        child: TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSM,
            ), // py-2
            alignment: Directionality.of(context) == TextDirection.rtl
                ? Alignment
                      .centerRight // text-right for RTL
                : Alignment.centerLeft, // text-left for LTR
            minimumSize: const Size(
              double.infinity,
              40,
            ), // Full width, 40px height
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: Directionality.of(context),
            mainAxisAlignment: Directionality.of(context) == TextDirection.rtl
                ? MainAxisAlignment
                      .end // Right align for RTL
                : MainAxisAlignment.start, // Left align for LTR
            children: [
              // For RTL: text first, then icon
              if (Directionality.of(context) == TextDirection.rtl) ...[
                Text(
                  widget.label,
                  style: AppTextStyles.bodyMediumStyle(
                    color:
                        widget.textColor ??
                        (_isHovered
                            ? const Color(0xFFFDE68A) // hover:text-amber-200
                            : Colors.white), // text-white
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: AppTheme.spacingSM), // space-x-2
                  widget.icon!,
                ],
              ] else ...[
                // For LTR: icon first, then text
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: AppTheme.spacingSM), // space-x-2
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.bodyMediumStyle(
                    color:
                        widget.textColor ??
                        (_isHovered
                            ? const Color(0xFFFDE68A) // hover:text-amber-200
                            : Colors.white), // text-white
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoverable Button with hover:text-amber-200 effect
class _HoverableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets? padding;

  const _HoverableButton({required this.child, this.onPressed, this.padding});

  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Pointer cursor for all buttons
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          padding: widget.padding ?? EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // Remove ripple/splash effect
          splashFactory: NoSplash.splashFactory,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: _isHovered
                ? const Color(0xFFFDE68A) // hover:text-amber-200
                : Colors.white, // text-white
          ),
          child: IconTheme(
            data: IconThemeData(
              color: _isHovered
                  ? const Color(0xFFFDE68A) // hover:text-amber-200
                  : Colors.white, // text-white
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// NavbarUser - User data model
class NavbarUser {
  final String name;
  final String role; // 'admin', 'customer', etc.

  const NavbarUser({required this.name, required this.role});
}

/// NavbarLabels - Localization labels
class NavbarLabels {
  final String searchProducts;
  final String toggleLanguage;
  final String toggleTheme;
  final String adminMenu;
  final String supportChat;
  final String wishlist;
  final String shoppingCart;
  final String signIn;
  final String profile;
  final String orders;
  final String contactSupport;
  final String settings;
  final String logout;
  final String admin;
  final String customer;
  final String manageSite;
  final String darkMode;
  final String lightMode;
  final String language;
  final String cart;
  final String makatebStore;

  const NavbarLabels({
    required this.searchProducts,
    required this.toggleLanguage,
    required this.toggleTheme,
    required this.adminMenu,
    required this.supportChat,
    required this.wishlist,
    required this.shoppingCart,
    required this.signIn,
    required this.profile,
    required this.orders,
    required this.contactSupport,
    required this.settings,
    required this.logout,
    required this.admin,
    required this.customer,
    required this.manageSite,
    required this.darkMode,
    required this.lightMode,
    required this.language,
    required this.cart,
    required this.makatebStore,
  });

  factory NavbarLabels.defaultLabels() {
    return NavbarLabels.forLanguage('en');
  }

  factory NavbarLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return NavbarLabels(
      searchProducts: isArabic ? 'ابحث عن المنتجات...' : 'Search products',
      toggleLanguage: isArabic ? 'تبديل اللغة' : 'Toggle language',
      toggleTheme: isArabic ? 'تبديل المظهر' : 'Toggle theme',
      adminMenu: isArabic ? 'قائمة الإدارة' : 'Admin Menu',
      supportChat: isArabic ? 'دردشة الدعم' : 'Support chat',
      wishlist: isArabic ? 'قائمة الأمنيات' : 'Wishlist',
      shoppingCart: isArabic ? 'سلة التسوق' : 'Shopping cart',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      profile: isArabic ? 'الملف الشخصي' : 'Profile',
      orders: isArabic ? 'الطلبات' : 'Orders',
      contactSupport: isArabic ? 'اتصل بالدعم' : 'Contact Support',
      settings: isArabic ? 'الإعدادات' : 'Settings',
      logout: isArabic ? 'تسجيل الخروج' : 'Logout',
      admin: isArabic ? 'الإدارة' : 'Admin',
      customer: isArabic ? 'عميل' : 'Customer',
      manageSite: isArabic ? 'إدارة الموقع' : 'Manage Site',
      darkMode: isArabic ? 'الوضع الليلي' : 'Dark Mode',
      lightMode: isArabic ? 'الوضع النهاري' : 'Light Mode',
      language: isArabic ? 'اللغة' : 'Language',
      cart: isArabic ? 'السلة' : 'Cart',
      makatebStore: isArabic ? 'مكاتب ستور' : 'Makateb Store',
    );
  }
}
