import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_services/catalog_api_service.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/widgets/product_card.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// SearchScreen - Product search screen
///
/// Equivalent to Vue's Search.vue page.
/// Displays searchable products with filters and sorting options.
///
/// Features:
/// - Search bar with icon
/// - Filter section (category, sort, price range)
/// - Products grid
/// - Results count
/// - Empty state
/// - Loading state
/// - Dark mode support
/// - Responsive design
class SearchScreen extends ConsumerStatefulWidget {
  /// Mock products data
  final List<SearchProductData>? products;

  /// Mock categories data
  final List<SearchCategoryData>? categories;

  /// Mock wishlist items (product IDs)
  final List<String>? wishlistProductIds;

  /// Mock user data (for showing/hiding buttons)
  final SearchUserData? user;

  /// Loading state
  final bool loading;

  /// Initial search query
  final String? initialQuery;

  /// Search category (if searching by category)
  final SearchCategoryData? searchCategory;

  /// Whether this is a category search
  final bool isCategorySearch;

  /// Callback when search is performed
  final void Function(String query)? onSearch;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when add to cart is tapped
  final void Function(SearchProductData product)? onAddToCart;

  /// Callback when wishlist toggle is tapped
  final void Function(String productId)? onToggleWishlist;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Labels for localization
  final SearchScreenLabels? labels;

