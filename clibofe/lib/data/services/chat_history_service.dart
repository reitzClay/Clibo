import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatSessionItem {
  final String id;
  final String prompt;
  final String response;
  final String provider;
  final DateTime timestamp;

  ChatSessionItem({
    required this.id,
    required this.prompt,
    required this.response,
    required this.provider,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'response': response,
        'provider': provider,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) => ChatSessionItem(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: json['prompt']?.toString() ?? '',
        response: json['response']?.toString() ?? '',
        provider: json['provider']?.toString() ?? 'Gemini',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class ChatHistoryService {
  final FlutterSecureStorage _storage;
  static const String _keyHistory = 'clibo_chat_history_logs';

  ChatHistoryService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<ChatSessionItem>> loadHistory() async {
    try {
      final jsonString = await _storage.read(key: _keyHistory);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => ChatSessionItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("[ChatHistoryService] Error loading history: $e");
      return [];
    }
  }

  Future<void> addSession({
    required String prompt,
    required String response,
    required String provider,
  }) async {
    try {
      final currentList = await loadHistory();
      final newItem = ChatSessionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        response: response,
        provider: provider,
        timestamp: DateTime.now(),
      );

      currentList.insert(0, newItem);

      // Keep up to 100 recent sessions in local history
      if (currentList.length > 100) {
        currentList.removeRange(100, currentList.length);
      }

      final encoded = jsonEncode(currentList.map((e) => e.toJson()).toList());
      await _storage.write(key: _keyHistory, value: encoded);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error saving chat session: $e");
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final currentList = await loadHistory();
      currentList.removeWhere((item) => item.id == id);
      final encoded = jsonEncode(currentList.map((e) => e.toJson()).toList());
      await _storage.write(key: _keyHistory, value: encoded);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error deleting chat session: $e");
    }
  }

  Future<void> clearHistory() async {
    try {
      await _storage.delete(key: _keyHistory);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error clearing history: $e");
    }
  }
}
