import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkConfig {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String keyBackendUrl = 'clibo_backend_url';

  /// Default backend URL based on current host environment.
  /// Android Emulator -> http://10.0.2.2:8080/api/v1
  /// Desktop / Web / iOS Simulator -> http://localhost:8080/api/v1
  static String get defaultBackendUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    return 'https://clibobe-277710406862.europe-west4.run.app/api/v1';
  }

  /// Retrieves the effective Spring Boot backend base URL.
  /// Prioritizes user-configured URL in secure storage, then falls back to [defaultBackendUrl].
  static Future<String> getBackendBaseUrl() async {
    try {
      final customUrl = await _storage.read(key: keyBackendUrl);
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        return customUrl.trim();
      }
    } catch (e) {
      debugPrint("NetworkConfig read error: $e");
    }
    return defaultBackendUrl;
  }

  /// Updates and persists the backend base URL in secure storage.
  static Future<void> setBackendBaseUrl(String url) async {
    await _storage.write(key: keyBackendUrl, value: url.trim());
  }
}
