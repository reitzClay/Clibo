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
    String? backendBaseUrl,
    FlutterSecureStorage? storage,
  }) : backendBaseUrl = backendBaseUrl ?? const String.fromEnvironment(
         'BACKEND_URL',
         defaultValue: 'http://192.168.0.103:8080/api/v1',
       ),
       _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String> generateResponse(
    String prompt, {
    String? imageBase64,
    String? imageMimeType,
    String? audioBase64,
    String? audioMimeType,
  }) async {
    final String? token = await _storage.read(key: _keyAuthToken);
    final String providerId = await _storage.read(key: 'clibo_ai_provider') ?? 'ollama';
    final String ollamaUrl = await _storage.read(key: 'clibo_ollama_url') ?? 'http://192.168.0.103:11434';
    final String ollamaModel = await _storage.read(key: 'clibo_ollama_model') ?? 'tinyllama:1.1b';
    final String byokKey = await _storage.read(key: 'clibo_byok_key') ?? '';
    final String customUrl = await _storage.read(key: 'clibo_custom_provider_url') ?? '';
    final String customModel = await _storage.read(key: 'clibo_custom_model') ?? '';

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
          'aiProvider': providerId,
          'ollamaBaseUrl': ollamaUrl,
          'ollamaModel': ollamaModel,
          'byokApiKey': byokKey,
          'customBaseUrl': customUrl,
          'customModel': customModel,
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

      final rawBody = buffer.toString().trim();

      // 1. Quick check: try parsing rawBody directly if it's JSON or prefixed with data:
      String directParse = rawBody;
      if (directParse.startsWith('data:')) {
        directParse = directParse.substring(5).trim();
      }
      try {
        final decoded = jsonDecode(directParse);
        if (decoded is Map) {
          if (decoded.containsKey('error')) {
            throw Exception(decoded['error']);
          }
          if (decoded.containsKey('text')) {
            return _cleanText(decoded['text'].toString());
          }
          if (decoded.containsKey('response')) {
            return _cleanText(decoded['response'].toString());
          }
        }
      } catch (_) {}

      // 2. Line-by-line SSE / chunk parsing
      final StringBuffer result = StringBuffer();
      for (final line in rawBody.split(RegExp(r'\r?\n'))) {
        String cleanLine = line.trim();
        if (cleanLine.startsWith('data:')) {
          cleanLine = cleanLine.substring(5).trim();
        }
        if (cleanLine.isEmpty || cleanLine.startsWith(':')) continue;

        try {
          final parsed = jsonDecode(cleanLine);
          if (parsed is Map) {
            if (parsed.containsKey('error')) {
              throw Exception(parsed['error']);
            }
            if (parsed.containsKey('text')) {
              result.write(parsed['text']);
            } else if (parsed.containsKey('response')) {
              result.write(parsed['response']);
            }
          }
        } catch (_) {
          final match = RegExp(r'"(?:text|response)"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(cleanLine);
          if (match != null && match.group(1) != null) {
            result.write(match.group(1)!);
          } else if (!cleanLine.startsWith('{') && !cleanLine.startsWith('}')) {
            result.write(cleanLine);
          }
        }
      }

      final finalOutput = _cleanText(result.toString());
      return finalOutput.isNotEmpty ? finalOutput : _cleanText(rawBody);
    } finally {
      client.close();
    }
  }

  String _cleanText(String text) {
    String cleaned = text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\u0027', "'")
        .replaceAll(r'\u0026', "&")
        .replaceAll(r'\\', '\\')
        .trim();

    if (cleaned.startsWith('data:')) {
      cleaned = cleaned.substring(5).trim();
    }

    if (cleaned.startsWith('{"error":') || cleaned.contains('"error":')) {
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map && decoded.containsKey('error')) {
          return "Error: ${decoded['error']}";
        }
      } catch (_) {}
    }

    if (cleaned.startsWith('{"text":') || cleaned.startsWith('{"response":')) {
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map) {
          if (decoded.containsKey('text')) {
            cleaned = decoded['text'].toString();
          } else if (decoded.containsKey('response')) {
            cleaned = decoded['response'].toString();
          }
        }
      } catch (_) {}
    }

    if (cleaned.endsWith('}') && !cleaned.contains('{')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    return cleaned.trim();
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

  /// Checks if the Spring Boot backend is healthy and reachable
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/ai/health'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'UP';
      }
    } catch (_) {}
    return false;
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
