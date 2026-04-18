import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/package_button.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/package_card.dart';
import '../../core/widgets/footer.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/services/api_services/catalog_api_service.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/stores/language_store.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/localization/app_localizations.dart';

/// DashboardScreen - Main dashboard/home screen
///
/// Equivalent to Vue's Dashboard.vue page.
/// Displays hero section, products/packages toggle, categories filter, and product/package grids.
///
/// Features:
/// - Hero section with background image
/// - Products/Packages toggle
/// - Categories filter (for products)
/// - Products grid
/// - Packages grid
/// - Mobile cart button
/// - Benefits modal
/// - Dark mode support
/// - Responsive design
class DashboardScreen extends ConsumerStatefulWidget {
  /// Mock products data
  final List<ProductData>? products;

  /// Mock packages data
  final List<PackageData>? packages;

  /// Mock categories data
  final List<DashboardCategoryData>? categories;

  /// Cart item count
  final int? cartCount;

  /// Loading states
  final bool loadingProducts;
  final bool loadingPackages;
  final bool loadingCategories;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when package is tapped
  final void Function(String packageId)? onPackageTap;

  /// Callback when cart is tapped
  final VoidCallback? onCartTap;

  /// Callback when shop now is tapped
  final VoidCallback? onShopNow;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Labels for localization
  final DashboardScreenLabels? labels;

