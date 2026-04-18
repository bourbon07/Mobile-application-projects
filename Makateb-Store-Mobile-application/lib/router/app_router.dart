import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../core/widgets/navbar.dart';
import '../core/widgets/notification_toast.dart';
import '../core/widgets/error_widget.dart';
import '../core/widgets/app_layout.dart';
// import '../core/widgets/notification_panel.dart'; // Removed unused import
import '../core/widgets/wood_button.dart';
import '../core/widgets/product_card.dart' show ProductData;
import '../core/widgets/package_card.dart' show PackageData;
import '../core/services/locale_service.dart';
import '../core/services/http_config_service.dart';
import '../core/stores/auth_store.dart';
import '../core/stores/language_store.dart';
import '../core/stores/cart_store.dart';
import '../core/stores/wishlist_store.dart';
import '../core/localization/localization_service.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_services/profile_api_service.dart';
import '../core/services/api_services/cloudinary_api_service.dart';
import '../core/services/api_services/order_api_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/blocked_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/dashboard_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/wishlist/wishlist_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/orders/order_details_screen.dart';
import '../features/product/product_screen.dart';
import '../features/product/category_screen.dart';
import '../features/package/packages_screen.dart';
import '../features/package/package_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chat_window_screen.dart';
import '../features/chat/chat_room_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/view_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/search/search_screen.dart';

/// AppRouter - Flutter routing configuration
///
/// Equivalent to Vue Router configuration.
/// Maps all Vue routes to Flutter screens using GoRouter.
///
/// Route names and paths are preserved from Vue Router.
/// Route guards are NOT implemented yet (as per requirements).
class AppRouter {
  AppRouter._();

  /// GoRouter instance
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Redirect root to splash
      GoRoute(path: '/', redirect: (context, state) => '/splash'),

