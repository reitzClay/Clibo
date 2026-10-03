import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../../domain/config/ai_provider_config.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select AI Provider",
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AiProviderType>(
              value: selectedType,
              dropdownColor: theme.colorScheme.card,
              style: TextStyle(color: theme.colorScheme.foreground, fontSize: 15),
              isExpanded: true,
              items: AiProviderType.values.map((type) {
                return DropdownMenuItem<AiProviderType>(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
