import 'package:flutter/material.dart';
import 'notification_toast.dart';
import '../theme/theme.dart';

/// NotificationPanel - A panel that displays active notifications
///
/// This is intended to be placed at the very top of the screen,
/// above the Navbar, as requested by the user.
class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
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

    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.8),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top > 0 ? 8.0 : 0.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: notifications.map((notification) {
          return _NotificationBar(notification: notification);
        }).toList(),
      ),
    );
  }
}

class _NotificationBar extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationBar({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(notification.type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
        vertical: AppTheme.spacingSM,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(_getNotificationIcon(notification.type), color: color, size: 18),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Text(
              notification.message,
              style: AppTextStyles.labelSmallStyle(
                color: Colors.white,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: () {
              NotificationToastService.instance.removeNotification(
                notification.id,
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

Color _getNotificationColor(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return const Color(0xFF22C55E);
    case NotificationType.error:
      return const Color(0xFFEF4444);
    case NotificationType.warning:
      return const Color(0xFFEAB308);
    case NotificationType.info:
      return const Color(0xFF3B82F6);
  }
}

IconData _getNotificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return Icons.check_circle;
    case NotificationType.error:
      return Icons.error;
    case NotificationType.warning:
      return Icons.warning;
    case NotificationType.info:
      return Icons.info;
  }
}
