package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.genai.Client;
import com.google.genai.gaos.models.interactions.CreateModelInteraction;
import com.google.genai.gaos.models.interactions.Interaction;
import com.google.genai.gaos.models.interactions.InteractionsInput;
import com.google.genai.gaos.models.interactions.Model;
import com.google.genai.gaos.models.operations.CreateInteractionRequestBody;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@Service
public class GeminiAiService implements AiProviderService {

    private static final Logger logger = LoggerFactory.getLogger(GeminiAiService.class);

    private final String geminiApiKey = System.getenv().getOrDefault("GEMINI_API_KEY", "");

    private final UsageGuardrailService guardrailService;
    private final ChatHistoryService chatHistoryService;
    private final Gson gson = new Gson();
    private Client client;

    public GeminiAiService(UsageGuardrailService guardrailService, ChatHistoryService chatHistoryService) {
        this.guardrailService = guardrailService;
        this.chatHistoryService = chatHistoryService;
    }

    @Override
    public String getProviderId() {
        return "gemini";
    }

    private Client getClient(String customApiKey) {
        String keyToUse = (customApiKey != null && !customApiKey.isBlank()) ? customApiKey : geminiApiKey;
        if (keyToUse != null && !keyToUse.isBlank()) {
            return Client.builder().apiKey(keyToUse).build();
        }
        if (client == null) {
            client = new Client();
        }
        return client;
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        try {
            CreateModelInteraction params =
                CreateModelInteraction.builder()
                    .model(Model.of("gemini-2.5-flash-lite"))
                    .input(InteractionsInput.of(prompt))
                    .build();

            String customKey = (request != null) ? request.getByokApiKey() : null;
            Interaction interaction =
                getClient(customKey).interactions
                    .create(CreateInteractionRequestBody.of(params))
                    .interaction()
                    .get();

            String output = "No output received";
            try {
                String json = gson.toJson(interaction);
                Map map = gson.fromJson(json, Map.class);
                List steps = (List) map.get("steps");
                if (steps != null) {
                    for (Object step : steps) {
                        Map stepMap = (Map) step;
                        if ("model_output".equals(stepMap.get("type"))) {
                            List contentList = (List) stepMap.get("content");
                            if (contentList != null && !contentList.isEmpty()) {
                                Map contentMap = (Map) contentList.get(0);
                                if (contentMap.containsKey("text")) {
                                    output = contentMap.get("text").toString();
                                    break;
                                }
                            }
                        }
                    }
                }
            } catch (Exception parseEx) {
                logger.warn("Failed to parse interaction json: {}", parseEx.getMessage());
                output = interaction.outputText().orElse("No output received");
            }

            try {
                guardrailService.incrementUserUsage(user, ModalityType.TEXT_MESSAGE);
                chatHistoryService.logChatInteraction(user, prompt, output);
            } catch (Exception e) {
                logger.error("Failed to increment usage or log chat for user {}: {}", user.getEmail(), e.getMessage());
            }

            return Flux.just("data: " + gson.toJson(Map.of("text", output)) + "\n\n");
        } catch (Exception e) {
            logger.error("Gemini SDK error: {}", e.getMessage(), e);
            String errorJson = gson.toJson(Map.of("error", "Gemini API error: " + e.getMessage()));
            return Flux.just("data: " + errorJson + "\n\n");
        }
    }
}
