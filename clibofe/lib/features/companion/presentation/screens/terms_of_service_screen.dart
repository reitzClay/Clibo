import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Terms of Service"),
        backgroundColor: theme.colorScheme.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Clibo Terms of Service", style: theme.textTheme.h2),
            const SizedBox(height: 8),
            Text("Last updated: October 2026", style: theme.textTheme.muted),
            const SizedBox(height: 24),
            _buildSection(theme, "1. Introduction", "Welcome to Clibo, developed and operated by ClayBytes (https://claybytes.nl/). By accessing or using our application, floating overlay, and backend services, you agree to be bound by these Terms of Service."),
            _buildSection(theme, "2. Account & Authentication", "You may authenticate using Google Sign-In or verified enterprise credentials. You are responsible for maintaining the security of your account and credentials stored locally on your device."),
            _buildSection(theme, "3. AI Services & Third-Party Providers", "Clibo routes requests between local AI instances (Ollama) and cloud providers (Google Gemini / BYOK). You acknowledge that queries processed through third-party providers are subject to their respective terms and data governance."),
            _buildSection(theme, "4. Usage Quotas & Guardrails", "Accounts are subject to tier-based usage limits (Free, Pro, Enterprise, Team). Attempting to bypass guardrails, abuse API quotas, or engage in malicious scraping is strictly prohibited."),
            _buildSection(theme, "5. Safety, Compliance & Auditing", "To comply with legal obligations and ensure safety, chat sessions and message interactions are securely logged and audited on our servers."),
            _buildSection(theme, "6. Limitation of Liability", "Clibo and ClayBytes shall not be liable for any indirect, incidental, or consequential damages arising from the use of AI-generated responses or floating companion features."),
            _buildSection(theme, "7. Contact Us", "For questions regarding these Terms, please visit us at https://claybytes.nl/."),
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
