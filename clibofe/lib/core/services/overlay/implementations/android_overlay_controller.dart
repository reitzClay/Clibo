/// # Android-specific code only
library;
// lib/core/services/overlay/implementations/android_overlay_controller.dart
import '../overlay_controller.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AndroidOverlayController implements OverlayController {
  @override
  Future<bool> checkOverlayPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  @override
  Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  @override
  Future<void> showOverlay() async {
    if (await checkOverlayPermission()) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerRight,
      );
    }
  }

  @override
  Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> updateAnimationState(String stateName) async {
    // Send data to the running overlay entry isolate/window
    await FlutterOverlayWindow.shareData(stateName);
  }
}
