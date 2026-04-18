import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/confirmation_store.dart';
import '../stores/language_store.dart';

/// ConfirmActionOptions - Options for confirmation action
///
/// Configuration options for showing a confirmation modal.
/// Equivalent to Vue's confirmAction options parameter.
class ConfirmActionOptions {
  /// The action text (e.g., "remove this item", "delete this product")
  final String? action;

  /// Custom title (defaults to translated "Confirm Action")
  final String? title;

  /// Custom message (defaults to template with action)
  final String? message;

  /// Custom confirm button text (defaults to translated "Confirm")
  final String? confirmText;

  /// Custom cancel button text (defaults to translated "Cancel")
  final String? cancelText;

  /// Whether this is a destructive action (red button)
  final bool destructive;

  /// Callback when user confirms
  final VoidCallback? onConfirm;

  /// Callback when user cancels
  final VoidCallback? onCancel;

  const ConfirmActionOptions({
    this.action,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    this.destructive = false,
    this.onConfirm,
    this.onCancel,
  });
}

/// ConfirmationHelper - Utility functions for confirmation dialogs
///
/// Equivalent to Vue's confirmation.js utility file.
/// Provides helper functions for showing confirmation modals with translations.
class ConfirmationHelper {
  ConfirmationHelper._();

  /// Show a confirmation modal
  ///
  /// Equivalent to Vue's confirmAction() function.
  ///
  /// [ref] - WidgetRef from Riverpod (required for accessing stores)
  /// [options] - Configuration options for the confirmation dialog
  /// Returns `Future<bool>` that resolves to true if confirmed, false if cancelled
  ///
  /// Example:
  /// ```dart
  /// final confirmed = await ConfirmationHelper.confirmAction(
  ///   ref,
  ///   ConfirmActionOptions(
  ///     action: 'delete this product',
  ///     destructive: true,
  ///   ),
  /// );
  /// if (confirmed) {
  ///   // User confirmed
  /// }
  /// ```
  static Future<bool> confirmAction(
    WidgetRef ref,
    ConfirmActionOptions options,
  ) {
    final completer = Completer<bool>();

    // Get stores
    final confirmationStore = ref.read(confirmationStoreProvider.notifier);
    final languageStore = ref.read(languageStoreProvider.notifier);
    final t = languageStore.t;

    // Extract options
    final action = options.action;
    final title = options.title;
    final message = options.message;
    final confirmText = options.confirmText;
    final cancelText = options.cancelText;
    final destructive = options.destructive;
    final onConfirm = options.onConfirm;
    final onCancel = options.onCancel;

    // Build title
    final modalTitle = title ?? t('confirm_action');

    // Build message
    String modalMessage;
    if (message != null && message.isNotEmpty) {
      modalMessage = message;
    } else if (action != null && action.isNotEmpty) {
      // Use template: "Are you sure you want to {action}?"
      final template = t('are_you_sure_you_want_to');
      if (template.isNotEmpty && template.contains('{action}')) {
        modalMessage = template.replaceAll('{action}', action);
      } else {
        // Fallback if template doesn't contain {action}
        final areYouSure = t('are_you_sure');
        modalMessage = '$areYouSure $action?';
      }
    } else {
      // Default message
      modalMessage = t('are_you_sure');
    }

    // Show modal
    confirmationStore.showWithParams(
      title: modalTitle,
      message: modalMessage,
      confirmText: confirmText ?? t('confirm'),
      cancelText: cancelText ?? t('cancel'),
      destructive: destructive,
      onConfirm: () {
        if (onConfirm != null) {
          onConfirm();
        }
        completer.complete(true);
      },
      onCancel: () {
        if (onCancel != null) {
          onCancel();
        }
        completer.complete(false);
      },
    );

    return completer.future;
  }
}
