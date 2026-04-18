import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_services/order_api_service.dart';

/// OrderDetailsScreen - Order details screen
///
/// Equivalent to Vue's OrderDetails.vue page.
/// Displays order information including items, customer info, and order summary.
///
/// Features:
/// - Order header with ID and date
/// - Order status badge
/// - Order items list with images and details
/// - Customer information section
/// - Order summary with totals
/// - Move to cart button
/// - Dark mode support
/// - Responsive design
class OrderDetailsScreen extends ConsumerStatefulWidget {
  /// Order ID to fetch
  final String? orderId;

  /// Mock order data (optional, if provided will use this as initial state)
  final OrderDetailsData? order;

  /// Loading state
  final bool loading;

  /// Moving to cart state
  final bool movingToCart;

  /// Callback when product is tapped
  final void Function(String productId)? onProductTap;

  /// Callback when move to cart is tapped
  final void Function(OrderDetailsData order)? onMoveToCart;

  /// Callback when back to orders is tapped
  final VoidCallback? onBackToOrders;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Date formatter function
  final String Function(DateTime date)? formatDate;

  /// Labels for localization
  final OrderDetailsScreenLabels? labels;

  const OrderDetailsScreen({
    super.key,
    this.orderId,
    this.order,
    this.loading = false,
    this.movingToCart = false,
    this.onProductTap,
    this.onMoveToCart,
    this.onBackToOrders,
    this.formatPrice,
    this.formatDate,
    this.labels,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  OrderDetailsData? _order;
  bool _isLoading = false;
  Timer? _refreshTimer;
  late final LaravelOrderApiService _orderApi;

  @override
  void initState() {
    super.initState();
    _orderApi = LaravelOrderApiService();
    _order = widget.order;
    _isLoading = widget.loading || (widget.orderId != null && _order == null);

    if (widget.orderId != null) {
      _fetchOrder();
      // Start polling every 5 seconds for status updates
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _fetchOrder(isBackground: true),
      );
    } else {
      _loadMockData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder({bool isBackground = false}) async {
    if (widget.orderId == null) return;

    if (!isBackground) {
      setState(() => _isLoading = true);
    }

    try {
      final data = await _orderApi.fetchOrder(widget.orderId!);
      if (data != null && mounted) {
        setState(() {
          _order = _mapToOrderData(data);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!isBackground && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  OrderDetailsData _mapToOrderData(Map<String, dynamic> data) {
    return OrderDetailsData(
      id: data['id'].toString(),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      status: data['status']?.toString() ?? 'pending',
      customerName: data['customer_name']?.toString() ?? 'Guest',
      customerPhone: data['customer_phone']?.toString(),
      paymentMethod: data['payment_method']?.toString(),
      totalPrice:
          double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0,
      items: (data['items'] as List? ?? []).map((item) {
        final product = item['product'];
        final package = item['package'];

        String name = 'Unknown Item';
        String? imageUrl;
        int stock = 0;

        if (product != null) {
          name = product['name']?.toString() ?? name;
          imageUrl = product['image_url']?.toString();
          stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
        } else if (package != null) {
          name = (package['name'] ?? package['title'])?.toString() ?? name;
          imageUrl = package['image_url']?.toString();
          stock = 1; // Packages usually don't have stock like products
        }

        return OrderItemData(
          id: item['id'].toString(),
          productId:
              (item['product_id'] ?? item['package_id'])?.toString() ?? '0',
          qty: int.tryParse(item['qty']?.toString() ?? '1') ?? 1,
          priceAtOrder:
              double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          product: OrderProductData(
            id: (item['product_id'] ?? item['package_id'])?.toString() ?? '0',
            name: name,
            imageUrl: imageUrl,
            stock: stock,
          ),
        );
      }).toList(),
    );
  }

  void _loadMockData() {
    _order =
        widget.order ??
        OrderDetailsData(
          id: '12345',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          status: 'completed',
          customerName: 'John Doe',
          customerPhone: '+1 234 567 8900',
          paymentMethod: 'credit_card',
          totalPrice: 299.99,
          items: [
            OrderItemData(
              id: '1',
              productId: '1',
              qty: 2,
              priceAtOrder: 149.99,
              product: OrderProductData(
                id: '1',
                name: 'Wooden Table',
                imageUrl: null,
                stock: 10,
              ),
            ),
            OrderItemData(
              id: '2',
              productId: '2',
              qty: 1,
              priceAtOrder: 99.99,
              product: OrderProductData(
                id: '2',
                name: 'Wooden Chair',
                imageUrl: null,
                stock: 5,
              ),
            ),
          ],
        );
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? '\$${price.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return widget.formatDate?.call(date) ??
        '${date.month} ${date.day}, ${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPaymentMethod(String? method) {
    if (method == null) return 'N/A';
    return method.replaceAll('_', ' ');
  }

  Color _getStatusColor(String status, bool isDark) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'pending') {
      return isDark
          ? const Color(0xFFFCD34D) // yellow-400
          : const Color(0xFF92400E); // yellow-800
    } else if (statusLower == 'completed' || statusLower == 'delivered') {
      return isDark
          ? const Color(0xFF4ADE80) // green-400
          : const Color(0xFF166534); // green-800
    } else if (statusLower == 'cancelled' || statusLower == 'rejected') {
      return isDark
          ? const Color(0xFFF87171) // red-400
          : const Color(0xFF991B1B); // red-800
    } else if (statusLower == 'processing') {
      return isDark
          ? const Color(0xFF60A5FA) // blue-400
          : const Color(0xFF1E40AF); // blue-800
    } else if (statusLower == 'shipped') {
      return isDark
          ? const Color(0xFFA78BFA) // purple-400
          : const Color(0xFF6B21A8); // purple-800
    }
    return isDark
        ? const Color(0xFF9CA3AF) // gray-400
        : const Color(0xFF374151); // gray-800
  }

  Color _getStatusBackgroundColor(String status, bool isDark) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'pending') {
      return isDark
          ? const Color(0xFFFCD34D).withValues(alpha: 0.2) // yellow-500/20
          : const Color(0xFFFEF3C7); // yellow-100
    } else if (statusLower == 'completed' || statusLower == 'delivered') {
      return isDark
          ? const Color(0xFF16A34A).withValues(alpha: 0.2) // green-900/20
          : const Color(0xFFD1FAE5); // green-100
    } else if (statusLower == 'cancelled' || statusLower == 'rejected') {
      return isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.2) // red-500/20
          : const Color(0xFFFEE2E2); // red-100
    } else if (statusLower == 'processing') {
      return isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.2) // blue-500/20
          : const Color(0xFFDBEAFE); // blue-100
    } else if (statusLower == 'shipped') {
      return isDark
          ? const Color(0xFF7C3AED).withValues(alpha: 0.2) // purple-500/20
          : const Color(0xFFE9D5FF); // purple-100
    }
    return isDark
        ? const Color(0xFF6B7280).withValues(alpha: 0.2) // gray-500/20
        : const Color(0xFFF3F4F6); // gray-100
  }

  double _calculateTotal() {
    if (_order == null) return 0.0;
    final subtotal = _order!.totalPrice;
    final tax = subtotal * 0.085;
    final shipping = subtotal >= 200 ? 0 : 15;
    return subtotal + tax + shipping;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? OrderDetailsScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      child: Container(
        color: isDark
            ? const Color(0xFF111827) // gray-900
            : const Color(0xFFF9FAFB), // gray-50
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingXXL * 3,
                      ), // py-12
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF6D4C41),
                          ),
                          const SizedBox(height: AppTheme.spacingLG),
                          Text(
                            labels.loadingOrderDetails,
                            style: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? const Color(0xFF9CA3AF) // gray-400
                                  : const Color(0xFF4B5563), // gray-600
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _order == null
                ? _buildNotFoundState(isDark, labels)
                : _buildOrderDetails(isDark, labels),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState(bool isDark, OrderDetailsScreenLabels labels) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL * 3), // py-12
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labels.orderNotFound,
              style:
                  AppTextStyles.titleMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                  ).copyWith(
                    fontSize: 20, // text-xl
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            WoodButton(
              onPressed: widget.onBackToOrders ?? () => context.go('/orders'),
              size: WoodButtonSize.md,
              child: Text(labels.backToOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(bool isDark, OrderDetailsScreenLabels labels) {
    final order = _order!;
    final orderId = order.id.padLeft(5, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppTheme.spacingLG * 1.5,
          ), // mb-6
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${labels.order} #ORD-$orderId',
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
                '${labels.placedOn} ${_formatDate(order.createdAt)}',
                style: AppTextStyles.bodySmallStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF4B5563), // gray-600
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingLG * 1.5), // space-y-6
        // Order Status
        _buildOrderStatusCard(order, isDark, labels),

        const SizedBox(height: AppTheme.spacingLG * 1.5), // space-y-6
        // Order Items
        _buildOrderItemsCard(order, isDark, labels),

        const SizedBox(height: AppTheme.spacingLG * 1.5), // space-y-6
        // Order Summary and Customer Info
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1024) {
              // Desktop: Side by side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCustomerInfoCard(order, isDark, labels),
                  ),
                  const SizedBox(width: AppTheme.spacingLG * 1.5), // gap-6
                  Expanded(
                    child: _buildOrderSummaryCard(order, isDark, labels),
                  ),
                ],
              );
            } else {
              // Mobile: Stacked
              return Column(
                children: [
                  _buildCustomerInfoCard(order, isDark, labels),
                  const SizedBox(height: AppTheme.spacingLG * 1.5), // gap-6
                  _buildOrderSummaryCard(order, isDark, labels),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildOrderStatusCard(
    OrderDetailsData order,
    bool isDark,
    OrderDetailsScreenLabels labels,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
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
                  labels.orderStatus,
                  style:
                      AppTextStyles.titleSmallStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        fontWeight: AppTextStyles.medium,
                      ).copyWith(
                        fontSize: 18, // text-lg
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD, // px-3
                    vertical: 4, // py-1
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status, isDark),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: AppTextStyles.bodySmallStyle(
                      color: _getStatusColor(order.status, isDark),
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(
    OrderDetailsData order,
    bool isDark,
    OrderDetailsScreenLabels labels,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
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
              children: [
                Text(
                  labels.orderItems,
                  style:
                      AppTextStyles.titleSmallStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        fontWeight: AppTextStyles.medium,
                      ).copyWith(
                        fontSize: 18, // text-lg
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
            child: order.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingXXL * 2,
                      ), // py-8
                      child: Text(
                        labels.noItemsInOrder,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF4B5563), // gray-600
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: order.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == order.items.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : AppTheme.spacingLG, // pb-4
                        ),
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : AppTheme.spacingLG, // pb-4
                          ),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF374151) // gray-700
                                          : const Color(0xFFE5E7EB), // gray-200
                                    ),
                                  ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              GestureDetector(
                                onTap: () {
                                  if (widget.onProductTap != null) {
                                    widget.onProductTap!.call(item.productId);
                                  } else {
                                    context.pushNamed(
                                      'product',
                                      pathParameters: {'id': item.productId},
                                    );
                                  }
                                },
                                child: Container(
                                  width: 80, // w-20
                                  height: 80, // h-20
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF374151) // gray-700
                                        : const Color(0xFFE5E7EB), // gray-200
                                    borderRadius:
                                        AppTheme.borderRadiusLargeValue,
                                  ),
                                  child: item.product?.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              AppTheme.borderRadiusLargeValue,
                                          child: Image.network(
                                            item.product!.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.inventory_2,
                                                      size: 48, // w-12 h-12
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF9CA3AF,
                                                            ) // gray-400
                                                          : const Color(
                                                              0xFF6B7280,
                                                            ), // gray-500
                                                    ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.inventory_2,
                                          size: 48, // w-12 h-12
                                          color: isDark
                                              ? const Color(
                                                  0xFF9CA3AF,
                                                ) // gray-400
                                              : const Color(
                                                  0xFF6B7280,
                                                ), // gray-500
                                        ),
                                ),
                              ),
                              const SizedBox(
                                width: AppTheme.spacingLG,
                              ), // gap-4
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (widget.onProductTap != null) {
                                          widget.onProductTap!.call(
                                            item.productId,
                                          );
                                        } else {
                                          context.pushNamed(
                                            'product',
                                            pathParameters: {
                                              'id': item.productId,
                                            },
                                          );
                                        }
                                      },
                                      child: Text(
                                        item.product?.name ?? 'Unknown Product',
                                        style: AppTextStyles.bodyMediumStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(
                                                  0xFF111827,
                                                ), // gray-900
                                          fontWeight: AppTextStyles.medium,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppTheme.spacingXS,
                                    ), // mb-1
                                    Text(
                                      '${labels.quantityLabel}: ${item.qty}',
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
                                      height: AppTheme.spacingSM,
                                    ), // mb-2
                                    Text(
                                      labels.priceEach.replaceAll(
                                        '{price}',
                                        _formatPrice(item.priceAtOrder),
                                      ),
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
                                    if (item.product != null) ...[
                                      const SizedBox(
                                        height: AppTheme.spacingXS,
                                      ), // mt-1
                                      Text(
                                        item.product!.stock > 0
                                            ? labels.inStockAvailable
                                                  .replaceAll(
                                                    '{stock}',
                                                    item.product!.stock
                                                        .toString(),
                                                  )
                                            : labels.outOfStock,
                                        style:
                                            AppTextStyles.bodySmallStyle(
                                              color: item.product!.stock > 0
                                                  ? const Color(
                                                      0xFF6D4C41,
                                                    ) // brown-600
                                                  : (isDark
                                                        ? const Color(
                                                            0xFFF87171,
                                                          ) // red-400
                                                        : const Color(
                                                            0xFFDC2626,
                                                          )), // red-600
                                            ).copyWith(
                                              fontSize: 12, // text-xs
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Price
                              Text(
                                _formatPrice(item.priceAtOrder * item.qty),
                                style:
                                    AppTextStyles.titleMediumStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827), // gray-900
                                      // font-weight: regular (default)
                                    ).copyWith(
                                      fontSize: 18, // text-lg
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(
    OrderDetailsData order,
    bool isDark,
    OrderDetailsScreenLabels labels,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
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
              children: [
                Text(
                  labels.customerInformation,
                  style:
                      AppTextStyles.titleSmallStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        fontWeight: AppTextStyles.medium,
                      ).copyWith(
                        fontSize: 18, // text-lg
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
            child: Column(
              children: [
                _buildInfoRow(
                  label: labels.name,
                  value: order.customerName,
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingMD), // space-y-3
                _buildInfoRow(
                  label: labels.phone,
                  value: order.customerPhone ?? 'N/A',
                  isDark: isDark,
                ),
                if (order.paymentMethod != null) ...[
                  const SizedBox(height: AppTheme.spacingMD), // space-y-3
                  _buildInfoRow(
                    label: labels.paymentMethod,
                    value: _formatPaymentMethod(order.paymentMethod),
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmallStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
            fontWeight: AppTextStyles.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(
    OrderDetailsData order,
    bool isDark,
    OrderDetailsScreenLabels labels,
  ) {
    final subtotal = order.totalPrice;
    final tax = subtotal * 0.085;
    final shipping = subtotal >= 200 ? 0.0 : 15.0;
    final total = _calculateTotal();

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
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
              children: [
                Text(
                  labels.orderSummary,
                  style:
                      AppTextStyles.titleSmallStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        fontWeight: AppTextStyles.medium,
                      ).copyWith(
                        fontSize: 18, // text-lg
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
            child: Column(
              children: [
                _buildSummaryRow(
                  label: labels.subtotal,
                  value: _formatPrice(subtotal),
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingMD), // space-y-3
                _buildSummaryRow(
                  label: labels.tax,
                  value: _formatPrice(tax),
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingMD), // space-y-3
                _buildSummaryRow(
                  label: labels.shipping,
                  value: shipping == 0 ? labels.free : _formatPrice(shipping),
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingLG), // mb-4
                Container(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingLG,
                  ), // pt-4
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF374151) // gray-700
                            : const Color(0xFFE5E7EB), // gray-200
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            labels.total,
                            style:
                                AppTextStyles.titleSmallStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827), // gray-900
                                  fontWeight: AppTextStyles.medium,
                                ).copyWith(
                                  fontSize: 18, // text-lg
                                ),
                          ),
                          Text(
                            '${_formatPrice(total)} JD',
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
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLG), // mb-4
                      SizedBox(
                        width: double.infinity,
                        child: WoodButton(
                          onPressed: widget.movingToCart
                              ? null
                              : () => widget.onMoveToCart?.call(order),
                          size: WoodButtonSize.md,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                size: 20,
                                color: Colors.white,
                              ), // w-5 h-5
                              const SizedBox(
                                width: AppTheme.spacingSM,
                              ), // gap-2
                              Text(
                                widget.movingToCart
                                    ? labels.addingToCart
                                    : labels.moveToCart,
                              ),
                            ],
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
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
        ),
      ],
    );
  }
}

/// OrderDetailsData - Order data model
class OrderDetailsData {
  final String id;
  final DateTime createdAt;
  final String status;
  final String customerName;
  final String? customerPhone;
  final String? paymentMethod;
  final double totalPrice;
  final List<OrderItemData> items;

  const OrderDetailsData({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.customerName,
    this.customerPhone,
    this.paymentMethod,
    required this.totalPrice,
    required this.items,
  });
}

/// OrderItemData - Order item data model
class OrderItemData {
  final String id;
  final String productId;
  final int qty;
  final double priceAtOrder;
  final OrderProductData? product;

  const OrderItemData({
    required this.id,
    required this.productId,
    required this.qty,
    required this.priceAtOrder,
    this.product,
  });
}

/// OrderProductData - Product data model
class OrderProductData {
  final String id;
  final String name;
  final String? imageUrl;
  final int stock;

  const OrderProductData({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.stock,
  });
}

/// OrderDetailsScreenLabels - Localization labels
class OrderDetailsScreenLabels {
  final String loadingOrderDetails;
  final String order;
  final String placedOn;
  final String orderStatus;
  final String orderItems;
  final String quantityLabel;
  final String priceEach;
  final String inStockAvailable;
  final String outOfStock;
  final String noItemsInOrder;
  final String customerInformation;
  final String name;
  final String phone;
  final String paymentMethod;
  final String orderSummary;
  final String subtotal;
  final String tax;
  final String shipping;
  final String free;
  final String total;
  final String moveToCart;
  final String addingToCart;
  final String orderNotFound;
  final String backToOrders;

  const OrderDetailsScreenLabels({
    required this.loadingOrderDetails,
    required this.order,
    required this.placedOn,
    required this.orderStatus,
    required this.orderItems,
    required this.quantityLabel,
    required this.priceEach,
    required this.inStockAvailable,
    required this.outOfStock,
    required this.noItemsInOrder,
    required this.customerInformation,
    required this.name,
    required this.phone,
    required this.paymentMethod,
    required this.orderSummary,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.free,
    required this.total,
    required this.moveToCart,
    required this.addingToCart,
    required this.orderNotFound,
    required this.backToOrders,
  });

  factory OrderDetailsScreenLabels.defaultLabels() {
    return OrderDetailsScreenLabels.forLanguage('en');
  }

  factory OrderDetailsScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return OrderDetailsScreenLabels(
      loadingOrderDetails: isArabic
          ? 'جاري تحميل تفاصيل الطلب...'
          : 'Loading order details...',
      order: isArabic ? 'طلب' : 'Order',
      placedOn: isArabic ? 'تم الطلب في' : 'Placed on',
      orderStatus: isArabic ? 'حالة الطلب' : 'Order Status',
      orderItems: isArabic ? 'عناصر الطلب' : 'Order Items',
      quantityLabel: isArabic ? 'الكمية' : 'Quantity',
      priceEach: isArabic ? '{price} لكل' : '{price} each',
      inStockAvailable: isArabic ? '{stock} متوفر' : '{stock} in stock',
      outOfStock: isArabic ? 'نفدت الكمية' : 'Out of stock',
      noItemsInOrder: isArabic ? 'لا توجد عناصر في الطلب' : 'No items in order',
      customerInformation: isArabic ? 'معلومات العميل' : 'Customer Information',
      name: isArabic ? 'الاسم' : 'Name',
      phone: isArabic ? 'الهاتف' : 'Phone',
      paymentMethod: isArabic ? 'طريقة الدفع' : 'Payment Method',
      orderSummary: isArabic ? 'ملخص الطلب' : 'Order Summary',
      subtotal: isArabic ? 'المجموع الفرعي' : 'Subtotal',
      tax: isArabic ? 'الضريبة' : 'Tax',
      shipping: isArabic ? 'الشحن' : 'Shipping',
      free: isArabic ? 'مجاني' : 'Free',
      total: isArabic ? 'المجموع' : 'Total',
      moveToCart: isArabic ? 'نقل إلى السلة' : 'Move to Cart',
      addingToCart: isArabic
          ? 'جاري الإضافة إلى السلة...'
          : 'Adding to cart...',
      orderNotFound: isArabic ? 'الطلب غير موجود' : 'Order not found',
      backToOrders: isArabic ? 'رجوع إلى الطلبات' : 'Back to Orders',
    );
  }
}
