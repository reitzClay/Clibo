import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../app/service_locator.dart';
import '../../../../interface/clibo_aI_client.dart';

class MetricsTab extends StatefulWidget {
  const MetricsTab({super.key});

  @override
  State<MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<MetricsTab> {
  final CliboAIClient _aiClient = locator<CliboAIClient>();
  bool _isLoading = false;
  Map<String, dynamic>? _usageMetrics;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_aiClient is BackendProxyAIClient) {
        final metrics = await _aiClient.fetchUsageStats();
        if (mounted) {
          setState(() => _usageMetrics = metrics);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (_isLoading && _usageMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usageMetrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.activity, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Token Calculations & Metrics View (Placeholder)", style: theme.textTheme.muted),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMetrics,
              child: const Text("Fetch Metrics"),
            ),
          ],
        ),
      );
    }

    final String tier = _usageMetrics!['userTier']?.toString() ?? 'FREE';
    final int msgUsed = _usageMetrics!['textMessagesUsed'] ?? 0;
    final int msgLimit = _usageMetrics!['textMessagesLimit'] ?? 50;
    final int msgRemaining = _usageMetrics!['textMessagesRemaining'] ?? 50;

    final int scUsed = _usageMetrics!['screenshotsUsed'] ?? 0;
    final int scLimit = _usageMetrics!['screenshotsLimit'] ?? 20;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Usage & Quotas", style: theme.textTheme.h3),
              Chip(
                label: Text(tier, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: tier == 'PRO' ? Colors.purple : Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildMetricCard(theme, "Text Messages", msgUsed, msgLimit, msgRemaining),
          const SizedBox(height: 16),
          _buildMetricCard(theme, "Screenshots Analysis", scUsed, scLimit, scLimit - scUsed),
        ],
      ),
    );
  }

  Widget _buildMetricCard(ShadThemeData theme, String title, int used, int limit, int remaining) {
    final double percent = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
              Text("$remaining remaining", style: theme.textTheme.small),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: theme.colorScheme.border,
            color: percent > 0.8 ? Colors.orange : theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text("$used / $limit used today", style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