  const DashboardScreen({
    super.key,
    this.products,
    this.packages,
    this.categories,
    this.cartCount,
    this.loadingProducts = false,
    this.loadingPackages = false,
    this.loadingCategories = false,
    this.onProductTap,
    this.onPackageTap,
    this.onCartTap,
    this.onShopNow,
    this.getLocalizedName,
    this.labels,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey _productsSectionKey = GlobalKey();
  final GlobalKey _packagesSectionKey = GlobalKey();
  bool _showPackages = false;
  String? _selectedCategoryId;
  bool _showBenefits = false;

  List<ProductData> _products = [];
  List<PackageData> _packages = [];
  List<DashboardCategoryData> _categories = [];
  bool _isLoadingApi = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use widget props if provided, otherwise load mock data
    if (widget.products != null) {
      _products = widget.products!;
    }
    if (widget.packages != null) {
      _packages = widget.packages!;
    }
    if (widget.categories != null) {
      _categories = widget.categories!;
    }
    // Load mock data if no props provided
    if (_products.isEmpty && _packages.isEmpty && _categories.isEmpty) {
      _loadFromApi(); // falls back to mock data if API fails
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Mock loader removed: the goal is to show backend DB data only.

  Future<void> _loadFromApi() async {
    setState(() {
      _isLoadingApi = true;
      _errorMessage = null;
    });

    try {
      final api = CatalogApiService();

      // Load categories + packages first so the dashboard can still show DB data
      // even if the products endpoint is failing.
      final categoriesRaw = await api.fetchCategories();
      final packagesRaw = await api.fetchPackages();

      // Build category lookup to enrich products
      final categoryById = <String, ProductCategory>{};
      final categories = <DashboardCategoryData>[];
      for (final item in categoriesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final name = (map['name'] ?? map['name_en'] ?? '').toString();
        final nameAr = map['name_ar']?.toString();
        final nameEn = map['name_en']?.toString() ?? name;
        final imageUrl = map['image_url']?.toString();

        final productCat = ProductCategory(
          id: id,
          name: nameEn,
          nameAr: nameAr,
          nameEn: nameEn,
        );
        categoryById[id] = productCat;

        categories.add(
          DashboardCategoryData(
            id: id,
            name: nameEn,
            nameAr: nameAr,
            nameEn: nameEn,
            imageUrl: imageUrl,
          ),
        );
      }

      final packages = <PackageData>[];
      for (final item in packagesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final priceStr = map['price']?.toString();
        final minPriceStr = map['min_price']?.toString();
        final price =
            double.tryParse(priceStr ?? '') ??
            double.tryParse(minPriceStr ?? '') ??
            0.0;

        final count = map['products_count'] is int
            ? map['products_count'] as int
            : int.tryParse(map['products_count']?.toString() ?? '') ?? 0;

        packages.add(
          PackageData(
            id: id,
            name: (map['name'] ?? '').toString(),
            description: map['description']?.toString(),
            price: price,
            imageUrl: map['image_url']?.toString(),
            productsCount: count,
          ),
        );
      }

      // Products load independently; if /products fails, we do NOT fall back to mock.
      List<ProductData> products = [];
      try {
        final productsRaw = await api.fetchProducts();
        final parsed = <ProductData>[];
        for (final item in productsRaw) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final id = (map['id'] ?? '').toString();
          if (id.isEmpty) continue;

          final categoriesList = <ProductCategory>[];
          final categoriesRaw = map['categories'];
          if (categoriesRaw is List) {
            for (final cat in categoriesRaw) {
              if (cat is Map) {
                final catMap = Map<String, dynamic>.from(cat);
                final catId = (catMap['id'] ?? '').toString();
                if (catId.isNotEmpty) {
                  categoriesList.add(
                    ProductCategory(
                      id: catId,
                      name: (catMap['name'] ?? catMap['name_en'] ?? '')
                          .toString(),
                      nameAr: catMap['name_ar']?.toString(),
                      nameEn: catMap['name_en']?.toString(),
                    ),
                  );
                }
              }
            }
          }

          final categoryId = map['category_id']?.toString();
          final category = (categoryId != null && categoryId.isNotEmpty)
              ? categoryById[categoryId]
              : (categoriesList.isNotEmpty ? categoriesList.first : null);

          // If categoriesList is empty but we have a category_id, add it for backward compat
          if (categoriesList.isEmpty &&
              categoryId != null &&
              categoryId.isNotEmpty) {
            categoriesList.add(
              ProductCategory(
                id: categoryId,
                name: category?.name ?? '',
                nameAr: category?.nameAr,
                nameEn: category?.nameEn,
              ),
            );
          }

          final imageUrl = map['image_url']?.toString();
          final imageUrls = map['image_urls'];
          final resolvedImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
              ? imageUrl
              : (imageUrls is List && imageUrls.isNotEmpty)
              ? imageUrls.first?.toString()
              : null;

          final priceStr = map['price']?.toString();
          final price = double.tryParse(priceStr ?? '') ?? 0.0;

          final stock = map['stock'] is int
              ? map['stock'] as int
              : int.tryParse(map['stock']?.toString() ?? '');

          final adminRatingMap = map['admin_rating'];
          AdminRating? adminRating;
          if (adminRatingMap is Map) {
            final m = Map<String, dynamic>.from(adminRatingMap);
            final ratingVal = m['rating'];
            adminRating = AdminRating(
              rating: ratingVal is num
                  ? ratingVal.toDouble()
                  : double.tryParse(ratingVal?.toString() ?? ''),
            );
          }

          parsed.add(
            ProductData(
              id: id,
              name: (map['name'] ?? '').toString(),
              description: map['description']?.toString(),
              price: price,
              imageUrl: resolvedImageUrl,
              stock: stock,
              adminRating: adminRating,
              category: category,
              categories: categoriesList.isNotEmpty ? categoriesList : null,
            ),
          );
        }
        products = parsed;
      } catch (e) {
        debugPrint('Dashboard products API failed (GET /products): $e');
        products = [];
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
        _packages = packages;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Dashboard API load failed: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingApi = false);
      }
    }
  }

  Future<void> _handleAddProductToCart(String productId) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .addProduct(productId);

    if (success) {
      NotificationToastService.instance.showSuccess(
        l10n.translate('product_added_to_cart'),
      );
    } else {
      final error = ref.read(cartStoreProvider).error;
      NotificationToastService.instance.showError(
        error ?? l10n.translate('failed_to_add_to_cart'),
      );
    }
  }

  Future<void> _handleAddPackageToCart(String packageId) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(cartStoreProvider.notifier)
        .addPackage(packageId);

