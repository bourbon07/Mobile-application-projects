import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// AppTheme - Theme configuration for light and dark modes
///
/// This class provides ThemeData for both light and dark themes.
/// Border radius and spacing values will be updated once CSS is provided.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = AppColors.lightPrimary;

  // Border Radius
  // Extracted from CSS: --radius: 0.625rem = 10px
  static const double borderRadius = 10.0; // --radius: 0.625rem
  static const double borderRadiusSmall = 4.0; // Common small radius
  static const double borderRadiusMedium = borderRadius; // 10px (default)
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusXXLarge = 24.0;
  static const double borderRadiusCircular = 999.0;

  // Spacing
  // Based on Tailwind CSS spacing system (4px base unit)
  // Extracted from CSS spacing classes: 0.5rem = 8px, 0.75rem = 12px, 1rem = 16px, 2.5rem = 40px
  static const double spacingXS = 4.0; // 0.25rem
  static const double spacingSM = 8.0; // 0.5rem (space-x-2, ml-2, mr-2)
  static const double spacingMD =
      12.0; // 0.75rem (ml-3, left-3, right-3, pl-3, pr-3)
  static const double spacingLG = 16.0; // 1rem (space-x-4, pr-4, pl-4)
  static const double spacingXL = 24.0; // 1.5rem
  static const double spacingXXL = 32.0; // 2rem
  static const double spacingXXXL = 40.0; // 2.5rem (pl-10)

  // Border Radius Values
  static const BorderRadius borderRadiusSmallValue = BorderRadius.all(
    Radius.circular(borderRadiusSmall),
  );
  static const BorderRadius borderRadiusMediumValue = BorderRadius.all(
    Radius.circular(borderRadiusMedium),
  );
  static const BorderRadius borderRadiusLargeValue = BorderRadius.all(
    Radius.circular(borderRadiusLarge),
  );
  static const BorderRadius borderRadiusXLargeValue = BorderRadius.all(
    Radius.circular(borderRadiusXLarge),
  );
  static const BorderRadius borderRadiusXXLargeValue = BorderRadius.all(
    Radius.circular(borderRadiusXXLarge),
  );
  static const BorderRadius borderRadiusCircularValue = BorderRadius.all(
    Radius.circular(borderRadiusCircular),
  );

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: AppColors.lightColorScheme,
      fontFamily: AppTextStyles.fontFamily,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.titleLargeStyle(
          color: AppColors.lightTextPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMediumValue,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        color: AppColors.lightCard,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputBackground,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.lightError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingLG,
        ),
      ),

      // Button Themes - Wood Texture Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: spacingXL,
                vertical: spacingLG,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: borderRadiusLargeValue,
              ),
              // Wood texture base color (gradient applied via wrapper)
              backgroundColor: AppColors.woodBase,
              foregroundColor: Colors.white,
              textStyle: AppTextStyles.labelLargeStyle(color: Colors.white)
                  .copyWith(
                    shadows: [
                      // Soft glow effect for white text
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.woodDark.withValues(alpha: 0.5);
                }
                return AppColors.woodBase;
              }),
              overlayColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.1),
              ),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingLG,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusLargeValue),
          // Wood texture with border
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          side: BorderSide(color: AppColors.woodDark, width: 2),
          textStyle: AppTextStyles.labelLargeStyle(color: Colors.white)
              .copyWith(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingSM,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusLargeValue),
          // Wood texture style for text buttons too
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.lightTextSecondary,
          textStyle: AppTextStyles.labelLargeStyle(
            color: AppColors.lightTextSecondary,
          ).copyWith(fontWeight: AppTextStyles.bold),
        ),
      ),

      // Text Theme - All text styles use Almarai font
      textTheme:
          TextTheme(
            displayLarge: AppTextStyles.displayLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            displayMedium: AppTextStyles.displayMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            displaySmall: AppTextStyles.displaySmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineLarge: AppTextStyles.headlineLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineMedium: AppTextStyles.headlineMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineSmall: AppTextStyles.headlineSmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleLarge: AppTextStyles.titleLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleMedium: AppTextStyles.titleMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleSmall: AppTextStyles.titleSmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodyLarge: AppTextStyles.bodyLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodyMedium: AppTextStyles.bodyMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodySmall: AppTextStyles.bodySmallStyle(
              color: AppColors.lightTextSecondary,
            ),
            labelLarge: AppTextStyles.labelLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            labelMedium: AppTextStyles.labelMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            labelSmall: AppTextStyles.labelSmallStyle(
              color: AppColors.lightTextSecondary,
            ),
          ).apply(
            fontFamily: AppTextStyles
                .fontFamily, // Ensure Almarai is applied to all text
          ),

      // Primary Text Theme (for AppBar, etc.)
      primaryTextTheme:
          TextTheme(
            displayLarge: AppTextStyles.displayLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            displayMedium: AppTextStyles.displayMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            displaySmall: AppTextStyles.displaySmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineLarge: AppTextStyles.headlineLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineMedium: AppTextStyles.headlineMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            headlineSmall: AppTextStyles.headlineSmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleLarge: AppTextStyles.titleLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleMedium: AppTextStyles.titleMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            titleSmall: AppTextStyles.titleSmallStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodyLarge: AppTextStyles.bodyLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodyMedium: AppTextStyles.bodyMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            bodySmall: AppTextStyles.bodySmallStyle(
              color: AppColors.lightTextSecondary,
            ),
            labelLarge: AppTextStyles.labelLargeStyle(
              color: AppColors.lightTextPrimary,
            ),
            labelMedium: AppTextStyles.labelMediumStyle(
              color: AppColors.lightTextPrimary,
            ),
            labelSmall: AppTextStyles.labelSmallStyle(
              color: AppColors.lightTextSecondary,
            ),
          ).apply(
            fontFamily: AppTextStyles.fontFamily, // Ensure Almarai is applied
          ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: spacingLG,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLargeValue,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        titleTextStyle: AppTextStyles.headlineSmallStyle(
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMediumStyle(
          color: AppColors.lightTextSecondary,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightCard,
        contentTextStyle: AppTextStyles.bodyMediumStyle(
          color: AppColors.lightTextPrimary,
        ),
        actionTextColor: AppColors.lightPrimary,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMediumValue,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColors.darkColorScheme,
      fontFamily: AppTextStyles.fontFamily,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.titleLargeStyle(
          color: AppColors.darkTextPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMediumValue,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        color: AppColors.darkCard,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInput,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumValue,
          borderSide: BorderSide(color: AppColors.darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingLG,
        ),
      ),

      // Button Themes - Wood Texture Style (Dark Theme)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: spacingXL,
                vertical: spacingLG,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: borderRadiusLargeValue,
              ),
              // Wood texture base color
              backgroundColor: AppColors.woodBase,
              foregroundColor: Colors.white,
              textStyle: AppTextStyles.labelLargeStyle(color: Colors.white)
                  .copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.woodDark.withValues(alpha: 0.5);
                }
                return AppColors.woodBase;
              }),
              overlayColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.1),
              ),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingLG,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusLargeValue),
          backgroundColor: AppColors.woodBase.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          side: BorderSide(color: AppColors.woodDark, width: 2),
          textStyle: AppTextStyles.labelLargeStyle(color: Colors.white)
              .copyWith(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: spacingLG,
                vertical: spacingSM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: borderRadiusLargeValue,
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.darkTextPrimary,
              textStyle: AppTextStyles.labelLargeStyle(
                color: AppColors.darkTextPrimary,
              ).copyWith(fontWeight: AppTextStyles.bold),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.woodBase.withValues(alpha: 0.2);
                }
                return Colors.transparent;
              }),
            ),
      ),

      // Text Theme - All text styles use Almarai font
      textTheme:
          TextTheme(
            displayLarge: AppTextStyles.displayLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            displayMedium: AppTextStyles.displayMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            displaySmall: AppTextStyles.displaySmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineLarge: AppTextStyles.headlineLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineMedium: AppTextStyles.headlineMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineSmall: AppTextStyles.headlineSmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleLarge: AppTextStyles.titleLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleMedium: AppTextStyles.titleMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleSmall: AppTextStyles.titleSmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodyLarge: AppTextStyles.bodyLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodyMedium: AppTextStyles.bodyMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodySmall: AppTextStyles.bodySmallStyle(
              color: AppColors.darkTextSecondary,
            ),
            labelLarge: AppTextStyles.labelLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            labelMedium: AppTextStyles.labelMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            labelSmall: AppTextStyles.labelSmallStyle(
              color: AppColors.darkTextSecondary,
            ),
          ).apply(
            fontFamily: AppTextStyles
                .fontFamily, // Ensure Almarai is applied to all text
          ),

      // Primary Text Theme (for AppBar, etc.)
      primaryTextTheme:
          TextTheme(
            displayLarge: AppTextStyles.displayLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            displayMedium: AppTextStyles.displayMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            displaySmall: AppTextStyles.displaySmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineLarge: AppTextStyles.headlineLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineMedium: AppTextStyles.headlineMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            headlineSmall: AppTextStyles.headlineSmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleLarge: AppTextStyles.titleLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleMedium: AppTextStyles.titleMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            titleSmall: AppTextStyles.titleSmallStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodyLarge: AppTextStyles.bodyLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodyMedium: AppTextStyles.bodyMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            bodySmall: AppTextStyles.bodySmallStyle(
              color: AppColors.darkTextSecondary,
            ),
            labelLarge: AppTextStyles.labelLargeStyle(
              color: AppColors.darkTextPrimary,
            ),
            labelMedium: AppTextStyles.labelMediumStyle(
              color: AppColors.darkTextPrimary,
            ),
            labelSmall: AppTextStyles.labelSmallStyle(
              color: AppColors.darkTextSecondary,
            ),
          ).apply(
            fontFamily: AppTextStyles.fontFamily, // Ensure Almarai is applied
          ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: spacingLG,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLargeValue,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        titleTextStyle: AppTextStyles.headlineSmallStyle(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMediumStyle(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTheme.primaryColor.withValues(
          alpha: 0.9,
        ), // Use primary as base for dark snackbar
        contentTextStyle: AppTextStyles.bodyMediumStyle(color: Colors.white),
        actionTextColor: Colors.white,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMediumValue),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
