import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Permanent top-level listener on Main Application Isolate for Overlay Requests
  FlutterOverlayWindow.overlayListener.listen((data) async {
    debugPrint("[MainIsolate] overlayListener event received: $data");
    if (data is Map && data['action'] == 'PICK_IMAGE') {
      try {
        debugPrint("[MainIsolate] Launching ImagePicker.pickImage...");
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (image != null) {
          debugPrint("[MainIsolate] Image selected: ${image.path}");
          final bytes = await image.readAsBytes();
          final String base64Img = base64Encode(bytes);
          final String mime = image.mimeType ?? 'image/jpeg';
          await FlutterOverlayWindow.shareData({
            'action': 'IMAGE_PICKED',
            'image': base64Img,
            'mimeType': mime,
          });
          debugPrint("[MainIsolate] Sent IMAGE_PICKED to OverlayIsolate");
        } else {
          debugPrint("[MainIsolate] Image picking cancelled by user");
          await FlutterOverlayWindow.shareData({
            'action': 'IMAGE_PICK_CANCELLED',
          });
        }
      } catch (e, stack) {
        debugPrint("[MainIsolate] ImagePicker ERROR: $e\n$stack");
        await FlutterOverlayWindow.shareData({
          'action': 'IMAGE_PICK_FAILED',
          'error': e.toString(),
        });
      }
    }
  });

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
  bool isMaximized = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'How can I help you today?', 'isAi': true},
  ];
  bool _isSending = false;

  Uint8List? _attachedImageBytes;
  String? _attachedImageMimeType;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      debugPrint("[OverlayIsolate] overlayListener received: $data");
      if (data == "CLEAR_CHAT") {
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.add({'text': 'How can I help you today?', 'isAi': true});
            _attachedImageBytes = null;
            _attachedImageMimeType = null;
            isExpanded = false;
            isMaximized = false;
          });
        }
      } else if (data is Map && data['action'] == 'IMAGE_PICKED') {
        final String base64Img = data['image'] ?? '';
        final String mime = data['mimeType'] ?? 'image/jpeg';
        if (base64Img.isNotEmpty) {
          final bytes = base64Decode(base64Img);
          if (mounted) {
            setState(() {
              _attachedImageBytes = bytes;
              _attachedImageMimeType = mime;
            });
          }
        }
      } else if (data is Map && data['action'] == 'IMAGE_PICK_FAILED') {
        if (mounted) {
          setState(() {
            _messages.insert(0, {
              'text': 'Failed to attach image: ${data['error'] ?? 'Unknown error'}',
              'isAi': true
            });
          });
        }
      }
    });
  }

  void _toggleExpansion() async {
    setState(() {
      isExpanded = !isExpanded;
      if (!isExpanded) {
        isMaximized = false;
      }
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

  void _toggleMaximize() async {
    setState(() {
      isMaximized = !isMaximized;
    });

    if (isMaximized) {
      await FlutterOverlayWindow.resizeOverlay(420, 720, true);
    } else {
      await FlutterOverlayWindow.resizeOverlay(350, 500, true);
    }
  }

  Future<void> _pickImage() async {
    try {
      debugPrint("[OverlayIsolate] Calling shareData(PICK_IMAGE)...");
      await FlutterOverlayWindow.shareData({
        'action': 'PICK_IMAGE',
      });
      debugPrint("[OverlayIsolate] shareData(PICK_IMAGE) sent successfully!");
    } catch (e) {
      debugPrint("[OverlayIsolate] _pickImage error: $e");
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'text': 'Error requesting image picker: $e',
            'isAi': true
          });
        });
      }
    }
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final String rawText = customPrompt ?? _messageController.text;
    if ((rawText.trim().isEmpty && _attachedImageBytes == null) || _isSending) return;
    
    final String prompt = rawText.trim().isNotEmpty
        ? rawText.trim()
        : "Describe the attached screenshot or image in detail.";
    _messageController.clear();

    final Uint8List? imageBytes = _attachedImageBytes;
    final String? mimeType = _attachedImageMimeType;

    setState(() {
      if (imageBytes != null) {
        _messages.insert(0, {'text': "🖼️ [Image Attached] $prompt", 'isAi': false});
      } else {
        _messages.insert(0, {'text': prompt, 'isAi': false});
      }
      _isSending = true;
      _attachedImageBytes = null;
      _attachedImageMimeType = null;
    });

    try {
      final aiClient = locator<CliboAIClient>();
      final String? base64Img = imageBytes != null ? base64Encode(imageBytes) : null;

      final responseText = await aiClient.generateResponse(
        prompt,
        imageBase64: base64Img,
        imageMimeType: base64Img != null ? (mimeType ?? 'image/jpeg') : null,
      );

      if (mounted) {
        setState(() {
          _messages.insert(0, {'text': responseText, 'isAi': true});
        });
      }
    } catch (e) {
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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: isExpanded ? null : _toggleExpansion,
          onDoubleTap: () async {
            setState(() {
              _messages.clear();
              _messages.add({'text': 'How can I help you today?', 'isAi': true});
              _attachedImageBytes = null;
              _attachedImageMimeType = null;
              isExpanded = false;
              isMaximized = false;
            });
            await FlutterOverlayWindow.closeOverlay();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isExpanded ? (isMaximized ? 400 : 300) : 70,
            height: isExpanded ? (isMaximized ? 680 : 450) : 70,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 35),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
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
                          style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.7), fontSize: 10)
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(isMaximized ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white70, size: 20),
                    onPressed: _toggleMaximize,
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: _toggleExpansion,
                  ),
                ],
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
                          _buildActionChip("🖼️ Attach Screenshot", _pickImage),
                          _buildActionChip("📝 Summarize Image", () => _sendMessage("Summarize the attached screenshot or document in detail.")),
                          _buildActionChip("💡 Fix settings", () => _sendMessage("How do I fix my settings?")),
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

        // 3. Image Attachment Preview Banner (if image is attached)
        if (_attachedImageBytes != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(_attachedImageBytes!, width: 32, height: 32, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Screenshot Attached",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _attachedImageBytes = null;
                      _attachedImageMimeType = null;
                    });
                  },
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),

        // 4. Input Area
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
                  onSubmitted: (val) => _sendMessage(val),
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
              const SizedBox(width: 8),
              _buildCircularButton(Icons.image_rounded, _pickImage, tooltip: "Attach Screenshot / Image"),
              const SizedBox(width: 6),
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
          color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
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
        constraints: BoxConstraints(
          maxWidth: isMaximized ? 350 : 260,
          maxHeight: isMaximized ? 500 : 250,
        ),
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
