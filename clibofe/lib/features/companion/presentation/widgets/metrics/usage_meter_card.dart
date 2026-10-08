import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class UsageMeterCard extends StatelessWidget {
  final String title;
  final int used;
  final int limit;
  final bool isUnlimited;
  final String? subtitle;

  const UsageMeterCard({
    super.key,
    required this.title,
    required this.used,
    required this.limit,
    this.isUnlimited = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Calculate progress fill percentage
    final double percent = isUnlimited
        ? ((used % 100) / 100.0).clamp(0.05, 1.0) // Fills continuously up to 100 milestone blocks
        : (limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0);

    final int remaining = isUnlimited ? 9999 : (limit - used).clamp(0, limit);
    final Color progressColor = isUnlimited
        ? const Color(0xFF10B981) // Emerald Green for BYOK / Local
        : (percent > 0.8 ? Colors.orangeAccent : Colors.blueAccent);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlimited
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : theme.colorScheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnlimited
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUnlimited ? "♾️ UNLIMITED" : "$remaining remaining",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlimited ? const Color(0xFF10B981) : Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filling-Up Progress Bar Meter
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: theme.colorScheme.border.withValues(alpha: 0.5),
              color: progressColor,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnlimited
                    ? "$used total messages processed 🚀"
                    : "$used / $limit messages used today",
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
              Text(
                isUnlimited ? "Level ${(used ~/ 100) + 1}" : "${(percent * 100).toInt()}%",
                style: theme.textTheme.muted.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: progressColor,
                ),
              ),
            ],
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.foreground.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
