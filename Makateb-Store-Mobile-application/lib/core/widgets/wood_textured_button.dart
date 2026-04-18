import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// WoodTexturedButton - Wrapper widget that applies wood texture to any button
///
/// This widget wraps standard Flutter buttons (ElevatedButton, TextButton, OutlinedButton)
/// and applies a wood texture gradient background with white text and glow effect.
///
/// Usage:
/// ```dart
/// WoodTexturedButton(
///   child: ElevatedButton(
///     onPressed: () {},
///     child: Text('Shop Now'),
///   ),
/// )
/// ```
class WoodTexturedButton extends StatelessWidget {
  /// The button widget to wrap (ElevatedButton, TextButton, OutlinedButton, etc.)
  final Widget child;

  /// Optional custom wood gradient colors
  final List<Color>? woodGradientColors;

  /// Optional border radius override
  final BorderRadius? borderRadius;

  const WoodTexturedButton({
    super.key,
    required this.child,
    this.woodGradientColors,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Wood texture image path
    const woodTexturePath =
        'asset/bde3a495c5ad0d23397811532fdfa02fe66f448c.png';

    final borderRadiusValue = borderRadius ?? AppTheme.borderRadiusLargeValue;

    return Container(
      decoration: BoxDecoration(
        // Wood texture image background
        image: const DecorationImage(
          image: AssetImage(woodTexturePath),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // Fallback color if image fails to load
        color: AppColors.woodBase,
        borderRadius: borderRadiusValue,
        // No shadow - removed as per design requirement
      ),
      child: ClipRRect(
        borderRadius: borderRadiusValue,
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

/// WoodButtonStyle - Helper class to create wood-textured button styles
///
/// Provides static methods to create button styles with wood texture.
class WoodButtonStyle {
  WoodButtonStyle._();

  /// Get wood texture gradient
  static LinearGradient get woodGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.woodLight,
      AppColors.woodBase,
      AppColors.woodMedium,
      AppColors.woodBase,
      AppColors.woodDark,
    ],
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Get text style (no glow effect - removed as per design requirement)
  static TextStyle get textStyleWithGlow => AppTextStyles.labelLargeStyle(
    color: Colors.white,
    // font-weight: regular (default)
  );

  /// Get box shadow for buttons (removed - no shadows on buttons)
  static List<BoxShadow> get boxShadow => [];
}


