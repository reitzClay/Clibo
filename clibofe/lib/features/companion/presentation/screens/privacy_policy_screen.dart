import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: theme.colorScheme.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Clibo Privacy Policy", style: theme.textTheme.h2),
            const SizedBox(height: 8),
            Text("Last updated: October 2026", style: theme.textTheme.muted),
            const SizedBox(height: 24),
            _buildSection(theme, "1. Overview", "ClayBytes (https://claybytes.nl/) respects your privacy. This Privacy Policy describes how Clibo collects, uses, and safeguards your information when you use our mobile/desktop companion and backend proxy."),
            _buildSection(theme, "2. Information We Collect", "• Authentication Data: Name, email address, and profile identifiers via Google Sign-In or enterprise login.\n• Usage & Metering Data: Request counts, token metrics, and feature limits.\n• Chat Interactions: Prompts and AI model responses logged for compliance, safety, and auditability."),
            _buildSection(theme, "3. Secure Storage", "API keys, authentication tokens, and user preferences are securely stored locally on your device using encrypted storage."),
            _buildSection(theme, "4. Data Sharing & Compliance", "We do not sell your personal data. Information is stored securely on enterprise databases and may be disclosed when required by law, legal process, or valid government requests to ensure compliance and safety."),
            _buildSection(theme, "5. Your Rights", "You have the right to request access to, correction of, or deletion of your personal data by contacting ClayBytes at https://claybytes.nl/."),
            _buildSection(theme, "6. Contact Information", "For privacy-related inquiries, visit https://claybytes.nl/."),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ShadThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.p.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
