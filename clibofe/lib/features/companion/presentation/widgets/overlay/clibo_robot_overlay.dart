import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/services/analytics_service.dart';
import 'package:clibofe/data/services/chat_history_service.dart';
import 'package:clibofe/data/services/config_service.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';

class CliboRobotOverlay extends StatefulWidget {
  const CliboRobotOverlay({super.key});

  @override
  State<CliboRobotOverlay> createState() => _CliboRobotOverlayState();
}

class _CliboRobotOverlayState extends State<CliboRobotOverlay> {
  bool isExpanded = false;
  bool isMaximized = false;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'How can I help you today? Copy and paste text here to ask anything!', 'isAi': true},
  ];
  bool _isSending = false;

  bool _isTickerVisible = false;
  bool _hasUnreadUpdates = true;

  final List<String> _companionTips = [
    '💡 Double-tap robot icon to close chat',
    '🤖 Clibo Companion • Always here over any app',
    '💡 Pinch with 2 fingers to scroll in compact view',
    '💡 Tap "Ask Clibo AI" to start typing',
    '🎭 "Why don’t AI secrets last? Too many parameters!"',
    '🚀 Smart, fast & zero context-switching',
    '🔍 Think it is a scam, then paste the chat into the Clibo',
    '🔍 You could also find out if she/he is cheating, then paste the chat into the Clibo',
  ];
  int _currentTipIndex = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      debugPrint("[OverlayIsolate] overlayListener received: $data");
      if (data == "CLEAR_CHAT") {
        if (mounted) {
          _clearChat();
        }
      }
    });

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
      }
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && isExpanded && _isTickerVisible) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _companionTips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add({'text': 'How can I help you today? Copy and paste text here to ask anything!', 'isAi': true});
      isExpanded = false;
      isMaximized = false;
      _isTickerVisible = false;
    });
  }

  void _toggleExpansion() async {
    setState(() {
      isExpanded = !isExpanded;
      if (!isExpanded) {
        isMaximized = false;
        _isTickerVisible = false;
      }
    });

    locator<AnalyticsService>().logOverlayToggled(isOpen: isExpanded);

    if (isExpanded) {
      await FlutterOverlayWindow.resizeOverlay(340, 500, true);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    } else {
      await FlutterOverlayWindow.resizeOverlay(120, 120, true);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _toggleMaximize() async {
    setState(() {
      isMaximized = !isMaximized;
    });

    if (isMaximized) {
      await FlutterOverlayWindow.resizeOverlay(-1, -1, false);
    } else {
      await FlutterOverlayWindow.resizeOverlay(340, 500, true);
    }
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final String rawText = customPrompt ?? _messageController.text;
    if (rawText.trim().isEmpty || _isSending) return;

    final String prompt = rawText.trim();
    _messageController.clear();

    setState(() {
      _messages.insert(0, {'text': prompt, 'isAi': false});
      _isSending = true;
    });

    try {
      final aiClient = locator<CliboAIClient>();
      final configService = locator<ConfigService>();
      final historyService = locator<ChatHistoryService>();
      final analytics = locator<AnalyticsService>();

      final responseText = await aiClient.generateResponse(prompt);
      final config = await configService.loadConfig();

      analytics.logPromptSent(
        provider: config.providerType.label,
        isBYOK: config.isBYOK,
        promptLength: prompt.length,
      );

      await historyService.addSession(
        prompt: prompt,
        response: responseText,
        provider: config.providerType.label,
      );

      if (mounted) {
        setState(() {
          _messages.insert(0, {'text': responseText, 'isAi': true});
        });
      }
    } catch (e) {
      locator<AnalyticsService>().logError(
        context: 'overlay_send_message',
        errorMessage: e.toString(),
      );
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'text': 'Error connecting to backend: ${e.toString().replaceAll('Exception: ', '')}',
            'isAi': true
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;

    // Generous top clearance ensuring status bar clock, notch & battery icons never overlap
    final double topSafeArea = mediaQuery.padding.top > 36.0 ? mediaQuery.padding.top : 68.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Material(
        color: Colors.transparent,
        child: Align(
          alignment: isMaximized ? Alignment.topCenter : Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: isMaximized
                ? EdgeInsets.only(
                    top: topSafeArea + 28.0,
                    bottom: mediaQuery.padding.bottom + 12.0,
                    left: 8.0,
                    right: 8.0,
                  )
                : EdgeInsets.zero,
            width: isExpanded ? (isMaximized ? screenWidth - 16 : 320) : 70,
            height: isExpanded
                ? (isMaximized
                    ? (screenHeight - topSafeArea - mediaQuery.padding.bottom - 56)
                    : 480)
                : 70,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(isMaximized ? 16 : (isExpanded ? 24 : 35)),
              border: Border.all(
                color: isMaximized ? Colors.blueAccent.withValues(alpha: 0.8) : Colors.white24,
                width: isMaximized ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: isExpanded
                ? _buildChatInterface(screenWidth)
                : GestureDetector(
                    onTap: _toggleExpansion,
                    onDoubleTap: () async {
                      _clearChat();
                      await FlutterOverlayWindow.closeOverlay();
                    },
                    child: const Center(
                      child: Text(
                        "🤖",
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface(double screenWidth) {
    return Column(
      children: [
        // 1. Header Bar with Glowing Robot Avatar & Interactive Smooth Marquee Ticker
        GestureDetector(
          onDoubleTap: _toggleExpansion,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.only(top: 14, bottom: 10, left: 12, right: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                _buildRobotAvatar(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Clibo AI",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      if (_isTickerVisible) ...[
                        SizedBox(
                          height: 14,
                          child: _SmoothMarqueeText(
                            key: ValueKey<String>(
                              isMaximized ? 'reading_$_currentTipIndex' : 'tip_$_currentTipIndex',
                            ),
                            text: isMaximized
                                ? '📖 Full Screen Reading Mode • ${_companionTips[_currentTipIndex]}'
                                : _companionTips[_currentTipIndex],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          isMaximized
                              ? "📖 Reading Mode • Tap 🤖 for tips"
                              : (_hasUnreadUpdates ? "✨ Tap 🤖 for What's New & Tips" : "Floating Companion • Tap 🤖 for tips"),
                          style: TextStyle(
                            color: _hasUnreadUpdates && !isMaximized ? Colors.cyanAccent : Colors.white38,
                            fontSize: 10,
                            fontWeight: _hasUnreadUpdates && !isMaximized ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: isMaximized ? Colors.blueAccent : Colors.white,
                          size: 18,
                        ),
                        onPressed: _toggleMaximize,
                        tooltip: isMaximized ? "Restore Floating Card" : "Snap to Full Screen",
                      ),
                      Container(width: 1, height: 16, color: Colors.white24),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        onPressed: _toggleExpansion,
                        tooltip: "Minimize Overlay",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Chat Message List
        Expanded(
          child: RawScrollbar(
            controller: _scrollController,
            thumbVisibility: isMaximized,
            trackVisibility: isMaximized,
            thickness: 6,
            radius: const Radius.circular(8),
            thumbColor: Colors.blueAccent.withValues(alpha: 0.8),
            trackColor: Colors.white10,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              reverse: true,
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text("Clibo is thinking...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }
                final msgIndex = _isSending ? index - 1 : index;
                final msg = _messages[msgIndex];

                return _buildChatBubble(msg['text'], isAi: msg['isAi'], screenWidth: screenWidth);
              },
            ),
          ),
        ),

        // 3. Bottom Text Input Bar
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  cursorColor: Colors.blueAccent,
                  enableInteractiveSelection: true,
                  selectionControls: MaterialTextSelectionControls(),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (val) => _sendMessage(val),
                  decoration: InputDecoration(
                    hintText: "Ask Clibo AI...",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  onPressed: () => _sendMessage(_messageController.text),
                  tooltip: "Send Prompt",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRobotAvatar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTickerVisible = !_isTickerVisible;
          _hasUnreadUpdates = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _isTickerVisible ? Colors.blueAccent.withValues(alpha: 0.25) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isTickerVisible ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.transparent,
                width: 1,
              ),
            ),
            child: const Text("🤖", style: TextStyle(fontSize: 20)),
          ),
          if (_hasUnreadUpdates)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.9),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isAi, required double screenWidth}) {
    final double maxBubbleWidth = isMaximized ? (screenWidth * 0.82) : 250.0;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        decoration: BoxDecoration(
          color: isAi ? Colors.white.withValues(alpha: 0.08) : Colors.blueAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 4 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 4),
          ),
          border: Border.all(
            color: isAi ? Colors.white12 : Colors.blueAccent.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
        ),
      ),
    );
  }
}

class _SmoothMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _SmoothMarqueeText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<_SmoothMarqueeText> createState() => _SmoothMarqueeTextState();
}

class _SmoothMarqueeTextState extends State<_SmoothMarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent > 0) {
          _scrollController.jumpTo(_animationController.value * maxExtent);
        }
      }
    });

    _animationController.repeat();
  }

  @override
  void didUpdateWidget(covariant _SmoothMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animationController.reset();
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(right: 60.0),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
        ),
      ),
    );
  }
}
