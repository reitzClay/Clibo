// The blueprint for any AI model the user chooses
abstract class CliboAIClient {
  Future<String> generateResponse(String prompt);
}

// Concrete implementation if they choose Gemini
class GeminiClient implements CliboAIClient {
  final String apiKey;
  GeminiClient(this.apiKey);

  @override
  Future<String> generateResponse(String prompt) async {
    // Implement direct HTTP/Dio call to Google AI Studio endpoint
    // https://googleapis.com
    return "Response from Gemini";
  }
}

// Concrete implementation for Claude / Custom OpenAI endpoints
class OpenAiCompatibleClient implements CliboAIClient {
  final String apiKey;
  final String baseUrl;
  final String modelName;
  OpenAiCompatibleClient({required this.apiKey, required this.baseUrl, required this.modelName});

  @override
  Future<String> generateResponse(String prompt) async {
    // Standard OpenAI chat completion format
    return "Response from custom endpoint";
  }
}
