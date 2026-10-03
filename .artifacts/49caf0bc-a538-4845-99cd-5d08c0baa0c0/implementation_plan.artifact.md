# Backend AI Provider Refactoring Plan (Strategy Pattern)

Refactor `GeminiProxyController` into a clean, extensible Strategy Pattern architecture for AI providers (`ollama`, `gemini`, `openai`, `claude`, `custom`), separating concerns and eliminating tight coupling.

## User Review Required

> [!IMPORTANT]
> This refactoring introduces an `AiProviderService` interface and dedicated implementations (`OllamaAiService`, `GeminiAiService`, etc.), routed dynamically through an `AiProxyController`. All existing API endpoints (`/api/v1/ai/chat`, `/api/v1/ai/health`, `/api/v1/ai/usage`) will maintain full backward compatibility.

## Proposed Changes

### Backend (`clibobe`)

#### [NEW] `[AiProviderService.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/service/ai/AiProviderService.java)`
- Defines the common contract for all AI providers:
  ```java
  public interface AiProviderService {
      Flux<String> generateStream(User user, AiPromptRequest request, String prompt);
      String getProviderId();
  }
  ```

#### [NEW] `[OllamaAiService.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/service/ai/OllamaAiService.java)`
- Dedicated service for Ollama communication (`/api/chat`), handling non-blocking WebClient requests and usage guardrails.

#### [NEW] `[GeminiAiService.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/service/ai/GeminiAiService.java)`
- Dedicated service for Google Gemini / GenAI SDK interactions.

#### [NEW] `[AiProxyController.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/AiProxyController.java)`
- Replaces `GeminiProxyController`.
- Autowires `Map<String, AiProviderService>` (or registry) to dispatch chat requests to the appropriate provider service dynamically based on `aiProvider`.
- Exposes `/health` and `/usage` endpoints.

#### [DELETE] `[GeminiProxyController.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/GeminiProxyController.java)`
- Replaced by `AiProxyController` and provider services.

## Verification Plan

### Automated Tests
- Build verification via Maven (`./mvnw clean compile`).
- Container build and startup check via Docker Compose.

### Manual Verification
- Test connection in the Clibo app Config tab (`/api/v1/ai/health`).
- Send a chat message with Ollama selected to verify successful response stream from `clibo-ollama`.
