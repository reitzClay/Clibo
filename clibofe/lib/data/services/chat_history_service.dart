import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';

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

  Future<List<ChatSessionItem>> _getLocalHistory() async {
    try {
      final jsonString = await _storage.read(key: _keyHistory);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => ChatSessionItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("[ChatHistoryService] Error loading local history: $e");
      return [];
    }
  }

  Future<void> _saveLocalHistory(List<ChatSessionItem> items) async {
    try {
      List<ChatSessionItem> listToSave = items;
      if (listToSave.length > 100) {
        listToSave = listToSave.sublist(0, 100);
      }
      final encoded = jsonEncode(listToSave.map((e) => e.toJson()).toList());
      await _storage.write(key: _keyHistory, value: encoded);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error saving local history: $e");
    }
  }

  /// Loads chat history from local storage and merges with backend history if available.
  Future<List<ChatSessionItem>> loadHistory() async {
    final localList = await _getLocalHistory();

    try {
      final aiClient = locator<CliboAIClient>();
      if (aiClient is BackendProxyAIClient) {
        final remoteHistory = await aiClient.fetchChatHistory();
        if (remoteHistory != null && remoteHistory.isNotEmpty) {
          final List<ChatSessionItem> remoteSessions =
              remoteHistory.map((json) => ChatSessionItem.fromJson(json)).toList();

          // Merge local and remote sessions, preserving local sessions that are not on remote
          final Map<String, ChatSessionItem> sessionMap = {};

          for (final session in remoteSessions) {
            sessionMap[session.id] = session;
          }

          for (final session in localList) {
            if (!sessionMap.containsKey(session.id)) {
              sessionMap[session.id] = session;
            }
          }

          final mergedList = sessionMap.values.toList();
          mergedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          await _saveLocalHistory(mergedList);
          return mergedList;
        }
      }
    } catch (e) {
      debugPrint("[ChatHistoryService] Error syncing with backend: $e");
    }

    return localList;
  }

  /// Saves a new chat interaction immediately to local storage.
  Future<void> addSession({
    required String prompt,
    required String response,
    required String provider,
  }) async {
    try {
      final localList = await _getLocalHistory();
      final newItem = ChatSessionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        response: response,
        provider: provider,
        timestamp: DateTime.now(),
      );

      localList.insert(0, newItem);
      await _saveLocalHistory(localList);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error adding chat session: $e");
    }
  }

  /// Deletes a session locally and remotely.
  Future<void> deleteSession(String id) async {
    try {
      final aiClient = locator<CliboAIClient>();
      if (aiClient is BackendProxyAIClient) {
        await aiClient.deleteBackendSession(id);
      }

      final localList = await _getLocalHistory();
      localList.removeWhere((item) => item.id == id);
      await _saveLocalHistory(localList);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error deleting chat session: $e");
    }
  }

  /// Clears chat history locally and remotely.
  Future<void> clearHistory() async {
    try {
      final aiClient = locator<CliboAIClient>();
      if (aiClient is BackendProxyAIClient) {
        await aiClient.clearBackendHistory();
      }
      await _storage.delete(key: _keyHistory);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error clearing history: $e");
    }
  }
}
