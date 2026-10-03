package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
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

    private static final Logger logger = LoggerFactory.getLogger(OllamaAiService.java);

    private final String defaultOllamaBaseUrl = System.getenv().getOrDefault("OLLAMA_BASE_URL", "http://host.docker.internal:11434");

    private final UsageGuardrailService guardrailService;
    private final Gson gson = new Gson();

    public OllamaAiService(UsageGuardrailService guardrailService) {
        this.guardrailService = guardrailService;
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
        Map<String, Object> reqBody = Map.of(
            "model", targetModel,
            "messages", List.of(Map.of("role", "user", "content", prompt)),
            "stream", false
        );

        return webClient.post()
                .uri("/api/chat")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(gson.toJson(reqBody))
                .retrieve()
                .bodyToMono(String.class)
                .map(responseJson -> {
                    Map respMap = gson.fromJson(responseJson, Map.class);
                    Map msgMap = (Map) respMap.get("message");
                    String output = msgMap != null && msgMap.containsKey("content") 
                        ? msgMap.get("content").toString() 
                        : "No output received from Ollama";

                    try {
                        guardrailService.incrementUserUsage(user, ModalityType.TEXT_MESSAGE);
                    } catch (Exception e) {
                        logger.error("Failed to increment usage: {}", e.getMessage());
                    }

                    return "data: " + gson.toJson(Map.of("text", output)) + "\n\n";
                })
                .onErrorResume(e -> {
                    logger.error("Ollama local LLM error: {}", e.getMessage(), e);
                    String errorJson = gson.toJson(Map.of("error", "Local LLM error (Ollama): " + e.getMessage() + ". Make sure Ollama is running and model is pulled."));
                    return Mono.just("data: " + errorJson + "\n\n");
                })
                .flux();
    }
}
