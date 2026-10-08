import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'provider_logo.dart';

class OllamaConfigCard extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController modelController;

  const OllamaConfigCard({
    super.key,
    required this.urlController,
    required this.modelController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ProviderLogo(providerKey: 'ollama', size: 22),
            const SizedBox(width: 8),
            Text("Ollama Base URL", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text("Android Emulator: http://10.0.2.2:11434\nDesktop/Web: http://localhost:11434", style: theme.textTheme.small),
        const SizedBox(height: 8),
        TextField(
          controller: urlController,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: "http://192.168.1.x:11434",
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text("Ollama Model Name", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Examples: tinyllama:1.1b, mistral, llama3", style: theme.textTheme.small),
        const SizedBox(height: 8),
        TextField(
          controller: modelController,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: "tinyllama:1.1b",
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
