import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NotificationType - Notification type enum
enum NotificationType { success, error, warning, info }

/// NotificationModel - Notification data model
///
/// Represents a single notification with all its properties.
class NotificationModel {
  final int id;
  final String message;
  final NotificationType type;
  final bool visible;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    this.visible = true,
  });

  /// Create a copy with updated fields
  NotificationModel copyWith({
    int? id,
    String? message,
    NotificationType? type,
    bool? visible,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      visible: visible ?? this.visible,
    );
  }
}

/// NotificationState - State class for notification store
///
/// Contains the state managed by the notification store.
/// Equivalent to Vue Pinia notification store state.
class NotificationState {
  final List<NotificationModel> notifications;

  const NotificationState({this.notifications = const []});

  /// Create a copy with updated fields
  NotificationState copyWith({List<NotificationModel>? notifications}) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
    );
  }
}

/// NotificationStoreNotifier - StateNotifier for notification store
///
/// Equivalent to Vue Pinia notification store actions and state management.
/// Handles adding, removing, and managing notifications.
class NotificationStoreNotifier extends StateNotifier<NotificationState> {
  NotificationStoreNotifier() : super(const NotificationState());

  int _notificationId = 0;
  final Map<int, Timer> _autoDismissTimers = {};
  final Map<int, Timer> _removeTimers = {};

  /// Get next notification ID
  int _getNextId() {
    return ++_notificationId;
  }

  /// Cancel and cleanup timers for a notification
  void _cancelTimers(int id) {
    _autoDismissTimers[id]?.cancel();
    _autoDismissTimers.remove(id);
    _removeTimers[id]?.cancel();
    _removeTimers.remove(id);
  }

  /// Cleanup all timers
  void _cleanupAllTimers() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
    for (final timer in _removeTimers.values) {
      timer.cancel();
    }
    _removeTimers.clear();
  }

  // ==================== Actions ====================

  /// Add notification
  /// Equivalent to Vue's addNotification()
  ///
  /// [message] - Notification message
  /// [type] - Notification type (default: success)
  /// [duration] - Auto-dismiss duration in milliseconds (null = manual dismiss only)
  /// Returns notification ID
  int addNotification(
    String message, {
    NotificationType type = NotificationType.success,
    int? duration,
  }) {
    final id = _getNextId();
    final notification = NotificationModel(
      id: id,
      message: message,
      type: type,
      visible: true,
    );

    // Add to state
    final notifications = [...state.notifications, notification];
    state = state.copyWith(notifications: notifications);

    // Auto-remove after duration if specified
    // Equivalent to Vue's setTimeout(() => { removeNotification(id); }, duration)
    if (duration != null) {
      final timer = Timer(Duration(milliseconds: duration), () {
        removeNotification(id);
      });
      _autoDismissTimers[id] = timer;
    }

    return id;
  }

  /// Remove notification
  /// Equivalent to Vue's removeNotification()
  ///
  /// [id] - Notification ID to remove
  void removeNotification(int id) {
    // Cancel any pending auto-dismiss timer
    _cancelTimers(id);

    // Find notification index
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    // Set visible to false (for animation)
    final notification = state.notifications[index];
    final updatedNotification = notification.copyWith(visible: false);
    final notifications = List<NotificationModel>.from(state.notifications);
    notifications[index] = updatedNotification;
    state = state.copyWith(notifications: notifications);

    // Remove from array after animation
    // Equivalent to Vue's setTimeout(() => { notifications.value = ... }, 300)
    final removeTimer = Timer(const Duration(milliseconds: 300), () {
      final filteredNotifications = state.notifications
          .where((n) => n.id != id)
          .toList();
      state = state.copyWith(notifications: filteredNotifications);
    });
    _removeTimers[id] = removeTimer;
  }

  /// Show success notification
  /// Equivalent to Vue's success()
  ///
  /// [message] - Success message
  /// Returns notification ID
  int success(String message) {
    return addNotification(
      message,
      type: NotificationType.success,
      duration: 6000, // Auto-dismiss after 6 seconds
    );
  }

  /// Show error notification
  /// Equivalent to Vue's error()
  ///
  /// [message] - Error message
  /// Returns notification ID
  int error(String message) {
    return addNotification(
      message,
      type: NotificationType.error,
      duration: 6000, // Auto-dismiss after 6 seconds
    );
  }

  /// Show warning notification
  /// Equivalent to Vue's warning()
  ///
  /// [message] - Warning message
  /// Returns notification ID
  int warning(String message) {
    return addNotification(
      message,
      type: NotificationType.warning,
      duration: 6000, // Auto-dismiss after 6 seconds
    );
  }

  /// Show info notification
  /// Convenience method for info notifications
  ///
  /// [message] - Info message
  /// Returns notification ID
  int info(String message) {
    return addNotification(
      message,
      type: NotificationType.info,
      duration: 6000, // Auto-dismiss after 6 seconds
    );
  }

  /// Clear all notifications
  /// Equivalent to Vue's clearAll()
  void clearAll() {
    // Cancel all timers
    _cleanupAllTimers();

    // Set all notifications to invisible
    final notifications = state.notifications
        .map((n) => n.copyWith(visible: false))
        .toList();
    state = state.copyWith(notifications: notifications);

    // Remove all after animation
    // Equivalent to Vue's setTimeout(() => { notifications.value = [] }, 300)
    Timer(const Duration(milliseconds: 300), () {
      state = const NotificationState();
    });
  }
}

/// NotificationStoreProvider - Riverpod provider for notification store
///
/// This is the main provider that exposes the notification store state and actions.
final notificationStoreProvider =
    StateNotifierProvider<NotificationStoreNotifier, NotificationState>(
      (ref) => NotificationStoreNotifier(),
    );

/// Computed/Selector Providers
///
/// These providers compute derived values from the notification store state.
/// Equivalent to Vue's computed properties.

/// Notifications provider
final notificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(notificationStoreProvider).notifications;
});

/// Visible notifications provider
/// Returns only visible notifications
final visibleNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref
      .watch(notificationStoreProvider)
      .notifications
      .where((n) => n.visible)
      .toList();
});


