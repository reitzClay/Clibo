import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/services/config_service.dart';
import 'package:clibofe/domain/config/ai_provider_config.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';
import 'package:clibofe/features/companion/presentation/widgets/config/byok_key_input.dart';
import 'package:clibofe/features/companion/presentation/widgets/config/connection_status_card.dart';
import 'package:clibofe/features/companion/presentation/widgets/config/custom_endpoint_card.dart';
import 'package:clibofe/features/companion/presentation/widgets/config/ollama_config_card.dart';
import 'package:clibofe/features/companion/presentation/widgets/config/provider_dropdown.dart';

class ConfigTab extends StatefulWidget {
  final VoidCallback? onSettingsSaved;

  const ConfigTab({super.key, this.onSettingsSaved});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final ConfigService _configService = locator<ConfigService>();
  final CliboAIClient _aiClient = locator<CliboAIClient>();

  AiProviderType _selectedProvider = AiProviderType.gemini;

  final TextEditingController _backendUrlController = TextEditingController();
  final TextEditingController _ollamaUrlController = TextEditingController();
  final TextEditingController _ollamaModelController = TextEditingController();
  final TextEditingController _byokKeyController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();

  bool _isTestingHealth = false;
  bool? _isBackendConnected;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final config = await _configService.loadConfig();
    if (mounted) {
      setState(() {
        _selectedProvider = config.providerType;
        _backendUrlController.text = config.backendUrl;
        _ollamaUrlController.text = config.ollamaBaseUrl;
        _ollamaModelController.text = config.ollamaModel;
        _byokKeyController.text = config.byokApiKey;
        _customUrlController.text = config.customBaseUrl;
        _customModelController.text = config.customModel;
      });
    }
    _testConnection();
  }

  Future<void> _testConnection() async {
    if (!mounted) return;
    setState(() {
      _isTestingHealth = true;
    });

    try {
      if (_aiClient is BackendProxyAIClient) {
        final connected = await _aiClient.checkBackendHealth();
        if (mounted) {
          setState(() {
            _isBackendConnected = connected;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBackendConnected = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingHealth = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final updatedConfig = AiProviderConfig(
      providerType: _selectedProvider,
      backendUrl: _backendUrlController.text.trim(),
      ollamaBaseUrl: _ollamaUrlController.text.trim(),
      ollamaModel: _ollamaModelController.text.trim(),
      byokApiKey: _byokKeyController.text.trim(),
      customBaseUrl: _customUrlController.text.trim(),
      customModel: _customModelController.text.trim(),
    );

    await _configService.saveConfig(updatedConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI Companion settings saved successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await _testConnection();
    widget.onSettingsSaved?.call();
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    _byokKeyController.dispose();
    _customUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI Engine & Preferences", style: theme.textTheme.h3),
              if (_isTestingHealth)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _testConnection,
                  tooltip: "Check Gateway Connection",
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Customize which AI model powers your floating Clibo assistant.",
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 16),

          if (_isBackendConnected != null) ...[
            ConnectionStatusCard(
              isConnected: _isBackendConnected!,
              backendUrl: _backendUrlController.text.trim(),
            ),
            const SizedBox(height: 16),
          ],

          ProviderDropdown(
            selectedType: _selectedProvider,
            onChanged: (type) => setState(() => _selectedProvider = type),
          ),
          const SizedBox(height: 16),

          if (_selectedProvider == AiProviderType.gemini) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text("✨", style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text("Google Gemini Cloud", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You are currently using the Clibo Free Tier powered by Google Gemini Flash. Option: Enter your own Google AI Studio API Key (BYOK) for unlimited personal requests.",
                    style: theme.textTheme.small.copyWith(color: theme.colorScheme.foreground.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 12),
                  ByokKeyInput(
                    label: "Google Gemini API Key (Optional BYOK)",
                    hintText: "AIzaSy...",
                    controller: _byokKeyController,
                  ),
                ],
              ),
            )
          ] else if (_selectedProvider == AiProviderType.ollama) ...[
            OllamaConfigCard(
              urlController: _ollamaUrlController,
              modelController: _ollamaModelController,
            )
          ] else if (_selectedProvider == AiProviderType.openai) ...[
            ByokKeyInput(
              label: "OpenAI API Key (sk-...)",
              hintText: "sk-proj-...",
              controller: _byokKeyController,
            )
          ] else if (_selectedProvider == AiProviderType.claude) ...[
            ByokKeyInput(
              label: "Anthropic Claude API Key (sk-ant-...)",
              hintText: "sk-ant-api...",
              controller: _byokKeyController,
            )
          ] else if (_selectedProvider == AiProviderType.custom) ...[
            CustomEndpointCard(
              urlController: _customUrlController,
              modelController: _customModelController,
              apiKeyController: _byokKeyController,
            )
          ],

          const SizedBox(height: 20),

          // Advanced Settings Accordion
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _showAdvancedSettings,
              onExpansionChanged: (val) => setState(() => _showAdvancedSettings = val),
              tilePadding: EdgeInsets.zero,
              title: Text(
                "⚙️ Advanced Gateway Server Settings",
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Spring Boot Gateway URL", style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Emulator: http://10.0.2.2:8080/api/v1\nDevice: http://<YOUR_PC_IP>:8080/api/v1", style: theme.textTheme.small),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _backendUrlController,
                        style: TextStyle(color: theme.colorScheme.foreground, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "http://192.168.1.x:8080/api/v1",
                          filled: true,
                          fillColor: theme.colorScheme.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: _saveSettings,
            child: const Text("Save Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
