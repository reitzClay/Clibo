import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for Firebase Remote Config & A/B Testing in Clibo.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Default fallback values when offline or before remote config fetches complete.
  static const Map<String, dynamic> _defaults = {
    'free_tier_daily_limit': 50,
    'default_ai_provider': 'gemini',
    'enable_ollama_local': true,
    'ab_test_welcome_variant': 'control',
  };

  /// Initialize Remote Config with fallbacks and fetch latest configs asynchronously.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.fetchAndActivate();
      debugPrint('RemoteConfigService: Initialized & fetched successfully.');
    } catch (e) {
      debugPrint(
          'RemoteConfigService: Error initializing/fetching remote config (using defaults): $e');
    }
  }

  /// Get the daily message quota limit for free-tier proxy users.
  int get freeTierDailyLimit => _remoteConfig.getInt('free_tier_daily_limit');

  /// Get the default AI provider name ('gemini', 'ollama', etc.).
  String get defaultAiProvider =>
      _remoteConfig.getString('default_ai_provider');

  /// Whether local Ollama integration is enabled.
  bool get isOllamaLocalEnabled =>
      _remoteConfig.getBool('enable_ollama_local');

  /// Get the active A/B testing welcome variant ('control', 'variant_a', 'variant_b').
  String get abTestWelcomeVariant =>
      _remoteConfig.getString('ab_test_welcome_variant');

  /// Generic string getter.
  String getString(String key) => _remoteConfig.getString(key);

  /// Generic bool getter.
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// Generic int getter.
  int getInt(String key) => _remoteConfig.getInt(key);
}
