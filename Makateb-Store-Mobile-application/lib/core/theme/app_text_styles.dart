import 'package:flutter/material.dart';

/// AppTextStyles - Design tokens for typography
/// 
/// Based on Almarai font family with weights: 300 (Light), 400 (Regular), 
/// 700 (Bold), 800 (ExtraBold)
class AppTextStyles {
  AppTextStyles._();

  // Font Family
  static const String fontFamily = 'Almarai';

  // Font Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Base Font Size
  // Extracted from CSS: --font-size: 16px
  static const double baseFontSize = 16.0;

  // Font Weights (from CSS)
  static const FontWeight medium = FontWeight.w500; // --font-weight-medium: 500
  static const FontWeight normal = FontWeight.w400; // --font-weight-normal: 400

  // Font Sizes
  // Based on Material Design 3 typography scale, using 16px as base
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = baseFontSize; // 16px
  static const double titleSmall = 14.0;
  static const double bodyLarge = baseFontSize; // 16px
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  // Tailwind Font Sizes (for Vue parity)
  // text-xs = 12px, text-sm = 14px, text-base = 16px, text-lg = 18px
  // text-xl = 20px, text-2xl = 24px, text-3xl = 30px, text-4xl = 36px
  // text-5xl = 48px, text-6xl = 60px
  static const double textXS = 12.0; // text-xs
  static const double textSM = 14.0; // text-sm
  static const double textBase = 16.0; // text-base (same as baseFontSize)
  static const double textLG = 18.0; // text-lg
  static const double textXL = 20.0; // text-xl
  static const double text2XL = 24.0; // text-2xl
  static const double text3XL = 30.0; // text-3xl
  static const double text4XL = 36.0; // text-4xl
  static const double text5XL = 48.0; // text-5xl
  static const double text6XL = 60.0; // text-6xl

  // Display Styles
  static TextStyle displayLargeStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: displayLarge,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: -0.25,
        height: 1.2,
      );

  static TextStyle displayMediumStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: displayMedium,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0,
        height: 1.2,
      );

  static TextStyle displaySmallStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: displaySmall,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0,
        height: 1.2,
      );

  // Headline Styles
  static TextStyle headlineLargeStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: headlineLarge,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle headlineMediumStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: headlineMedium,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle headlineSmallStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: headlineSmall,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0,
        height: 1.3,
      );

  // Title Styles
  static TextStyle titleLargeStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: titleLarge,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle titleMediumStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: titleMedium,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle titleSmallStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: titleSmall,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // Body Styles
  static TextStyle bodyLargeStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyLarge,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle bodyMediumStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyMedium,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle bodySmallStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: bodySmall,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.4,
        height: 1.5,
      );

  // Label Styles
  static TextStyle labelLargeStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: labelLarge,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle labelMediumStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: labelMedium,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.5,
        height: 1.4,
      );

  static TextStyle labelSmallStyle({
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: labelSmall,
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // Utility methods matching CSS classes
  static TextStyle almaraiLight({
    double? fontSize,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontWeight: light,
        fontSize: fontSize,
        color: color,
      );

  static TextStyle almaraiRegular({
    double? fontSize,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontWeight: regular,
        fontSize: fontSize,
        color: color,
      );

  static TextStyle almaraiBold({
    double? fontSize,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontWeight: bold,
        fontSize: fontSize,
        color: color,
      );

  static TextStyle almaraiExtraBold({
    double? fontSize,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontWeight: extraBold,
        fontSize: fontSize,
        color: color,
      );
}



