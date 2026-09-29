import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/service_locator.dart';
import 'features/companion/presentation/screens/splash_screen.dart';
import 'interface/clibo_aI_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupServices();
  runApp(const CliboApp());
}

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupServices();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CliboRobotOverlay(),
    ),
  );
}

class CliboRobotOverlay extends StatefulWidget {
  const CliboRobotOverlay({super.key});

  @override
  State<CliboRobotOverlay> createState() => _CliboRobotOverlayState();
}

class _CliboRobotOverlayState extends State<CliboRobotOverlay> {
  bool isExpanded = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'How can I help you today?', 'isAi': true},
  ];
  bool _isSending = false;

  void _toggleExpansion() async {
    setState(() {
      isExpanded = !isExpanded;
    });

    if (isExpanded) {
      // Expand: Window slightly larger than the 300x450 container to allow for shadows
      await FlutterOverlayWindow.resizeOverlay(350, 500, true);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    } else {
      // Contract: Window slightly larger than the 70x70 robot head
      await FlutterOverlayWindow.resizeOverlay(120, 120, true);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    final prompt = text.trim();
    _messageController.clear();

    setState(() {
      _messages.insert(0, {'text': prompt, 'isAi': false});
      _isSending = true;
    });

    try {
      final aiClient = locator<CliboAIClient>();
      final responseText = await aiClient.generateResponse(prompt);
      if (mounted) {
        setState(() {
          _messages.insert(0, {'text': responseText, 'isAi': true});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {'text': 'Error connecting to backend: ${e.toString().replaceAll('Exception: ', '')}', 'isAi': true});
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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: isExpanded ? null : _toggleExpansion,
          onDoubleTap: () async {
            await FlutterOverlayWindow.closeOverlay();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isExpanded ? 300 : 70,
            height: isExpanded ? 450 : 70,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 35),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isExpanded
                ? _buildChatInterface()
                : const Center(
              child: Text(
                "🤖",
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // 1. Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("🤖", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "Clibo AI",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(
                          "Always listening...",
                          style: TextStyle(color: Colors.greenAccent.withOpacity(0.7), fontSize: 10)
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: _toggleExpansion,
              ),
            ],
          ),
        ),

        // 2. Chat History
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                );
              }
              final msgIndex = _isSending ? index - 1 : index;
              final msg = _messages[msgIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msgIndex == _messages.length - 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildActionChip("🔍 What's this?", () => _sendMessage("What's this on my screen?")),
                          _buildActionChip("💡 Fix settings", () => _sendMessage("How do I fix my settings?")),
                          _buildActionChip("📝 Read page", () => _sendMessage("Read and summarize this page.")),
                        ],
                      ),
                    ),
                  ],
                  _buildChatBubble(msg['text'], isAi: msg['isAi']),
                ],
              );
            },
          ),
        ),

        // 3. Input Area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(
                    hintText: "Ask Clibo AI...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildCircularButton(Icons.send, () => _sendMessage(_messageController.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isAi}) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 240, maxHeight: 200),
        decoration: BoxDecoration(
          color: isAi ? Colors.white10 : Colors.blueGrey.shade900,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 4 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 4),
          ),
        ),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class CliboApp extends StatelessWidget {
  const CliboApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Corrected: Initialized standard ShadApp instance configuration wrapper with global ScaffoldMessenger builder
    return ShadApp(
      title: 'Clibo AI Companion',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) => ScaffoldMessenger(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
