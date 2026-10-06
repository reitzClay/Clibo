package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.genai.Client;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentResponse;
import com.google.genai.types.Part;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.Base64;
import java.util.List;
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

            String userPrompt = (prompt != null && !prompt.isBlank()) ? prompt : "Describe what you see on this screen in detail.";
            String systemPrefix = "[System: You are Clibo AI Companion, a helpful context-aware assistant developed for ClayBytes (https://claybytes.nl/), powered by Google Gemini.]\n";
            String fullPrompt = systemPrefix + userPrompt;

            Object contentInput = fullPrompt;
            ModalityType modality = ModalityType.TEXT_MESSAGE;

            if (request != null && request.getImageBase64() != null && !request.getImageBase64().isBlank()) {
                modality = ModalityType.SCREENSHOT;
                try {
                    byte[] imageBytes = Base64.getDecoder().decode(request.getImageBase64().trim());
                    String mimeType = (request.getImageMimeType() != null && !request.getImageMimeType().isBlank())
                            ? request.getImageMimeType()
                            : "image/jpeg";

                    Part imagePart = Part.fromBytes(imageBytes, mimeType);
                    Part textPart = Part.fromText(fullPrompt);

                    contentInput = Content.builder()
                            .parts(List.of(imagePart, textPart))
                            .build();

                    logger.info("Prepared multi-modal vision request with image payload (length: {} bytes)", imageBytes.length);
                } catch (Exception imgEx) {
                    logger.warn("Failed to decode image payload, falling back to text prompt: {}", imgEx.getMessage());
                }
            }

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
                    GenerateContentResponse response;
                    if (contentInput instanceof Content contentObj) {
                        response = client.models.generateContent(modelName, contentObj, null);
                    } else {
                        response = client.models.generateContent(modelName, fullPrompt, null);
                    }

                    if (response != null && response.text() != null && !response.text().isBlank()) {
                        output = response.text();
                        logger.info("Successfully generated multi-modal response using model {}", modelName);
                        break;
                    }
                } catch (Exception modelEx) {
                    logger.warn("Gemini model {} failed: {}", modelName, modelEx.getMessage());
                }
            }

            if (output == null || output.isBlank()) {
                throw new RuntimeException("Gemini generation failed. Please check your Gemini API key or image payload.");
            }

            try {
                guardrailService.incrementUserUsage(user, modality);
                chatHistoryService.logChatInteraction(user, userPrompt, output);
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
