import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/notification_store.dart';

/// NotificationTypeString - String representation of notification types
///
/// Used for type parameter in showNotification and notify functions.
/// Equivalent to Vue's notification type union type.
enum NotificationTypeString {
  success,
  error,
  warning,
}

/// NotificationsHelper - Helper functions for showing notifications
///
/// Equivalent to Vue's notifications.js utility file.
/// Provides helper functions to show notifications instead of browser alerts.
class NotificationsHelper {
  NotificationsHelper._();

  /// Show notification
  ///
  /// Equivalent to Vue's showNotification() function.
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing stores)
  /// [message] - The message to display
  /// [type] - The notification type ('success', 'error', 'warning')
  /// Returns notification ID
  ///
  /// Example:
  /// ```dart
  /// NotificationsHelper.showNotification(
  ///   ref,
  ///   'Operation completed!',
  ///   NotificationTypeString.success,
  /// );
  /// ```
  static int showNotification(
    WidgetRef ref,
    String message, [
    NotificationTypeString type = NotificationTypeString.success,
  ]) {
    final notificationStore = ref.read(notificationStoreProvider.notifier);

    switch (type) {
      case NotificationTypeString.success:
        return notificationStore.success(message);
      case NotificationTypeString.error:
        return notificationStore.error(message);
      case NotificationTypeString.warning:
        return notificationStore.warning(message);
    }
  }

  /// Notify - Drop-in replacement for alert()
  ///
  /// Equivalent to Vue's notify() function.
  /// This function can be used as a drop-in replacement for alert().
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing stores)
  /// [message] - The message to display
  /// [type] - The notification type ('success', 'error', 'warning')
  /// Returns notification ID
  ///
  /// Example:
  /// ```dart
  /// NotificationsHelper.notify(
  ///   ref,
  ///   'Something went wrong!',
  ///   NotificationTypeString.error,
  /// );
  /// ```
  static int notify(
    WidgetRef ref,
    String message, [
    NotificationTypeString type = NotificationTypeString.success,
  ]) {
    return showNotification(ref, message, type);
  }

  /// Show notification with string type
  ///
  /// Convenience method that accepts string type parameter.
  /// Equivalent to Vue's showNotification() with string type.
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing stores)
  /// [message] - The message to display
  /// [type] - The notification type as string ('success', 'error', 'warning')
  /// Returns notification ID
  ///
  /// Example:
  /// ```dart
  /// NotificationsHelper.showNotificationString(
  ///   ref,
  ///   'Operation completed!',
  ///   'success',
  /// );
  /// ```
  static int showNotificationString(
    WidgetRef ref,
    String message, [
    String type = 'success',
  ]) {
    final notificationStore = ref.read(notificationStoreProvider.notifier);

    switch (type.toLowerCase()) {
      case 'success':
        return notificationStore.success(message);
      case 'error':
        return notificationStore.error(message);
      case 'warning':
        return notificationStore.warning(message);
      default:
        // Default to success (matches Vue behavior)
        return notificationStore.success(message);
    }
  }

  /// Notify with string type
  ///
  /// Convenience method that accepts string type parameter.
  /// Equivalent to Vue's notify() with string type.
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing stores)
  /// [message] - The message to display
  /// [type] - The notification type as string ('success', 'error', 'warning')
  /// Returns notification ID
  ///
  /// Example:
  /// ```dart
  /// NotificationsHelper.notifyString(
  ///   ref,
  ///   'Something went wrong!',
  ///   'error',
  /// );
  /// ```
  static int notifyString(
    WidgetRef ref,
    String message, [
    String type = 'success',
  ]) {
    return showNotificationString(ref, message, type);
  }
}



