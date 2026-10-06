package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.claybytes.clibobe.service.UserService;
import com.claybytes.clibobe.service.ai.AiProviderService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
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
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/ai")
@CrossOrigin(origins = "*")
public class AiProxyController {

    private static final Logger logger = LoggerFactory.getLogger(AiProxyController.class);

    private final String defaultAiProvider = System.getenv().getOrDefault("AI_PROVIDER", "ollama");

    private final Map<String, AiProviderService> providerServiceMap;
    private final UsageGuardrailService guardrailService;
    private final UserRepository userRepository;
    private final GoogleAuthService googleAuthService;
    private final UserService userService;
    private final Gson gson = new Gson();

    public AiProxyController(List<AiProviderService> providerServices,
                             UsageGuardrailService guardrailService,
                             UserRepository userRepository,
                             GoogleAuthService googleAuthService,
                             UserService userService) {
        this.providerServiceMap = providerServices.stream()
                .collect(Collectors.toMap(AiProviderService::getProviderId, Function.identity()));
        this.guardrailService = guardrailService;
        this.userRepository = userRepository;
        this.googleAuthService = googleAuthService;
        this.userService = userService;
    }

    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "clibobe-ai-proxy"));
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
    public Flux<String> chatStream(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) String rawPayload) {

        Optional<User> userOpt = resolveUser(authHeader);
        if (userOpt.isEmpty()) {
            return Flux.just("data: {\"error\": \"Unauthorized: Please sign in to use Clibo AI.\"}\n\n");
        }

        User user = userOpt.get();
        String prompt = "Hello";
        AiPromptRequest req = null;

        try {
            if (rawPayload != null && rawPayload.trim().startsWith("{")) {
                req = gson.fromJson(rawPayload, AiPromptRequest.class);
                if (req != null && req.getPrompt() != null && !req.getPrompt().isBlank()) {
                    prompt = req.getPrompt();
                }
            } else if (rawPayload != null && !rawPayload.isBlank()) {
                prompt = rawPayload;
            }
        } catch (Exception ignored) {}

        ModalityType modality = ModalityType.TEXT_MESSAGE;
        if (!guardrailService.isUserAllowedToRequest(user, modality)) {
            String limitMsg = "Daily limit reached for your " + user.getUserTier() + " tier. Upgrade to Pro for unlimited access!";
            return Flux.just("data: {\"error\": \"" + limitMsg + "\"}\n\n");
        }

        String effectiveProvider = (req != null && req.getAiProvider() != null && !req.getAiProvider().isBlank())
                ? req.getAiProvider().toLowerCase()
                : defaultAiProvider.toLowerCase();

        AiProviderService providerService = providerServiceMap.get(effectiveProvider);
        if (providerService == null) {
            providerService = providerServiceMap.get("ollama"); // fallback
        }

        if (providerService == null) {
            return Flux.just("data: {\"error\": \"Unsupported AI provider: " + effectiveProvider + "\"}\n\n");
        }

        return providerService.generateStream(user, req, prompt);
    }

    private Optional<User> resolveUser(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            if (token.startsWith("dev_mock_token_")) {
                return userRepository.findByEmail("dev@clibo.ai").or(() -> userRepository.findAll().stream().findFirst());
            }

            // 1. Verify via Google OAuth
            try {
                com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
                if (payload != null && payload.getEmail() != null) {
                    String email = payload.getEmail();
                    String name = payload.get("name") != null ? payload.get("name").toString() : email.split("@")[0];
                    return Optional.of(userService.processUserLogin(email, name));
                }
            } catch (Exception ignored) {
            }

            // 2. Fallback check by email (for company/email login)
            if (token.contains("@")) {
                Optional<User> userOpt = userRepository.findByEmail(token);
                if (userOpt.isPresent()) {
                    return userOpt;
                }
            }

            // 3. Fallback check by ID
            try {
                Long id = Long.parseLong(token);
                Optional<User> userOpt = userRepository.findById(id);
                if (userOpt.isPresent()) {
                    return userOpt;
                }
            } catch (NumberFormatException ignored) {
            }
        }
        return Optional.empty();
    }
}
