import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/services/api_services/catalog_api_service.dart';
import '../../core/stores/language_store.dart';
import '../../core/stores/cart_store.dart';
import '../../core/stores/wishlist_store.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/notification_toast.dart';
import '../../core/widgets/package_card.dart' show PackageCard, PackageData;

/// PackagesScreen - All packages listing screen
///
/// Equivalent to Vue's Packages.vue page.
/// Displays a grid of packages with search and filter functionality.
///
/// Features:
/// - Page header
/// - Search bar
/// - Sort dropdown
/// - Packages grid
/// - Empty state
/// - Loading state
/// - Dark mode support
/// - Responsive design
class PackagesScreen extends ConsumerStatefulWidget {
  /// Mock packages data
  final List<PackagesPackageData>? packages;

  /// Mock user data (for showing/hiding buttons)
  final PackagesUserData? user;

  /// Loading state
  final bool loading;

  /// Adding to cart states (packageId -> bool)
  final Map<String, bool>? addingToCart;

  /// Wishlist states (packageId -> bool)
  final Map<String, bool>? isInWishlist;

  /// Callback when package is tapped
  final void Function(String packageId)? onPackageTap;

  /// Callback when add to cart is tapped
  final void Function(String packageId)? onAddToCart;

  /// Callback when wishlist toggle is tapped
  final void Function(String packageId)? onToggleWishlist;

  /// Localized name getter function
  final String Function(dynamic)? getLocalizedName;

  /// Localized description getter function
  final String Function(dynamic)? getLocalizedDescription;

  /// Labels for localization
  final PackagesScreenLabels? labels;

