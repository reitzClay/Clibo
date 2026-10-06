import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/services/chat_history_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ChatHistoryService _historyService = locator<ChatHistoryService>();

  bool _isLoading = false;
  List<ChatSessionItem> _allSessions = [];
  List<ChatSessionItem> _filteredSessions = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            session.prompt.toLowerCase().contains(query) ||
            session.response.toLowerCase().contains(query);

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

  void _showSessionDetailSheet(ChatSessionItem session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(session.provider.contains('Ollama') ? '🦙' : '✨', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(session.provider, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const Text("Prompt", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: SelectableText(session.prompt, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    const Text("AI Response", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SelectableText(session.response, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text("Copy AI Response"),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: session.response));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied response to clipboard!")),
                    );
                  },
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
              if (_allSessions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  onPressed: _clearAllHistory,
                  tooltip: "Clear All History",
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

          // 4. Session Item List
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
                              title: Text(
                                session.prompt,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.foreground),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  session.response,
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