      // Shell route that wraps all routes with AppLayout
      // This provides the navbar, global overlays, and initialization logic
      ShellRoute(
        builder: (context, state, child) {
          // Determine if navbar should be shown based on route
          // Some routes like login might not need navbar
          final showNavbar = state.uri.path != '/login';

          return AppLayoutWrapper(showNavbar: showNavbar, child: child);
        },
        routes: [
          // Login (no navbar)
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) {
              return _LoginScreenWrapper();
            },
          ),

          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => DashboardScreen(
              onProductTap: (id) => context.push('/product/$id'),
              onPackageTap: (id) => context.push('/package/$id'),
              onCartTap: () => context.push('/cart'),
            ),
          ),

          // Cart
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  return CartScreen(
                    onUpdateQuantity: (itemId, quantity) async {
                      // Cart screen handles API call internally
                    },
                    onRemoveItem: (itemId) async {
                      // Cart screen handles API call internally
                    },
                    onCheckout: () => context.push('/checkout'),
                    onProductTap: (productId) =>
                        context.push('/product/$productId'),
                    onPackageTap: (packageId) =>
                        context.push('/package/$packageId'),
                    onStartShopping: () => context.go('/dashboard'),
                    getLocalizedName: (item) {
                      if (item is ProductData) {
                        // Use name directly (translation handled by backend)
                        return item.name;
                      }
                      if (item is PackageData) {
                        final translatePackageName = ref.read(
                          translatePackageNameProvider,
                        );
                        return translatePackageName(item.name);
                      }
                      return '';
                    },
                    formatPrice: (price) => price.toStringAsFixed(2),
                  );
                },
              );
            },
          ),

          // Checkout
          GoRoute(
            path: '/checkout',
            name: 'checkout',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final cartState = ref.watch(cartStoreProvider);
                  final l10n = AppLocalizations.of(context);
                  final orderApi = LaravelOrderApiService();

                  return CheckoutScreen(
                    cartItems: cartState.items
                        .map(
                          (item) => CheckoutCartItemData(
                            id: item.id,
                            quantity: item.quantity,
                            product: item.product != null
                                ? CheckoutProductData(
                                    id: item.product!.id,
                                    name: item.product!.name,
                                    price: item.product!.price,
                                  )
                                : null,
                            package: item.package != null
                                ? CheckoutPackageData(
                                    id: item.package!.id,
                                    price: item.package!.price,
                                  )
                                : null,
                          ),
                        )
                        .toList(),
                    loading: cartState.isLoading,
                    onPlaceOrder: (formData) async {
                      try {
                        // Prepare items for API
                        final items = cartState.items.map((item) {
                          final map = <String, dynamic>{'qty': item.quantity};
                          if (item.productId != null) {
                            map['product_id'] = item.productId;
                          } else if (item.packageId != null) {
                            map['package_id'] = item.packageId;
                          }
                          return map;
                        }).toList();

                        if (items.isEmpty) {
                          NotificationToastService.instance.showError(
                            l10n.translate('cart_empty'),
                          );
                          return;
                        }

                        // Call API
                        final result = await orderApi.createOrder(
                          customerName: formData.customerName,
                          customerEmail: formData.customerEmail,
                          customerPhone: formData.customerPhone,
                          deliveryLocation: formData.deliveryLocation,
                          feeLocation: formData.city,
                          paymentMethod: formData.paymentMethod,
                          items: items,
                          cardDetails: formData.cardDetails != null
                              ? {
                                  'cardNumber':
                                      formData.cardDetails!.cardNumber,
                                  'expiryDate':
                                      formData.cardDetails!.expiryDate,
                                  'cvv': formData.cardDetails!.cvv,
                                }
                              : null,
                        );

                        // Clear cart
                        await ref.read(cartStoreProvider.notifier).clear();

                        // Show success and redirect
                        if (context.mounted) {
                          final paymentUrl = result['payment_url']?.toString();

                          if (paymentUrl != null && paymentUrl.isNotEmpty) {
                            NotificationToastService.instance.showSuccess(
                              l10n.translate('redirecting_to_payment'),
                            );

                            final uri = Uri.parse(paymentUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              NotificationToastService.instance.showError(
                                l10n.translate('could_not_open_payment_url'),
                              );
                            }
                          } else {
                            final msg =
                                result['message']?.toString() ??
                                l10n.translate('order_placed_successfully');
                            NotificationToastService.instance.showSuccess(msg);
                            context.go('/orders');
                          }
                        }
                      } catch (e) {
                        // Extract error message from exception
                        String errorMessage = l10n.translate(
                          'failed_to_place_order',
                        );

                        if (e.toString().contains('Exception:')) {
                          errorMessage = e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                        } else {
                          errorMessage = '$errorMessage: ${e.toString()}';
                        }

                        NotificationToastService.instance.showError(
                          errorMessage,
                        );
                      }
                    },
                    onStartShopping: () => context.go('/dashboard'),
                  );
                },
              );
            },
          ),

          // Wishlist
          GoRoute(
            path: '/wishlist',
            name: 'wishlist',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  return WishlistScreen(
                    onBrowseProducts: () => context.go('/dashboard'),
                    onViewProduct: (productId) =>
                        context.push('/product/$productId'),
                    onViewPackage: (packageId) =>
                        context.push('/package/$packageId'),
                  );
                },
              );
            },
          ),

          // Orders
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authStoreProvider);
                  final currentUser = authState.user;
                  return OrdersScreen(
                    user: currentUser != null
                        ? OrdersUserData(
                            id: currentUser.id,
                            name: currentUser.name,
                            email: currentUser.email,
                          )
                        : null,
                    onSignIn: () => context.go('/login'),
                    onReorder: (order) async {
                      final l10n = AppLocalizations.of(context);
                      final cartStore = ref.read(cartStoreProvider.notifier);
                      int successCount = 0;

                      NotificationToastService.instance.showSuccess(
                        l10n.translate('adding_to_cart'),
                      );

                      for (final item in order.items) {
                        bool success = false;
                        if (item.productId != null) {
                          success = await cartStore.addProduct(
                            item.productId!,
                            quantity: item.qty,
                          );
                        } else if (item.packageId != null) {
                          success = await cartStore.addPackage(
                            item.packageId!,
                            quantity: item.qty,
                          );
                        }
                        if (success) successCount++;
                      }

                      if (successCount > 0) {
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('items_added_to_cart'),
                        );
                        if (!context.mounted) return;
                        context.push('/cart');
                      } else {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_add_to_cart'),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),

          // Order Details
          GoRoute(
            path: '/orders/:id',
            name: 'order-details',
            builder: (context, state) {
              final orderId = state.pathParameters['id'];
              return OrderDetailsScreen(orderId: orderId);
            },
          ),

          // Product
          GoRoute(
            path: '/product/:id',
            name: 'product',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context);

              return Consumer(
                builder: (context, ref, _) {
                  return ProductScreen(
                    productId: productId,
                    onAddToCart: () async {
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
                          l10n.translate('failed_to_add_to_cart') +
                              (error != null ? ': `$error`' : ''),
                        );
                      }
                    },
                    onToggleWishlist: () async {
                      final wishlistStore = ref.read(
                        wishlistStoreProvider.notifier,
                      );
                      final isInWishlist = await wishlistStore
                          .isProductInWishlist(productId);
                      if (isInWishlist) {
                        final success = await wishlistStore.removeProduct(
                          productId,
                        );
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('removed_from_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      } else {
                        final success = await wishlistStore.addProduct(
                          productId,
                        );
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('added_to_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),

          // Packages
          GoRoute(
            path: '/packages',
            name: 'packages',
            builder: (context, state) {
              final l10n = AppLocalizations.of(context);

              return Consumer(
                builder: (context, ref, _) {
                  return PackagesScreen(
                    onAddToCart: (packageId) async {
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
                          l10n.translate('failed_to_add_to_cart') +
                              (error != null ? ': `$error`' : ''),
                        );
                      }
                    },
                    onToggleWishlist: (packageId) async {
                      final wishlistStore = ref.read(
                        wishlistStoreProvider.notifier,
                      );
                      final isInWishlist = await wishlistStore
                          .isPackageInWishlist(packageId);
                      if (isInWishlist) {
                        final success = await wishlistStore.removePackage(
                          packageId,
                        );
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('removed_from_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      } else {
                        final success = await wishlistStore.addPackage(
                          packageId,
                        );
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('added_to_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      }
                    },
                    onPackageTap: (packageId) =>
                        context.push('/package/$packageId'),
                  );
                },
              );
            },
          ),

          // Package Details
          GoRoute(
            path: '/package/:id',
            name: 'package',
            builder: (context, state) {
              final packageId = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context);

              return Consumer(
                builder: (context, ref, _) {
                  return PackageScreen(
                    packageId: packageId,
                    addingToCart: ref.watch(cartStoreProvider).isLoading,
                    onAddToCart: (id, quantity) async {
                      final success = await ref
                          .read(cartStoreProvider.notifier)
                          .addPackage(id, quantity: quantity);
                      if (success) {
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('package_added_to_cart'),
                        );
                      } else {
                        final error = ref.read(cartStoreProvider).error;
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_add_to_cart') +
                              (error != null ? ': `$error`' : ''),
                        );
                      }
                    },
                    onToggleWishlist: (id) async {
                      final wishlistStore = ref.read(
                        wishlistStoreProvider.notifier,
                      );
                      final isInWishlist = await wishlistStore
                          .isPackageInWishlist(id);
                      if (isInWishlist) {
                        final success = await wishlistStore.removePackage(id);
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('removed_from_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      } else {
                        final success = await wishlistStore.addPackage(id);
                        if (success) {
                          NotificationToastService.instance.showSuccess(
                            l10n.translate('added_to_wishlist'),
                          );
                        } else {
                          final error = ref.read(wishlistStoreProvider).error;
                          NotificationToastService.instance.showError(
                            l10n.translate('failed_to_update_wishlist') +
                                (error != null ? ': `$error`' : ''),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),

          // Chat
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authStoreProvider);
                  final currentUser = authState.user;
                  final isAuthenticated = authState.isAuthenticated;
                  return ChatScreen(
                    user: currentUser != null
                        ? ChatUserData(
                            id: currentUser.id,
                            name: currentUser.name,
                            email: currentUser.email,
                            avatarUrl: null,
                            isOnline: true,
                          )
                        : null,
                    isGuestMode: !isAuthenticated,
                    onLoginTap: () => context.go('/login'),
                  );
                },
              );
            },
          ),

          // Chat Window (Private chat with user)
          GoRoute(
            path: '/chat/:userId',
            name: 'chat-user',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return ChatWindowScreen(initialConversationId: userId);
            },
          ),

          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authStoreProvider);
                  final currentUser = authState.user;
                  final authStore = ref.read(authStoreProvider.notifier);
                  final additionalData = currentUser?.additionalData ?? {};
                  final profileApi = LaravelProfileApiService();
                  final cloudinaryApi = LaravelCloudinaryApiService();

                  return ProfileScreen(
                    user: currentUser != null
                        ? ProfileUserData(
                            id: currentUser.id,
                            name: currentUser.name,
                            email: currentUser.email,
                            firstName: currentUser.name.split(' ').first,
                            lastName: currentUser.name.split(' ').length > 1
                                ? currentUser.name.split(' ').skip(1).join(' ')
                                : '',
                            avatarUrl:
                                (additionalData['avatarUrl'] ??
                                        additionalData['avatar_url'])
                                    as String?,
                            bio: additionalData['bio'] as String?,
                            phone: additionalData['phone'] as String?,
                            location: additionalData['location'] as String?,
                          )
                        : null,
                    profile: currentUser != null
                        ? ProfileData(
                            avatarUrl:
                                (additionalData['avatarUrl'] ??
                                        additionalData['avatar_url'])
                                    as String?,
                            bio: additionalData['bio'] as String?,
                            phone: additionalData['phone'] as String?,
                            location: additionalData['location'] as String?,
                            isPrivate:
                                (additionalData['isPrivate'] ??
                                        additionalData['is_private'])
                                    as bool? ??
                                false,
                          )
                        : null,
                    onSignIn: () => context.go('/login'),
                    onSave: (profileData) async {
                      final l10n = AppLocalizations.of(context);
                      try {
                        // Persist to backend
                        await profileApi.updateProfile(
                          bio: profileData.bio,
                          phone: profileData.phone,
                          location: profileData.location,
                          isPrivate: profileData.isPrivate,
                        );
                        // Refresh local auth user so changes reflect everywhere
                        await authStore.fetchUser();
                        await authStore.updateUser(
                          bio: profileData.bio,
                          phone: profileData.phone,
                          location: profileData.location,
                          isPrivate: profileData.isPrivate,
                        );
                        // Show success notification
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('profile_updated_successfully'),
                        );
                      } catch (e) {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_update_profile'),
                        );
                      }
                    },
                    onAvatarUpdate: (imageUrl) async {
                      final l10n = AppLocalizations.of(context);
                      try {
                        await profileApi.updateAvatarUrl(imageUrl);
                        await authStore.fetchUser();
                        await authStore.updateUser(avatarUrl: imageUrl);
                        // Show success notification
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('avatar_updated_successfully'),
                        );
                      } catch (e) {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_update_avatar'),
                        );
                      }
                    },
                    onFetchCloudinaryImages: () => cloudinaryApi.fetchImages(),
                    onUploadToCloudinary:
                        ({source, fileBytes, fileName}) async {
                          if (fileBytes != null) {
                            // Priority 1: Direct binary data (works on Web)
                            return cloudinaryApi.uploadFile(
                              fileBytes: fileBytes,
                              fileName: fileName,
                            );
                          }

                          if (source != null && source.isNotEmpty) {
                            // Priority 2: URL or File Path
                            if (source.startsWith('http://') ||
                                source.startsWith('https://')) {
                              return cloudinaryApi.uploadFromUrl(source);
                            } else {
                              return cloudinaryApi.uploadFile(filePath: source);
                            }
                          }
                          return null;
                        },
                  );
                },
              );
            },
          ),

          // View Profile (Other user's profile)
          GoRoute(
            path: '/profile/:userId',
            name: 'view-profile',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return ViewProfileScreen(userId: userId);
            },
          ),

          // Blocked
          GoRoute(
            path: '/blocked',
            name: 'blocked',
            builder: (context, state) => const BlockedScreen(),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authStoreProvider);
                  final currentUser = authState.user;
                  return SettingsScreen(
                    user: currentUser != null
                        ? SettingsUserData(
                            id: currentUser.id,
                            name: currentUser.name,
                            email: currentUser.email,
                          )
                        : null,
                    selectedLanguage: ref.watch(currentLanguageProvider),
                    onSignIn: () => context.go('/login'),
                    onSavePersonalInfo: (data) async {
                      final l10n = AppLocalizations.of(context);
                      final authStore = ref.read(authStoreProvider.notifier);
                      final profileApi = LaravelProfileApiService();
                      try {
                        final fullName =
                            '${data.firstName.trim()} ${data.lastName.trim()}'
                                .trim();
                        // Persist to backend
                        await profileApi.updateProfile(
                          name: fullName,
                          email: data.email.trim(),
                        );
                        await authStore.fetchUser();
                        // Update user in auth store with new name and email
                        await authStore.updateUser(
                          name: fullName,
                          email: data.email.trim(),
                        );
                        // Show success notification
                        NotificationToastService.instance.showSuccess(
                          l10n.translate(
                            'basic_information_updated_successfully',
                          ),
                        );
                      } catch (e) {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_update_profile'),
                        );
                      }
                    },
                    onChangePassword: (data) async {
                      final l10n = AppLocalizations.of(context);
                      final profileApi = LaravelProfileApiService();
                      try {
                        await profileApi.changePassword(
                          data.currentPassword,
                          data.password,
                        );
                        // Show success notification
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('password_changed_successfully'),
                        );
                      } catch (e) {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_change_password'),
                        );
                      }
                    },
                    onLanguageChanged: (language) {
                      final languageStore = ref.read(
                        languageStoreProvider.notifier,
                      );
                      languageStore.setLanguage(language);
                    },
                    onDeleteAccount: () async {
                      final l10n = AppLocalizations.of(context);
                      // Mock implementation - in real app, call API
                      final authStore = ref.read(authStoreProvider.notifier);
                      try {
                        // Simulate API call
                        await Future.delayed(const Duration(seconds: 1));
                        // Logout user
                        await authStore.logout();
                        if (!context.mounted) return;
                        // Show success notification
                        NotificationToastService.instance.showSuccess(
                          l10n.translate('account_deleted_successfully'),
                        );
                        // Navigate to dashboard
                        context.go('/dashboard');
                      } catch (e) {
                        NotificationToastService.instance.showError(
                          l10n.translate('failed_to_delete_account'),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),

          // Search
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) {
              // Extract query parameter if present
              final query = state.uri.queryParameters['q'];
              return SearchScreen(
                initialQuery: query,
                onProductTap: (productId) {
                  context.pushNamed(
                    AppRouteNames.product,
                    pathParameters: {'id': productId},
                  );
                },
              );
            },
          ),

          // Category
          GoRoute(
            path: '/category/:id',
            name: 'category',
            builder: (context, state) {
              final categoryId = state.pathParameters['id']!;
              return CategoryScreen(categoryId: categoryId);
            },
          ),

          // Chat Room
          GoRoute(
            path: '/chat-room',
            name: 'chat-room',
            builder: (context, state) => const ChatRoomScreen(),
          ),

          // Block List
          GoRoute(
            path: '/block-list',
            name: 'block-list',
            builder: (context, state) {
              // NOTE: Implement BlockListScreen when available in future updates
              return const Scaffold(
                body: Center(child: Text('Block List - Coming Soon')),
              );
            },
          ),

          // Admin routes removed (customer-only app)
        ],
      ),
    ],
    errorBuilder: (context, state) {
      // Router error handler - equivalent to router.onError
      debugPrint('Router error: ${state.error}');
      debugPrint('Error loading route: ${state.uri}');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: AppTheme.spacingLG),
              Text(
                'Route Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: AppTheme.spacingSM),
              Text(
                'Failed to load: ${state.uri}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacingXL),
              WoodButton(
                onPressed: () => context.go('/dashboard'),
                size: WoodButtonSize.md,
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// AppLayoutWrapper - Wraps routes with AppLayout functionality
///
/// This widget provides the initialization, navbar, and global overlays
/// that AppLayout provides, but works with GoRouter's ShellRoute.
class AppLayoutWrapper extends ConsumerStatefulWidget {
  final bool showNavbar;
  final Widget child;

  const AppLayoutWrapper({
    super.key,
    required this.showNavbar,
    required this.child,
  });

  @override
  ConsumerState<AppLayoutWrapper> createState() => _AppLayoutWrapperState();
}

class _AppLayoutWrapperState extends ConsumerState<AppLayoutWrapper> {
  // Track initialization state
  bool _isInitialized = false;
  Object? _initializationError;

  // Track last back press for double-click to exit
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupLocaleListener();
  }

  @override
  void dispose() {
    LocaleService.instance.localeNotifier?.removeListener(_onLocaleChanged);
    super.dispose();
  }

  /// Setup locale change listener
  void _setupLocaleListener() {
    LocaleService.instance.localeNotifier?.addListener(_onLocaleChanged);
  }

  /// Handle locale changes
  void _onLocaleChanged() {
    final currentLang = LocaleService.instance.currentLanguageCode;
    HttpConfigService.instance.setLanguage(currentLang);
    if (mounted) {
      setState(() {});
    }
  }

  /// Initialize the application
  Future<void> _initializeApp() async {
    try {
      final storage = LocaleService.instance;
      if (storage.currentLanguageCode.isEmpty) {
        await storage.setLanguage('ar');
      } else {
        final currentLang = storage.currentLanguageCode;
        await HttpConfigService.instance.setLanguage(currentLang);
      }

      final token = HttpConfigService.instance.authToken;
      if (token != null) {
        debugPrint('Session token found, user session restored');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('App initialization error: $error');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _initializationError = error;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error UI if initialization failed
    if (_initializationError != null) {
      return AppErrorWidget(
        error: _initializationError!,
        onRetry: () {
          setState(() {
            _initializationError = null;
            _isInitialized = false;
          });
          _initializeApp();
        },
      );
    }

    // Show loading state during initialization
    if (!_isInitialized) {
      return const AppLoadingWidget();
    }

    // Get dark mode state from auth store
    final isDarkMode = ref.watch(authDarkModeProvider);
    final authStore = ref.read(authStoreProvider.notifier);
    final authState = ref.watch(authStoreProvider);
    final currentUser = authState.user;

    // Watch language changes
    final currentLanguage = ref.watch(currentLanguageProvider);

    // Get current locale for RTL/LTR direction - use LocalizationService for reactive updates
    final localeService = LocalizationService();

    // Watch counts from stores
    final cartCount = ref.watch(cartCountProvider);
    final wishlistCount = ref.watch(wishlistStoreProvider).itemCount;

    // Watch locale changes to update RTL direction immediately
    return ValueListenableBuilder<Locale>(
      valueListenable: localeService.localeNotifier,
      builder: (context, locale, _) {
        final isRTLDirection = locale.languageCode == 'ar';

        // Main app content with navbar and overlays
        return Directionality(
          textDirection: isRTLDirection ? TextDirection.rtl : TextDirection.ltr,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final router = GoRouter.of(context);
              final currentPath =
                  router.routeInformationProvider.value.uri.path;

              // If on dashboard, handle double-click to exit
              if (currentPath == '/dashboard') {
                final now = DateTime.now();
                if (_lastBackPressTime == null ||
                    now.difference(_lastBackPressTime!) >
                        const Duration(seconds: 2)) {
                  _lastBackPressTime = now;

                  // Show "Press back again to exit" toast
                  final isArabic = currentLanguage == 'ar';
                  NotificationToastService.instance.showInfo(
                    isArabic
                        ? 'اضغط مرة أخرى للخروج'
                        : 'Press back again to exit',
                  );
                  return;
                }
                // Close the application
                await SystemChannels.platform.invokeMethod(
                  'SystemNavigator.pop',
                );
              } else {
                // Not on dashboard: try to go back
                if (router.canPop()) {
                  router.pop();
                } else {
                  // If no history, navigate to dashboard instead of closing
                  router.go('/dashboard');
                }
              }
            },
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                top: true,
                child: Column(
                  children: [
                    // Notification Panel at the very top
                    // Notification Panel removed to avoid duplicates (using NotificationToast instead)
                    // const NotificationPanel(),

                    // Navbar below the Notification Panel
                    if (widget.showNavbar)
                      Navbar(
                        woodTexturePath:
                            'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png',
                        user: currentUser != null
                            ? NavbarUser(
                                name: currentUser.name,
                                // Customer-only: don't expose admin/role UX.
                                role: 'customer',
                              )
                            : null,
                        cartCount: cartCount,
                        wishlistCount: wishlistCount,
                        unreadMessageCount:
                            0, // NOTE: Get from chat store when available
                        onLogoTap: () => context.go('/dashboard'),
                        onSearch: (query) {
                          context.push('/search?q=$query');
                        },
                        onLanguageToggle: () {
                          // Use language store for language switching
                          final languageStore = ref.read(
                            languageStoreProvider.notifier,
                          );
                          final newLang = currentLanguage == 'ar' ? 'en' : 'ar';
                          languageStore.setLanguage(newLang);
                        },
                        onDarkModeToggle: () {
                          // Toggle dark mode using auth store
                          authStore.toggleDarkMode();
                        },
                        isDarkMode: isDarkMode,
                        onChatTap: () => context.push('/chat'),
                        onWishlistTap: () => context.push('/wishlist'),
                        onCartTap: () => context.push('/cart'),
                        onProfileTap: () => context.push('/profile'),
                        onOrdersTap: () => context.push('/orders'),
                        onSettingsTap: () => context.push('/settings'),
                        onLoginTap: () => context.push('/login'),
                        onLogoutTap: () async {
                          // Call logout - state update happens synchronously in the fixed copyWith
                          // This will trigger an immediate rebuild of AppLayoutWrapper
                          await authStore.logout();

                          // After state update, clear other stores if needed
                          ref.read(cartStoreProvider.notifier).loadCart();
                          ref
                              .read(wishlistStoreProvider.notifier)
                              .loadWishlist();

                          // Navigate to dashboard if not already there
                          if (context.mounted) {
                            context.go('/dashboard');
                          }
                        },
                        currentLanguage: currentLanguage,
                      ),

                    // Content area
                    Expanded(
                      child: Stack(
                        children: [
                          // Main content (router view)
                          widget.child,
                          // Global overlay widgets (toasts still floating if needed,
                          // but they will appear over the body content)
                          const NotificationToast(),
                        ],
                      ),
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

/// Login loading state provider
final _loginLoadingProvider = StateProvider<bool>((ref) => false);

/// Login error state provider
final _loginErrorProvider = StateProvider<String?>((ref) => null);

/// Login Screen Wrapper - Handles login/register logic
class _LoginScreenWrapper extends ConsumerStatefulWidget {
  const _LoginScreenWrapper();

  @override
  ConsumerState<_LoginScreenWrapper> createState() =>
      _LoginScreenWrapperState();
}

class _LoginScreenWrapperState extends ConsumerState<_LoginScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    final authStore = ref.read(authStoreProvider.notifier);
    final isLoading = ref.watch(_loginLoadingProvider);
    final error = ref.watch(_loginErrorProvider);

    return LoginScreen(
      loading: isLoading,
      error: error,
      onLogin: (email, password) async {
        ref.read(_loginLoadingProvider.notifier).state = true;
        ref.read(_loginErrorProvider.notifier).state = null;
        try {
          await authStore.login({'email': email, 'password': password});
          // Sync guest data after successful login
          await ref.read(cartStoreProvider.notifier).syncGuest();
          await ref.read(wishlistStoreProvider.notifier).syncGuest();

          // Navigate to dashboard on success
          if (context.mounted) {
            context.go('/dashboard');
          }
        } catch (e) {
          ref.read(_loginErrorProvider.notifier).state = e
              .toString()
              .replaceAll('Exception: ', '');
        } finally {
          if (mounted) {
            ref.read(_loginLoadingProvider.notifier).state = false;
          }
        }
      },
      onRegister: (name, email, password, passwordConfirmation) async {
        ref.read(_loginLoadingProvider.notifier).state = true;
        ref.read(_loginErrorProvider.notifier).state = null;
        try {
          await authStore.register({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          });
          // Show success message
          if (!context.mounted) return;
          final currentLang = ref.read(currentLanguageProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentLang == 'ar'
                    ? 'تم إنشاء الحساب بنجاح!'
                    : 'Account created successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Sync guest data after successful registration
          await ref.read(cartStoreProvider.notifier).syncGuest();
          await ref.read(wishlistStoreProvider.notifier).syncGuest();

          // Navigate to dashboard on success
          if (!context.mounted) return;
          context.go('/dashboard');
        } catch (e) {
          ref.read(_loginErrorProvider.notifier).state = e
              .toString()
              .replaceAll('Exception: ', '');
        } finally {
          if (mounted) {
            ref.read(_loginLoadingProvider.notifier).state = false;
          }
        }
      },
      onClose: () {
        context.go('/dashboard');
      },
      onContinueAsGuest: () {
        context.go('/dashboard');
      },
    );
  }
}

/// Route names constants
/// These match the Vue Router route names for easy reference
class AppRouteNames {
  AppRouteNames._();

  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String cart = 'cart';
  static const String checkout = 'checkout';
  static const String wishlist = 'wishlist';
  static const String orders = 'orders';
  static const String orderDetails = 'order-details';
  static const String product = 'product';
  static const String packages = 'packages';
  static const String package = 'package';
  static const String chat = 'chat';
  static const String chatUser = 'chat-user';
  static const String profile = 'profile';
  static const String viewProfile = 'view-profile';
  static const String blocked = 'blocked';
  static const String settings = 'settings';
  static const String search = 'search';
  static const String category = 'category';
  static const String chatRoom = 'chat-room';
  static const String blockList = 'block-list';
}
