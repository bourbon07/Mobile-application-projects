import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ConfirmationOptions - Options for showing confirmation dialog
///
/// Contains all the configuration needed to display a confirmation modal.
class ConfirmationOptions {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationOptions({
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });
}

/// ConfirmationState - State class for confirmation store
///
/// Contains the state managed by the confirmation store.
/// Equivalent to Vue Pinia confirmation store state.
class ConfirmationState {
  final bool isVisible;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationState({
    this.isVisible = false,
    this.title = '',
    this.message = '',
    this.confirmText = '',
    this.cancelText = '',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  /// Create a copy with updated fields
  ConfirmationState copyWith({
    bool? isVisible,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
    bool? isDestructive,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationState(
      isVisible: isVisible ?? this.isVisible,
      title: title ?? this.title,
      message: message ?? this.message,
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      isDestructive: isDestructive ?? this.isDestructive,
      onConfirm: onConfirm ?? this.onConfirm,
      onCancel: onCancel ?? this.onCancel,
    );
  }

  /// Create state from options
  factory ConfirmationState.fromOptions(ConfirmationOptions options) {
    return ConfirmationState(
      isVisible: true,
      title: options.title,
      message: options.message,
      confirmText: options.confirmText,
      cancelText: options.cancelText,
      isDestructive: options.isDestructive,
      onConfirm: options.onConfirm,
      onCancel: options.onCancel,
    );
  }
}

/// ConfirmationStoreNotifier - StateNotifier for confirmation store
///
/// Equivalent to Vue Pinia confirmation store actions and state management.
/// Handles showing/hiding confirmation dialogs and executing callbacks.
class ConfirmationStoreNotifier extends StateNotifier<ConfirmationState> {
  ConfirmationStoreNotifier() : super(const ConfirmationState());

  Timer? _clearTimer;

  /// Cleanup method to cancel pending timers
  /// Call this when the notifier is no longer needed
  void cleanup() {
    _clearTimer?.cancel();
  }

  /// Show confirmation dialog
  /// Equivalent to Vue's show()
  ///
  /// [options] - Configuration for the confirmation dialog
  void show(ConfirmationOptions options) {
    // Cancel any pending clear timer
    _clearTimer?.cancel();

    // Update state with new options
    state = ConfirmationState.fromOptions(options);
  }

  /// Show confirmation dialog with individual parameters
  /// Convenience method matching Vue's show() signature
  void showWithParams({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool destructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    show(
      ConfirmationOptions(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: destructive,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Hide confirmation dialog
  /// Equivalent to Vue's hide()
  ///
  /// Clears state after a delay to allow animations to complete.
  void hide() {
    state = state.copyWith(isVisible: false);

    // Clear callbacks after a short delay to allow animations
    // Equivalent to Vue's setTimeout(() => { ... }, 300)
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 300), () {
      if (!state.isVisible) {
        state = const ConfirmationState();
      }
    });
  }

  /// Handle confirm action
  /// Equivalent to Vue's handleConfirm()
  ///
  /// Executes the confirm callback if present, then hides the dialog.
  void handleConfirm() {
    final callback = state.onConfirm;
    hide();
    
    // Execute callback after hiding (allows animation to start)
    if (callback != null) {
      // Small delay to ensure state is updated first
      Future.delayed(const Duration(milliseconds: 50), callback);
    }
  }

  /// Handle cancel action
  /// Equivalent to Vue's handleCancel()
  ///
  /// Executes the cancel callback if present, then hides the dialog.
  void handleCancel() {
    final callback = state.onCancel;
    hide();
    
    // Execute callback after hiding (allows animation to start)
    if (callback != null) {
      // Small delay to ensure state is updated first
      Future.delayed(const Duration(milliseconds: 50), callback);
    }
  }
}

/// ConfirmationStoreProvider - Riverpod provider for confirmation store
///
/// This is the main provider that exposes the confirmation store state and actions.
final confirmationStoreProvider =
    StateNotifierProvider<ConfirmationStoreNotifier, ConfirmationState>(
  (ref) => ConfirmationStoreNotifier(),
);

/// Computed/Selector Providers
///
/// These providers compute derived values from the confirmation store state.
/// Equivalent to Vue's computed properties.

/// Is visible provider
final confirmationIsVisibleProvider = Provider<bool>((ref) {
  return ref.watch(confirmationStoreProvider).isVisible;
});

/// Title provider
final confirmationTitleProvider = Provider<String>((ref) {
  return ref.watch(confirmationStoreProvider).title;
});

/// Message provider
final confirmationMessageProvider = Provider<String>((ref) {
  return ref.watch(confirmationStoreProvider).message;
});

/// Confirm text provider
final confirmationConfirmTextProvider = Provider<String>((ref) {
  return ref.watch(confirmationStoreProvider).confirmText;
});

/// Cancel text provider
final confirmationCancelTextProvider = Provider<String>((ref) {
  return ref.watch(confirmationStoreProvider).cancelText;
});

/// Is destructive provider
final confirmationIsDestructiveProvider = Provider<bool>((ref) {
  return ref.watch(confirmationStoreProvider).isDestructive;
});