  const PackagesScreen({
    super.key,
    this.packages,
    this.user,
    this.loading = false,
    this.addingToCart,
    this.isInWishlist,
    this.onPackageTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.getLocalizedName,
    this.getLocalizedDescription,
    this.labels,
  });

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'latest';
  List<PackagesPackageData> _packages = [];
  bool _isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    if (widget.packages != null) {
      _packages = widget.packages!;
    } else {
      _loadFromApi(); // falls back to mock data if API fails
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFromApi() async {
    setState(() => _isLoadingApi = true);
    try {
      final api = CatalogApiService();
      final packagesRaw = await api.fetchPackages();

      final packages = <PackagesPackageData>[];
      for (final item in packagesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final count = map['products_count'] is int
            ? map['products_count'] as int
            : int.tryParse(map['products_count']?.toString() ?? '');

        packages.add(
          PackagesPackageData(
            id: id,
            name: (map['name'] ?? '').toString(),
            description: map['description']?.toString(),
            imageUrl: map['image_url']?.toString(),
            productsCount: count,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _packages = packages);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Packages API load failed: $e');
      }
      // Don't fall back to mock data - show error instead
      if (mounted) {
        setState(() => _packages = []);
      }
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  List<PackagesPackageData> get _filteredPackages {
    List<PackagesPackageData> filtered = List.from(_packages);

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((pkg) {
        final name = pkg.name.toLowerCase();
        final description = (pkg.description ?? '').toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name_asc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'products_asc':
        filtered.sort(
          (a, b) => (a.productsCount ?? 0).compareTo(b.productsCount ?? 0),
        );
        break;
      case 'products_desc':
        filtered.sort(
          (a, b) => (b.productsCount ?? 0).compareTo(a.productsCount ?? 0),
        );
        break;
      // 'latest' is default (no sorting needed)
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _sortBy = 'latest';
      _searchController.clear();
    });
  }

  // Removed unused _getLocalizedName and _getLocalizedDescription

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? PackagesScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      child: Container(
        color: isDark
            ? const Color(0xFF111827) // gray-900
            : const Color(0xFFF9FAFB), // gray-50
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppTheme.spacingLG * 1.5,
                  ), // mb-6
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels.allPackages,
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
                        labels.browsePackages,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters Section
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppTheme.spacingLG * 1.5,
                  ), // mb-6
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 448,
                        ), // max-w-md
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: labels.searchPackages,
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                            ), // h-5 w-5
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1F2937) // gray-800
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF374151) // gray-700
                                    : const Color(0xFFD1D5DB), // gray-300
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF374151) // gray-700
                                    : const Color(0xFFD1D5DB), // gray-300
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF6B7280) // gray-500
                                    : const Color(0xFF6B7280), // gray-500
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingLG,
                              vertical: AppTheme.spacingSM, // py-2
                            ),
                            hintStyle: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? const Color(0xFF6B7280) // gray-500
                                  : const Color(0xFF9CA3AF), // gray-400
                            ),
                          ),
                          style: AppTextStyles.bodyMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-800
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLG), // space-y-4
                      // Filter Controls
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 640) {
                            // Desktop: Side by side
                            return Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildSortDropdown(isDark, labels),
                                ),
                                const SizedBox(
                                  width: AppTheme.spacingLG,
                                ), // gap-4
                                _buildClearFiltersButton(isDark, labels),
                              ],
                            );
                          } else {
                            // Mobile: Stacked
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSortDropdown(isDark, labels),
                                const SizedBox(
                                  height: AppTheme.spacingLG,
                                ), // gap-4
                                _buildClearFiltersButton(isDark, labels),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                (widget.loading || _isLoadingApi)
                    ? _buildLoadingState(isDark, labels)
                    : _filteredPackages.isEmpty
                    ? _buildEmptyState(isDark, labels)
                    : _buildPackagesGrid(isDark, labels),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(bool isDark, PackagesScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.sortBy,
          style: AppTextStyles.bodySmallStyle(
            color: isDark
                ? const Color(0xFFD1D5DB) // gray-300
                : const Color(0xFF374151), // gray-700
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        DropdownButtonFormField<String>(
          initialValue: _sortBy,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1F2937) // gray-800
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF374151) // gray-700
                    : const Color(0xFFD1D5DB), // gray-300
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF374151) // gray-700
                    : const Color(0xFFD1D5DB), // gray-300
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF6B7280) // gray-500
                    : const Color(0xFF6B7280), // gray-500
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4
              vertical: AppTheme.spacingSM, // py-2
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-800
          ),
          items: [
            DropdownMenuItem(value: 'latest', child: Text(labels.latest)),
            DropdownMenuItem(value: 'name_asc', child: Text(labels.nameAToZ)),
            DropdownMenuItem(value: 'name_desc', child: Text(labels.nameZToA)),
            DropdownMenuItem(
              value: 'products_asc',
              child: Text(labels.productsLowToHigh),
            ),
            DropdownMenuItem(
              value: 'products_desc',
              child: Text(labels.productsHighToLow),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortBy = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildClearFiltersButton(bool isDark, PackagesScreenLabels labels) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _clearFilters,
        borderRadius: AppTheme.borderRadiusLargeValue,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG, // px-4
            vertical: AppTheme.spacingSM, // py-2
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151) // gray-700
                : const Color(0xFFE5E7EB), // gray-200
            borderRadius: AppTheme.borderRadiusLargeValue,
          ),
          child: Text(
            labels.clearFilters,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xFF374151), // gray-700
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, PackagesScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 3), // py-12
        child: Text(
          labels.loadingPackages,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, PackagesScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 3), // py-12
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64, // w-16 h-16
              color: isDark
                  ? const Color(0xFF4B5563) // gray-600
                  : const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              labels.noPackagesFound,
              style:
                  AppTextStyles.titleMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                    fontWeight: AppTextStyles.medium,
                  ).copyWith(
                    fontSize: 18, // text-lg
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            Text(
              _searchQuery.isNotEmpty
                  ? labels.tryDifferentSearchTerm
                  : labels.checkBackLater,
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

  Widget _buildPackagesGrid(bool isDark, PackagesScreenLabels labels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 4
            : constraints.maxWidth >= 768
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
            mainAxisSpacing: AppTheme.spacingLG * 1.5, // gap-6
            childAspectRatio: 0.75,
          ),
          itemCount: _filteredPackages.length,
          itemBuilder: (context, index) {
            final pkg = _filteredPackages[index];
            final packageData = PackageData(
              id: pkg.id,
              name: pkg.name,
              description: pkg.description,
              imageUrl: pkg.imageUrl,
              productsCount: pkg.productsCount ?? 0,
              price: 0, // Packages screen model lacks price, fallback to 0
            );

            // Watch stores for state
            final wishlistItems = ref.watch(wishlistStoreProvider).items;
            final isInWishlist = wishlistItems.any(
              (item) => item.packageId == pkg.id,
            );

            return PackageCard(
              package: packageData,
              isInWishlist: isInWishlist,
              onViewDetails: (id) {
                if (widget.onPackageTap != null) {
                  widget.onPackageTap!(id);
                } else {
                  context.push('/package/$id');
                }
              },
              onAddToCart: (id) async {
                final l10n = AppLocalizations.of(context);
                final success = await ref
                    .read(cartStoreProvider.notifier)
                    .addPackage(id);

                if (success) {
                  NotificationToastService.instance.showSuccess(
                    l10n.translate('package_added_to_cart'),
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
                    .togglePackage(id);
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

/// PackagesUserData - User data model
class PackagesUserData {
  final String id;
  final String name;
  final String email;

  const PackagesUserData({
    required this.id,
    required this.name,
    required this.email,
  });
}

/// PackagesPackageData - Package data model
class PackagesPackageData {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? productsCount;

  const PackagesPackageData({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.productsCount,
  });
}

/// PackagesScreenLabels - Localization labels
class PackagesScreenLabels {
  final String allPackages;
  final String browsePackages;
  final String searchPackages;
  final String sortBy;
  final String latest;
  final String nameAToZ;
  final String nameZToA;
  final String productsLowToHigh;
  final String productsHighToLow;
  final String clearFilters;
  final String loadingPackages;
  final String noPackagesFound;
  final String tryDifferentSearchTerm;
  final String checkBackLater;
  final String items;
  final String exploreCuratedCollection;
  final String adding;
  final String addToCart;
  final String view;

  const PackagesScreenLabels({
    required this.allPackages,
    required this.browsePackages,
    required this.searchPackages,
    required this.sortBy,
    required this.latest,
    required this.nameAToZ,
    required this.nameZToA,
    required this.productsLowToHigh,
    required this.productsHighToLow,
    required this.clearFilters,
    required this.loadingPackages,
    required this.noPackagesFound,
    required this.tryDifferentSearchTerm,
    required this.checkBackLater,
    required this.items,
    required this.exploreCuratedCollection,
    required this.adding,
    required this.addToCart,
    required this.view,
  });

  factory PackagesScreenLabels.defaultLabels() {
    return PackagesScreenLabels.forLanguage('en');
  }

  factory PackagesScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return PackagesScreenLabels(
      allPackages: isArabic ? 'جميع الباقات' : 'All Packages',
      browsePackages: isArabic
          ? 'تصفح عروض الباقات المختارة'
          : 'Browse our curated package deals',
      searchPackages: isArabic ? 'ابحث عن الباقات...' : 'Search packages...',
      sortBy: isArabic ? 'ترتيب حسب' : 'Sort By',
      latest: isArabic ? 'الأحدث' : 'Latest',
      nameAToZ: isArabic ? 'الاسم (أ-ي)' : 'Name (A-Z)',
      nameZToA: isArabic ? 'الاسم (ي-أ)' : 'Name (Z-A)',
      productsLowToHigh: isArabic
          ? 'المنتجات (من الأقل إلى الأعلى)'
          : 'Products (Low to High)',
      productsHighToLow: isArabic
          ? 'المنتجات (من الأعلى إلى الأقل)'
          : 'Products (High to Low)',
      clearFilters: isArabic ? 'مسح الفلاتر' : 'Clear Filters',
      loadingPackages: isArabic
          ? 'جاري تحميل الباقات...'
          : 'Loading packages...',
      noPackagesFound: isArabic
          ? 'لم يتم العثور على باقات'
          : 'No packages found',
      tryDifferentSearchTerm: isArabic
          ? 'جرب مصطلح بحث مختلف'
          : 'Try a different search term',
      checkBackLater: isArabic
          ? 'تحقق لاحقاً للباقات الجديدة'
          : 'Check back later for new packages',
      items: isArabic ? 'عناصر' : 'items',
      exploreCuratedCollection: isArabic
          ? 'استكشف مجموعتنا المختارة'
          : 'Explore our curated collection',
      adding: isArabic ? 'جاري الإضافة...' : 'Adding...',
      addToCart: isArabic ? 'أضف إلى السلة' : 'Add to Cart',
      view: isArabic ? 'عرض' : 'View',
    );
  }
}