  const SearchScreen({
    super.key,
    this.products,
    this.categories,
    this.wishlistProductIds,
    this.user,
    this.loading = false,
    this.initialQuery,
    this.searchCategory,
    this.isCategorySearch = false,
    this.onSearch,
    this.onProductTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'relevance';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _showFilters = false;

  List<SearchProductData> _products = [];
  List<SearchProductData> _filteredProducts = [];

  final _catalogApi = CatalogApiService();

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController.text = _searchQuery;
    _minPriceController.text = '0';
    _maxPriceController.text = '1000';
    if (widget.products != null) {
      _products = widget.products!;
      _applyFilters();
    } else {
      _loadFromApi();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadFromApi() async {
    try {
      final results = await Future.wait([
        _catalogApi.fetchProducts(),
        _catalogApi.fetchPackages(),
      ]);

      final productsRaw = results[0];
      final packagesRaw = results[1];

      final parsed = <SearchProductData>[];

      // Parse Products
      for (final item in productsRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

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

        final categoryId = map['category_id']?.toString() ?? '';
        final averageRating = map['average_rating'] is num
            ? (map['average_rating'] as num).toDouble()
            : double.tryParse(map['average_rating']?.toString() ?? '') ?? 0.0;
        final reviewCount = map['review_count'] is int
            ? map['review_count'] as int
            : int.tryParse(map['review_count']?.toString() ?? '') ?? 0;

        parsed.add(
          SearchProductData(
            id: id,
            name: (map['name'] ?? '').toString(),
            description: map['description']?.toString(),
            price: price,
            imageUrl: resolvedImageUrl,
            categoryId: categoryId,
            stock: stock,
            averageRating: averageRating,
            reviewCount: reviewCount,
            isPackage: false,
          ),
        );
      }

      // Parse Packages
      for (final item in packagesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final priceStr = map['price']?.toString();
        final price = double.tryParse(priceStr ?? '') ?? 0.0;

        final imageUrl = map['image_url']?.toString();

        parsed.add(
          SearchProductData(
            id: id,
            name: (map['name'] ?? '').toString(),
            description: map['description']?.toString(),
            price: price,
            imageUrl: imageUrl,
            isPackage: true,
            stock:
                999, // Packages usually don't have stock limits in the same way
          ),
        );
      }

      if (mounted) {
        setState(() {
          _products = parsed;
        });
        _applyFilters();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Search results load failed: $e');
      }
      if (mounted) {
        setState(() {
          _products = [];
        });
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    List<SearchProductData> results = List.from(_products);

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((product) {
        final name = product.name.toLowerCase();
        final description = (product.description ?? '').toLowerCase();
        final categoryName = _getCategoryName(
          product.categoryId,
          isPackage: product.isPackage,
        ).toLowerCase();
        return name.contains(query) ||
            description.contains(query) ||
            categoryName.contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      results = results.where((product) {
        if (product.categories != null && product.categories!.isNotEmpty) {
          return product.categories!.any((cat) => cat.id == _selectedCategory);
        }
        return product.categoryId == _selectedCategory;
      }).toList();
    }

    // Price range filter
    final minPrice = double.tryParse(_minPriceController.text) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text) ?? 1000;
    results = results.where((product) {
      final price = product.price;
      return price >= minPrice && price <= maxPrice;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'price-low':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price-high':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        results.sort((a, b) {
          final ratingA = _getProductRating(a);
          final ratingB = _getProductRating(b);
          return ratingB.compareTo(ratingA);
        });
        break;
      // 'relevance' - keep original order
    }

    setState(() {
      _filteredProducts = results;
    });
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
    widget.onSearch?.call(_searchQuery);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _sortBy = 'relevance';
      _minPriceController.text = '0';
      _maxPriceController.text = '1000';
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  String _getCategoryName(String? categoryId, {bool isPackage = false}) {
    if (isPackage) {
      final currentLanguage = ref.read(currentLanguageProvider);
      final activeLabels =
          widget.labels ?? SearchScreenLabels.forLanguage(currentLanguage);
      return activeLabels.category;
    }
    if (categoryId == null) return 'Uncategorized';
    final category = widget.categories?.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => SearchCategoryData(id: '', name: ''),
    );
    if (category == null || category.id.isEmpty) {
      return 'Uncategorized';
    }
    return widget.getLocalizedName?.call(category) ?? category.name;
  }

  double _getProductRating(SearchProductData product) {
    if (product.averageRating != null) return product.averageRating!;
    if (product.adminRating != null) return product.adminRating!;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? SearchScreenLabels.forLanguage(currentLanguage);

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive horizontal padding: smaller on very small screens
            final horizontalPadding = constraints.maxWidth < 400
                ? AppTheme.spacingLG
                : constraints.maxWidth < 640
                ? AppTheme.spacingLG * 1.5
                : AppTheme.spacingLG * 2;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppTheme.spacingXXL * 2, // py-8
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXXL * 2,
                      ), // mb-8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingLG,
                            ), // mb-4
                            child: Text(
                              widget.isCategorySearch &&
                                      widget.searchCategory != null
                                  ? '${labels.category}: ${widget.getLocalizedName?.call(widget.searchCategory) ?? widget.searchCategory!.name}'
                                  : labels.searchPage,
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
                          ),

                          // Search Bar
                          PopScope(
                            canPop: false,
                            onPopInvokedWithResult: (didPop, result) {
                              if (didPop) return;
                              _handleSearch();
                            },
                            child: Form(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Stack vertically on very small screens (< 400px)
                                  if (constraints.maxWidth < 400) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TextField(
                                          controller: _searchController,
                                          onSubmitted: (_) => _handleSearch(),
                                          decoration: InputDecoration(
                                            hintText: labels.searchProducts,
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              size: 24,
                                            ), // w-6 h-6
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(
                                                    0xFF1F2937,
                                                  ) // gray-800
                                                : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF78350F,
                                                      ) // amber-800
                                                    : const Color(
                                                        0xFFFDE68A,
                                                      ), // amber-200
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF78350F,
                                                      ) // amber-800
                                                    : const Color(
                                                        0xFFFDE68A,
                                                      ), // amber-200
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: const Color(
                                                  0xFFF59E0B,
                                                ), // amber-500
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppTheme.spacingLG *
                                                      1.5, // px-6
                                                  vertical: AppTheme
                                                      .spacingLG, // py-4
                                                ),
                                            hintStyle:
                                                AppTextStyles.bodyMediumStyle(
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ), // gray-400
                                                ),
                                          ),
                                          style: AppTextStyles.bodyLargeStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(
                                                    0xFF111827,
                                                  ), // gray-900
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppTheme.spacingMD,
                                        ), // gap-3
                                        WoodButton(
                                          onPressed: _handleSearch,
                                          size: WoodButtonSize.lg,
                                          child: Text(
                                            labels.search,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  // Horizontal layout on larger screens
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onSubmitted: (_) => _handleSearch(),
                                          decoration: InputDecoration(
                                            hintText: labels.searchProducts,
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              size: 24,
                                            ), // w-6 h-6
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(
                                                    0xFF1F2937,
                                                  ) // gray-800
                                                : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF78350F,
                                                      ) // amber-800
                                                    : const Color(
                                                        0xFFFDE68A,
                                                      ), // amber-200
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF78350F,
                                                      ) // amber-800
                                                    : const Color(
                                                        0xFFFDE68A,
                                                      ), // amber-200
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: AppTheme
                                                  .borderRadiusLargeValue,
                                              borderSide: BorderSide(
                                                color: const Color(
                                                  0xFFF59E0B,
                                                ), // amber-500
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppTheme.spacingLG *
                                                      1.5, // px-6
                                                  vertical: AppTheme
                                                      .spacingLG, // py-4
                                                ),
                                            hintStyle:
                                                AppTextStyles.bodyMediumStyle(
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ), // gray-400
                                                ),
                                          ),
                                          style: AppTextStyles.bodyLargeStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(
                                                    0xFF111827,
                                                  ), // gray-900
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppTheme.spacingMD,
                                      ), // gap-3
                                      Flexible(
                                        child: WoodButton(
                                          onPressed: _handleSearch,
                                          size: WoodButtonSize.lg,
                                          child: Text(
                                            labels.search,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filters Bar
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXXL * 2,
                      ), // mb-8
                      child: Column(
                        children: [
                          // Mobile Filter Toggle
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 768) {
                                // Desktop: Hide toggle button
                                return const SizedBox.shrink();
                              } else {
                                // Mobile: Show toggle button
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacingLG,
                                  ), // mb-4
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showFilters = !_showFilters;
                                        });
                                      },
                                      borderRadius:
                                          AppTheme.borderRadiusLargeValue,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              AppTheme.spacingLG, // px-4
                                          vertical: AppTheme.spacingSM, // py-2
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF1F2937,
                                                ) // gray-800
                                              : Colors.white,
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(
                                                    0xFF78350F,
                                                  ) // amber-800
                                                : const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.filter_list,
                                              size: 20,
                                            ), // w-5 h-5
                                            const SizedBox(
                                              width: AppTheme.spacingSM,
                                            ),
                                            Text(
                                              labels.filter,
                                              style:
                                                  AppTextStyles.bodyMediumStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF111827,
                                                          ), // gray-900
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          // Filters (Desktop always visible, Mobile toggleable)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final shouldShow =
                                  constraints.maxWidth >= 768 || _showFilters;
                              if (!shouldShow) return const SizedBox.shrink();

                              return Wrap(
                                spacing: AppTheme.spacingLG, // gap-4
                                runSpacing: AppTheme.spacingLG,
                                children: [
                                  // Category Filter
                                  SizedBox(
                                    width: constraints.maxWidth >= 768
                                        ? null
                                        : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(
                                                0xFF1F2937,
                                              ) // gray-800
                                            : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(
                                                    0xFF78350F,
                                                  ) // amber-800
                                                : const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                            width: 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(
                                                    0xFF78350F,
                                                  ) // amber-800
                                                : const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: const Color(
                                              0xFFF59E0B,
                                            ), // amber-500
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal:
                                                  AppTheme.spacingLG, // px-4
                                              vertical:
                                                  AppTheme.spacingSM, // py-2
                                            ),
                                      ),
                                      style: AppTextStyles.bodyMediumStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF111827,
                                              ), // gray-900
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(labels.all),
                                        ),
                                        ...(widget.categories ?? []).map((
                                          category,
                                        ) {
                                          return DropdownMenuItem(
                                            value: category.id,
                                            child: Text(
                                              widget.getLocalizedName?.call(
                                                    category,
                                                  ) ??
                                                  category.name,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  ),

                                  // Sort By
                                  SizedBox(
                                    width: constraints.maxWidth >= 768
                                        ? null
                                        : double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _sortBy,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(
                                                0xFF1F2937,
                                              ) // gray-800
                                            : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(
                                                    0xFF78350F,
                                                  ) // amber-800
                                                : const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                            width: 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(
                                                    0xFF78350F,
                                                  ) // amber-800
                                                : const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          borderSide: BorderSide(
                                            color: const Color(
                                              0xFFF59E0B,
                                            ), // amber-500
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal:
                                                  AppTheme.spacingLG, // px-4
                                              vertical:
                                                  AppTheme.spacingSM, // py-2
                                            ),
                                      ),
                                      style: AppTextStyles.bodyMediumStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF111827,
                                              ), // gray-900
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'relevance',
                                          child: Text(labels.mostRelevant),
                                        ),
                                        DropdownMenuItem(
                                          value: 'price-low',
                                          child: Text(labels.priceLowToHigh),
                                        ),
                                        DropdownMenuItem(
                                          value: 'price-high',
                                          child: Text(labels.priceHighToLow),
                                        ),
                                        DropdownMenuItem(
                                          value: 'rating',
                                          child: Text(labels.highestRated),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _sortBy = value;
                                          });
                                          _applyFilters();
                                        }
                                      },
                                    ),
                                  ),

                                  // Price Range
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingLG, // px-4
                                      vertical: AppTheme.spacingSM, // py-2
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1F2937) // gray-800
                                          : Colors.white,
                                      borderRadius:
                                          AppTheme.borderRadiusLargeValue,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(
                                                0xFF78350F,
                                              ) // amber-800
                                            : const Color(
                                                0xFFFDE68A,
                                              ), // amber-200
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${labels.price}:',
                                          style: AppTextStyles.bodySmallStyle(
                                            color: isDark
                                                ? const Color(
                                                    0xFF9CA3AF,
                                                  ) // gray-400
                                                : const Color(
                                                    0xFF4B5563,
                                                  ), // gray-600
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppTheme.spacingSM,
                                        ),
                                        Flexible(
                                          child: TextField(
                                            controller: _minPriceController,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => _applyFilters(),
                                            decoration: InputDecoration(
                                              hintText: labels.min,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppTheme
                                                        .spacingSM, // px-2
                                                    vertical: 4, // py-1
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF92400E,
                                                        ) // amber-700
                                                      : const Color(
                                                          0xFFFDE68A,
                                                        ), // amber-200
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF92400E,
                                                        ) // amber-700
                                                      : const Color(
                                                          0xFFFDE68A,
                                                        ), // amber-200
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? const Color(
                                                      0xFF374151,
                                                    ) // gray-700
                                                  : Colors.white,
                                            ),
                                            style: AppTextStyles.bodySmallStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF111827,
                                                    ), // gray-900
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppTheme.spacingSM,
                                        ),
                                        Text(
                                          '-',
                                          style: AppTextStyles.bodyMediumStyle(
                                            color: isDark
                                                ? const Color(
                                                    0xFF9CA3AF,
                                                  ) // gray-400
                                                : const Color(
                                                    0xFF4B5563,
                                                  ), // gray-600
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppTheme.spacingSM,
                                        ),
                                        Flexible(
                                          child: TextField(
                                            controller: _maxPriceController,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => _applyFilters(),
                                            decoration: InputDecoration(
                                              hintText: labels.max,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppTheme
                                                        .spacingSM, // px-2
                                                    vertical: 4, // py-1
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF92400E,
                                                        ) // amber-700
                                                      : const Color(
                                                          0xFFFDE68A,
                                                        ), // amber-200
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF92400E,
                                                        ) // amber-700
                                                      : const Color(
                                                          0xFFFDE68A,
                                                        ), // amber-200
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? const Color(
                                                      0xFF374151,
                                                    ) // gray-700
                                                  : Colors.white,
                                            ),
                                            style: AppTextStyles.bodySmallStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF111827,
                                                    ), // gray-900
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Reset Filters Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _resetFilters,
                                      borderRadius:
                                          AppTheme.borderRadiusLargeValue,
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppTheme.spacingSM * 2.5,
                                        ), // px-4 py-2
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(
                                                    0xFF991B1B,
                                                  ) // red-800
                                                : const Color(
                                                    0xFFFECACA,
                                                  ), // red-200
                                            width: 2,
                                          ),
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 20, // w-5 h-5
                                          color: isDark
                                              ? const Color(
                                                  0xFFF87171,
                                                ) // red-400
                                              : const Color(
                                                  0xFFDC2626,
                                                ), // red-600
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

                    // Results Count
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingLG * 1.5,
                      ), // mb-6
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ),
                          children: [
                            TextSpan(text: '${labels.found} '),
                            TextSpan(
                              text: '${_filteredProducts.length}',
                              style: AppTextStyles.bodyMediumStyle(
                                color: isDark
                                    ? const Color(0xFFF59E0B) // amber-500
                                    : const Color(0xFF92400E), // amber-800
                                // font-weight: regular (default)
                              ),
                            ),
                            TextSpan(text: ' ${labels.products}'),
                            if (_searchQuery.isNotEmpty) ...[
                              TextSpan(text: ' ${labels.for_} '),
                              TextSpan(
                                text: '"$_searchQuery"',
                                style: AppTextStyles.bodyMediumStyle(
                                  color: isDark
                                      ? const Color(0xFF9CA3AF) // gray-400
                                      : const Color(0xFF4B5563), // gray-600
                                  fontWeight: AppTextStyles.medium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Content
                    if (widget.loading)
                      _buildLoadingState(isDark, labels)
                    else if (_filteredProducts.isEmpty)
                      _buildEmptyState(isDark, labels)
                    else
                      _buildProductsGrid(isDark, labels),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, SearchScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 3), // py-12
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

  Widget _buildEmptyState(bool isDark, SearchScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 4), // py-16
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64, // w-16 h-16
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              labels.noProductsFound,
              style:
                  AppTextStyles.titleMediumStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    // font-weight: regular (default)
                  ).copyWith(
                    fontSize: 24, // text-2xl
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            Text(
              labels.tryAdjustingSearch,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
            WoodButton(
              onPressed: _resetFilters,
              child: Text(
                labels.clearAllFilters,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(bool isDark, SearchScreenLabels labels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
            mainAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
            childAspectRatio: 0.75,
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final searchProduct = _filteredProducts[index];

            // Watch wishlist items to react to heart clicks
            final wishlistItems = ref.watch(wishlistStoreProvider).items;
            final isInWishlist = wishlistItems.any(
              (item) => item.productId == searchProduct.id,
            );

            // Map SearchProductData to ProductData for ProductCard
            final product = ProductData(
              id: searchProduct.id,
              name: searchProduct.name,
              description: searchProduct.description,
              price: searchProduct.price,
              imageUrl: searchProduct.imageUrl,
              stock: searchProduct.stock,
              isPackage: searchProduct.isPackage,
              adminRating: searchProduct.adminRating != null
                  ? AdminRating(rating: searchProduct.adminRating)
                  : null,
            );

            return ProductCard(
              product: product,
              size: ProductCardSize.small,
              isInWishlist: isInWishlist,
              getProductCategoryName: (p) => p.isPackage
                  ? labels.category
                  : _getCategoryName(searchProduct.categoryId),
              onViewDetails: (id) {
                if (searchProduct.isPackage) {
                  context.pushNamed(
                    AppRouteNames.package,
                    pathParameters: {'id': id},
                  );
                } else {
                  widget.onProductTap?.call(id);
                }
              },
              onAddToCart: (id) async {
                final l10n = AppLocalizations.of(context);
                final success = searchProduct.isPackage
                    ? await ref.read(cartStoreProvider.notifier).addPackage(id)
                    : await ref.read(cartStoreProvider.notifier).addProduct(id);

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
                final success = searchProduct.isPackage
                    ? await ref
                          .read(wishlistStoreProvider.notifier)
                          .togglePackage(id)
                    : await ref
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

/// SearchProductData - Product data model
class SearchProductData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? categoryId;
  final List<SearchCategoryData>? categories;
  final int? stock;
  final double? averageRating;
  final double? adminRating;
  final int? reviewCount;
  final bool isPackage;

  const SearchProductData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imageUrls,
    this.categoryId,
    this.categories,
    this.stock,
    this.averageRating,
    this.adminRating,
    this.reviewCount,
    this.isPackage = false,
  });
}

/// SearchCategoryData - Category data model
class SearchCategoryData {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;

  const SearchCategoryData({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
  });
}

/// SearchUserData - User data model
class SearchUserData {
  final String id;
  final String name;
  final String email;

  const SearchUserData({
    required this.id,
    required this.name,
    required this.email,
  });
}

/// SearchScreenLabels - Localization labels
class SearchScreenLabels {
  final String category;
  final String searchPage;
  final String searchProducts;
  final String search;
  final String filter;
  final String all;
  final String mostRelevant;
  final String priceLowToHigh;
  final String priceHighToLow;
  final String highestRated;
  final String price;
  final String min;
  final String max;
  final String found;
  final String products;
  final String for_;
  final String loading;
  final String noProductsFound;
  final String tryAdjustingSearch;
  final String clearAllFilters;
  final String onlyLeft;
  final String noDescriptionAvailable;
  final String addToCart;

  const SearchScreenLabels({
    required this.category,
    required this.searchPage,
    required this.searchProducts,
    required this.search,
    required this.filter,
    required this.all,
    required this.mostRelevant,
    required this.priceLowToHigh,
    required this.priceHighToLow,
    required this.highestRated,
    required this.price,
    required this.min,
    required this.max,
    required this.found,
    required this.products,
    required this.for_,
    required this.loading,
    required this.noProductsFound,
    required this.tryAdjustingSearch,
    required this.clearAllFilters,
    required this.onlyLeft,
    required this.noDescriptionAvailable,
    required this.addToCart,
  });

  factory SearchScreenLabels.defaultLabels() {
    return SearchScreenLabels.forLanguage('en');
  }

  factory SearchScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return SearchScreenLabels(
      category: isArabic ? 'الفئة' : 'Category',
      searchPage: isArabic ? 'صفحة البحث' : 'Search Page',
      searchProducts: isArabic ? 'ابحث عن المنتجات...' : 'Search products...',
      search: isArabic ? 'بحث' : 'Search',
      filter: isArabic ? 'تصفية' : 'Filter',
      all: isArabic ? 'الكل' : 'All',
      mostRelevant: isArabic ? 'الأكثر صلة' : 'Most Relevant',
      priceLowToHigh: isArabic
          ? 'السعر: من الأقل إلى الأعلى'
          : 'Price: Low to High',
      priceHighToLow: isArabic
          ? 'السعر: من الأعلى إلى الأقل'
          : 'Price: High to Low',
      highestRated: isArabic ? 'الأعلى تقييماً' : 'Highest Rated',
      price: isArabic ? 'السعر' : 'Price',
      min: isArabic ? 'الحد الأدنى' : 'Min',
      max: isArabic ? 'الحد الأقصى' : 'Max',
      found: isArabic ? 'تم العثور على' : 'Found',
      products: isArabic ? 'منتجات' : 'products',
      for_: isArabic ? 'لـ' : 'for',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      noProductsFound: isArabic
          ? 'لم يتم العثور على منتجات'
          : 'No products found',
      tryAdjustingSearch: isArabic
          ? 'حاول تعديل البحث أو الفلاتر'
          : 'Try adjusting your search or filters',
      clearAllFilters: isArabic ? 'مسح جميع الفلاتر' : 'Clear All Filters',
      onlyLeft: isArabic ? 'بقي فقط' : 'Only',
      noDescriptionAvailable: isArabic
          ? 'لا يوجد وصف متاح'
          : 'No description available',
      addToCart: isArabic ? 'أضف إلى السلة' : 'Add to Cart',
    );
  }
}
