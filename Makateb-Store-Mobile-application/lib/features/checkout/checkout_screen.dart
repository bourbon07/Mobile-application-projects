import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_services/delivery_fee_api_service.dart';
import '../../core/services/api_services/service_fee_api_service.dart';
import '../../core/stores/auth_store.dart';
import '../../core/services/storage_service.dart';

/// CheckoutScreen - Checkout page screen
///
/// Equivalent to Vue's Checkout.vue page.
/// Displays checkout form with contact info, shipping address, payment method, and order summary.
///
/// Features:
/// - Empty cart state
/// - Contact information form
/// - Shipping address form with city dropdown
/// - Payment method selection (credit card, PayPal, cash on delivery)
/// - Credit card details form (conditional)
/// - Order summary sidebar (sticky)
/// - Dark mode support
/// - Responsive design
class CheckoutScreen extends ConsumerStatefulWidget {
  /// Mock cart items
  final List<CheckoutCartItemData>? cartItems;

  /// Mock delivery locations
  final List<CheckoutDeliveryLocationData>? deliveryLocations;

  /// Service fee amount
  final double? serviceFee;

  /// Loading state
  final bool loading;

  /// Callback when order is placed
  final void Function(CheckoutFormData formData)? onPlaceOrder;

  /// Callback when start shopping is tapped
  final VoidCallback? onStartShopping;

  /// Price formatter function
  final String Function(double price)? formatPrice;

  /// Labels for localization
  final CheckoutScreenLabels? labels;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.deliveryLocations,
    this.serviceFee,
    this.loading = false,
    this.onPlaceOrder,
    this.onStartShopping,
    this.formatPrice,
    this.labels,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String? _selectedCity;
  String _selectedPaymentMethod = 'credit_card';
  double _locationFee = 0.0;
  bool _processing = false;

