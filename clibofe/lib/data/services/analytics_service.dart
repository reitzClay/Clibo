import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for logging analytics events in Clibo.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Log when a chat prompt is submitted to an AI provider.
  Future<void> logPromptSent({
    required String provider,
    required bool isBYOK,
    required int promptLength,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'prompt_sent',
        parameters: {
          'provider': provider,
          'is_byok': isBYOK ? 1 : 0,
          'prompt_length': promptLength,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: Error logging prompt_sent: $e');
    }
  }

  /// Log when the user switches their active AI model or provider.
  Future<void> logModelChanged({
    required String newProvider,
    String? model,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'model_changed',
        parameters: {
          'new_provider': newProvider,
          'model': model ?? 'default',
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: Error logging model_changed: $e');
    }
  }

  /// Log when the floating overlay is toggled (opened or closed).
  Future<void> logOverlayToggled({required bool isOpen}) async {
    try {
      await _analytics.logEvent(
        name: 'overlay_toggled',
        parameters: {
          'is_open': isOpen ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: Error logging overlay_toggled: $e');
    }
  }

  /// Log when a Bring-Your-Own-Key (BYOK) is saved.
  Future<void> logBYOKSaved({required String provider}) async {
    try {
      await _analytics.logEvent(
        name: 'byok_saved',
        parameters: {
          'provider': provider,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: Error logging byok_saved: $e');
    }
  }

  /// Log user authentication event.
  Future<void> logUserLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('AnalyticsService: Error logging login: $e');
    }
  }

  /// Log application or streaming errors for diagnostic tracking.
  Future<void> logError({
    required String context,
    required String errorMessage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'context': context,
          'error_message': errorMessage.length > 100
              ? errorMessage.substring(0, 100)
              : errorMessage,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService: Error logging app_error: $e');
    }
  }
}
