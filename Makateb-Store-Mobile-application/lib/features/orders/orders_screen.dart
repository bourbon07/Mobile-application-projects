import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_services/order_api_service.dart';

/// OrdersScreen - Orders history screen
///
/// Equivalent to Vue's Orders.vue page.
/// Displays user's order history with order details and reorder functionality.
///
/// Features:
/// - Guest check (requires login)
/// - Empty state
/// - Loading state
/// - Orders list with status badges
/// - Order items display
/// - Reorder button
/// - Dark mode support
/// - Responsive design
class OrdersScreen extends ConsumerStatefulWidget {
  /// Mock user data (null for guest)
  final OrdersUserData? user;

  /// Mock orders data
  final List<OrderData>? orders;

  /// Loading state
  final bool loading;

  /// Callback when sign in is tapped
  final VoidCallback? onSignIn;

  /// Callback when continue shopping is tapped
  final VoidCallback? onContinueShopping;

  /// Callback when start shopping is tapped
  final VoidCallback? onStartShopping;

  /// Callback when back to home is tapped
  final VoidCallback? onBackToHome;

  /// Callback when reorder is tapped
  final void Function(OrderData order)? onReorder;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Date formatter function
  final String Function(DateTime date)? formatDate;

  /// Payment method formatter function
  final String Function(String? method)? formatPaymentMethod;

  /// Labels for localization
  final OrdersScreenLabels? labels;

  /// Callback when an order is deleted
  final void Function(String orderId)? onDeleteOrder;

  const OrdersScreen({
    super.key,
    this.user,
    this.orders,
    this.loading = false,
    this.onSignIn,
    this.onContinueShopping,
    this.onStartShopping,
    this.onBackToHome,
    this.onReorder,
    this.formatPrice,
    this.formatDate,
    this.formatPaymentMethod,
    this.labels,
    this.onDeleteOrder,
  });

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<OrderData> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // If not loading already via parent or something (widget.loading is passed but we manage internal state too?)
    // The widget accepts 'orders', if null we load.
    if (widget.orders != null) {
      _orders = widget.orders!;
      if (kDebugMode) {
        debugPrint(
          '[OrdersScreen] Using provided orders: ${_orders.length} items',
        );
      }
      return;
    }

    // We can't set widget.loading, so we look at if we should show local loading state.
    // Ideally use a provider, but for now local fetch.
    try {
      if (kDebugMode) {
        debugPrint('[OrdersScreen] Starting to load orders from API...');
      }

      final api = LaravelOrderApiService();
      final rawOrders = await api.fetchOrders();

      if (kDebugMode) {
        debugPrint(
          '[OrdersScreen] Received ${rawOrders.length} raw orders from API',
        );
        if (rawOrders.isNotEmpty) {
          debugPrint(
            '[OrdersScreen] First order structure: ${rawOrders.first}',
          );
        }
      }

      if (mounted) {
        setState(() {
          _orders = rawOrders.map((o) {
            try {
              final map = o as Map<String, dynamic>;

              if (kDebugMode) {
                debugPrint('[OrdersScreen] Parsing order ID: ${map['id']}');
              }

              return OrderData(
                id: map['id']?.toString() ?? '',
                createdAt:
                    DateTime.tryParse(map['created_at'] ?? '') ??
                    DateTime.now(),
                status: map['status'] ?? 'pending',
                totalPrice:
                    double.tryParse(map['total_price']?.toString() ?? '0') ??
                    0.0,
                paymentMethod: map['payment_method'],
                items: (map['items'] as List? ?? []).map((i) {
                  final iMap = i as Map<String, dynamic>;
                  return OrderItemData(
                    id: iMap['id']?.toString() ?? '',
                    productId: iMap['product_id']?.toString(),
                    packageId: iMap['package_id']?.toString(), // Add packageId
                    qty: int.tryParse(iMap['qty']?.toString() ?? '0') ?? 0,
                    priceAtOrder:
                        double.tryParse(
                          iMap['price_at_order']?.toString() ?? '0',
                        ) ??
                        0.0,
                    product: iMap['product'] != null
                        ? OrderProductData(
                            id: iMap['product']['id']?.toString() ?? '',
                            name: iMap['product']['name'] ?? '',
                            imageUrl: iMap['product']['image_url'],
                          )
                        : null,
                    package: iMap['package'] != null
                        ? OrderPackageData(
                            id: iMap['package']['id']?.toString() ?? '',
                            name: iMap['package']['name'] ?? '',
                            imageUrl: iMap['package']['image_url'],
                          )
                        : null,
                  );
                }).toList(),
              );
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[OrdersScreen] Error parsing order: $e');
              }
              rethrow;
            }
          }).toList();

          if (kDebugMode) {
            debugPrint(
              '[OrdersScreen] Successfully parsed ${_orders.length} orders',
            );
          }
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[OrdersScreen] Error loading orders: $e');
        debugPrint('[OrdersScreen] Stack trace: $stackTrace');
      }

      if (mounted) {
        setState(() {
          _orders = [];
        });
      }
    }
  }

