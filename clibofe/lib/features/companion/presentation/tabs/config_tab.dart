import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/services/config_service.dart';
import '../../../../domain/config/ai_provider_config.dart';
import '../../../../interface/clibo_aI_client.dart';
import '../widgets/config/byok_key_input.dart';
import '../widgets/config/connection_status_card.dart';
import '../widgets/config/custom_endpoint_card.dart';
import '../widgets/config/ollama_config_card.dart';
import '../widgets/config/provider_dropdown.dart';

class ConfigTab extends StatefulWidget {
  final VoidCallback? onSettingsSaved;

  const ConfigTab({super.key, this.onSettingsSaved});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  final ConfigService _configService = locator<ConfigService>();
  final CliboAIClient _aiClient = locator<CliboAIClient>();

  AiProviderType _selectedProvider = AiProviderType.ollama;

  final TextEditingController _backendUrlController = TextEditingController();
  final TextEditingController _ollamaUrlController = TextEditingController();
  final TextEditingController _ollamaModelController = TextEditingController();
  final TextEditingController _byokKeyController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();

  bool _isTestingHealth = false;
  bool? _isBackendConnected;

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
          content: Text('AI Provider settings saved successfully!'),
          behavior: SnackBarBehavior.floating,
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
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI Provider Configuration", style: theme.textTheme.h3),
              if (_isTestingHealth)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _testConnection,
                  tooltip: "Test Connection",
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Select your preferred LLM provider, enter credentials or endpoint URLs, and save.",
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 16),

          if (_isBackendConnected != null) ...[
            ConnectionStatusCard(
              isConnected: _isBackendConnected!,
              backendUrl: _backendUrlController.text.trim(),
            ),
            const SizedBox(height: 24),
          ],

          ProviderDropdown(
            selectedType: _selectedProvider,
            onChanged: (type) => setState(() => _selectedProvider = type),
          ),
          const SizedBox(height: 24),

          Text("Spring Boot Gateway Backend URL", style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Android Emulator: http://10.0.2.2:8080/api/v1\nPhysical Device: http://<YOUR_PC_IP>:8080/api/v1", style: theme.textTheme.small),
          const SizedBox(height: 8),
          TextField(
            controller: _backendUrlController,
            style: TextStyle(color: theme.colorScheme.foreground),
            decoration: InputDecoration(
              hintText: "http://192.168.1.x:8080/api/v1",
              filled: true,
              fillColor: theme.colorScheme.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedProvider == AiProviderType.ollama) ...[
            OllamaConfigCard(
              urlController: _ollamaUrlController,
              modelController: _ollamaModelController,
            ),
          ] else if (_selectedProvider == AiProviderType.gemini) ...[
            ByokKeyInput(
              label: "Google Gemini API Key (BYOK / Proxy)",
              hintText: "AIzaSy...",
              controller: _byokKeyController,
            ),
          ] else if (_selectedProvider == AiProviderType.openai) ...[
            ByokKeyInput(
              label: "OpenAI API Key (sk-...)",
              hintText: "sk-proj-...",
              controller: _byokKeyController,
            ),
          ] else if (_selectedProvider == AiProviderType.claude) ...[
            ByokKeyInput(
              label: "Anthropic Claude API Key (sk-ant-...)",
              hintText: "sk-ant-api...",
              controller: _byokKeyController,
            ),
          ] else if (_selectedProvider == AiProviderType.custom) ...[
            CustomEndpointCard(
              urlController: _customUrlController,
              modelController: _customModelController,
              apiKeyController: _byokKeyController,
            ),
          ],

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveSettings,
            child: const Text("Save Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
