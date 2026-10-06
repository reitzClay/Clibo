package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@Service
public class OpenAiCompatibleAiService implements AiProviderService {

    private static final Logger logger = LoggerFactory.getLogger(OpenAiCompatibleAiService.class);

    private final UsageGuardrailService guardrailService;
    private final ChatHistoryService chatHistoryService;
    private final Gson gson = new Gson();

    public OpenAiCompatibleAiService(UsageGuardrailService guardrailService, ChatHistoryService chatHistoryService) {
        this.guardrailService = guardrailService;
        this.chatHistoryService = chatHistoryService;
    }

    @Override
    public String getProviderId() {
        return "openai";
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        String baseUrl = (request != null && request.getCustomBaseUrl() != null && !request.getCustomBaseUrl().isBlank())
                ? request.getCustomBaseUrl()
                : "https://api.openai.com/v1";

        String apiKey = (request != null && request.getByokApiKey() != null && !request.getByokApiKey().isBlank())
                ? request.getByokApiKey()
                : System.getenv().getOrDefault("OPENAI_API_KEY", "");

        String model = (request != null && request.getCustomModel() != null && !request.getCustomModel().isBlank())
                ? request.getCustomModel()
                : "gpt-4o-mini";

        WebClient.Builder builder = WebClient.builder().baseUrl(baseUrl);
        if (apiKey != null && !apiKey.isBlank()) {
            builder.defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey);
        }
        WebClient client = builder.build();

        Map<String, Object> reqBody = Map.of(
            "model", model,
            "messages", List.of(Map.of("role", "user", "content", prompt)),
            "stream", false
        );

        return client.post()
                .uri("/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(gson.toJson(reqBody))
                .retrieve()
                .bodyToMono(String.class)
                .map(respJson -> {
                    Map respMap = gson.fromJson(respJson, Map.class);
                    List choices = (List) respMap.get("choices");
                    if (choices != null && !choices.isEmpty()) {
                        Map firstChoice = (Map) choices.get(0);
                        Map msg = (Map) firstChoice.get("message");
                        if (msg != null && msg.containsKey("content")) {
                            return msg.get("content").toString();
                        }
                    }
                    return "No response from OpenAI compatible provider";
                })
                .map(output -> {
                    try {
                        guardrailService.incrementUserUsage(user, ModalityType.TEXT_MESSAGE);
                        chatHistoryService.logChatInteraction(user, prompt, output);
                    } catch (Exception ex) {
                        logger.error("Failed to increment usage or log chat: {}", ex.getMessage());
                    }
                    return "data: " + gson.toJson(Map.of("text", output)) + "\n\n";
                })
                .onErrorResume(e -> {
                    logger.error("OpenAI compatible provider error: {}", e.getMessage(), e);
                    String errorJson = gson.toJson(Map.of("error", "AI Provider error: " + e.getMessage()));
                    return Mono.just("data: " + errorJson + "\n\n");
                })
                .flux();
    }
}
