import 'package:flutter/material.dart';

/// Responsive utility functions for handling overflow and responsive layouts
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Breakpoints
  static const double mobileBreakpoint = 640;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive button layout
  /// Returns Column for mobile, Row for desktop
  static Widget responsiveButtonLayout({
    required BuildContext context,
    required Widget primaryButton,
    Widget? secondaryButton,
    double spacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < mobileBreakpoint;
        
        if (isSmallScreen) {
          // Mobile: Stack vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primaryButton,
              if (secondaryButton != null) ...[
                SizedBox(height: spacing),
                secondaryButton,
              ],
            ],
          );
        } else {
          // Desktop: Horizontal layout
          return Row(
            children: [
              Expanded(child: primaryButton),
              if (secondaryButton != null) ...[
                SizedBox(width: spacing),
                secondaryButton,
              ],
            ],
          );
        }
      },
    );
  }

  /// Wrap text with overflow handling
  static Widget safeText({
    required String text,
    required TextStyle style,
    int maxLines = 1,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}



