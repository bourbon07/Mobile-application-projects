import 'package:flutter/material.dart';

/// AppColors - Design tokens for colors
///
/// Extracted from app.css CSS variables.
/// Colors are based on the Vue + Tailwind design system.
class AppColors {
  AppColors._();

  // Light Theme Colors
  // Extracted from :root CSS variables
  static const Color lightBackground = Color(
    0xFFFFFFFF,
  ); // --background: #ffffff
  static const Color lightForeground = Color(
    0xFF252525,
  ); // --foreground: oklch(0.145 0 0) ≈ #252525
  static const Color lightCard = Color(0xFFFFFFFF); // --card: #ffffff
  static const Color lightCardForeground = Color(
    0xFF252525,
  ); // --card-foreground: oklch(0.145 0 0)
  static const Color lightPopover = Color(
    0xFFFFFFFF,
  ); // --popover: oklch(1 0 0) = white
  static const Color lightPopoverForeground = Color(
    0xFF252525,
  ); // --popover-foreground: oklch(0.145 0 0)
  static const Color lightPrimary = Color(0xFF030213); // --primary: #030213
  static const Color lightPrimaryForeground = Color(
    0xFFFFFFFF,
  ); // --primary-foreground: oklch(1 0 0) = white
  static const Color lightSecondary = Color(
    0xFFF2F2F2,
  ); // --secondary: oklch(0.95 0.0058 264.53) ≈ #F2F2F2
  static const Color lightSecondaryForeground = Color(
    0xFF030213,
  ); // --secondary-foreground: #030213
  static const Color lightMuted = Color(0xFFECECF0); // --muted: #ececf0
  static const Color lightMutedForeground = Color(
    0xFF717182,
  ); // --muted-foreground: #717182
  static const Color lightAccent = Color(0xFFE9EBEF); // --accent: #e9ebef
  static const Color lightAccentForeground = Color(
    0xFF030213,
  ); // --accent-foreground: #030213
  static const Color lightDestructive = Color(
    0xFFD4183D,
  ); // --destructive: #d4183d
  static const Color lightDestructiveForeground = Color(
    0xFFFFFFFF,
  ); // --destructive-foreground: #ffffff
  static const Color lightBorder = Color(
    0x1A000000,
  ); // --border: rgba(0, 0, 0, 0.1) = 10% opacity black
  static const Color lightInputBackground = Color(
    0xFFF3F3F5,
  ); // --input-background: #f3f3f5
  static const Color lightSwitchBackground = Color(
    0xFFCBCED4,
  ); // --switch-background: #cbced4
  static const Color lightRing = Color(
    0xFFB5B5B5,
  ); // --ring: oklch(0.708 0 0) ≈ #B5B5B5

  // Dark Theme Colors
  // Extracted from .dark CSS variables
  static const Color darkBackground = Color(
    0xFF252525,
  ); // --background: oklch(0.145 0 0) ≈ #252525
  static const Color darkForeground = Color(
    0xFFFAFAFA,
  ); // --foreground: oklch(0.985 0 0) ≈ #FAFAFA
  static const Color darkCard = Color(0xFF252525); // --card: oklch(0.145 0 0)
  static const Color darkCardForeground = Color(
    0xFFFAFAFA,
  ); // --card-foreground: oklch(0.985 0 0)
  static const Color darkPopover = Color(
    0xFF252525,
  ); // --popover: oklch(0.145 0 0)
  static const Color darkPopoverForeground = Color(
    0xFFFAFAFA,
  ); // --popover-foreground: oklch(0.985 0 0)
  static const Color darkPrimary = Color(
    0xFFFAFAFA,
  ); // --primary: oklch(0.985 0 0) ≈ white
  static const Color darkPrimaryForeground = Color(
    0xFF353535,
  ); // --primary-foreground: oklch(0.205 0 0) ≈ #353535
  static const Color darkSecondary = Color(
    0xFF454545,
  ); // --secondary: oklch(0.269 0 0) ≈ #454545
  static const Color darkSecondaryForeground = Color(
    0xFFFAFAFA,
  ); // --secondary-foreground: oklch(0.985 0 0)
  static const Color darkMuted = Color(0xFF454545); // --muted: oklch(0.269 0 0)
  static const Color darkMutedForeground = Color(
    0xFFB5B5B5,
  ); // --muted-foreground: oklch(0.708 0 0)
  static const Color darkAccent = Color(
    0xFF454545,
  ); // --accent: oklch(0.269 0 0)
  static const Color darkAccentForeground = Color(
    0xFFFAFAFA,
  ); // --accent-foreground: oklch(0.985 0 0)
  static const Color darkDestructive = Color(
    0xFFC85A3A,
  ); // --destructive: oklch(0.396 0.141 25.723) ≈ #C85A3A
  static const Color darkDestructiveForeground = Color(
    0xFFE88A6B,
  ); // --destructive-foreground: oklch(0.637 0.237 25.331) ≈ #E88A6B
  static const Color darkBorder = Color(
    0xFF454545,
  ); // --border: oklch(0.269 0 0)
  static const Color darkInput = Color(0xFF454545); // --input: oklch(0.269 0 0)
  static const Color darkRing = Color(
    0xFF707070,
  ); // --ring: oklch(0.439 0 0) ≈ #707070

  // Semantic color mappings for Material Design compatibility (Light Theme)
  static const Color lightTextPrimary = lightForeground;
  static const Color lightTextSecondary = lightMutedForeground;
  static const Color lightDivider = lightBorder;
  static const Color lightSurface = lightCard;
  static const Color lightError = lightDestructive;
  static const Color lightOnPrimary = lightPrimaryForeground;
  static const Color lightOnSecondary = lightSecondaryForeground;
  static const Color lightOnBackground = lightForeground;
  static const Color lightOnSurface = lightForeground;
  static const Color lightOnError = lightDestructiveForeground;

  // Semantic color mappings for Material Design compatibility (Dark Theme)
  static const Color darkTextPrimary = darkForeground;
  static const Color darkTextSecondary = darkMutedForeground;
  static const Color darkDivider = darkBorder;
  static const Color darkSurface = darkCard;
  static const Color darkError = darkDestructive;
  static const Color darkOnPrimary = darkPrimaryForeground;
  static const Color darkOnSecondary = darkSecondaryForeground;
  static const Color darkOnBackground = darkForeground;
  static const Color darkOnSurface = darkForeground;
  static const Color darkOnError = darkDestructiveForeground;

  /// Get light theme color scheme
  static ColorScheme get lightColorScheme => ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    error: lightError,
    onError: lightOnError,
    surface: lightSurface,
    onSurface: lightOnSurface,
  );

  /// Get dark theme color scheme
  static ColorScheme get darkColorScheme => ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    error: darkError,
    onError: darkOnError,
    surface: darkSurface,
    onSurface: darkOnSurface,
  );

  // Wood Texture Colors
  // Light to medium brown wood grain colors
  static const Color woodLight = Color(0xFFD4A574); // Light brown wood
  static const Color woodMedium = Color(0xFFB8864F); // Medium brown wood
  static const Color woodDark = Color(0xFF8B5A3C); // Darker brown wood
  static const Color woodBase = Color(0xFFA67C52); // Base wood color
}
