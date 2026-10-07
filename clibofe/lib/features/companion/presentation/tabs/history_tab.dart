import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/services/chat_history_service.dart';

class HistoryTab extends StatefulWidget {
  final TabController? tabController;

  const HistoryTab({super.key, this.tabController});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with WidgetsBindingObserver {
  final ChatHistoryService _historyService = locator<ChatHistoryService>();

  bool _isLoading = false;
  List<ChatSessionItem> _allSessions = [];
  List<ChatSessionItem> _filteredSessions = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.tabController?.addListener(_handleTabChange);
    _loadHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.tabController?.removeListener(_handleTabChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  void _handleTabChange() {
    if (widget.tabController != null && widget.tabController!.index == 0) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final sessions = await _historyService.loadHistory();
      if (mounted) {
        setState(() {
          _allSessions = sessions;
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint("[HistoryTab] Error loading history: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSessions = _allSessions.where((session) {
        final matchesQuery = query.isEmpty ||
            session.title.toLowerCase().contains(query) ||
            session.messages.any((m) =>
                m.prompt.toLowerCase().contains(query) ||
                m.response.toLowerCase().contains(query));

        final matchesFilter = _selectedFilter == 'All' ||
            session.provider.toLowerCase().contains(_selectedFilter.toLowerCase());

        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  Future<void> _deleteSession(String id) async {
    await _historyService.deleteSession(id);
    await _loadHistory();
  }

  Future<void> _clearAllHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Clear Chat History", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to clear all past chat history sessions? This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearHistory();
      await _loadHistory();
    }
  }

  Future<void> _resumeSessionInOverlay(ChatSessionItem session) async {
    try {
      final bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        final bool? status = await FlutterOverlayWindow.requestPermission();
        if (status != true) return;
      }

      _historyService.setActiveSessionId(session.id);

      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Clibo Assistant",
          overlayContent: "Floating assistant is active",
          height: 200,
          width: 200,
          alignment: OverlayAlignment.center,
          flag: OverlayFlag.defaultFlag,
          positionGravity: PositionGravity.auto,
        );
      }

      final payload = jsonEncode({
        'action': 'RESUME_CHAT',
        'sessionId': session.id,
        'messages': session.messages.map((m) => m.toJson()).toList(),
      });

      await FlutterOverlayWindow.shareData(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resumed '${session.title}' in overlay!"),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("[HistoryTab] Error resuming session in overlay: $e");
    }
  }

  void _showSessionDetailSheet(ChatSessionItem session) {
    final StringBuffer fullCopyText = StringBuffer();
    for (int i = 0; i < session.messages.length; i++) {
      fullCopyText.writeln("User: ${session.messages[i].prompt}");
      fullCopyText.writeln("AI (${session.provider}): ${session.messages[i].response}\n");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(session.provider.contains('Ollama') ? '🦙' : '✨', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.provider,
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${session.messageCount} message ${session.messageCount == 1 ? 'turn' : 'turns'}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: session.messages.length,
                  itemBuilder: (context, idx) {
                    final msg = session.messages[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_outline, size: 14, color: Colors.blueAccent),
                              SizedBox(width: 6),
                              Text("You", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                            ),
                            child: SelectableText(msg.prompt, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.greenAccent),
                              const SizedBox(width: 6),
                              Text("Clibo (${session.provider})", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: SelectableText(msg.response, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text("Resume in Overlay"),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _resumeSessionInOverlay(session);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(46, 46),
                      ),
                      icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                      tooltip: "Copy Thread",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullCopyText.toString()));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied conversation to clipboard!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Chat History", style: theme.textTheme.h3),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
                    onPressed: _loadHistory,
                    tooltip: "Refresh History",
                  ),
                  if (_allSessions.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      onPressed: _clearAllHistory,
                      tooltip: "Clear All History",
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Search Input Field
          TextField(
            controller: _searchController,
            style: TextStyle(color: theme.colorScheme.foreground, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search prompts or responses...",
              hintStyle: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.mutedForeground),
              filled: true,
              fillColor: theme.colorScheme.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Provider Filter Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Gemini', 'Ollama', 'OpenAI', 'Claude'].map((filter) {
                final bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: theme.colorScheme.card,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Grouped Session Item List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: theme.colorScheme.mutedForeground),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty || _selectedFilter != 'All'
                                  ? "No chat logs match your filters."
                                  : "No chat history recorded yet.",
                              style: theme.textTheme.muted,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = _filteredSessions[index];
                          final formattedTime =
                              "${session.timestamp.hour.toString().padLeft(2, '0')}:${session.timestamp.minute.toString().padLeft(2, '0')}";

                          return Card(
                            color: theme.colorScheme.card,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                                child: Text(session.provider.contains('Ollama') ? '🦙' : '✨', style: const TextStyle(fontSize: 18)),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.foreground),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (session.messageCount > 1)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "${session.messageCount} msgs",
                                        style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  session.lastResponse,
                                  style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formattedTime, style: theme.textTheme.small.copyWith(fontSize: 10)),
                                  InkWell(
                                    onTap: () => _deleteSession(session.id),
                                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white38),
                                  ),
                                ],
                              ),
                              onTap: () => _showSessionDetailSheet(session),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
