import 'package:flutter/material.dart';
import 'wood_button.dart';
import '../theme/theme.dart';

/// CartButton - Consistent cart button widget for the entire application
///
/// Ensures all cart buttons have the same styling:
/// - White text
/// - Shadow effects (shadow-lg, hover:shadow-xl)
/// - Scale effects (hover:scale-105, active:scale-95)
/// - Rounded-lg
/// - Shopping cart icon
class CartButton extends StatelessWidget {
  /// Button text/label
  final String? text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button size
  final WoodButtonSize size;

  /// Whether the button is in loading/adding state
  final bool isLoading;

  /// Loading text (default: "Adding...")
  final String? loadingText;

  /// Icon to display (default: shopping_cart)
  final IconData? icon;

  /// Icon size (default: 20 for lg, 16 for smaller sizes)
  final double? iconSize;

  const CartButton({
    super.key,
    this.text,
    this.onPressed,
    this.size = WoodButtonSize.lg,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    // Determine icon size based on button size
    final defaultIconSize = iconSize ??
        (size == WoodButtonSize.lg ? 20.0 : 16.0);

    // Determine icon
    final cartIcon = icon ?? Icons.shopping_cart;

    return WoodButton(
      onPressed: isLoading ? null : onPressed,
      variant: WoodButtonVariant.primary,
      size: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: defaultIconSize,
              height: defaultIconSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              cartIcon,
              size: defaultIconSize,
              color: Colors.white,
            ),
          if (text != null) ...[
            SizedBox(width: size == WoodButtonSize.lg ? AppTheme.spacingSM : AppTheme.spacingXS),
            Flexible(
              child: Text(
                isLoading ? (loadingText ?? 'Adding...') : text!,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



