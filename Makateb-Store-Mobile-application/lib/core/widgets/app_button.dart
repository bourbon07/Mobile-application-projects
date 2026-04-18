import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// AppButton - Universal button widget with wood texture style
///
/// Replaces standard Flutter buttons (ElevatedButton, TextButton, OutlinedButton)
/// with a consistent wood texture style matching the "Shop Now" button design.
///
/// Features:
/// - Wood texture gradient background
/// - White text with soft glow effect
/// - Rounded corners
/// - Hover/press animations
/// - Supports all button variants
class AppButton extends StatefulWidget {
  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant
  final AppButtonVariant variant;

  /// Button size
  final AppButtonSize size;

  /// Optional icon before text
  final Widget? icon;

  /// Optional icon after text
  final Widget? trailingIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final padding = _getPadding();
    final fontSize = _getFontSize();

    return MouseRegion(
      onEnter: (_) {
        if (!isDisabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (!isDisabled) {
          setState(() => _isHovered = false);
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) {
            _scaleController.forward();
          }
        },
        onTapUp: (_) {
          if (!isDisabled) {
            _scaleController.reverse();
            widget.onPressed?.call();
          }
        },
        onTapCancel: () {
          if (!isDisabled) {
            _scaleController.reverse();
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusLargeValue,
            child: Container(
              padding: padding,
              decoration: _buildDecoration(isDisabled, _isHovered),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: AppTheme.spacingSM),
                  ],
                  Text(widget.text, style: _getTextStyle(fontSize, isDisabled)),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: AppTheme.spacingSM),
                    widget.trailingIcon!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLG, // px-4 (16px)
          vertical: AppTheme.spacingSM, // py-2 (8px)
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL, // px-6 (24px)
          vertical: AppTheme.spacingMD, // py-3 (12px)
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXXL, // px-8 (32px)
          vertical: AppTheme.spacingLG, // py-4 (16px)
        );
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 14.0;
      case AppButtonSize.medium:
        return 16.0;
      case AppButtonSize.large:
        return 18.0;
    }
  }

  BoxDecoration _buildDecoration(bool isDisabled, bool isHovered) {
    final baseDecoration = BoxDecoration(
      borderRadius: AppTheme.borderRadiusLargeValue,
    );

    // Wood texture image path
    const woodTexturePath =
        'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png';

    switch (widget.variant) {
      case AppButtonVariant.filled:
        return baseDecoration.copyWith(
          // Wood texture image background
          image: isDisabled
              ? null
              : const DecorationImage(
                  image: AssetImage(woodTexturePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
          // Fallback color if image fails to load
          color: isDisabled
              ? AppColors.woodDark.withValues(alpha: 0.5)
              : null, // Don't set color when image is present to allow texture to show through
          // Shadow effects: shadow-lg, hover:shadow-xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDisabled ? 0.1 : (_isHovered ? 0.25 : 0.15),
              ),
              blurRadius: isDisabled ? 5 : (_isHovered ? 20 : 10),
              offset: const Offset(0, 4),
              spreadRadius: isDisabled ? 0 : (_isHovered ? 2 : 0),
            ),
          ],
        );

      case AppButtonVariant.outlined:
        return baseDecoration.copyWith(
          // Wood texture image with transparency overlay
          image: isDisabled
              ? null
              : DecorationImage(
                  image: const AssetImage(woodTexturePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.3),
                    BlendMode.overlay,
                  ),
                ),
          color: isDisabled
              ? Colors.transparent
              : AppColors.woodBase.withValues(alpha: 0.2),
          border: Border.all(
            color: isDisabled
                ? AppColors.woodDark.withValues(alpha: 0.3)
                : AppColors.woodDark,
            width: 2,
          ),
        );

      case AppButtonVariant.text:
        return baseDecoration.copyWith(
          color: isDisabled
              ? Colors.transparent
              : (_isHovered
                    ? AppColors.woodBase.withValues(alpha: 0.2)
                    : Colors.transparent),
        );
    }
  }

  TextStyle _getTextStyle(double fontSize, bool isDisabled) {
    final baseStyle = AppTextStyles.labelLargeStyle(
      color: isDisabled ? Colors.white.withValues(alpha: 0.5) : Colors.white,
      // font-weight: regular (default)
    ).copyWith(fontSize: fontSize);

    // No text shadow - removed as per design requirement
    return baseStyle;
  }
}

/// AppButtonVariant - Button variant enum
enum AppButtonVariant {
  filled, // Wood texture background
  outlined, // Wood texture with border
  text, // Transparent with wood texture on hover
}

/// AppButtonSize - Button size enum
enum AppButtonSize { small, medium, large }


