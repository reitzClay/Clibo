enum AiProviderType {
  ollama('ollama', 'Local Ollama (Zero Tokens / Local LLM)'),
  gemini('gemini', 'Google Gemini (Cloud Proxy or BYOK)'),
  openai('openai', 'OpenAI (GPT-4o / GPT-4o-mini BYOK)'),
  claude('claude', 'Anthropic Claude (Claude 3.5 Sonnet BYOK)'),
  custom('custom', 'Custom Endpoint (vLLM / LM Studio / LocalAI)');

  final String id;
  final String label;

  const AiProviderType(this.id, this.label);

  static AiProviderType fromId(String? id) {
    return AiProviderType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => AiProviderType.gemini,
    );
  }
}

class AiProviderConfig {
  final AiProviderType providerType;
  final String backendUrl;
  final String ollamaBaseUrl;
  final String ollamaModel;
  final String geminiApiKey;
  final String openaiApiKey;
  final String claudeApiKey;
  final String customApiKey;
  final String customBaseUrl;
  final String customModel;

  const AiProviderConfig({
    required this.providerType,
    required this.backendUrl,
    this.ollamaBaseUrl = 'http://10.0.2.2:11434',
    this.ollamaModel = 'llama3',
    this.geminiApiKey = '',
    this.openaiApiKey = '',
    this.claudeApiKey = '',
    this.customApiKey = '',
    this.customBaseUrl = 'http://10.0.2.2:1234/v1',
    this.customModel = 'local-model',
  });

  /// Get the active API key corresponding to the currently selected provider type
  String get activeApiKey {
    switch (providerType) {
      case AiProviderType.gemini:
        return geminiApiKey;
      case AiProviderType.openai:
        return openaiApiKey;
      case AiProviderType.claude:
        return claudeApiKey;
      case AiProviderType.custom:
        return customApiKey;
      case AiProviderType.ollama:
        return '';
    }
  }

  bool get isBYOK => activeApiKey.trim().isNotEmpty;

  factory AiProviderConfig.fromJson(Map<String, dynamic> json, {required String defaultBackendUrl}) {
    return AiProviderConfig(
      providerType: AiProviderType.fromId(json['aiProvider']?.toString()),
      backendUrl: json['backendUrl']?.toString() ?? defaultBackendUrl,
      ollamaBaseUrl: json['ollamaUrl']?.toString() ?? 'http://10.0.2.2:11434',
      ollamaModel: json['ollamaModel']?.toString() ?? 'llama3',
      geminiApiKey: json['geminiApiKey']?.toString() ?? json['byokKey']?.toString() ?? '',
      openaiApiKey: json['openaiApiKey']?.toString() ?? '',
      claudeApiKey: json['claudeApiKey']?.toString() ?? '',
      customApiKey: json['customApiKey']?.toString() ?? '',
      customBaseUrl: json['customBaseUrl']?.toString() ?? 'http://10.0.2.2:1234/v1',
      customModel: json['customModel']?.toString() ?? 'local-model',
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'clibo_ai_provider': providerType.id,
      'clibo_backend_url': backendUrl,
      'clibo_ollama_url': ollamaBaseUrl,
      'clibo_ollama_model': ollamaModel,
      'clibo_gemini_key': geminiApiKey,
      'clibo_openai_key': openaiApiKey,
      'clibo_claude_key': claudeApiKey,
      'clibo_custom_key': customApiKey,
      'clibo_custom_provider_url': customBaseUrl,
      'clibo_custom_model': customModel,
    };
  }

  Map<String, dynamic> toApiBody() {
    return {
      'aiProvider': providerType.id,
      'ollamaBaseUrl': ollamaBaseUrl,
      'ollamaModel': ollamaModel,
      'byokApiKey': activeApiKey,
      'customBaseUrl': customBaseUrl,
      'customModel': customModel,
    };
  }
}
