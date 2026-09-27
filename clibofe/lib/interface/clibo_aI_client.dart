import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// The blueprint for any AI client
abstract class CliboAIClient {
  Future<String> generateResponse(
    String prompt, {
    String? imageBase64,
    String? imageMimeType,
    String? audioBase64,
    String? audioMimeType,
  });
}

/// Default production client: Proxies through your Spring Boot backend to meter usage and enforce quotas
class BackendProxyAIClient implements CliboAIClient {
  final String backendBaseUrl;
  final FlutterSecureStorage _storage;
  static const String _keyAuthToken = 'clibo_auth_token';

  BackendProxyAIClient({
    this.backendBaseUrl = 'http://10.0.2.2:8080/api/v1',
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String> generateResponse(
    String prompt, {
    String? imageBase64,
    String? imageMimeType,
    String? audioBase64,
    String? audioMimeType,
  }) async {
    final String? token = await _storage.read(key: _keyAuthToken);
    final client = http.Client();

    try {
      final request = http.Request('POST', Uri.parse('$backendBaseUrl/ai/chat'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        })
        ..body = jsonEncode({
          'prompt': prompt,
          if (imageBase64 != null) 'imageBase64': imageBase64,
          if (imageMimeType != null) 'imageMimeType': imageMimeType,
          if (audioBase64 != null) 'audioBase64': audioBase64,
          if (audioMimeType != null) 'audioMimeType': audioMimeType,
        });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        try {
          final Map<String, dynamic> errorMap = jsonDecode(body);
          throw Exception(errorMap['error'] ?? 'AI request failed (${streamedResponse.statusCode})');
        } catch (_) {
          throw Exception('AI request failed with status ${streamedResponse.statusCode}: $body');
        }
      }

      final StringBuffer buffer = StringBuffer();
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
      }

      final rawBody = buffer.toString();
      final StringBuffer result = StringBuffer();
      for (final line in rawBody.split('\n')) {
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data.isNotEmpty) {
            try {
              final parsed = jsonDecode(data);
              if (parsed is Map) {
                if (parsed.containsKey('error')) {
                  throw Exception(parsed['error']);
                }
                if (parsed.containsKey('candidates')) {
                  final candidates = parsed['candidates'] as List;
                  if (candidates.isNotEmpty) {
                    final content = candidates[0]['content'];
                    if (content != null && content['parts'] != null) {
                      for (final part in content['parts']) {
                        if (part['text'] != null) {
                          result.write(part['text']);
                        }
                      }
                    }
                  }
                }
              }
            } catch (_) {
              result.write(data);
            }
          }
        } else if (line.trim().isNotEmpty && !line.startsWith(':')) {
          result.write(line);
        }
      }

      final finalOutput = result.toString().trim();
      return finalOutput.isNotEmpty ? finalOutput : rawBody.trim();
    } finally {
      client.close();
    }
  }

  /// Fetches the user's current metered usage stats (messages, screenshots, voice notes remaining)
  Future<Map<String, dynamic>?> fetchUsageStats() async {
    try {
      final String? token = await _storage.read(key: _keyAuthToken);
      final response = await http.get(
        Uri.parse('$backendBaseUrl/ai/usage'),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}

/// Optional BYOK implementation if user provides their own Gemini API key
class GeminiClient implements CliboAIClient {
  final String apiKey;
  GeminiClient(this.apiKey);

  @override
  Future<String> generateResponse(
    String prompt, {
    String? imageBase64,
    String? imageMimeType,
    String? audioBase64,
    String? audioMimeType,
  }) async {
    // Direct call using user's BYOK key
    return "Response from Gemini (BYOK)";
  }
}

/// Optional BYOK implementation for Claude / Custom OpenAI endpoints
class OpenAiCompatibleClient implements CliboAIClient {
  final String apiKey;
  final String baseUrl;
  final String modelName;
  OpenAiCompatibleClient({required this.apiKey, required this.baseUrl, required this.modelName});

  @override
  Future<String> generateResponse(
    String prompt, {
    String? imageBase64,
    String? imageMimeType,
    String? audioBase64,
    String? audioMimeType,
  }) async {
    return "Response from custom endpoint";
  }
}
