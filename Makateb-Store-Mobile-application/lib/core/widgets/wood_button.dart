import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../theme/responsive.dart';

/// WoodButton - Styled button widget
///
/// Equivalent to Vue's WoodButton.vue component.
/// A custom button with wood texture styling, variants, and sizes.
///
/// Features:
/// - Variants: primary, secondary, outline, ghost
/// - Sizes: xs, sm, md, lg, xl
/// - Wood texture background for primary variant
/// - Hover effects (scale, shadow)
/// - RTL support
/// - Disabled state styling
class WoodButton extends StatefulWidget {
  /// Button child content
  final Widget child;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant
  final WoodButtonVariant variant;

  /// Button size
  final WoodButtonSize size;

  /// Path to wood texture image asset (for primary variant)
  /// Default: 'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png'
  final String? woodTexturePath;

  /// Text direction (RTL/LTR)
  final TextDirection? textDirection;

  const WoodButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = WoodButtonVariant.primary,
    this.size = WoodButtonSize.md,
    this.woodTexturePath,
    this.textDirection,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    // Note: hover:scale-105 is handled by _scaleAnimation
    // active:scale-95 is handled by the pressed state animation
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDir = widget.textDirection ?? Directionality.of(context);

    final isDisabled = widget.onPressed == null;

    // Size-based values
    final padding = _getPadding();
    final fontSize = _getFontSize();

