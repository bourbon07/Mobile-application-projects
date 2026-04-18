import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/notification_store.dart';

/// ToastOptions - Options for toast notifications
///
/// Optional configuration for toast notifications.
/// Currently matches Vue's options parameter structure.
class ToastOptions {
  final int? duration;
  final Map<String, dynamic>? additionalData;

  const ToastOptions({this.duration, this.additionalData});
}

/// ToastService - Toast notification service
///
/// Equivalent to Vue's useToast composable.
/// Provides a simple API for showing toast notifications.
///
/// Usage:
/// ```dart
/// // In a ConsumerWidget or ConsumerStatefulWidget
/// final toast = ToastService(ref);
/// toast.success('Operation completed!');
/// ```
class ToastService {
  final WidgetRef ref;

  /// Create a ToastService instance
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing providers)
  ToastService(this.ref);

  /// Toast object with notification methods
  ///
  /// Equivalent to Vue's toast object returned by useToast()
  Toast get toast => Toast._(ref);
}

/// Toast - Toast notification helper
///
/// Provides methods for showing different types of toast notifications.
/// Equivalent to Vue's toast object.
class Toast {
  final WidgetRef _ref;

  Toast._(this._ref);

  /// Get the notification store notifier
  NotificationStoreNotifier get _store {
    return _ref.read(notificationStoreProvider.notifier);
  }

  /// Show success notification
  ///
  /// [message] - Success message to display
  /// [options] - Optional toast options (currently unused, matches Vue API)
  /// Returns notification ID
  ///
  /// Equivalent to Vue's toast.success()
  int success(String message, [ToastOptions? options]) {
    return _store.success(message);
  }

  /// Show error notification
  ///
  /// [message] - Error message to display
  /// [options] - Optional toast options (currently unused, matches Vue API)
  /// Returns notification ID
  ///
  /// Equivalent to Vue's toast.error()
  int error(String message, [ToastOptions? options]) {
    return _store.error(message);
  }

  /// Show warning notification
  ///
  /// [message] - Warning message to display
  /// [options] - Optional toast options (currently unused, matches Vue API)
  /// Returns notification ID
  ///
  /// Equivalent to Vue's toast.warning()
  int warning(String message, [ToastOptions? options]) {
    return _store.warning(message);
  }

  /// Show info notification
  ///
  /// [message] - Info message to display
  /// [options] - Optional toast options (currently unused, matches Vue API)
  /// Returns notification ID
  ///
  /// Note: In the Vue composable, info calls success().
  /// This implementation calls info() on the store for proper type handling.
  /// Equivalent to Vue's toast.info()
  int info(String message, [ToastOptions? options]) {
    // Vue composable calls success() for info, but we use info() for proper type
    return _store.info(message);
  }
}

/// ToastServiceHelper - Static helper for toast notifications
///
/// Provides static methods for showing toasts without creating a ToastService instance.
/// Useful for use outside of widgets or in utility functions.
///
/// Usage:
/// ```dart
/// ToastServiceHelper.success(ref, 'Operation completed!');
/// ```
class ToastServiceHelper {
  ToastServiceHelper._();

  /// Show success notification
  ///
  /// [ref] - WidgetRef from Riverpod
  /// [message] - Success message
  /// [options] - Optional toast options
  /// Returns notification ID
  static int success(WidgetRef ref, String message, [ToastOptions? options]) {
    return ref.read(notificationStoreProvider.notifier).success(message);
  }

  /// Show error notification
  ///
  /// [ref] - WidgetRef from Riverpod
  /// [message] - Error message
  /// [options] - Optional toast options
  /// Returns notification ID
  static int error(WidgetRef ref, String message, [ToastOptions? options]) {
    return ref.read(notificationStoreProvider.notifier).error(message);
  }

  /// Show warning notification
  ///
  /// [ref] - WidgetRef from Riverpod
  /// [message] - Warning message
  /// [options] - Optional toast options
  /// Returns notification ID
  static int warning(WidgetRef ref, String message, [ToastOptions? options]) {
    return ref.read(notificationStoreProvider.notifier).warning(message);
  }

  /// Show info notification
  ///
  /// [ref] - WidgetRef from Riverpod
  /// [message] - Info message
  /// [options] - Optional toast options
  /// Returns notification ID
  static int info(WidgetRef ref, String message, [ToastOptions? options]) {
    return ref.read(notificationStoreProvider.notifier).info(message);
  }
}


