import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'app/service_locator.dart';
import 'data/services/remote_config_service.dart';
import 'features/companion/presentation/screens/splash_screen.dart';
import 'features/companion/presentation/widgets/overlay/clibo_robot_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupServices();

  // Pass uncaught Flutter framework errors to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Remote Config & A/B testing fallbacks
  await locator<RemoteConfigService>().initialize();

  // Top-level listener on Main Application Isolate for Overlay Requests
  FlutterOverlayWindow.overlayListener.listen((data) {
    debugPrint("[MainIsolate] overlayListener event received: $data");
  });

  runApp(const CliboApp());
}

// Overlay Entry Point (Separate Background Service Isolate)
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupServices();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CliboRobotOverlay(),
    ),
  );
}

class CliboApp extends StatelessWidget {
  const CliboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Clibo AI Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(
          primary: Colors.blueAccent,
          background: Color(0xFF121212),
          card: Color(0xFF1E1E1E),
        ),
      ),
      home: const SplashScreen(),
      builder: (context, child) => ScaffoldMessenger(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