    return MouseRegion(
      onEnter: (_) {
        if (!isDisabled) {
          setState(() => _isHovered = true);
          if (widget.variant == WoodButtonVariant.primary) {
            _scaleController.forward();
          }
        }
      },
      onExit: (_) {
        if (!isDisabled) {
          setState(() => _isHovered = false);
          if (widget.variant == WoodButtonVariant.primary) {
            _scaleController.reverse();
          }
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled && widget.variant == WoodButtonVariant.primary) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (!isDisabled && widget.variant == WoodButtonVariant.primary) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (!isDisabled && widget.variant == WoodButtonVariant.primary) {
            setState(() => _isPressed = false);
          }
        },
        child: ScaleTransition(
          scale: _isPressed
              ? Tween<double>(begin: 1.0, end: 0.95).animate(
                  CurvedAnimation(
                    parent: _scaleController,
                    curve: Curves.easeInOut,
                  ),
                )
              : _scaleAnimation,
          child: ClipRRect(
            borderRadius: AppTheme
                .borderRadiusLargeValue, // rounded-lg with overflow-hidden
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
                child: Container(
                  padding: padding,
                  alignment: Alignment.center,
                  decoration: _buildDecoration(isDark, isDisabled, _isHovered),
                  child: DefaultTextStyle(
                    style: AppTextStyles.labelLargeStyle(
                      color: _getTextColor(isDark, _isHovered),
                      fontWeight: AppTextStyles.medium,
                    ).copyWith(fontSize: fontSize),
                    child: Directionality(
                      textDirection: textDir,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    double horizontal;
    double vertical;

    switch (widget.size) {
      case WoodButtonSize.xs:
        horizontal = AppTheme.spacingSM;
        vertical = AppTheme.spacingXS;
        break;
      case WoodButtonSize.sm:
        horizontal = AppTheme.spacingMD;
        vertical = AppTheme.spacingSM / 2;
        break;
      case WoodButtonSize.md:
        horizontal = AppTheme.spacingLG;
        vertical = AppTheme.spacingSM;
        break;
      case WoodButtonSize.lg:
        horizontal = AppTheme.spacingXL;
        vertical = AppTheme.spacingMD;
        break;
      case WoodButtonSize.xl:
        horizontal = AppTheme.spacingXXL;
        vertical = AppTheme.spacingLG;
        break;
    }

    return EdgeInsets.symmetric(
      horizontal: Responsive.scale(context, horizontal),
      vertical: Responsive.scale(context, vertical),
    );
  }

  double _getFontSize() {
    double size;
    switch (widget.size) {
      case WoodButtonSize.xs:
        size = 12.0;
        break;
      case WoodButtonSize.sm:
        size = 14.0;
        break;
      case WoodButtonSize.md:
        size = 16.0;
        break;
      case WoodButtonSize.lg:
        size = 18.0;
        break;
      case WoodButtonSize.xl:
        size = 20.0;
        break;
    }
    return Responsive.font(context, size);
  }

  BoxDecoration _buildDecoration(bool isDark, bool isDisabled, bool isHovered) {
    final baseDecoration = BoxDecoration(
      borderRadius: AppTheme.borderRadiusLargeValue, // rounded-lg
    );

    switch (widget.variant) {
      case WoodButtonVariant.primary:
        // Default wood texture path
        final texturePath =
            widget.woodTexturePath ??
            'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png';

        return baseDecoration.copyWith(
          // Wood texture background
          image: DecorationImage(
            image: AssetImage(texturePath),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            onError: (exception, stackTrace) {
              // Fallback handled by color
            },
          ),
          // Fallback color if image fails to load (only used if image fails)
          color: const Color(0xFF8B4513), // Fallback wood color
          // Shadow effects: shadow-lg, hover:shadow-xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isHovered ? 0.25 : 0.15),
              blurRadius: isHovered ? 20 : 10,
              offset: const Offset(0, 4),
              spreadRadius: isHovered ? 2 : 0,
            ),
          ],
        );

      case WoodButtonVariant.secondary:
        return baseDecoration.copyWith(
          color: isHovered
              ? (isDark
                    ? const Color(0xFF78350F).withValues(
                        alpha: 0.5,
                      ) // amber-900/50
                    : const Color(0xFFFDE68A)) // amber-200
              : (isDark
                    ? const Color(0xFF78350F).withValues(
                        alpha: 0.3,
                      ) // amber-900/30
                    : const Color(0xFFFEF3C7)), // amber-100
          border: Border.all(
            color: const Color(
              0xFF92400E,
            ).withValues(alpha: 0.3), // amber-800/30
            width: 2,
          ),
        );

      case WoodButtonVariant.outline:
        return baseDecoration.copyWith(
          color: isHovered
              ? (isDark
                    ? const Color(0xFFD97706) // amber-600
                    : const Color(0xFF92400E)) // amber-800
              : Colors.transparent,
          border: Border.all(
            color: isDark
                ? const Color(0xFFD97706) // amber-600
                : const Color(0xFF92400E), // amber-800
            width: 2,
          ),
        );

      case WoodButtonVariant.ghost:
        return baseDecoration.copyWith(
          color: isHovered
              ? (isDark
                    ? const Color(0xFF78350F).withValues(
                        alpha: 0.3,
                      ) // amber-900/30
                    : const Color(0xFFFEF3C7)) // amber-100
              : Colors.transparent,
        );
    }
  }

  Color _getTextColor(bool isDark, bool isHovered) {
    if (widget.onPressed == null) {
      // Disabled state
      return isDark
          ? const Color(0xFF9CA3AF).withValues(
              alpha: 0.5,
            ) // gray-400 with opacity
          : const Color(
              0xFF6B7280,
            ).withValues(alpha: 0.5); // gray-500 with opacity
    }

    switch (widget.variant) {
      case WoodButtonVariant.primary:
        return Colors.white;
      case WoodButtonVariant.secondary:
        return isDark
            ? const Color(0xFFFCD34D) // amber-100
            : const Color(0xFF78350F); // amber-900
      case WoodButtonVariant.outline:
        // Outline variant changes text color on hover
        if (isHovered) {
          return Colors.white;
        }
        return isDark
            ? const Color(0xFFFCD34D) // amber-100
            : const Color(0xFF78350F); // amber-900
      case WoodButtonVariant.ghost:
        return isDark
            ? const Color(0xFFFCD34D) // amber-100
            : const Color(0xFF78350F); // amber-900
    }
  }
}

/// WoodButtonVariant - Button variant enum
enum WoodButtonVariant { primary, secondary, outline, ghost }

/// WoodButtonSize - Button size enum
enum WoodButtonSize { xs, sm, md, lg, xl }
