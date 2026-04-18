import 'package:flutter/material.dart';

/// OverlayManager - Manages overlay z-indexing and ensures only one overlay active at a time
///
/// Handles coordination between menus, modals, and toasts to prevent overlapping issues.
class OverlayManager {
  OverlayManager._();
  static final OverlayManager instance = OverlayManager._();

  // Z-index layers (higher number = on top)
  static const int toastLayer = 10000;
  static const int modalLayer = 9000;
  static const int menuLayer = 8000;

  // Track active overlays
  final Set<String> _activeOverlays = {};
  final Map<String, OverlayEntry> _overlayEntries = {};

  /// Register an overlay
  void registerOverlay(String id, OverlayEntry entry) {
    _overlayEntries[id] = entry;
    _activeOverlays.add(id);
  }

  /// Unregister an overlay
  void unregisterOverlay(String id) {
    _overlayEntries.remove(id);
    _activeOverlays.remove(id);
  }

  /// Close all overlays of a specific type
  void closeAllOfType(OverlayType type) {
    final idsToClose = _activeOverlays.where((id) {
      return _getOverlayType(id) == type;
    }).toList();

    for (final id in idsToClose) {
      _closeOverlay(id);
    }
  }

  /// Close all overlays except toasts
  void closeAllMenusAndModals() {
    final idsToClose = _activeOverlays.where((id) {
      final type = _getOverlayType(id);
      return type != OverlayType.toast;
    }).toList();

    for (final id in idsToClose) {
      _closeOverlay(id);
    }
  }

  /// Close a specific overlay
  void _closeOverlay(String id) {
    final entry = _overlayEntries[id];
    if (entry != null) {
      entry.remove();
      unregisterOverlay(id);
    }
  }

  /// Get overlay type from ID
  OverlayType _getOverlayType(String id) {
    if (id.startsWith('toast_')) return OverlayType.toast;
    if (id.startsWith('modal_')) return OverlayType.modal;
    if (id.startsWith('menu_')) return OverlayType.menu;
    return OverlayType.other;
  }

  /// Check if any overlay is active
  bool get hasActiveOverlay => _activeOverlays.isNotEmpty;

  /// Check if a specific overlay type is active
  bool isTypeActive(OverlayType type) {
    return _activeOverlays.any((id) => _getOverlayType(id) == type);
  }
}

/// OverlayType - Types of overlays
enum OverlayType {
  toast,
  modal,
  menu,
  other,
}


