/// # The abstract interface
library;
// lib/core/services/overlay/overlay_controller.dart

abstract class OverlayController {
  /// Check if the app is allowed to draw over other apps (SYSTEM_ALERT_WINDOW).
  Future<bool> checkOverlayPermission();

  /// Request the overlay permission from the user.
  Future<void> requestOverlayPermission();

  /// Show the floating overlay asset.
  Future<void> showOverlay();

  /// Hide or destroy the floating overlay.
  Future<void> hideOverlay();

  /// Update the Lottie state (e.g., 'idle', 'thinking', 'speaking').
  Future<void> updateAnimationState(String stateName);
}
