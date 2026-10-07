import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomEndpointCard extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController modelController;
  final TextEditingController apiKeyController;

  const CustomEndpointCard({
    super.key,
    required this.urlController,
    required this.modelController,
    required this.apiKeyController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/custom.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('⚙️', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Text("Custom Endpoint Base URL", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text("e.g. http://10.0.2.2:1234/v1 or https://api.together.xyz/v1", style: theme.textTheme.small),
        const SizedBox(height: 8),
        TextField(
          controller: urlController,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: "http://10.0.2.2:1234/v1",
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text("Custom Model Name", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: modelController,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: "local-model",
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text("API Key (Optional)", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: "Optional bearer token...",
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
