import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';

class ChatMessagePair {
  final String prompt;
  final String response;
  final String provider;
  final DateTime timestamp;

  ChatMessagePair({
    required this.prompt,
    required this.response,
    required this.provider,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'response': response,
        'provider': provider,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessagePair.fromJson(Map<String, dynamic> json, {String? defaultProvider}) => ChatMessagePair(
        prompt: json['prompt']?.toString() ?? '',
        response: json['response']?.toString() ?? '',
        provider: json['provider']?.toString() ?? defaultProvider ?? 'Google Gemini',
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
  String get initialProvider => messages.isNotEmpty ? messages.first.provider : provider;
  String get activeProvider => messages.isNotEmpty ? messages.last.provider : provider;
  int get messageCount => messages.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'provider': provider,
        'timestamp': timestamp.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) {
    final String defaultProvider = json['provider']?.toString() ?? 'Google Gemini';

    List<ChatMessagePair> msgs = [];
    if (json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => ChatMessagePair.fromJson(m as Map<String, dynamic>, defaultProvider: defaultProvider))
          .toList();
    } else if (json['prompt'] != null || json['response'] != null) {
      msgs.add(ChatMessagePair(
        prompt: json['prompt']?.toString() ?? '',
        response: json['response']?.toString() ?? '',
        provider: defaultProvider,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      ));
    }

    final String initialProvider = msgs.isNotEmpty ? msgs.first.provider : defaultProvider;
    final String titleStr = json['title']?.toString() ??
        (msgs.isNotEmpty ? msgs.first.prompt : 'Chat Session');

    return ChatSessionItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleStr,
      provider: initialProvider,
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

  /// Deduplicates sessions by ID and merges/removes fragment sessions whose messages
  /// are already subsumed inside a larger multi-turn conversation session.
  List<ChatSessionItem> _deduplicateSessions(List<ChatSessionItem> rawList) {
    if (rawList.isEmpty) return [];

    // 1. Group & merge by exact ID first
    final Map<String, ChatSessionItem> sessionMap = {};

    for (final session in rawList) {
      final String idKey = session.id.trim();
      if (idKey.isEmpty) continue;

      if (sessionMap.containsKey(idKey)) {
        final existing = sessionMap[idKey]!;
        final mergedMsgs = List<ChatMessagePair>.from(existing.messages);
        for (final msg in session.messages) {
          if (!mergedMsgs.any((m) =>
              m.prompt.trim() == msg.prompt.trim() &&
              m.response.trim() == msg.response.trim())) {
            mergedMsgs.add(msg);
          }
        }

        final String initialProvider = existing.messages.isNotEmpty
            ? existing.messages.first.provider
            : (session.messages.isNotEmpty
                ? session.messages.first.provider
                : (existing.provider.isNotEmpty ? existing.provider : session.provider));

        sessionMap[idKey] = ChatSessionItem(
          id: existing.id,
          title: existing.title.isNotEmpty ? existing.title : session.title,
          provider: initialProvider,
          timestamp: session.timestamp.isAfter(existing.timestamp) ? session.timestamp : existing.timestamp,
          messages: mergedMsgs,
        );
      } else {
        sessionMap[idKey] = session;
      }
    }

    final List<ChatSessionItem> sessions = sessionMap.values.toList();

    // 2. Sort by message count descending so largest multi-turn sessions are evaluated first
    sessions.sort((a, b) => b.messages.length.compareTo(a.messages.length));

    final List<ChatSessionItem> consolidated = [];

    for (final candidate in sessions) {
      if (candidate.messages.isEmpty) continue;

      bool isSubsumed = false;

      for (int i = 0; i < consolidated.length; i++) {
        final master = consolidated[i];

        // Count how many messages in candidate match messages in master
        final int matchingCount = candidate.messages.where((cMsg) {
          return master.messages.any((mMsg) =>
              mMsg.prompt.trim().toLowerCase() == cMsg.prompt.trim().toLowerCase() &&
              mMsg.response.trim().toLowerCase() == cMsg.response.trim().toLowerCase());
        }).length;

        // If candidate's messages are completely contained inside master -> discard candidate fragment
        if (matchingCount == candidate.messages.length) {
          isSubsumed = true;
          break;
        }

        // If candidate shares messages with master, merge any new messages from candidate into master
        if (matchingCount > 0) {
          final updatedMasterMsgs = List<ChatMessagePair>.from(master.messages);
          for (final cMsg in candidate.messages) {
            if (!updatedMasterMsgs.any((m) =>
                m.prompt.trim().toLowerCase() == cMsg.prompt.trim().toLowerCase() &&
                m.response.trim().toLowerCase() == cMsg.response.trim().toLowerCase())) {
              updatedMasterMsgs.add(cMsg);
            }
          }

          consolidated[i] = ChatSessionItem(
            id: master.id,
            title: master.title,
            provider: master.provider,
            timestamp: candidate.timestamp.isAfter(master.timestamp) ? candidate.timestamp : master.timestamp,
            messages: updatedMasterMsgs,
          );

          isSubsumed = true;
          break;
        }
      }

      if (!isSubsumed) {
        consolidated.add(candidate);
      }
    }

    // Sort final list by timestamp descending (most recent conversation first)
    consolidated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return consolidated;
  }

  /// Loads chat history from local storage and merges/deduplicates with backend history if available.
  Future<List<ChatSessionItem>> loadHistory() async {
    final localList = await _getLocalHistory();

    try {
      final aiClient = locator<CliboAIClient>();
      if (aiClient is BackendProxyAIClient) {
        final remoteHistory = await aiClient.fetchChatHistory();
        if (remoteHistory != null && remoteHistory.isNotEmpty) {
          final List<ChatSessionItem> remoteSessions =
              remoteHistory.map((json) => ChatSessionItem.fromJson(json)).toList();

          final combined = [...remoteSessions, ...localList];
          final mergedList = _deduplicateSessions(combined);

          await _saveLocalHistory(mergedList);
          return mergedList;
        }
      }
    } catch (e) {
      debugPrint("[ChatHistoryService] Error syncing with backend: $e");
    }

    return _deduplicateSessions(localList);
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
      final newPair = ChatMessagePair(
        prompt: prompt,
        response: response,
        provider: provider,
        timestamp: now,
      );

      ChatSessionItem? targetSession;
      if (_activeSessionId != null) {
        final index = localList.indexWhere((s) => s.id == _activeSessionId);
        if (index != -1) {
          targetSession = localList.removeAt(index);
        }
      }

      if (targetSession != null) {
        final updatedMessages = List<ChatMessagePair>.from(targetSession.messages);
        if (!updatedMessages.any((m) => m.prompt.trim() == prompt.trim() && m.response.trim() == response.trim())) {
          updatedMessages.add(newPair);
        }
        final initialProvider = targetSession.messages.isNotEmpty
            ? targetSession.messages.first.provider
            : targetSession.provider;

        final updatedSession = ChatSessionItem(
          id: targetSession.id,
          title: targetSession.title,
          provider: initialProvider,
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

      final deduplicated = _deduplicateSessions(localList);
      await _saveLocalHistory(deduplicated);
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
      final deduplicated = _deduplicateSessions(localList);
      await _saveLocalHistory(deduplicated);
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
