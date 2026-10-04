package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.Map;

@Service
public class GeminiAiService implements AiProviderService {

    private static final Logger logger = LoggerFactory.getLogger(GeminiAiService.class);

    private final String geminiApiKey = System.getenv().getOrDefault("GEMINI_API_KEY", "AQ.Ab8RN6JCZOQ7-U69Nk7cXw77dlOBPoQNXIud5r6xWPW31q5Hrg");

    private final UsageGuardrailService guardrailService;
    private final ChatHistoryService chatHistoryService;
    private final Gson gson = new Gson();
    private Client defaultClient;

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
        if (defaultClient == null) {
            defaultClient = new Client();
        }
        return defaultClient;
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        try {
            String customKey = (request != null) ? request.getByokApiKey() : null;
            Client client = getClient(customKey);

            String output = null;
            String[] modelsToTry = new String[]{
                "gemini-3.5-flash-lite",
                "gemini-3.8-flash",
                "gemini-3.5-flash",
                "gemini-3.6-flash",
                "gemini-3.7-flash",
                "gemini-flash-latest"
            };

            for (String modelName : modelsToTry) {
                try {
                    GenerateContentResponse response = client.models.generateContent(modelName, prompt, null);
                    if (response != null && response.text() != null && !response.text().isBlank()) {
                        output = response.text();
                        logger.info("Successfully generated response using model {}", modelName);
                        break;
                    }
                } catch (Exception modelEx) {
                    logger.warn("Gemini model {} failed: {}", modelName, modelEx.getMessage());
                }
            }

            if (output == null || output.isBlank()) {
                throw new RuntimeException("Gemini generation failed. Please check your Gemini API key in the Config Tab or environment.");
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
