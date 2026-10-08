package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@Service
public class OllamaAiService implements AiProviderService {

    private static final Logger logger = LoggerFactory.getLogger(OllamaAiService.class);

    private final String defaultOllamaBaseUrl = System.getenv().getOrDefault("OLLAMA_BASE_URL", "http://localhost:11434");

    private final UsageGuardrailService guardrailService;
    private final ChatHistoryService chatHistoryService;
    private final Gson gson = new Gson();

    public OllamaAiService(UsageGuardrailService guardrailService, ChatHistoryService chatHistoryService) {
        this.guardrailService = guardrailService;
        this.chatHistoryService = chatHistoryService;
    }

    @Override
    public String getProviderId() {
        return "ollama";
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        String targetOllamaUrl = (request != null && request.getOllamaBaseUrl() != null && !request.getOllamaBaseUrl().isBlank())
                ? request.getOllamaBaseUrl()
                : defaultOllamaBaseUrl;

        String targetModel = (request != null && request.getOllamaModel() != null && !request.getOllamaModel().isBlank())
                ? request.getOllamaModel()
                : "tinyllama:1.1b";

        WebClient webClient = WebClient.builder().baseUrl(targetOllamaUrl).build();
        Map<String, Object> chatReqBody = Map.of(
            "model", targetModel,
            "messages", List.of(Map.of("role", "user", "content", prompt)),
            "stream", false
        );

        return webClient.post()
                .uri("/api/chat")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(gson.toJson(chatReqBody))
                .retrieve()
                .bodyToMono(String.class)
                .map(responseJson -> {
                    Map respMap = gson.fromJson(responseJson, Map.class);
                    Map msgMap = (Map) respMap.get("message");
                    return msgMap != null && msgMap.containsKey("content") 
                        ? msgMap.get("content").toString() 
                        : "No output received from Ollama";
                })
                .onErrorResume(e -> {
                    logger.info("Ollama /api/chat failed ({}), falling back to /api/generate", e.getMessage());
                    Map<String, Object> genReqBody = Map.of(
                        "model", targetModel,
                        "prompt", prompt,
                        "stream", false
                    );
                    return webClient.post()
                            .uri("/api/generate")
                            .contentType(MediaType.APPLICATION_JSON)
                            .bodyValue(gson.toJson(genReqBody))
                            .retrieve()
                            .bodyToMono(String.class)
                            .map(responseJson -> {
                                Map respMap = gson.fromJson(responseJson, Map.class);
                                return respMap != null && respMap.containsKey("response")
                                    ? respMap.get("response").toString()
                                    : "No output received from Ollama";
                            });
                })
                .map(output -> {
                    try {
                        guardrailService.incrementUserUsage(user, ModalityType.TEXT_MESSAGE);
                        String dbPrompt = (request != null && request.getCleanPrompt() != null && !request.getCleanPrompt().isBlank())
                                ? request.getCleanPrompt()
                                : prompt;
                        String sessId = (request != null) ? request.getSessionId() : null;
                        chatHistoryService.logChatInteraction(user, dbPrompt, output, "Ollama Local", sessId);
                    } catch (Exception ex) {
                        logger.error("Failed to increment usage or log chat: {}", ex.getMessage());
                    }

                    return "data: " + gson.toJson(Map.of("text", output)) + "\n\n";
                })
                .onErrorResume(e -> {
                    logger.error("Ollama local LLM error on both /api/chat and /api/generate: {}", e.getMessage(), e);
                    String errorJson = gson.toJson(Map.of("error", "Local LLM error (Ollama): " + e.getMessage() + ". Make sure Ollama is running and model is pulled."));
                    return Mono.just("data: " + errorJson + "\n\n");
                })
                .flux();
    }
}
