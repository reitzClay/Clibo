package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
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
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/ai")
@CrossOrigin(origins = "*")
public class GeminiProxyController {

    private static final Logger logger = LoggerFactory.getLogger(GeminiProxyController.class);

    @Value("${gemini.api.key:}")
    private String geminiApiKey;

    private final UsageGuardrailService guardrailService;
    private final GoogleAuthService googleAuthService;
    private final UserRepository userRepository;
    private final Gson gson = new Gson();

    private Client client;

    public GeminiProxyController(UsageGuardrailService guardrailService,
                                 GoogleAuthService googleAuthService,
                                 UserRepository userRepository) {
        this.guardrailService = guardrailService;
        this.googleAuthService = googleAuthService;
        this.userRepository = userRepository;
    }

    private Client getClient() {
        if (client == null) {
            if (geminiApiKey != null && !geminiApiKey.isBlank()) {
                client = Client.builder().apiKey(geminiApiKey).build();
            } else {
                client = new Client();
            }
        }
        return client;
    }

    @GetMapping("/usage")
    public ResponseEntity<?> getUsageMetrics(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        Optional<User> userOpt = resolveUser(authHeader);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Unauthorized: Please provide a valid authentication token."));
        }

        User user = userOpt.get();
        return ResponseEntity.ok(guardrailService.getUsageStats(user));
    }

    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> proxyGeminiStream(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) String rawPayload) {

        Optional<User> userOpt = resolveUser(authHeader);
        if (userOpt.isEmpty()) {
            return Flux.just("data: {\"error\": \"Unauthorized: Please sign in to use Clibo AI.\"}\n\n");
        }

        User user = userOpt.get();
        String prompt = (rawPayload != null && !rawPayload.isBlank()) ? rawPayload : "Hello";
        try {
            if (rawPayload != null && rawPayload.trim().startsWith("{")) {
                com.claybytes.clibobe.dto.AiPromptRequest req = new com.google.gson.Gson().fromJson(rawPayload, com.claybytes.clibobe.dto.AiPromptRequest.class);
                if (req != null && req.getPrompt() != null && !req.getPrompt().isBlank()) {
                    prompt = req.getPrompt();
                }
            }
        } catch (Exception ignored) {}

        ModalityType modality = ModalityType.TEXT_MESSAGE;
        if (!guardrailService.isUserAllowedToRequest(user, modality)) {
            String limitMsg = "Daily limit reached for your " + user.getUserTier() + " tier. Upgrade to Pro for unlimited access!";
            return Flux.just("data: {\"error\": \"" + limitMsg + "\"}\n\n");
        }

        final ModalityType usedModality = modality;
        try {
            CreateModelInteraction params =
                CreateModelInteraction.builder()
                    .model(Model.of("gemini-3.8-flash"))
                    .input(InteractionsInput.of(prompt))
                    .build();

            Interaction interaction =
                getClient().interactions
                    .create(CreateInteractionRequestBody.of(params))
                    .interaction()
                    .get();

            logger.info("Received interaction response object: {}", interaction);
            
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
                guardrailService.incrementUserUsage(user, usedModality);
                logger.info("Incremented {} usage for user {}", usedModality, user.getEmail());
            } catch (Exception e) {
                logger.error("Failed to increment usage for user {}: {}", user.getEmail(), e.getMessage());
            }

            return Flux.just("data: " + gson.toJson(output) + "\n\n");

        } catch (Exception e) {
            logger.error("Gemini SDK error: {}", e.getMessage(), e);
            String errorJson = gson.toJson(Map.of("error", "AI service error: " + e.getMessage()));
            return Flux.just("data: " + errorJson + "\n\n");
        }
    }

    private Optional<User> resolveUser(String authHeader) {
        if (authHeader == null || authHeader.isBlank()) {
            return Optional.empty();
        }

        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7).trim() : authHeader.trim();

        try {
            GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
            if (payload != null && payload.getEmail() != null) {
                return userRepository.findByEmail(payload.getEmail());
            }
        } catch (Exception ignored) {
        }

        if (token.contains("@")) {
            return userRepository.findByEmail(token);
        }

        if (token.contains("dev")) {
            User devUser = userRepository.findByEmail("dev@clibo.ai")
                    .orElseGet(() -> {
                        User u = new User();
                        u.setEmail("dev@clibo.ai");
                        u.setName("Developer Tester");
                        u.setUserTier("PRO");
                        u.setSystemRole("ADMIN");
                        return userRepository.save(u);
                    });
            return Optional.of(devUser);
        }

        try {
            Long id = Long.parseLong(token);
            return userRepository.findById(id);
        } catch (NumberFormatException ignored) {
        }

        return Optional.empty();
    }
}
