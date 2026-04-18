import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// PackageButton - Custom outlined package button widget
///
/// Matches the design with:
/// - Transparent background
/// - 2px border (amber-800 light / amber-600 dark)
/// - Text color (amber-900 light / amber-100 dark)
/// - Hover effects (bg-amber-800 text-white light / bg-amber-600 dark)
/// - Rounded-lg
/// - Padding: px-4 py-2
/// - Package icon (16px)
class PackageButton extends StatefulWidget {
  final bool isDark;
  final String? text;
  final VoidCallback onTap;
  final IconData? icon;
  final double? iconSize;

  const PackageButton({
    super.key,
    required this.isDark,
    this.text,
    required this.onTap,
    this.icon,
    this.iconSize,
  });

  @override
  State<PackageButton> createState() => _PackageButtonState();
}

class _PackageButtonState extends State<PackageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on hover and dark mode
    final borderColor = widget.isDark
        ? const Color(0xFFD97706) // amber-600
        : const Color(0xFF78350F); // amber-800

    final backgroundColor = _isHovered
        ? (widget.isDark
            ? const Color(0xFFD97706) // amber-600
            : const Color(0xFF78350F)) // amber-800
        : Colors.transparent;

    final textColor = _isHovered
        ? Colors.white
        : (widget.isDark
            ? const Color(0xFFFEF3C7) // amber-100
            : const Color(0xFF78350F)); // amber-900

    final iconColor = _isHovered
        ? Colors.white
        : (widget.isDark
            ? const Color(0xFFFEF3C7) // amber-100
            : const Color(0xFF78350F)); // amber-900

    final iconSize = widget.iconSize ?? 16.0; // w-4 h-4
    final packageIcon = widget.icon ?? Icons.inventory_2;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppTheme.borderRadiusLargeValue,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, // px-4
              vertical: 8, // py-2
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppTheme.borderRadiusLargeValue,
              border: Border.all(width: 2, color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  packageIcon,
                  size: iconSize,
                  color: iconColor,
                ),
                if (widget.text != null) ...[
                  SizedBox(width: AppTheme.spacingSM), // gap-2
                  Text(
                    widget.text!,
                    style: AppTextStyles.bodyMediumStyle(
                      color: textColor,
                      fontWeight: AppTextStyles.medium,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}



