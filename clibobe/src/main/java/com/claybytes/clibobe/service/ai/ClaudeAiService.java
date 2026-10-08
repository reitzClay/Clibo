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
public class ClaudeAiService implements AiProviderService {

    private static final Logger logger = LoggerFactory.getLogger(ClaudeAiService.class);

    private final String defaultClaudeApiKey = System.getenv().getOrDefault("CLAUDE_API_KEY", "");

    private final UsageGuardrailService guardrailService;
    private final ChatHistoryService chatHistoryService;
    private final Gson gson = new Gson();

    public ClaudeAiService(UsageGuardrailService guardrailService, ChatHistoryService chatHistoryService) {
        this.guardrailService = guardrailService;
        this.chatHistoryService = chatHistoryService;
    }

    @Override
    public String getProviderId() {
        return "claude";
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        String baseUrl = "https://api.anthropic.com/v1";

        String apiKey = (request != null && request.getByokApiKey() != null && !request.getByokApiKey().isBlank())
                ? request.getByokApiKey()
                : defaultClaudeApiKey;

        String model = (request != null && request.getCustomModel() != null && !request.getCustomModel().isBlank())
                ? request.getCustomModel()
                : "claude-3-5-sonnet-20241022";

        WebClient client = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("x-api-key", apiKey)
                .defaultHeader("anthropic-version", "2023-06-01")
                .build();

        Map<String, Object> reqBody = Map.of(
            "model", model,
            "max_tokens", 1024,
            "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        return client.post()
                .uri("/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(gson.toJson(reqBody))
                .retrieve()
                .bodyToMono(String.class)
                .map(respJson -> {
                    Map respMap = gson.fromJson(respJson, Map.class);
                    List content = (List) respMap.get("content");
                    if (content != null && !content.isEmpty()) {
                        Map firstBlock = (Map) content.get(0);
                        if (firstBlock != null && firstBlock.containsKey("text")) {
                            return firstBlock.get("text").toString();
                        }
                    }
                    return "No response from Claude provider";
                })
                .map(output -> {
                    try {
                        guardrailService.incrementUserUsage(user, ModalityType.TEXT_MESSAGE);
                        String dbPrompt = (request != null && request.getCleanPrompt() != null && !request.getCleanPrompt().isBlank())
                                ? request.getCleanPrompt()
                                : prompt;
                        String sessId = (request != null) ? request.getSessionId() : null;
                        chatHistoryService.logChatInteraction(user, dbPrompt, output, "Anthropic Claude", sessId);
                    } catch (Exception ex) {
                        logger.error("Failed to increment usage or log chat: {}", ex.getMessage());
                    }
                    return "data: " + gson.toJson(Map.of("text", output)) + "\n\n";
                })
                .onErrorResume(e -> {
                    logger.error("Claude API error: {}", e.getMessage(), e);
                    String errorJson = gson.toJson(Map.of("error", "Claude API error: " + e.getMessage()));
                    return Mono.just("data: " + errorJson + "\n\n");
                })
                .flux();
    }
}
