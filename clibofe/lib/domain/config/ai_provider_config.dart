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
      orElse: () => AiProviderType.ollama,
    );
  }
}

class AiProviderConfig {
  final AiProviderType providerType;
  final String backendUrl;
  final String ollamaBaseUrl;
  final String ollamaModel;
  final String byokApiKey;
  final String customBaseUrl;
  final String customModel;

  const AiProviderConfig({
    required this.providerType,
    required this.backendUrl,
    this.ollamaBaseUrl = 'http://10.0.2.2:11434',
    this.ollamaModel = 'llama3',
    this.byokApiKey = '',
    this.customBaseUrl = 'http://10.0.2.2:1234/v1',
    this.customModel = 'local-model',
  });

  bool get isBYOK => byokApiKey.trim().isNotEmpty;

  factory AiProviderConfig.fromJson(Map<String, dynamic> json, {required String defaultBackendUrl}) {
    return AiProviderConfig(
      providerType: AiProviderType.fromId(json['aiProvider']?.toString()),
      backendUrl: json['backendUrl']?.toString() ?? defaultBackendUrl,
      ollamaBaseUrl: json['ollamaUrl']?.toString() ?? 'http://10.0.2.2:11434',
      ollamaModel: json['ollamaModel']?.toString() ?? 'llama3',
      byokApiKey: json['byokKey']?.toString() ?? '',
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
      'clibo_byok_key': byokApiKey,
      'clibo_custom_provider_url': customBaseUrl,
      'clibo_custom_model': customModel,
    };
  }

  Map<String, dynamic> toApiBody() {
    return {
      'aiProvider': providerType.id,
      'ollamaBaseUrl': ollamaBaseUrl,
      'ollamaModel': ollamaModel,
      'byokApiKey': byokApiKey,
      'customBaseUrl': customBaseUrl,
      'customModel': customModel,
    };
  }

  AiProviderConfig copyWith({
    AiProviderType? providerType,
    String? backendUrl,
    String? ollamaBaseUrl,
    String? ollamaModel,
    String? byokApiKey,
    String? customBaseUrl,
    String? customModel,
  }) {
    return AiProviderConfig(
      providerType: providerType ?? this.providerType,
      backendUrl: backendUrl ?? this.backendUrl,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      byokApiKey: byokApiKey ?? this.byokApiKey,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      customModel: customModel ?? this.customModel,
    );
  }
}