  List<CheckoutCartItemData> _cartItems = [];
  List<CheckoutDeliveryLocationData> _deliveryLocations = [];
  double _serviceFee = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData(); // changed name to _loadData
  }

  Future<void> _loadData() async {
    setState(
      () => _processing = true,
    ); // reuse processing flag for initial load or add loading flag

    // 1. Load Cart Items (from Store if not passed)
    if (widget.cartItems != null) {
      _cartItems = widget.cartItems!;
    } else {
      // access via provider if available or wait for consumer build?
      // It's better to ref.read in initState callback or similar, but here we can't easily.
      // However, the build method gets it. Let's start with empty and let build update or rely on parameter.
      // Actually build method passes it! "cartItems: cartState.items..." in AppRouter.
      // So _cartItems being empty initially is fine as widget.cartItems will be used.
      _cartItems = widget.cartItems ?? [];
    }

    // 2. Load Delivery Locations
    try {
      final deliveryApi = DeliveryFeeApiService();
      final fees = await deliveryApi.fetchDeliveryFees();
      _deliveryLocations = fees.map((f) {
        final map = f as Map<String, dynamic>;
        return CheckoutDeliveryLocationData(
          id: map['id'].toString(),
          location: map['location'],
          fee: double.tryParse(map['fee'].toString()) ?? 0.0,
          isActive: map['is_active'] == true || map['is_active'] == 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading delivery fees: $e');
    }

    // 3. Load Service Fee
    try {
      final serviceApi = ServiceFeeApiService();
      final feeData = await serviceApi.fetchServiceFee();
      _serviceFee = double.tryParse(feeData['fee']?.toString() ?? '0') ?? 0.0;
    } catch (e) {
      debugPrint('Error loading service fee: $e');
    }

    // 4. Pre-fill user info if logged in
    final user = ref.read(authUserProvider);
    if (user != null) {
      if (_fullNameController.text.isEmpty) {
        _fullNameController.text = user.name;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = user.email;
      }
      // Optional: phone/location from additionalData if present
      final phone = user.additionalData?['phone']?.toString();
      if (phone != null && _phoneController.text.isEmpty) {
        _phoneController.text = phone;
      }
      final location = user.additionalData?['location']?.toString();
      if (location != null && _addressController.text.isEmpty) {
        _addressController.text = location;
      }
    }

    // 5. Load Saved Payment Info
    final storage = StorageService.instance;
    final savedCardNumber = storage.getString('payment_card_number') ?? '';
    if (savedCardNumber.isNotEmpty) {
      _cardNumberController.text = savedCardNumber;
      _expiryDateController.text =
          storage.getString('payment_expiry_date') ?? '';
      _cvvController.text = storage.getString('payment_cvv') ?? '';
      _selectedPaymentMethod =
          storage.getString('default_payment_method') ?? 'credit_card';
    }

    if (mounted) setState(() => _processing = false);
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item.package?.price ?? item.product?.price ?? 0.0;
      return sum + (price * (item.quantity ?? 1));
    });
  }

  double get _serviceFees {
    return _serviceFee + _locationFee;
  }

  double get _total {
    return _subtotal + _serviceFees;
  }

  String _formatPrice(double price) {
    return widget.formatPrice?.call(price) ?? '\$${price.toStringAsFixed(2)}';
  }

  void _updateLocationFee() {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      setState(() {
        _locationFee = 0.0;
      });
      return;
    }

    final location = _deliveryLocations.firstWhere(
      (loc) => loc.location == _selectedCity && loc.isActive != false,
      orElse: () => CheckoutDeliveryLocationData(
        id: '',
        location: '',
        fee: 0.0,
        isActive: true,
      ),
    );

    setState(() {
      _locationFee = location.fee;
    });
  }

  void _completePurchase() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.labels?.pleaseSelectPaymentMethod ??
                'Please select a payment method',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.labels?.pleaseFillShippingAddress ??
                'Please fill in all shipping address fields',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'credit_card') {
      if (_cardNumberController.text.trim().isEmpty ||
          _expiryDateController.text.trim().isEmpty ||
          _cvvController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.labels?.pleaseFillCardDetails ??
                  'Please fill in all credit card details',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _processing = true;
    });

    final formData = CheckoutFormData(
      paymentMethod: _selectedPaymentMethod,
      deliveryLocation:
          '${_addressController.text.trim()}, $_selectedCity, ${_zipCodeController.text.trim()}',
      customerName: _fullNameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim(),
      city: _selectedCity, // Add city
      cardDetails: _selectedPaymentMethod == 'credit_card'
          ? CheckoutCardDetailsData(
              cardNumber: _cardNumberController.text.trim(),
              expiryDate: _expiryDateController.text.trim(),
              cvv: _cvvController.text.trim(),
            )
          : null,
    );

    widget.onPlaceOrder?.call(formData);

    // Reset processing state after a delay (in real app, this would be after API call)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? CheckoutScreenLabels.forLanguage(currentLanguage);

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
        child: widget.loading
            ? const Center(child: CircularProgressIndicator())
            : _cartItems.isEmpty
            ? _buildEmptyCartState(isDark, labels)
            : _buildCheckoutForm(isDark, labels),
      ),
    );
  }

  Widget _buildEmptyCartState(bool isDark, CheckoutScreenLabels labels) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            labels.yourCartIsEmpty,
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
          WoodButton(
            onPressed: widget.onStartShopping ?? () => context.go('/dashboard'),
            size: WoodButtonSize.md,
            child: Text(labels.startShopping),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm(bool isDark, CheckoutScreenLabels labels) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppTheme.spacingXXL * 2,
            ), // mb-8
            child: Text(
              labels.checkoutPage,
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

          // Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1024) {
                // Desktop: Grid layout
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkout Form (2 columns)
                    Expanded(
                      flex: 2,
                      child: _buildFormSections(isDark, labels),
                    ),
                    const SizedBox(width: AppTheme.spacingXXL * 2), // gap-8
                    // Order Summary (1 column)
                    Expanded(
                      flex: 1,
                      child: _buildOrderSummary(isDark, labels),
                    ),
                  ],
                );
              } else {
                // Mobile: Stacked layout
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormSections(isDark, labels),
                    const SizedBox(height: AppTheme.spacingXXL * 2), // gap-8
                    _buildOrderSummary(isDark, labels),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormSections(bool isDark, CheckoutScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contact Information
        _buildContactInformation(isDark, labels),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // space-y-6
        // Shipping Address
        _buildShippingAddress(isDark, labels),
        const SizedBox(height: AppTheme.spacingLG * 1.5), // space-y-6
        // Payment Method
        _buildPaymentMethod(isDark, labels),
      ],
    );
  }

  Widget _buildContactInformation(bool isDark, CheckoutScreenLabels labels) {
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
          Text(
            labels.contactInformation,
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
          const SizedBox(height: AppTheme.spacingLG), // mb-4
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 640) {
                // Desktop: 2 columns
                return Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _fullNameController,
                        label: labels.fullName,
                        isRequired: true,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingLG), // gap-4
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: labels.email,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile: Stacked
                return Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: labels.fullName,
                      isRequired: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // gap-4
                    _buildTextField(
                      controller: _emailController,
                      label: labels.email,
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingLG), // gap-4
          _buildTextField(
            controller: _phoneController,
            label: labels.phone,
            isRequired: true,
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(bool isDark, CheckoutScreenLabels labels) {
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
          Text(
            labels.shippingAddress,
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
          const SizedBox(height: AppTheme.spacingLG), // mb-4
          _buildTextField(
            controller: _addressController,
            label: labels.address,
            isRequired: true,
            isDark: isDark,
          ),
          const SizedBox(height: AppTheme.spacingLG), // space-y-4
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 640) {
                // Desktop: 2 columns
                return Row(
                  children: [
                    Expanded(child: _buildCityDropdown(isDark, labels)),
                    const SizedBox(width: AppTheme.spacingLG), // gap-4
                    Expanded(
                      child: _buildTextField(
                        controller: _zipCodeController,
                        label: labels.zipCode,
                        isRequired: true,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile: Stacked
                return Column(
                  children: [
                    _buildCityDropdown(isDark, labels),
                    const SizedBox(height: AppTheme.spacingLG), // gap-4
                    _buildTextField(
                      controller: _zipCodeController,
                      label: labels.zipCode,
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown(bool isDark, CheckoutScreenLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labels.city} *',
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151) // gray-700
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4
              vertical: AppTheme.spacingSM, // py-2
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(labels.selectLocation),
            ),
            ..._deliveryLocations.map(
              (location) => DropdownMenuItem<String>(
                value: location.location,
                child: Text(location.location),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
            });
            _updateLocationFee();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${labels.city} is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(bool isDark, CheckoutScreenLabels labels) {
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
          Text(
            labels.paymentMethod,
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
          const SizedBox(height: AppTheme.spacingLG), // mb-4
          // Payment Options
          RadioGroup<String>(
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              }
            },
            child: Column(
              children: [
                _buildPaymentOption(
                  value: 'credit_card',
                  icon: Icons.credit_card,
                  label: labels.creditCard,
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingMD), // space-y-3
                _buildPaymentOption(
                  value: 'paypal',
                  icon: Icons.account_balance_wallet,
                  label: 'PayPal',
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.spacingMD), // space-y-3
                _buildPaymentOption(
                  value: 'cash_on_delivery',
                  icon: Icons.local_shipping,
                  label: labels.cashOnDelivery,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Credit Card Details
          if (_selectedPaymentMethod == 'credit_card') ...[
            const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF78350F).withValues(
                        alpha: 0.2,
                      ) // amber-900/20
                    : const Color(0xFFFFFBEB), // amber-50
                borderRadius: AppTheme.borderRadiusLargeValue,
              ),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _cardNumberController,
                    label: labels.cardNumber,
                    hintText: '1234 5678 9012 3456',
                    isRequired: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppTheme.spacingLG), // space-y-4
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 360) {
                        // Very small screens: Stack vertically
                        return Column(
                          children: [
                            _buildTextField(
                              controller: _expiryDateController,
                              label: labels.expiryDate,
                              hintText: 'MM/YY',
                              isRequired: true,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppTheme.spacingLG), // gap-4
                            _buildTextField(
                              controller: _cvvController,
                              label: labels.cvv,
                              hintText: '123',
                              isRequired: true,
                              isDark: isDark,
                            ),
                          ],
                        );
                      } else {
                        // Normal screens: Horizontal layout
                        return Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _expiryDateController,
                                label: labels.expiryDate,
                                hintText: 'MM/YY',
                                isRequired: true,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingLG), // gap-4
                            Expanded(
                              child: _buildTextField(
                                controller: _cvvController,
                                label: labels.cvv,
                                hintText: '123',
                                isRequired: true,
                                isDark: isDark,
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
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        borderRadius: AppTheme.borderRadiusLargeValue,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? const Color(0xFF92400E) // amber-800
                  : const Color(0xFFFDE68A), // amber-200
              width: 2,
            ),
            borderRadius: AppTheme.borderRadiusLargeValue,
            color: isSelected
                ? (isDark
                      ? const Color(0xFF78350F).withValues(
                          alpha: 0.2,
                        ) // amber-900/20
                      : const Color(0xFFFFFBEB)) // amber-50
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                activeColor: const Color(0xFFD97706), // amber-600
              ),
              const SizedBox(width: AppTheme.spacingSM), // mr-3
              Icon(
                icon,
                size: 20,
                color: isDark
                    ? const Color(0xFFD97706) // amber-500
                    : const Color(0xFF92400E), // amber-800
              ),
              const SizedBox(width: AppTheme.spacingSM), // mr-2
              Text(
                label,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool isRequired = false,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151) // gray-700
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF92400E) // amber-800
                    : const Color(0xFFFDE68A), // amber-200
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4
              vertical: AppTheme.spacingSM, // py-2
            ),
            hintStyle: AppTextStyles.bodyMediumStyle(
              color: const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  if (keyboardType == TextInputType.emailAddress) {
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildOrderSummary(bool isDark, CheckoutScreenLabels labels) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG * 1.5), // p-6
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F) // amber-900
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
          Text(
            labels.orderSummary,
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
          const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
          // Summary Items
          Column(
            children: [
              _buildSummaryRow(
                label: labels.subtotal,
                value: _formatPrice(_subtotal),
                isDark: isDark,
              ),
              const SizedBox(height: AppTheme.spacingMD), // space-y-3
              _buildSummaryRow(
                label: labels.serviceFees,
                value: _formatPrice(_serviceFees),
                isDark: isDark,
              ),
              const SizedBox(height: AppTheme.spacingMD), // space-y-3
              Container(
                padding: const EdgeInsets.only(top: AppTheme.spacingMD), // pt-3
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF92400E) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labels.total,
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
                    Text(
                      _formatPrice(_total),
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
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: WoodButton(
              onPressed: _processing ? null : _completePurchase,
              size: WoodButtonSize.lg,
              child: Text(_processing ? labels.processing : labels.placeOrder),
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG), // mt-4
          Text(
            labels.agreeTermsConditions,
            style:
                AppTextStyles.bodySmallStyle(
                  color: isDark
                      ? const Color(0xFF6B7280) // gray-500
                      : const Color(0xFF6B7280), // gray-500
                ).copyWith(
                  fontSize: 12, // text-xs
                ),
            textAlign: TextAlign.center,
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
            fontWeight: AppTextStyles.medium,
          ),
        ),
      ],
    );
  }
}

/// CheckoutCartItemData - Cart item data model
class CheckoutCartItemData {
  final String id;
  final int? quantity;
  final CheckoutProductData? product;
  final CheckoutPackageData? package;

  const CheckoutCartItemData({
    required this.id,
    this.quantity,
    this.product,
    this.package,
  });
}

/// CheckoutProductData - Product data model
class CheckoutProductData {
  final String id;
  final String name;
  final double price;

  const CheckoutProductData({
    required this.id,
    required this.name,
    required this.price,
  });
}

/// CheckoutPackageData - Package data model
class CheckoutPackageData {
  final String id;
  final double? price;
  final List<CheckoutProductData>? products;

  const CheckoutPackageData({required this.id, this.price, this.products});
}

/// CheckoutDeliveryLocationData - Delivery location data model
class CheckoutDeliveryLocationData {
  final String id;
  final String location;
  final double fee;
  final bool? isActive;

  const CheckoutDeliveryLocationData({
    required this.id,
    required this.location,
    required this.fee,
    this.isActive,
  });
}

/// CheckoutFormData - Form data model
class CheckoutFormData {
  final String paymentMethod;
  final String deliveryLocation;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? city; // Add city field
  final CheckoutCardDetailsData? cardDetails;

  const CheckoutFormData({
    required this.paymentMethod,
    required this.deliveryLocation,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.city, // Add city
    this.cardDetails,
  });
}

/// CheckoutCardDetailsData - Card details data model
class CheckoutCardDetailsData {
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  const CheckoutCardDetailsData({
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });
}

/// CheckoutScreenLabels - Localization labels
class CheckoutScreenLabels {
  final String yourCartIsEmpty;
  final String startShopping;
  final String checkoutPage;
  final String contactInformation;
  final String fullName;
  final String email;
  final String phone;
  final String shippingAddress;
  final String address;
  final String city;
  final String zipCode;
  final String selectLocation;
  final String paymentMethod;
  final String creditCard;
  final String cashOnDelivery;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String orderSummary;
  final String subtotal;
  final String serviceFees;
  final String total;
  final String placeOrder;
  final String processing;
  final String agreeTermsConditions;
  final String pleaseSelectPaymentMethod;
  final String pleaseFillContactInfo;
  final String pleaseFillShippingAddress;
  final String pleaseFillCardDetails;

  const CheckoutScreenLabels({
    required this.yourCartIsEmpty,
    required this.startShopping,
    required this.checkoutPage,
    required this.contactInformation,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.shippingAddress,
    required this.address,
    required this.city,
    required this.zipCode,
    required this.selectLocation,
    required this.paymentMethod,
    required this.creditCard,
    required this.cashOnDelivery,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.orderSummary,
    required this.subtotal,
    required this.serviceFees,
    required this.total,
    required this.placeOrder,
    required this.processing,
    required this.agreeTermsConditions,
    required this.pleaseSelectPaymentMethod,
    required this.pleaseFillContactInfo,
    required this.pleaseFillShippingAddress,
    required this.pleaseFillCardDetails,
  });

  factory CheckoutScreenLabels.defaultLabels() {
    return CheckoutScreenLabels.forLanguage('en');
  }

  factory CheckoutScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return CheckoutScreenLabels(
      yourCartIsEmpty: isArabic ? 'سلة التسوق فارغة' : 'Your cart is empty',
      startShopping: isArabic ? 'ابدأ التسوق' : 'Start Shopping',
      checkoutPage: isArabic ? 'صفحة الدفع' : 'Checkout Page',
      contactInformation: isArabic ? 'معلومات الاتصال' : 'Contact Information',
      fullName: isArabic ? 'الاسم الكامل' : 'Full Name',
      email: isArabic ? 'البريد الإلكتروني' : 'Email',
      phone: isArabic ? 'الهاتف' : 'Phone',
      shippingAddress: isArabic ? 'عنوان الشحن' : 'Shipping Address',
      address: isArabic ? 'العنوان' : 'Address',
      city: isArabic ? 'المدينة' : 'City',
      zipCode: isArabic ? 'الرمز البريدي' : 'Zip Code',
      selectLocation: isArabic ? 'اختر الموقع' : 'Select location',
      paymentMethod: isArabic ? 'طريقة الدفع' : 'Payment Method',
      creditCard: isArabic ? 'بطاقة ائتمان' : 'Credit Card',
      cashOnDelivery: isArabic ? 'الدفع عند الاستلام' : 'Cash on Delivery',
      cardNumber: isArabic ? 'رقم البطاقة' : 'Card Number',
      expiryDate: isArabic ? 'تاريخ انتهاء الصلاحية' : 'Expiry Date',
      cvv: isArabic ? 'رمز الأمان' : 'CVV',
      orderSummary: isArabic ? 'ملخص الطلب' : 'Order Summary',
      subtotal: isArabic ? 'المجموع الفرعي' : 'Subtotal',
      serviceFees: isArabic ? 'رسوم الخدمة' : 'Service Fees',
      total: isArabic ? 'المجموع' : 'Total',
      placeOrder: isArabic ? 'إتمام الطلب' : 'Place Order',
      processing: isArabic ? 'جاري المعالجة...' : 'Processing...',
      agreeTermsConditions: isArabic
          ? 'بإتمام هذا الطلب، أنت توافق على الشروط والأحكام'
          : 'By placing this order, you agree to our terms and conditions',
      pleaseSelectPaymentMethod: isArabic
          ? 'يرجى اختيار طريقة الدفع'
          : 'Please select a payment method',
      pleaseFillContactInfo: isArabic
          ? 'يرجى ملء جميع حقول معلومات الاتصال'
          : 'Please fill in all contact information fields',
      pleaseFillShippingAddress: isArabic
          ? 'يرجى ملء جميع حقول عنوان الشحن'
          : 'Please fill in all shipping address fields',
      pleaseFillCardDetails: isArabic
          ? 'يرجى ملء جميع تفاصيل البطاقة الائتمانية'
          : 'Please fill in all credit card details',
    );
  }
}
