import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../screen_capturer.dart';

class AndroidScreenCapturer implements ScreenCapturer {
  static const MethodChannel _channel = MethodChannel('com.claybytes.clibo/screen_capture');

  @override
  Future<bool> hasPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('hasPermissions');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Uint8List?> captureScreen() async {
    try {
      final Uint8List? imageBytes = await _channel.invokeMethod<Uint8List>('captureScreen');
      if (imageBytes != null && imageBytes.isNotEmpty) {
        return imageBytes;
      }
    } catch (e) {
      debugPrint("Native screen capture channel info: $e");
    }
    return null;
  }
}