  Future<void> _handleDeleteOrder(String orderId) async {
    try {
      final api = LaravelOrderApiService();
      await api.deleteOrder(orderId);

      // Refresh data
      await _loadData();

      if (mounted) {
        final currentLanguage = ref.read(currentLanguageProvider);
        final isArabic = currentLanguage == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تمت إزالة الطلب بنجاح' : 'Order removed successfully',
            ),
          ),
        );
      }

      widget.onDeleteOrder?.call(orderId);
    } catch (e) {
      if (mounted) {
        final currentLanguage = ref.read(currentLanguageProvider);
        final isArabic = currentLanguage == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'فشل إزالة الطلب: $e' : 'Failed to remove order: $e',
            ),
          ),
        );
      }
    }
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? '\$${price.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return widget.formatDate?.call(date) ??
        '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatPaymentMethod(String? method) {
    return widget.formatPaymentMethod?.call(method) ??
        (method == null
            ? 'N/A'
            : method
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) {
                    if (word.isEmpty) return word;
                    return word[0].toUpperCase() + word.substring(1);
                  })
                  .join(' '));
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.inventory_2;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor(String status, bool isDark) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return isDark
            ? const Color(0xFFFCD34D) // yellow-400
            : const Color(0xFF92400E); // yellow-800
      case 'processing':
        return isDark
            ? const Color(0xFF60A5FA) // blue-400
            : const Color(0xFF1E40AF); // blue-800
      case 'shipped':
        return isDark
            ? const Color(0xFFA78BFA) // purple-400
            : const Color(0xFF6B21A8); // purple-800
      case 'delivered':
        return isDark
            ? const Color(0xFF4ADE80) // green-400
            : const Color(0xFF166534); // green-800
      case 'rejected':
        return isDark
            ? const Color(0xFFF87171) // red-400
            : const Color(0xFF991B1B); // red-800
      default:
        return isDark
            ? const Color(0xFFFCD34D) // yellow-400
            : const Color(0xFF92400E); // yellow-800
    }
  }

  Color _getStatusBackgroundColor(String status, bool isDark) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return isDark
            ? const Color(0xFFFCD34D).withValues(alpha: 0.3) // yellow-900/30
            : const Color(0xFFFEF3C7); // yellow-100
      case 'processing':
        return isDark
            ? const Color(0xFF3B82F6).withValues(alpha: 0.3) // blue-900/30
            : const Color(0xFFDBEAFE); // blue-100
      case 'shipped':
        return isDark
            ? const Color(0xFF7C3AED).withValues(alpha: 0.3) // purple-900/30
            : const Color(0xFFE9D5FF); // purple-100
      case 'delivered':
        return isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.3) // green-900/30
            : const Color(0xFFD1FAE5); // green-100
      case 'rejected':
        return isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) // red-900/30
            : const Color(0xFFFEE2E2); // red-100
      default:
        return isDark
            ? const Color(0xFFFCD34D).withValues(alpha: 0.3) // yellow-900/30
            : const Color(0xFFFEF3C7); // yellow-100
    }
  }

  List<OrderItemData> _getOrderItems(OrderData order) {
    return order.items;
  }

  int _getOrderItemsCount(OrderData order) {
    return order.items.length;
  }

  String? _getItemImage(OrderItemData item) {
    return item.product?.imageUrl ?? item.package?.imageUrl;
  }

  String _getItemName(OrderItemData item) {
    return item.product?.name ?? item.package?.name ?? 'Item';
  }

  int _getItemQuantity(OrderItemData item) {
    return item.qty;
  }

  double _getItemTotalPrice(OrderItemData item) {
    return item.priceAtOrder * item.qty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? OrdersScreenLabels.forLanguage(currentLanguage);

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
                    const Color(0xFFFFFBEB), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            child: widget.user == null
                ? _buildGuestState(isDark, labels)
                : widget.loading
                ? _buildLoadingState(isDark, labels)
                : _orders.isEmpty
                ? _buildEmptyState(isDark, labels)
                : _buildOrdersList(isDark, labels),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(bool isDark, OrdersScreenLabels labels) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG,
          ), // px-4
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels.accountRequired,
                style:
                    AppTextStyles.titleLargeStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      // font-weight: regular (default)
                    ).copyWith(
                      fontSize: 30, // text-3xl
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLG), // mb-4
              Text(
                labels.accountRequiredForOrdersSupport,
                style:
                    AppTextStyles.bodyMediumStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF) // gray-400
                          : const Color(0xFF4B5563), // gray-600
                    ).copyWith(
                      fontSize: 18, // text-lg
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WoodButton(
                    onPressed: widget.onSignIn ?? () => context.go('/login'),
                    size: WoodButtonSize.md,
                    child: Text(labels.signIn),
                  ),
                  const SizedBox(width: AppTheme.spacingLG), // gap-4
                  WoodButton(
                    onPressed:
                        widget.onContinueShopping ??
                        () => context.go('/dashboard'),
                    variant: WoodButtonVariant.outline,
                    size: WoodButtonSize.md,
                    child: Text(labels.continueShopping),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, OrdersScreenLabels labels) {
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

  Widget _buildEmptyState(bool isDark, OrdersScreenLabels labels) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2,
            size: 96, // w-24 h-24
            color: const Color(0xFF9CA3AF), // gray-400
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
          Text(
            labels.noOrders,
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
          Text(
            labels.startShoppingAndOrders,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF4B5563), // gray-600
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
          WoodButton(
            onPressed: widget.onStartShopping ?? () => context.go('/dashboard'),
            size: WoodButtonSize.lg,
            child: Text(labels.startShopping),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(bool isDark, OrdersScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        WoodButton(
          onPressed: widget.onBackToHome ?? () => context.go('/dashboard'),
          variant: WoodButtonVariant.ghost,
          size: WoodButtonSize.sm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, size: 20),
              const SizedBox(width: AppTheme.spacingSM),
              Text(labels.backToHome),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
        // Title
        Text(
          labels.orderHistory,
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
        const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
        // Orders List
        Column(
          children: _orders.map((order) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppTheme.spacingLG * 1.5,
              ), // space-y-6
              child: _buildOrderCard(order, isDark, labels),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    OrderData order,
    bool isDark,
    OrdersScreenLabels labels,
  ) {
    final orderId = order.id.padLeft(5, '0');
    final status = order.status.toLowerCase();
    final statusColor = _getStatusColor(status, isDark);
    final statusBgColor = _getStatusBackgroundColor(status, isDark);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 640) {
                // Desktop: Side by side
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${labels.order} #$orderId',
                            style:
                                AppTextStyles.titleMediumStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827), // gray-900
                                  // font-weight: regular (default)
                                ).copyWith(
                                  fontSize: 20, // text-xl
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            '${labels.placedOn} ${_formatDate(order.createdAt)}',
                            style: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? const Color(0xFF9CA3AF) // gray-400
                                  : const Color(0xFF4B5563), // gray-600
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingLG), // space-x-3
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Badge
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLG, // px-4
                                vertical: AppTheme.spacingSM, // py-2
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius:
                                    AppTheme.borderRadiusCircularValue,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    size: 20,
                                    color: statusColor,
                                  ),
                                  const SizedBox(
                                    width: AppTheme.spacingSM,
                                  ), // space-x-2
                                  Flexible(
                                    child: Text(
                                      status,
                                      style: AppTextStyles.bodyMediumStyle(
                                        color: statusColor,
                                        fontWeight: AppTextStyles.medium,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: AppTheme.spacingMD,
                          ), // space-x-3
                          // Price
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatPrice(order.totalPrice)} JD',
                                  style:
                                      AppTextStyles.titleLargeStyle(
                                        color: isDark
                                            ? const Color(
                                                0xFFD97706,
                                              ) // amber-500
                                            : const Color(
                                                0xFF78350F,
                                              ), // amber-900
                                        // font-weight: regular (default)
                                      ).copyWith(
                                        fontSize: 24, // text-2xl
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.end,
                                ),
                                Text(
                                  _formatPaymentMethod(order.paymentMethod),
                                  style: AppTextStyles.bodySmallStyle(
                                    color: isDark
                                        ? const Color(0xFF6B7280) // gray-500
                                        : const Color(0xFF6B7280), // gray-500
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile: Stacked
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${labels.order} #$orderId',
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-900
                            // font-weight: regular (default)
                          ).copyWith(
                            fontSize: 20, // text-xl
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${labels.placedOn} ${_formatDate(order.createdAt)}',
                      style: AppTextStyles.bodyMediumStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // gap-4
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Badge
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingLG, // px-4
                              vertical: AppTheme.spacingSM, // py-2
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: AppTheme.borderRadiusCircularValue,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 20,
                                  color: statusColor,
                                ),
                                const SizedBox(
                                  width: AppTheme.spacingSM,
                                ), // space-x-2
                                Flexible(
                                  child: Text(
                                    status,
                                    style: AppTextStyles.bodyMediumStyle(
                                      color: statusColor,
                                      fontWeight: AppTextStyles.medium,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatPrice(order.totalPrice)} JD',
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
                            Text(
                              _formatPaymentMethod(order.paymentMethod),
                              style: AppTextStyles.bodySmallStyle(
                                color: isDark
                                    ? const Color(0xFF6B7280) // gray-500
                                    : const Color(0xFF6B7280), // gray-500
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: AppTheme.spacingLG), // mb-4
          // Items Section
          Container(
            padding: const EdgeInsets.only(top: AppTheme.spacingLG), // pt-4
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF92400E) // amber-800
                      : const Color(0xFFFDE68A), // amber-200
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${labels.items} (${_getOrderItemsCount(order)})',
                  style: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD), // mb-3
                Column(
                  children: _getOrderItems(order).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMD,
                      ), // space-y-3
                      child: Row(
                        children: [
                          // Image
                          Container(
                            width: 64, // w-16
                            height: 64, // h-16
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151) // gray-700
                                  : const Color(0xFFE5E7EB), // gray-200
                              borderRadius: AppTheme.borderRadiusLargeValue,
                            ),
                            child: _getItemImage(item) != null
                                ? ClipRRect(
                                    borderRadius:
                                        AppTheme.borderRadiusLargeValue,
                                    child: Image.network(
                                      _getItemImage(item)!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.inventory_2,
                                            size: 24,
                                            color: const Color(
                                              0xFF9CA3AF,
                                            ), // gray-400
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.inventory_2,
                                    size: 24,
                                    color: const Color(0xFF9CA3AF), // gray-400
                                  ),
                          ),
                          const SizedBox(width: AppTheme.spacingLG), // gap-4
                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getItemName(item),
                                  style: AppTextStyles.bodyMediumStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827), // gray-900
                                    fontWeight: AppTextStyles.medium,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                Text(
                                  '${labels.quantityLabel}: ${_getItemQuantity(item)}',
                                  style: AppTextStyles.bodySmallStyle(
                                    color: isDark
                                        ? const Color(0xFF9CA3AF) // gray-400
                                        : const Color(0xFF4B5563), // gray-600
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Text(
                            '${_formatPrice(_getItemTotalPrice(item))} JD',
                            style: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827), // gray-900
                              // font-weight: regular (default)
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Reorder Button
                Container(
                  margin: const EdgeInsets.only(
                    top: AppTheme.spacingLG,
                  ), // mt-4
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingLG,
                  ), // pt-4
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF92400E) // amber-800
                            : const Color(0xFFFDE68A), // amber-200
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      WoodButton(
                        onPressed: () => widget.onReorder?.call(order),
                        size: WoodButtonSize.sm,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.white,
                            ), // RefreshCw
                            const SizedBox(width: AppTheme.spacingSM), // gap-2
                            Text(labels.reorder),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      WoodButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(labels.removeOrder),
                              content: Text(labels.confirmRemoveOrder),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(labels.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    labels.remove,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _handleDeleteOrder(order.id);
                          }
                        },
                        variant: WoodButtonVariant.outline,
                        size: WoodButtonSize.sm,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete_outline, size: 16),
                            const SizedBox(width: AppTheme.spacingSM),
                            Text(labels.removeOrder),
                          ],
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
    );
  }
}

/// OrdersUserData - User data model
class OrdersUserData {
  final String id;
  final String name;
  final String email;

  const OrdersUserData({
    required this.id,
    required this.name,
    required this.email,
  });
}

/// OrderData - Order data model
class OrderData {
  final String id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;
  final String? paymentMethod;
  final List<OrderItemData> items;

  const OrderData({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    this.paymentMethod,
    required this.items,
  });
}

/// OrderItemData - Order item data model
class OrderItemData {
  final String id;
  final String? productId; // Nullable
  final String? packageId; // Add packageId
  final int qty;
  final double priceAtOrder;
  final OrderProductData? product;
  final OrderPackageData? package; // Add package

  const OrderItemData({
    required this.id,
    this.productId,
    this.packageId,
    required this.qty,
    required this.priceAtOrder,
    this.product,
    this.package,
  });
}

/// OrderProductData - Product data model
class OrderProductData {
  final String id;
  final String name;
  final String? imageUrl;

  const OrderProductData({required this.id, required this.name, this.imageUrl});
}

/// OrderPackageData - Package data model
class OrderPackageData {
  final String id;
  final String name;
  final String? imageUrl;

  const OrderPackageData({required this.id, required this.name, this.imageUrl});
}

/// OrdersScreenLabels - Localization labels
class OrdersScreenLabels {
  final String accountRequired;
  final String accountRequiredForOrdersSupport;
  final String signIn;
  final String continueShopping;
  final String noOrders;
  final String startShoppingAndOrders;
  final String startShopping;
  final String backToHome;
  final String orderHistory;
  final String loading;
  final String order;
  final String placedOn;
  final String items;
  final String quantityLabel;
  final String reorder;
  final String removeOrder;
  final String confirmRemoveOrder;
  final String cancel;
  final String remove;

  const OrdersScreenLabels({
    required this.accountRequired,
    required this.accountRequiredForOrdersSupport,
    required this.signIn,
    required this.continueShopping,
    required this.noOrders,
    required this.startShoppingAndOrders,
    required this.startShopping,
    required this.backToHome,
    required this.orderHistory,
    required this.loading,
    required this.order,
    required this.placedOn,
    required this.items,
    required this.quantityLabel,
    required this.reorder,
    required this.removeOrder,
    required this.confirmRemoveOrder,
    required this.cancel,
    required this.remove,
  });

  factory OrdersScreenLabels.defaultLabels() {
    return OrdersScreenLabels.forLanguage('en');
  }

  factory OrdersScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return OrdersScreenLabels(
      accountRequired: isArabic ? 'حساب مطلوب' : 'Account Required',
      accountRequiredForOrdersSupport: isArabic
          ? 'تحتاج إلى تسجيل الدخول لعرض طلباتك والحصول على الدعم'
          : 'You need to sign in to view your orders and get support',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      continueShopping: isArabic ? 'متابعة التسوق' : 'Continue Shopping',
      noOrders: isArabic ? 'لا توجد طلبات' : 'No Orders',
      startShoppingAndOrders: isArabic
          ? 'ابدأ التسوق وستظهر طلباتك هنا'
          : 'Start shopping and your orders will appear here',
      startShopping: isArabic ? 'ابدأ التسوق' : 'Start Shopping',
      backToHome: isArabic ? 'رجوع إلى الرئيسية' : 'Back to Home',
      orderHistory: isArabic ? 'سجل الطلبات' : 'Order History',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      order: isArabic ? 'طلب' : 'Order',
      placedOn: isArabic ? 'تم الطلب في' : 'Placed on',
      items: isArabic ? 'عناصر' : 'Items',
      quantityLabel: isArabic ? 'الكمية' : 'Quantity',
      reorder: isArabic ? 'إعادة الطلب' : 'Reorder',
      removeOrder: isArabic ? 'إزالة الطلب' : 'Remove Order',
      confirmRemoveOrder: isArabic
          ? 'هل أنت متأكد من إزالة هذا الطلب من السجل الخاص بك؟'
          : 'Are you sure you want to remove this order from your history?',
      cancel: isArabic ? 'إلغاء' : 'Cancel',
      remove: isArabic ? 'إزالة' : 'Remove',
    );
  }
}
