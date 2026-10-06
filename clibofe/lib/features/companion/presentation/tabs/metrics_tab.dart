import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/services/config_service.dart';
import 'package:clibofe/domain/config/ai_provider_config.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';
import 'package:clibofe/features/companion/presentation/widgets/metrics/usage_meter_card.dart';

class MetricsTab extends StatefulWidget {
  const MetricsTab({super.key});

  @override
  State<MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<MetricsTab> {
  final ConfigService _configService = locator<ConfigService>();
  final CliboAIClient _aiClient = locator<CliboAIClient>();

  bool _isLoading = false;
  Map<String, dynamic>? _usageMetrics;
  AiProviderConfig? _activeConfig;

  @override
  void initState() {
    super.initState();
    _fetchMetricsAndConfig();
  }

  Future<void> _fetchMetricsAndConfig() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final config = await _configService.loadConfig();
      if (mounted) {
        setState(() => _activeConfig = config);
      }

      if (_aiClient is BackendProxyAIClient) {
        final metrics = await _aiClient.fetchUsageStats();
        if (mounted) {
          setState(() => _usageMetrics = metrics);
        }
      }
    } catch (e) {
      debugPrint("[MetricsTab] Error fetching stats: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (_isLoading && _activeConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = _activeConfig;
    final bool isLocalOrByok = config != null &&
        (config.providerType == AiProviderType.ollama ||
            config.providerType == AiProviderType.custom ||
            config.byokApiKey.trim().isNotEmpty);

    final String userTier = _usageMetrics?['userTier']?.toString() ?? (isLocalOrByok ? 'UNLIMITED' : 'FREE');
    final int msgUsed = _usageMetrics?['textMessagesUsed'] ?? 0;
    final int msgLimit = _usageMetrics?['textMessagesLimit'] ?? 50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Header & Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Usage & Quotas", style: theme.textTheme.h3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocalOrByok ? const Color(0xFF10B981) : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLocalOrByok ? "UNLIMITED BYOK" : userTier,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _fetchMetricsAndConfig,
                    tooltip: "Refresh Metrics",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Active Provider Info Banner
          if (config != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isLocalOrByok
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLocalOrByok
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    config.providerType == AiProviderType.ollama ? "🦙" : "✨",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${config.providerType.label} Engine",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                        ),
                        Text(
                          isLocalOrByok
                              ? "Requests run directly on your computer or key with zero quota limits."
                              : "Tip: Enter your own Gemini API key in Config for unlimited messages!",
                          style: theme.textTheme.small.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Filling-Up Usage Meter Card Widget
          UsageMeterCard(
            title: isLocalOrByok ? "Assistant Usage Meter" : "Daily Free Proxy Quota",
            used: msgUsed,
            limit: msgLimit,
            isUnlimited: isLocalOrByok,
            subtitle: isLocalOrByok
                ? "Tracks total assistant messages processed across local & personal key sessions."
                : "Resets daily at midnight UTC.",
          ),
        ],
      ),
    );
  }
}
