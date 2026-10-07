import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';

class ChatMessagePair {
  final String prompt;
  final String response;
  final DateTime timestamp;

  ChatMessagePair({
    required this.prompt,
    required this.response,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'response': response,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessagePair.fromJson(Map<String, dynamic> json) => ChatMessagePair(
        prompt: json['prompt']?.toString() ?? '',
        response: json['response']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class ChatSessionItem {
  final String id;
  final String title;
  final String provider;
  final DateTime timestamp;
  final List<ChatMessagePair> messages;

  ChatSessionItem({
    required this.id,
    required this.title,
    required this.provider,
    required this.timestamp,
    required this.messages,
  });

  String get lastPrompt => messages.isNotEmpty ? messages.last.prompt : title;
  String get lastResponse => messages.isNotEmpty ? messages.last.response : '';
  int get messageCount => messages.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'provider': provider,
        'timestamp': timestamp.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) {
    List<ChatMessagePair> msgs = [];
    if (json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => ChatMessagePair.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (json['prompt'] != null || json['response'] != null) {
      msgs.add(ChatMessagePair(
        prompt: json['prompt']?.toString() ?? '',
        response: json['response']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      ));
    }

    final String titleStr = json['title']?.toString() ??
        (msgs.isNotEmpty ? msgs.first.prompt : 'Chat Session');

    return ChatSessionItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleStr,
      provider: json['provider']?.toString() ?? 'Gemini',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: msgs,
    );
  }
}

class ChatHistoryService {
  final FlutterSecureStorage _storage;
  static const String _keyHistory = 'clibo_chat_history_logs';
  String? _activeSessionId;

  ChatHistoryService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Call this when clear chat is pressed or overlay session ends to start a fresh thread on next prompt
  void startNewSession() {
    _activeSessionId = null;
  }

  /// Explicitly set active session ID when resuming a past conversation from Chat History
  void setActiveSessionId(String? id) {
    _activeSessionId = id;
  }

  String? get activeSessionId => _activeSessionId;

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

  /// Adds a message pair (prompt + response) into the active conversation session.
  Future<void> addSession({
    required String prompt,
    required String response,
    required String provider,
  }) async {
    try {
      final localList = await _getLocalHistory();
      final now = DateTime.now();
      final newPair = ChatMessagePair(prompt: prompt, response: response, timestamp: now);

      ChatSessionItem? targetSession;
      if (_activeSessionId != null) {
        final index = localList.indexWhere((s) => s.id == _activeSessionId);
        if (index != -1) {
          targetSession = localList.removeAt(index);
        }
      } else if (localList.isNotEmpty) {
        final top = localList.first;
        if (now.difference(top.timestamp).inMinutes < 20) {
          targetSession = localList.removeAt(0);
          _activeSessionId = targetSession.id;
        }
      }

      if (targetSession != null) {
        final updatedMessages = List<ChatMessagePair>.from(targetSession.messages)..add(newPair);
        final updatedSession = ChatSessionItem(
          id: targetSession.id,
          title: targetSession.title,
          provider: provider,
          timestamp: now,
          messages: updatedMessages,
        );
        localList.insert(0, updatedSession);
      } else {
        final newId = now.millisecondsSinceEpoch.toString();
        _activeSessionId = newId;
        final newSession = ChatSessionItem(
          id: newId,
          title: prompt.length > 40 ? "${prompt.substring(0, 40)}..." : prompt,
          provider: provider,
          timestamp: now,
          messages: [newPair],
        );
        localList.insert(0, newSession);
      }

      await _saveLocalHistory(localList);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error adding message to session: $e");
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
      if (_activeSessionId == id) {
        _activeSessionId = null;
      }
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
      _activeSessionId = null;
      await _storage.delete(key: _keyHistory);
    } catch (e) {
      debugPrint("[ChatHistoryService] Error clearing history: $e");
    }
  }
}
