import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/theme.dart';

/// NotificationToast - Global notification toast widget
///
/// Equivalent to Vue's NotificationToast component.
/// Displays toast notifications at the app level in a fixed overlay.
///
/// Features:
/// - Fixed positioning (top-4 left-4 or right-4 for RTL)
/// - Multiple notification support
/// - Transition animations
/// - RTL/LTR support
/// - Backdrop blur
/// - Different types (success, error, warning)
class NotificationToast extends StatefulWidget {
  const NotificationToast({super.key});

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast> {
  @override
  void initState() {
    super.initState();
    NotificationToastService.instance.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    NotificationToastService.instance.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationToastService.instance.notifications;
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Widget is used in Stack, so return positioned content
    // Highest z-index - toasts appear above everything
    // fixed z-[9999] flex flex-col gap-3 p-4 top-4 left-4 w-auto max-w-sm sm:max-w-md
    return Positioned(
      top: AppTheme.spacingLG, // top-4 = 16px
      left: isRTL ? null : AppTheme.spacingLG, // left-4 = 16px
      right: isRTL ? AppTheme.spacingLG : null, // right-4 for RTL
      child: Material(
        color: Colors.transparent,
        child: Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4 = 16px
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width >= 640
                  ? 448 // sm:max-w-md = 448px
                  : 384, // max-w-sm = 384px
            ),
            child: MediaQuery.of(context).size.width >= 640
                ? _buildNotifications(notifications, isRTL)
                : _buildNotificationsMobile(notifications, isRTL),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifications(List<NotificationModel> notifications, bool isRTL) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: notifications.map((notification) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMD), // gap-3 = 12px
          child: _NotificationItem(
            notification: notification,
            isRTL: isRTL,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsMobile(List<NotificationModel> notifications, bool isRTL) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: notifications.map((notification) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMD), // gap: 0.75rem on mobile
          child: _NotificationItem(
            notification: notification,
            isRTL: isRTL,
            isMobile: true,
          ),
        );
      }).toList(),
    );
  }
}

/// NotificationItem - Individual notification widget
///
/// Displays a single notification with icon, message, and OK button.
class _NotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final bool isRTL;
  final bool isMobile;

  const _NotificationItem({
    required this.notification,
    required this.isRTL,
    this.isMobile = false,
  });

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1), // translateY(-10px)
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    NotificationToastService.instance.removeNotification(widget.notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = widget.notification.type;

    // Colors based on type
    final borderColor = _getBorderColor(type, isDark);
    final iconColor = _getIconColor(type);
    final textColor = _getTextColor(type, isDark);
    final buttonColor = _getButtonColor(type);
    final buttonHoverColor = _getButtonHoverColor(type);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // backdrop-blur-sm
          child: Container(
            padding: EdgeInsets.all(
              widget.isMobile ? 12 : AppTheme.spacingLG, // p-4 = 16px, mobile: 0.75rem = 12px
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F2937) // gray-800
                  : Colors.white,
              borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                // shadow-lg
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon - 32px x 32px
                SizedBox(
                  width: 32, // width: 32px
                  height: 32, // height: 32px
                  child: Icon(
                    _getIcon(type),
                    size: 32, // 32px x 32px
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD), // gap-3 = 12px

                // Message
                Expanded(
                  child: Text(
                    widget.notification.message,
                    style: AppTextStyles.labelSmallStyle(
                      color: textColor,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD), // gap-3

                // OK Button
                _NotificationButton(
                  label: widget.notification.okText ?? 'OK',
                  backgroundColor: buttonColor,
                  hoverColor: buttonHoverColor,
                  onPressed: _dismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.success:
        return isDark
            ? const Color(0xFF166534) // green-800
            : const Color(0xFFBBF7D0); // green-200
      case NotificationType.error:
        return isDark
            ? const Color(0xFF991B1B) // red-800
            : const Color(0xFFFECACA); // red-200
      case NotificationType.warning:
        return isDark
            ? const Color(0xFF854D0E) // yellow-800
            : const Color(0xFFFEF08A); // yellow-200
      default:
        return isDark
            ? const Color(0xFF374151) // gray-700
            : const Color(0xFFE5E7EB); // gray-200
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF22C55E); // green-500
      case NotificationType.error:
        return const Color(0xFFEF4444); // red-500
      case NotificationType.warning:
        return const Color(0xFFEAB308); // yellow-500
      default:
        return const Color(0xFF6B7280); // gray-500
    }
  }

  Color _getTextColor(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.success:
        return isDark
            ? const Color(0xFFBBF7D0) // green-200
            : const Color(0xFF166534); // green-800
      case NotificationType.error:
        return isDark
            ? const Color(0xFFFECACA) // red-200
            : const Color(0xFF991B1B); // red-800
      case NotificationType.warning:
        return isDark
            ? const Color(0xFFFEF08A) // yellow-200
            : const Color(0xFF854D0E); // yellow-800
      default:
        return isDark
            ? const Color(0xFFE5E7EB) // gray-200
            : const Color(0xFF1F2937); // gray-800
    }
  }

  Color _getButtonColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF16A34A); // green-600
      case NotificationType.error:
        return const Color(0xFFDC2626); // red-600
      case NotificationType.warning:
        return const Color(0xFFCA8A04); // yellow-600
      default:
        return const Color(0xFF4B5563); // gray-600
    }
  }

  Color _getButtonHoverColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF15803D); // green-700
      case NotificationType.error:
        return const Color(0xFFB91C1C); // red-700
      case NotificationType.warning:
        return const Color(0xFFA16207); // yellow-700
      default:
        return const Color(0xFF374151); // gray-700
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.cancel;
      case NotificationType.warning:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

/// NotificationButton - OK button widget
class _NotificationButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color hoverColor;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.label,
    required this.backgroundColor,
    required this.hoverColor,
    required this.onPressed,
  });

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 12, // px-3
            vertical: 6, // py-1.5
          ),
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.backgroundColor,
            borderRadius: AppTheme.borderRadiusMediumValue, // rounded-md
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.labelSmallStyle(
              color: Colors.white,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// NotificationModel - Notification data model
class NotificationModel {
  final String id;
  final String message;
  final NotificationType type;
  final String? okText;
  final VoidCallback? onTap;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    this.okText,
    this.onTap,
  });
}

/// NotificationType - Notification type enum
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// NotificationToastService - Service for managing toast notifications
///
/// Equivalent to Vue's notification store.
/// Manages the list of notifications and provides methods to add/remove them.
class NotificationToastService extends ChangeNotifier {
  NotificationToastService._();
  static final NotificationToastService instance = NotificationToastService._();

  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Show a success notification
  void showSuccess(String message, {String? okText, VoidCallback? onTap}) {
    _addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        type: NotificationType.success,
        okText: okText,
        onTap: onTap,
      ),
    );
  }

  /// Show an error notification
  void showError(String message, {String? okText, VoidCallback? onTap}) {
    _addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        type: NotificationType.error,
        okText: okText,
        onTap: onTap,
      ),
    );
  }

  /// Show a warning notification
  void showWarning(String message, {String? okText, VoidCallback? onTap}) {
    _addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        type: NotificationType.warning,
        okText: okText,
        onTap: onTap,
      ),
    );
  }

  /// Show an info notification
  void showInfo(String message, {String? okText, VoidCallback? onTap}) {
    _addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        type: NotificationType.info,
        okText: okText,
        onTap: onTap,
      ),
    );
  }

  /// Add a notification
  void _addNotification(NotificationModel notification) {
    _notifications.add(notification);
    notifyListeners();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      removeNotification(notification.id);
    });
  }

  /// Remove a notification
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}