    if (success) {
      NotificationToastService.instance.showSuccess(
        l10n.translate('package_added_to_cart'),
      );
    } else {
      final error = ref.read(cartStoreProvider).error;
      NotificationToastService.instance.showError(
        error ?? l10n.translate('failed_to_add_to_cart'),
      );
    }
  }

  Future<void> _handleToggleProductWishlist(String productId) async {
    final wishListNotifier = ref.read(wishlistStoreProvider.notifier);
    final success = await wishListNotifier.toggleProduct(productId);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    if (success) {
      final isInWishlist = wishListNotifier.isProductInWishlistSync(productId);
      if (isInWishlist) {
        NotificationToastService.instance.showSuccess(
          l10n.translate('added_to_wishlist'),
        );
      } else {
        NotificationToastService.instance.showSuccess(
          l10n.translate('removed_from_wishlist'),
        );
      }
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_update_wishlist'),
      );
    }
  }

  Future<void> _handleTogglePackageWishlist(String packageId) async {
    final wishListNotifier = ref.read(wishlistStoreProvider.notifier);
    final success = await wishListNotifier.togglePackage(packageId);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    if (success) {
      final isInWishlist = wishListNotifier.isPackageInWishlistSync(packageId);
      if (isInWishlist) {
        NotificationToastService.instance.showSuccess(
          l10n.translate('added_to_wishlist'),
        );
      } else {
        NotificationToastService.instance.showSuccess(
          l10n.translate('removed_from_wishlist'),
        );
      }
    } else {
      NotificationToastService.instance.showError(
        l10n.translate('failed_to_update_wishlist'),
      );
    }
  }

  List<ProductData> get _filteredProducts {
    if (_selectedCategoryId == null) {
      return _products;
    }
    // Vue: Filter by category_id or categories array
    return _products.where((p) {
      // Check if product has categories array (many-to-many)
      if (p.categories != null && p.categories!.isNotEmpty) {
        return p.categories!.any((cat) => cat.id == _selectedCategoryId);
      }
      // Fallback to category_id for backward compatibility
      // Note: ProductData might have category_id field, check both
      if (p.category?.id == _selectedCategoryId) {
        return true;
      }
      // Check if product has category_id field directly
      // (This would require ProductData to have category_id, which it might not)
      return false;
    }).toList();
  }

  String _getLocalizedName(dynamic item) {
    // For categories, use translation function
    if (item is DashboardCategoryData) {
      final lang = ref.read(currentLanguageProvider);
      if (lang == 'ar' && item.nameAr != null && item.nameAr!.isNotEmpty) {
        return item.nameAr!;
      }
      if (lang == 'en' && item.nameEn != null && item.nameEn!.isNotEmpty) {
        return item.nameEn!;
      }
      // Fallback to existing translation map for any older mock names.
      final translateCategoryName = ref.read(translateCategoryNameProvider);
      return translateCategoryName(item.name);
    }
    // For other items, use the provided function or fallback to name
    return widget.getLocalizedName?.call(item) ?? (item?.name ?? '');
  }

  void _scrollToContent() {
    widget.onShopNow?.call();
    // Scroll to appropriate section based on toggle
    final targetKey = _showPackages ? _packagesSectionKey : _productsSectionKey;
    final context = targetKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show section near top of viewport
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Watch language changes to update labels
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? DashboardScreenLabels.forLanguage(currentLanguage);

    // Vue: min-h-screen bg-gradient-to-b from-amber-50 to-white dark:from-gray-900 dark:to-gray-800
    // Note: PageLayout already provides SingleChildScrollView, so we don't need another one
    return PageLayout(
      showCartButton: true, // Show cart button in PageLayout (fixed position)
      cartCount: widget.cartCount ?? 0,
      onCartTap: widget.onCartTap,
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
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hero Section
                _buildHeroSection(isDark, labels),

                // Main Content
                // Toggle Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG, // px-4
                    vertical: AppTheme.spacingXXL * 1.5, // py-12
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1280,
                    ), // max-w-7xl
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButtons(isDark, labels),
                        const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
                        // Categories Filter (only for products)
                        if (!_showPackages)
                          _buildCategoriesFilter(isDark, labels),

                        const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
                        // Products or Packages Section
                        if (!_showPackages)
                          _buildProductsSection(
                            isDark,
                            labels,
                            key: _productsSectionKey,
                          )
                        else
                          _buildPackagesSection(isDark, labels),

                        // Error message display
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLG),
                            child: Column(
                              children: [
                                Text(
                                  "Error: $_errorMessage",
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadFromApi,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          ),

                        // Empty data message
                        if (!_isLoadingApi &&
                            _errorMessage == null &&
                            _products.isEmpty &&
                            !_showPackages)
                          const Padding(
                            padding: EdgeInsets.all(AppTheme.spacingXL),
                            child: Text(
                              "No products found in database.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Footer(
                  copyrightText: AppLocalizations.of(
                    context,
                  ).translate('copyright'),
                ),
              ],
            ),

            // Benefits Modal
            if (_showBenefits) _buildBenefitsModal(isDark, labels),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark, DashboardScreenLabels labels) {
    return SizedBox(
      height: Responsive.scale(context, 384), // h-96
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image - bg-cover bg-center
          // Vue: backgroundImage: 'url(/background%20image.png)'
          Positioned.fill(
            child: Image.asset(
              'asset/background image.png', // Background image
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading background image: $error');
                return Container(
                  color: const Color(
                    0xFFF3F4F6,
                  ), // Fallback to light gray (matches office scene)
                );
              },
            ),
          ),

          // Gradient Overlay: absolute inset-0 bg-gradient-to-r from-amber-900/40 to-amber-950/40
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft, // from-r (left to right)
                  end: Alignment.centerRight, // to-r
                  colors: [
                    const Color(
                      0xFF78350F,
                    ).withValues(alpha: 0.4), // amber-900/40
                    const Color(
                      0xFF451A03,
                    ).withValues(alpha: 0.4), // amber-950/40
                  ],
                ),
              ),
            ),
          ),

          // Content: relative z-10 text-center text-white px-4
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG,
                ), // px-4
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // h1.text-5xl md:text-6xl font-bold mb-4
                    Text(
                      labels.makatebStore,
                      style:
                          AppTextStyles.titleLargeStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // Make it bold
                          ).copyWith(
                            fontSize: MediaQuery.of(context).size.width >= 768
                                ? AppTextStyles.text6XL
                                : AppTextStyles.text5XL,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // mb-4
                    // p.text-xl md:text-2xl mb-8
                    Text(
                      labels.welcomeDescription,
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: Colors.white, // text-white
                          ).copyWith(
                            fontSize: MediaQuery.of(context).size.width >= 768
                                ? AppTextStyles
                                      .text2XL // md:text-2xl
                                : AppTextStyles.textXL, // text-xl
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
                    // button with wood texture: Shop Now
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: AppButton(
                        text: labels.shopNow,
                        onPressed: _scrollToContent,
                        size: AppButtonSize.large,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(bool isDark, DashboardScreenLabels labels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxWidth < 360;
        final spacing = isVerySmall ? AppTheme.spacingSM : AppTheme.spacingLG;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _buildToggleButton(
                text: labels.products,
                isSelected: !_showPackages,
                isDark: isDark,
                onPressed: () {
                  setState(() {
                    _showPackages = false;
                  });
                },
                labels: labels,
              ),
            ),
            SizedBox(width: spacing), // space-x-4 (responsive)
            Flexible(
              child: _buildToggleButton(
                text: labels.packages,
                isSelected: _showPackages,
                isDark: isDark,
                onPressed: () {
                  setState(() {
                    _showPackages = true;
                  });
                },
                labels: labels,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onPressed,
    required DashboardScreenLabels labels,
  }) {
    final isPackagesButton = text == labels.packages;

    // Use PackageButton for Packages toggle when not selected
    if (isPackagesButton && !isSelected) {
      return PackageButton(
        isDark: isDark,
        text: text,
        onTap: onPressed,
        icon: Icons.inventory_2,
        iconSize: 16, // w-4 h-4
      );
    }

    const woodTexturePath =
        'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png';

    return _ToggleButtonWidget(
      text: text,
      isSelected: isSelected,
      isDark: isDark,
      woodTexturePath: woodTexturePath,
      onPressed: onPressed,
      isPackagesButton: isPackagesButton,
    );
  }

  Widget _buildCategoriesFilter(bool isDark, DashboardScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vue: text-lg font-semibold mb-4 text-center
        SizedBox(
          width: double.infinity, // Full width to center the text
          child: Text(
            labels.categories,
            style:
                AppTextStyles.titleSmallStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                  fontWeight: FontWeight.bold, // Make it bold
                ).copyWith(
                  fontSize: AppTextStyles.textLG, // text-lg
                ),
            textAlign: TextAlign.center, // text-center - centers on screen
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG), // mb-4
        LayoutBuilder(
          builder: (context, constraints) {
            // Vue: grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-8
            final crossAxisCount = constraints.maxWidth >= 1100
                ? 10 // xl: 10
                : constraints.maxWidth >= 800
                ? 5 // lg/md: 5
                : constraints.maxWidth >= 500
                ? 3 // sm/md: 3
                : 2; // xs: 2

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: constraints.maxWidth < 640
                    ? 6 // tighter gap on mobile
                    : AppTheme.spacingLG,
                mainAxisSpacing: constraints.maxWidth < 640
                    ? 6 // tighter gap on mobile
                    : AppTheme.spacingLG,
                childAspectRatio: constraints.maxWidth < 500
                    ? 1.45 // Even more compact height
                    : constraints.maxWidth < 800
                    ? 1.35 // 3 columns compact
                    : 1.25, // Large screen compact
              ),
              itemCount: _categories.length + 1, // +1 for "All" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" button
                  return _buildCategoryButton(
                    category: null,
                    label: labels.all,
                    isSelected: _selectedCategoryId == null,
                    isDark: isDark,
                  );
                }
                final category = _categories[index - 1];
                return _buildCategoryButton(
                  category: category,
                  label: _getLocalizedName(category),
                  isSelected: _selectedCategoryId == category.id,
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryButton({
    DashboardCategoryData? category,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return _CategoryButtonWidget(
      category: category,
      label: label,
      isSelected: isSelected,
      isDark: isDark,
      onTap: () {
        setState(() {
          _selectedCategoryId = category?.id;
        });
      },
    );
  }

  Widget _buildProductsSection(
    bool isDark,
    DashboardScreenLabels labels, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedCategoryId == null
                  ? labels.allProducts
                  : _getLocalizedName(
                      _categories.firstWhere(
                        (c) => c.id == _selectedCategoryId,
                        orElse: () => DashboardCategoryData(id: '', name: ''),
                      ),
                    ),
              style:
                  AppTextStyles.titleLargeStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    fontWeight: FontWeight.bold, // Make it bold
                  ).copyWith(
                    fontSize: AppTextStyles.text3XL, // text-3xl
                  ),
            ),
            const SizedBox(width: AppTheme.spacingMD), // ml-3
            Text(
              '(${_filteredProducts.length} ${labels.items})',
              style:
                  AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                  ).copyWith(
                    fontSize: AppTextStyles.textLG, // text-lg
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        if (_isLoadingApi || widget.loadingProducts)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
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
        else if (_filteredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
              child: Text(
                labels.noProductsFound,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF4B5563), // gray-600
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Vue: grid-cols-2 sm:grid-cols-2 lg:grid-cols-4
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 4 // lg:grid-cols-4
                  : 2; // grid-cols-2 sm:grid-cols-2

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                  mainAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                  childAspectRatio: constraints.maxWidth < 640 ? 0.58 : 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  // Watch wishlist items to react to heart clicks
                  final wishlistItems = ref.watch(wishlistStoreProvider).items;
                  final isInWishlist = wishlistItems.any(
                    (item) => item.productId == product.id,
                  );

                  return ProductCard(
                    product: product,
                    size: ProductCardSize.small,
                    isInWishlist: isInWishlist,
                    onViewDetails: widget.onProductTap != null
                        ? (id) => widget.onProductTap!(id)
                        : null,
                    onAddToCart: _handleAddProductToCart,
                    onToggleWishlist: _handleToggleProductWishlist,
                    getLocalizedName: widget.getLocalizedName,
                    getProductCategoryName: (product) {
                      // Use translation function for category names
                      final translateCategoryName = ref.read(
                        translateCategoryNameProvider,
                      );
                      return translateCategoryName(product.category?.name);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildPackagesSection(bool isDark, DashboardScreenLabels labels) {
    return Column(
      key: _packagesSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.specialPackageDeals,
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-900
                fontWeight: FontWeight.bold, // make it bold
              ).copyWith(
                fontSize: AppTextStyles.text3XL, // text-3xl
              ),
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        if (_isLoadingApi || widget.loadingPackages)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
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
        else if (_packages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
              child: Text(
                labels.noPackagesAvailable,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF4B5563), // gray-600
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Match product card grid: 2 per row on mobile, 4 per row on large screens
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 4 // lg:grid-cols-4
                  : 2; // grid-cols-2 sm:grid-cols-2

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                  mainAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
                  childAspectRatio: constraints.maxWidth < 640 ? 0.58 : 0.75,
                ),
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final package = _packages[index];
                  // Watch wishlist items to react to heart clicks
                  final wishlistItems = ref.watch(wishlistStoreProvider).items;
                  final isInWishlist = wishlistItems.any(
                    (item) => item.packageId == package.id,
                  );

                  return PackageCard(
                    package: package,
                    size: PackageCardSize.small,
                    isInWishlist: isInWishlist,
                    onViewDetails: widget.onPackageTap != null
                        ? (id) => widget.onPackageTap!(id)
                        : null,
                    onAddToCart: _handleAddPackageToCart,
                    onToggleWishlist: _handleTogglePackageWishlist,
                    getLocalizedName: widget.getLocalizedName,
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildBenefitsModal(bool isDark, DashboardScreenLabels labels) {
    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showBenefits = false;
              });
            },
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),

        // Modal Content
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Responsive.scale(context, 672), // max-w-2xl
              maxHeight: Responsive.scale(context, 640), // max-h-[80vh]
            ),
            margin: EdgeInsets.all(
              Responsive.scale(context, AppTheme.spacingLG),
            ), // mx-4
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F2937) // gray-800
                  : Colors.white,
              borderRadius: AppTheme.borderRadiusLargeValue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(
                    AppTheme.spacingLG * 1.5,
                  ), // p-6
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF374151) // gray-700
                            : const Color(0xFFE5E7EB), // gray-200
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${labels.membershipTier} Benefits',
                        style:
                            AppTextStyles.titleMediumStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827), // gray-900
                              fontWeight: AppTextStyles.medium,
                            ).copyWith(
                              fontSize: Responsive.font(
                                context,
                                AppTextStyles.textXL,
                              ), // text-xl
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showBenefits = false;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          size: Responsive.scale(context, 24), // w-6 h-6
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                    ],
                  ),
                ),

                // Benefits List
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(
                      AppTheme.spacingLG * 1.5,
                    ), // p-6
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: labels.roleBenefits.map((benefit) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingLG,
                          ), // space-y-4
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: Responsive.scale(context, 20), // w-5 h-5
                                color: const Color(0xFF6D4C41), // brown-600
                              ),
                              const SizedBox(
                                width: AppTheme.spacingMD,
                              ), // gap-3
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: AppTextStyles.bodyMediumStyle(
                                    color: isDark
                                        ? const Color(0xFFD1D5DB) // gray-300
                                        : const Color(0xFF374151), // gray-700
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Category Button Widget with hover effects
class _CategoryButtonWidget extends StatefulWidget {
  final DashboardCategoryData? category;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryButtonWidget({
    this.category,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CategoryButtonWidget> createState() => _CategoryButtonWidgetState();
}

class _CategoryButtonWidgetState extends State<_CategoryButtonWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.transparent,
          child: MouseRegion(
            cursor: SystemMouseCursors.click, // cursor-pointer
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppTheme.borderRadiusLargeValue,
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 300,
                ), // transition-all duration-300
                curve: Curves.easeInOut,
                // Width and height are controlled by GridView's childAspectRatio
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ), // Tight padding for smaller card feel
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1F2937) // dark:bg-gray-800
                      : Colors.white, // bg-white
                  borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
                  border: Border.all(
                    color: widget.isDark
                        ? const Color(0xFF92400E).withValues(
                            alpha: 0.5,
                          ) // dark:border-amber-800/50
                        : const Color(0xFFFDE68A), // border-amber-200
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isHovered ? 0.1 : 0.05,
                      ), // hover:shadow-md, shadow-sm
                      blurRadius: _isHovered ? 4 : 2, // hover:shadow-md
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // flex flex-col items-center justify-center
                  children: [
                    Container(
                      width: Responsive.scale(
                        context,
                        constraints.maxWidth < 500
                            ? 38
                            : (constraints.maxWidth < 1100 ? 44 : 48),
                      ), // Increased icon size
                      height: Responsive.scale(
                        context,
                        constraints.maxWidth < 500
                            ? 38
                            : (constraints.maxWidth < 1100 ? 44 : 48),
                      ), // Increased icon size
                      margin: EdgeInsets.only(
                        bottom: Responsive.scale(context, AppTheme.spacingXS),
                      ), // mb-1
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xFF78350F).withValues(
                                alpha: 0.2,
                              ) // amber-950/20
                            : const Color(0xFFFFFBEB), // amber-50
                        borderRadius: AppTheme.borderRadiusLargeValue,
                      ),
                      child: widget.category?.imageUrl != null
                          ? ClipRRect(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              child: Image.network(
                                widget.category!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.category,
                                      size: 32,
                                      color: widget.isDark
                                          ? const Color(0xFFD97706) // amber-600
                                          : const Color(
                                              0xFF92400E,
                                            ), // amber-800
                                    ),
                              ),
                            )
                          : Icon(
                              widget.category == null
                                  ? Icons.menu
                                  : Icons.category,
                              size: Responsive.scale(context, 32),
                              color: widget.isDark
                                  ? const Color(0xFFD97706) // amber-600
                                  : const Color(0xFF92400E), // amber-800
                            ),
                    ),
                    Text(
                      widget.label,
                      style:
                          AppTextStyles.bodySmallStyle(
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-900
                            fontWeight: FontWeight.w900, // Maximum bold
                          ).copyWith(
                            fontSize: Responsive.font(
                              context,
                              constraints.maxWidth < 500 ? 11 : 12,
                            ), // Increased font size
                            height: 1.2,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Toggle Button Widget with hover and press states
class _ToggleButtonWidget extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool isDark;
  final String woodTexturePath;
  final VoidCallback onPressed;
  final bool isPackagesButton;

  const _ToggleButtonWidget({
    required this.text,
    required this.isSelected,
    required this.isDark,
    required this.woodTexturePath,
    required this.onPressed,
    this.isPackagesButton = false,
  });

  @override
  State<_ToggleButtonWidget> createState() => _ToggleButtonWidgetState();
}

class _ToggleButtonWidgetState extends State<_ToggleButtonWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ), // transition-all duration-200
          curve: Curves.easeInOut,
          height: widget.isSelected
              ? Responsive.scale(context, 40)
              : Responsive.scale(
                  context,
                  44,
                ), // Selected: 40px, Unselected: 44px
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.scale(context, AppTheme.spacingLG), // px-4
            vertical: Responsive.scale(context, AppTheme.spacingSM), // py-2
          ),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
            // Selected state: Wood texture background
            image: widget.isSelected
                ? DecorationImage(
                    image: AssetImage(widget.woodTexturePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  )
                : null,
            // Unselected state: Transparent, hover:bg-amber-800 dark:hover:bg-amber-600
            color: widget.isSelected
                ? null
                : (_isHovered
                      ? (widget.isDark
                            ? const Color(0xFFD97706) // dark:hover:bg-amber-600
                            : const Color(0xFF92400E)) // hover:bg-amber-800
                      : Colors.transparent), // bg-transparent
            border: widget.isSelected
                ? null
                : Border.all(
                    color: widget.isDark
                        ? const Color(0xFFD97706) // dark:border-amber-600
                        : const Color(0xFF92400E), // border-amber-800
                    width: 2, // border-2
                  ),
            // Shadow for selected state: shadow-lg hover:shadow-xl
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isHovered ? 0.25 : 0.15,
                      ),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ]
                : null,
          ),
          // Scale animation: hover:scale-105 active:scale-95 (only for selected)
          transform: Matrix4.diagonal3Values(
            widget.isSelected
                ? (_isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0))
                : 1.0,
            widget.isSelected
                ? (_isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0))
                : 1.0,
            1.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isPackagesButton)
                Icon(
                  Icons.inventory_2,
                  size: Responsive.scale(context, 16), // w-4 h-4
                  color: Colors.white,
                ),
              if (widget.isPackagesButton)
                const SizedBox(width: AppTheme.spacingSM), // gap-2
              Flexible(
                child: Text(
                  widget.text,
                  style: AppTextStyles.bodyMediumStyle(
                    color: widget.isSelected
                        ? Colors
                              .white // text-white (selected)
                        : (_isHovered
                              ? Colors
                                    .white // hover:text-white (unselected hover)
                              : (widget.isDark
                                    ? const Color(
                                        0xFFFDE68A,
                                      ) // dark:text-amber-100 (unselected)
                                    : const Color(
                                        0xFF78350F,
                                      ))), // text-amber-900 (unselected)
                    fontWeight: AppTextStyles.medium, // font-medium
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DashboardCategoryData - Category data model
class DashboardCategoryData {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? imageUrl;

  const DashboardCategoryData({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.imageUrl,
  });
}

/// DashboardScreenLabels - Localization labels
class DashboardScreenLabels {
  final String makatebStore;
  final String welcomeDescription;
  final String shopNow;
  final String products;
  final String packages;
  final String categories;
  final String all;
  final String allProducts;
  final String items;
  final String loading;
  final String noProductsFound;
  final String specialPackageDeals;
  final String noPackagesAvailable;
  final String viewYourCart;
  final String membershipTier;
  final List<String> roleBenefits;

  const DashboardScreenLabels({
    required this.makatebStore,
    required this.welcomeDescription,
    required this.shopNow,
    required this.products,
    required this.packages,
    required this.categories,
    required this.all,
    required this.allProducts,
    required this.items,
    required this.loading,
    required this.noProductsFound,
    required this.specialPackageDeals,
    required this.noPackagesAvailable,
    required this.viewYourCart,
    required this.membershipTier,
    required this.roleBenefits,
  });

  factory DashboardScreenLabels.defaultLabels() {
    return DashboardScreenLabels.forLanguage('en');
  }

  factory DashboardScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return DashboardScreenLabels(
      makatebStore: isArabic ? 'مكاتب ستور' : 'Makateb Store',
      welcomeDescription: isArabic
          ? 'مرحباً بك في مكاتب ستور! كل ما يحتاجه مكتبك في مكان واحد.'
          : 'Welcome to Makateb Store! Everything your office needs, all in one place.',
      shopNow: isArabic ? 'تسوق الآن' : 'Shop Now',
      products: isArabic ? 'المنتجات' : 'Products',
      packages: isArabic ? 'الباقات' : 'Packages',
      categories: isArabic ? 'الفئات' : 'Categories',
      all: isArabic ? 'الكل' : 'All',
      allProducts: isArabic ? 'جميع المنتجات' : 'All Products',
      items: isArabic ? 'عناصر' : 'items',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      noProductsFound: isArabic
          ? 'لم يتم العثور على منتجات'
          : 'No products found',
      specialPackageDeals: isArabic
          ? 'عروض الباقات الخاصة'
          : 'Special Package Deals',
      noPackagesAvailable: isArabic
          ? 'لا توجد باقات متاحة'
          : 'No packages available',
      viewYourCart: isArabic ? 'عرض سلة التسوق' : 'View Your Cart',
      membershipTier: isArabic ? 'المستوى الذهبي' : 'Gold Tier',
      roleBenefits: isArabic
          ? [
              'تصفح وشراء المنتجات',
              'إضافة المنتجات إلى قائمة الأمنيات',
              'عرض سجل الطلبات',
              'تقييم ومراجعة المنتجات',
              'الدردشة مع الإدارة',
              'الوصول إلى دعم العملاء',
            ]
          : [
              'Browse and purchase products',
              'Add products to wishlist',
              'View order history',
              'Rate and review products',
              'Chat with admins',
              'Access customer support',
            ],
    );
  }
}
