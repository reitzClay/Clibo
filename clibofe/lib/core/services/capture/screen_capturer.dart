/// # The abstract interface
library;
// lib/core/services/capture/screen_capturer.dart
import 'dart:typed_data';

abstract class ScreenCapturer {
  /// Checks if the user has granted OS-level Screen Recording / MediaProjection permissions.
  Future<bool> hasPermissions();

  /// Requests permissions from the system.
  Future<bool> requestPermissions();

  /// Captures the screen canvas and returns compressed bytes (JPEG/WebP) for the LLM.
  Future<Uint8List?> captureScreen();
}
