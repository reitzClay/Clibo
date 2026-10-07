import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:clibofe/domain/config/ai_provider_config.dart';

class ProviderDropdown extends StatelessWidget {
  final AiProviderType selectedType;
  final ValueChanged<AiProviderType> onChanged;

  const ProviderDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final List<Map<String, dynamic>> providers = [
      {
        'type': AiProviderType.gemini,
        'name': 'Google Gemini',
        'badge': 'Recommended (Free Tier)',
        'description': 'Smart, fast cloud AI powered by Gemini Flash.',
        'icon': '✨',
        'assetImage': 'assets/images/gemini.png',
        'color': Colors.blueAccent,
      },
      {
        'type': AiProviderType.ollama,
        'name': 'Ollama Local',
        'badge': '100% Offline & Private',
        'description': 'Zero token cost. Runs on your computer network.',
        'icon': '🦙',
        'assetImage': 'assets/images/ollama.png',
        'color': Colors.orangeAccent,
      },
      {
        'type': AiProviderType.openai,
        'name': 'OpenAI (GPT-4o)',
        'badge': 'BYOK Key',
        'description': 'Connect your OpenAI API key directly.',
        'icon': '🧠',
        'assetImage': 'assets/images/openai.png',
        'color': const Color(0xFF10B981),
      },
      {
        'type': AiProviderType.claude,
        'name': 'Anthropic Claude',
        'badge': 'BYOK Key',
        'description': 'Connect your Claude API key directly.',
        'icon': '🎭',
        'assetImage': 'assets/images/claude.png',
        'color': Colors.purpleAccent,
      },
      {
        'type': AiProviderType.custom,
        'name': 'Custom Endpoint',
        'badge': 'Advanced',
        'description': 'LM Studio, vLLM, or self-hosted LLM endpoints.',
        'icon': '⚙️',
        'assetImage': 'assets/images/custom.png',
        'color': Colors.grey,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose AI Engine",
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Column(
          children: providers.map((p) {
            final AiProviderType type = p['type'] as AiProviderType;
            final bool isSelected = type == selectedType;

            return GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (p['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        p['assetImage'] as String,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          p['icon'] as String,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                p['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: theme.colorScheme.foreground,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (p['color'] as Color).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: p['color'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['description'] as String,
                            style: theme.textTheme.small.copyWith(
                              fontSize: 11.5,
                              color: theme.colorScheme.foreground.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<AiProviderType>(
                      value: type,
                      groupValue: selectedType,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        if (val != null) onChanged(val);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
