import 'package:flutter/material.dart';

/// Reusable widget for displaying AI provider logo assets consistently across tabs with white tinting.
class ProviderLogo extends StatelessWidget {
  final String providerKey; // 'gemini', 'ollama', 'openai', 'claude', 'custom' or label
  final double size;
  final Color? color;

  const ProviderLogo({
    super.key,
    required this.providerKey,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final lower = providerKey.toLowerCase();

    if (lower.contains('claude') || lower.contains('anthropic')) {
      return Image.asset(
        'assets/images/claude.png',
        width: size * 1.5,
        height: size * 1.5,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🎭', style: TextStyle(fontSize: size * 0.8)),
      );
    }

    if (lower.contains('ollama')) {
      return Image.asset(
        'assets/images/ollama.png',
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🦙', style: TextStyle(fontSize: size * 0.8)),
      );
    }

    if (lower.contains('openai') || lower.contains('gpt')) {
      return Image.asset(
        'assets/images/openai.png',
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🧠', style: TextStyle(fontSize: size * 0.8)),
      );
    }

    if (lower.contains('gemini')) {
      return Image.asset(
        'assets/images/gemini.png',
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('✨', style: TextStyle(fontSize: size * 0.8)),
      );
    }

    return Image.asset(
      'assets/images/custom.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text('⚙️', style: TextStyle(fontSize: size * 0.8)),
    );
  }
}
