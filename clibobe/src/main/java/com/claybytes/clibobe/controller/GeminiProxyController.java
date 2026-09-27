package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.dto.Content;
import com.claybytes.clibobe.dto.GeminiRequest;
import com.claybytes.clibobe.dto.Part;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/ai")
@CrossOrigin(origins = "*")
public class GeminiProxyController {

    private static final Logger logger = LoggerFactory.getLogger(GeminiProxyController.class);

    private final WebClient geminiWebClient;
    private final UsageGuardrailService guardrailService;
    private final GoogleAuthService googleAuthService;
    private final UserRepository userRepository;
    private final Gson gson = new Gson();

    public GeminiProxyController(WebClient geminiWebClient,
                                 UsageGuardrailService guardrailService,
                                 GoogleAuthService googleAuthService,
                                 UserRepository userRepository) {
        this.geminiWebClient = geminiWebClient;
        this.guardrailService = guardrailService;
        this.googleAuthService = googleAuthService;
        this.userRepository = userRepository;
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
        AiPromptRequest request = parseRequest(rawPayload);

        // Determine modality types involved
        ModalityType modality = ModalityType.TEXT_MESSAGE;
        if (request.getImageBase64() != null && !request.getImageBase64().isBlank()) {
            modality = ModalityType.SCREENSHOT;
        } else if (request.getAudioBase64() != null && !request.getAudioBase64().isBlank()) {
            modality = ModalityType.VOICE_NOTE;
        }

        // Check user tier & guardrail limits
        if (!guardrailService.isUserAllowedToRequest(user, modality)) {
            String limitMsg = "Daily limit reached for your " + user.getUserTier() + " tier (" + modality + "). Upgrade to Pro for unlimited access!";
            return Flux.just("data: {\"error\": \"" + limitMsg + "\"}\n\n");
        }

        // Build Gemini payload
        List<Part> parts = new ArrayList<>();
        if (request.getImageBase64() != null && !request.getImageBase64().isBlank()) {
            parts.add(new Part(request.getImageMimeType(), request.getImageBase64()));
        }
        if (request.getAudioBase64() != null && !request.getAudioBase64().isBlank()) {
            parts.add(new Part(request.getAudioMimeType(), request.getAudioBase64()));
        }
        if (request.getPrompt() != null && !request.getPrompt().isBlank()) {
            parts.add(new Part(request.getPrompt()));
        } else if (parts.isEmpty()) {
            parts.add(new Part("Hello"));
        }

        GeminiRequest geminiPayload = new GeminiRequest(
                List.of(new Content("user", parts))
        );

        final ModalityType usedModality = modality;
        return this.geminiWebClient.post()
                .uri("/models/gemini-1.5-flash:streamGenerateContent")
                .bodyValue(geminiPayload)
                .retrieve()
                .bodyToFlux(String.class)
                .doOnComplete(() -> {
                    try {
                        guardrailService.incrementUserUsage(user, usedModality);
                        logger.info("Incremented {} usage for user {}", usedModality, user.getEmail());
                    } catch (Exception e) {
                        logger.error("Failed to increment usage for user {}: {}", user.getEmail(), e.getMessage());
                    }
                })
                .onErrorResume(e -> {
                    logger.error("Gemini stream error: {}", e.getMessage(), e);
                    return Flux.just("data: {\"error\": \"AI service error: " + e.getMessage() + "\"}\n\n");
                });
    }

    private AiPromptRequest parseRequest(String rawPayload) {
        if (rawPayload == null || rawPayload.isBlank()) {
            return new AiPromptRequest("");
        }
        try {
            if (rawPayload.trim().startsWith("{")) {
                AiPromptRequest req = gson.fromJson(rawPayload, AiPromptRequest.class);
                if (req != null) return req;
            }
        } catch (Exception e) {
            logger.debug("Parsing raw prompt as plain text string: {}", e.getMessage());
        }
        return new AiPromptRequest(rawPayload);
    }

    private Optional<User> resolveUser(String authHeader) {
        if (authHeader == null || authHeader.isBlank()) {
            return Optional.empty();
        }

        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7).trim() : authHeader.trim();

        // 1. Try Google OAuth token verification
        try {
            GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
            if (payload != null && payload.getEmail() != null) {
                return userRepository.findByEmail(payload.getEmail());
            }
        } catch (Exception ignored) {
        }

        // 2. Direct fallback lookup by email or user ID (useful for dev testing / mock user)
        if (token.contains("@")) {
            return userRepository.findByEmail(token);
        }

        try {
            Long id = Long.parseLong(token);
            return userRepository.findById(id);
        } catch (NumberFormatException ignored) {
        }

        return Optional.empty();
    }
}

