import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/services/network_config.dart';
import '../../domain/config/ai_provider_config.dart';

class ConfigService {
  final FlutterSecureStorage _storage;

  ConfigService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Loads current user AI provider configuration from secure storage.
  Future<AiProviderConfig> loadConfig() async {
    final providerId = await _storage.read(key: 'clibo_ai_provider');
    final backendUrl = await _storage.read(key: 'clibo_backend_url');
    final ollamaUrl = await _storage.read(key: 'clibo_ollama_url');
    final ollamaModel = await _storage.read(key: 'clibo_ollama_model');
    final byokKey = await _storage.read(key: 'clibo_byok_key');
    final customUrl = await _storage.read(key: 'clibo_custom_provider_url');
    final customModel = await _storage.read(key: 'clibo_custom_model');

    return AiProviderConfig(
      providerType: AiProviderType.fromId(providerId),
      backendUrl: backendUrl ?? '',
      ollamaBaseUrl: ollamaUrl ?? '',
      ollamaModel: ollamaModel ?? '',
      byokApiKey: byokKey ?? '',
      customBaseUrl: customUrl ?? '',
      customModel: customModel ?? '',
    );
  }

  /// Persists AI provider configuration to secure storage.
  Future<void> saveConfig(AiProviderConfig config) async {
    final storageMap = config.toStorageMap();
    for (final entry in storageMap.entries) {
      await _storage.write(key: entry.key, value: entry.value.trim());
    }
    await NetworkConfig.setBackendBaseUrl(config.backendUrl.trim());
  }
}
