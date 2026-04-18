import 'package:flutter/material.dart';

/// Responsive - Utility class for responsive design scaling
///
/// Helps scaling dimensions and fonts across different screen sizes.
/// Uses a base width of 375px (standard mobile) for scaling.
class Responsive {
  Responsive._();

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Scale a dimension based on screen width
  /// baseWidth is 375.0
  static double scale(BuildContext context, double size) {
    final width = screenWidth(context);
    // Limit scaling on very large screens to avoid oversized elements
    final ratio = width / 375.0;
    if (ratio > 1.5) {
      return size * (1.5 + (ratio - 1.5) * 0.5);
    }
    return size * ratio;
  }

  /// Scale font size with a dampened ratio to keep text readable
  static double font(BuildContext context, double size) {
    final width = screenWidth(context);
    final ratio = width / 375.0;

    // Dampened scaling for fonts: full scale up to 1.2x, then 30% after that
    if (ratio > 1.2) {
      return size * (1.2 + (ratio - 1.2) * 0.3);
    }
    // Minimal font size protection
    if (ratio < 0.8) {
      return size * (0.8 + (ratio - 0.8) * 0.5);
    }
    return size * ratio;
  }

  /// Responsive spacing based on scale
  static double spacing(BuildContext context, double size) =>
      scale(context, size);

  /// Device type checks
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1024;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  /// Get safe area top padding
  static double safeAreaTop(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /// Get safe area bottom padding
  static double safeAreaBottom(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;
}
