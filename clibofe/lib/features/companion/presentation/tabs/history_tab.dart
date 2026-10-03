import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 48, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 16),
          Text("Chat Log History List View (Placeholder)", style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
