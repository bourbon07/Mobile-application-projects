import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Footer - Application footer widget
///
/// Equivalent to Vue's Footer.vue component.
/// Displays a footer with wood texture background, gradient overlay, and copyright text.
///
/// Features:
/// - Wood texture background image
/// - Gradient overlay (amber-900/95 to amber-950/95)
/// - Orange divider line at top
/// - Copyright text centered
/// - Configurable background image and text
class Footer extends StatelessWidget {
  /// Copyright text to display
  final String copyrightText;

  /// Path to wood texture image asset
  /// Default: '/bde3a495c5ad0d23397811532fdfa02fe66f448c.png'
  final String? woodTexturePath;

  /// Margin top (equivalent to mt-12 = 48px)
  final double topMargin;

  const Footer({
    super.key,
    required this.copyrightText,
    this.woodTexturePath,
    this.topMargin = 48.0, // mt-12 = 3rem = 48px
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: topMargin),
      child: Stack(
        children: [
          // Background image (wood texture)
          if (woodTexturePath != null)
            Positioned.fill(
              child: Image.asset(
                woodTexturePath!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    color: const Color(0xFF78350F), // amber-900 fallback
                  );
                },
              ),
            )
          else
            // Fallback background color if no image
            Positioned.fill(
              child: Container(
                color: const Color(0xFF78350F), // amber-900
              ),
            ),

          // Gradient overlay (from-amber-900/95 to-amber-950/95)
          // amber-900: #78350F, amber-950: #451A03
          // 95% opacity = 0.95
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, // from
                  end: Alignment.bottomRight, // to-br
                  colors: [
                    const Color(0xFF78350F).withValues(alpha: 0.95), // amber-900/95
                    const Color(0xFF451A03).withValues(alpha: 0.95), // amber-950/95
                  ],
                ),
              ),
            ),
          ),

          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Orange line at the top (h-px bg-orange-500)
              // orange-500: #F97316
              Container(
                height: 1, // h-px = 1px
                width: double.infinity,
                color: const Color(0xFFF97316), // orange-500
              ),

              // Copyright section (py-8 text-center)
              // py-8 = 32px (2rem)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXXL, // py-8 = 32px
                ),
                width: double.infinity,
                child: Text(
                  copyrightText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMediumStyle(
                    color: const Color(0xFFFDE68A), // amber-200
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Footer with network image support
///
/// Use this if the wood texture is loaded from a URL instead of assets.
class FooterNetwork extends StatelessWidget {
  /// Copyright text to display
  final String copyrightText;

  /// URL to wood texture image
  final String? woodTextureUrl;

  /// Margin top (equivalent to mt-12 = 48px)
  final double topMargin;

  const FooterNetwork({
    super.key,
    required this.copyrightText,
    this.woodTextureUrl,
    this.topMargin = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: topMargin),
      child: Stack(
        children: [
          // Background image (wood texture from URL)
          if (woodTextureUrl != null)
            Positioned.fill(
              child: Image.network(
                woodTextureUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF78350F), // amber-900 fallback
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return Container(
                    color: const Color(0xFF78350F), // amber-900 fallback
                  );
                },
              ),
            )
          else
            // Fallback background color if no URL
            Positioned.fill(
              child: Container(
                color: const Color(0xFF78350F), // amber-900
              ),
            ),

          // Gradient overlay (from-amber-900/95 to-amber-950/95)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, // from
                  end: Alignment.bottomRight, // to-br
                  colors: [
                    const Color(0xFF78350F).withValues(alpha: 0.95), // amber-900/95
                    const Color(0xFF451A03).withValues(alpha: 0.95), // amber-950/95
                  ],
                ),
              ),
            ),
          ),

          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Orange line at the top (h-px bg-orange-500)
              Container(
                height: 1, // h-px = 1px
                width: double.infinity,
                color: const Color(0xFFF97316), // orange-500
              ),

              // Copyright section (py-8 text-center)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXXL, // py-8 = 32px
                ),
                width: double.infinity,
                child: Text(
                  copyrightText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMediumStyle(
                    color: const Color(0xFFFDE68A), // amber-200
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


