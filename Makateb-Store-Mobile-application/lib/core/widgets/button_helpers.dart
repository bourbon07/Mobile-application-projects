import 'package:flutter/material.dart';
import 'wood_textured_button.dart';

/// ButtonHelpers - Helper functions and extensions for wood-textured buttons
///
/// Provides utilities to wrap standard Flutter buttons with wood texture style.
class ButtonHelpers {
  ButtonHelpers._();

  /// Wrap an ElevatedButton with wood texture
  ///
  /// Usage:
  /// ```dart
  /// ButtonHelpers.wrapElevatedButton(
  ///   ElevatedButton(
  ///     onPressed: () {},
  ///     child: Text('Shop Now'),
  ///   ),
  /// )
  /// ```
  static Widget wrapElevatedButton(Widget button) {
    return WoodTexturedButton(child: button);
  }

  /// Wrap a TextButton with wood texture
  static Widget wrapTextButton(Widget button) {
    return WoodTexturedButton(child: button);
  }

  /// Wrap an OutlinedButton with wood texture
  static Widget wrapOutlinedButton(Widget button) {
    return WoodTexturedButton(child: button);
  }

  /// Wrap any button with wood texture
  static Widget wrapButton(Widget button) {
    return WoodTexturedButton(child: button);
  }
}

/// Extension methods for easier button wrapping
extension ButtonExtension on Widget {
  /// Wrap this button with wood texture
  ///
  /// Usage:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {},
  ///   child: Text('Shop Now'),
  /// ).withWoodTexture()
  /// ```
  Widget withWoodTexture() {
    if (this is ElevatedButton ||
        this is TextButton ||
        this is OutlinedButton ||
        this is IconButton) {
      return WoodTexturedButton(child: this);
    }
    return this;
  }
}



