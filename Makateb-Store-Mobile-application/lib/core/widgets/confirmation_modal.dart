import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/theme.dart';
import '../services/overlay_manager.dart';

/// ConfirmationModal - Confirmation modal widget
/// 
/// Equivalent to Vue's ConfirmationModal component.
/// Displays a confirmation dialog with backdrop, header, body, and footer buttons.
/// 
/// Features:
/// - Backdrop with blur effect
/// - RTL/LTR support
/// - Dark mode support
/// - Transition animations
/// - Destructive vs normal button styling
/// - Click outside to cancel
class ConfirmationModal extends StatefulWidget {
  /// Modal title
  final String title;

  /// Modal message
  final String message;

  /// Confirm button text
  final String confirmText;

  /// Cancel button text
  final String cancelText;

  /// Whether this is a destructive action (red button vs amber)
  final bool isDestructive;

  /// Callback when confirmed
  final VoidCallback? onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  /// Whether modal is visible
  final bool isVisible;

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
    this.isVisible = true,
  });

  @override
  State<ConfirmationModal> createState() => _ConfirmationModalState();
}

class _ConfirmationModalState extends State<ConfirmationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ConfirmationModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    widget.onCancel?.call();
  }

  void _handleConfirm() {
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Tailwind colors
    // gray-800: #1F2937, gray-700: #374151, gray-300: #D1D5DB, gray-200: #E5E7EB
    // red-600: #DC2626, red-700: #B91C1C, amber-600: #D97706, amber-700: #B45309
    final modalBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF111827);
    final bodyTextColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final cancelBorderColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);
    final cancelHoverColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fixed overlay (equivalent to fixed inset-0 z-[9000])
            // Modal layer - below toasts but above menus
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleCancel, // Click outside to cancel
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Backdrop with blur (equivalent to bg-black/50 backdrop-blur-sm)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Modal content (equivalent to flex items-center justify-center p-4)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from closing modal
                  child: Directionality(
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: modalBg,
                        borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
                        boxShadow: [
                          // shadow-xl
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isRTL
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Header (px-6 py-4 border-b)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXL, // px-6 = 24px
                              vertical: AppTheme.spacingLG, // py-4 = 16px
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              widget.title,
                              style: AppTextStyles.titleLargeStyle(
                                color: textColor,
                                // font-weight: regular (default)
                              ),
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            ),
                          ),

                          // Body (px-6 py-4)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXL, // px-6
                              vertical: AppTheme.spacingLG, // py-4
                            ),
                            child: Text(
                              widget.message,
                              style: AppTextStyles.bodyMediumStyle(
                                color: bodyTextColor,
                              ),
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            ),
                          ),

                          // Footer (px-6 py-4 border-t flex gap-3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXL, // px-6
                              vertical: AppTheme.spacingLG, // py-4
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                              children: [
                                // Cancel button
                                _ModalButton(
                                  text: widget.cancelText,
                                  onPressed: _handleCancel,
                                  isCancel: true,
                                  borderColor: cancelBorderColor,
                                  hoverColor: cancelHoverColor,
                                  textColor: bodyTextColor,
                                ),
                                const SizedBox(width: AppTheme.spacingMD), // gap-3 = 12px

                                // Confirm button
                                _ModalButton(
                                  text: widget.confirmText,
                                  onPressed: _handleConfirm,
                                  isDestructive: widget.isDestructive,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ModalButton - Button widget for modal footer
/// 
/// Matches Vue button styling with hover effects and focus rings.
class _ModalButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isCancel;
  final bool isDestructive;
  final Color? borderColor;
  final Color? hoverColor;
  final Color? textColor;

  const _ModalButton({
    required this.text,
    required this.onPressed,
    this.isCancel = false,
    this.isDestructive = false,
    this.borderColor,
    this.hoverColor,
    this.textColor,
  });

  @override
  State<_ModalButton> createState() => _ModalButtonState();
}

class _ModalButtonState extends State<_ModalButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCancel) {
      // Cancel button styling
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4 = 16px
              vertical: AppTheme.spacingSM, // py-2 = 8px
            ),
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor : Colors.transparent,
              border: Border.all(
                color: widget.borderColor ?? const Color(0xFFD1D5DB),
                width: 2,
              ),
              borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
            ),
            child: Text(
              widget.text,
              style: AppTextStyles.labelLargeStyle(
                color: widget.textColor ?? const Color(0xFF374151),
                fontWeight: AppTextStyles.medium, // font-medium
              ),
            ),
          ),
        ),
      );
    } else {
      // Confirm button styling
      // red-600: #DC2626, red-700: #B91C1C, amber-600: #D97706, amber-700: #B45309
      final backgroundColor = widget.isDestructive
          ? (_isHovered ? const Color(0xFFB91C1C) : const Color(0xFFDC2626))
          : (_isHovered ? const Color(0xFFB45309) : const Color(0xFFD97706));

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4
              vertical: AppTheme.spacingSM, // py-2
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
            ),
            child: Text(
              widget.text,
              style: AppTextStyles.labelLargeStyle(
                color: Colors.white,
                fontWeight: AppTextStyles.medium, // font-medium
              ),
            ),
          ),
        ),
      );
    }
  }
}

/// ConfirmationModalService - Service for showing confirmation modals
/// 
/// Provides methods to show confirmation dialogs.
/// Equivalent to Vue's confirmation store usage.
class ConfirmationModalService {
  ConfirmationModalService._();
  static final ConfirmationModalService instance = ConfirmationModalService._();

  /// Show a confirmation dialog
  /// 
  /// Returns true if user confirms, false if cancelled.
  Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    // Close all menus and other modals before showing this modal
    OverlayManager.instance.closeAllMenusAndModals();

    bool? result;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => ConfirmationModal(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () {
          result = true;
          Navigator.of(context).pop();
        },
        onCancel: () {
          result = false;
          Navigator.of(context).pop();
        },
      ),
    );

    return result ?? false;
  }

  /// Show a delete confirmation dialog
  Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String message,
  }) async {
    return showConfirmation(
      context: context,
      title: 'Delete Confirmation',
      message: message,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
  }
}



