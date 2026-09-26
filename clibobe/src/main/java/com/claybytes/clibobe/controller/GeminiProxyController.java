package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.dto.Content;
import com.claybytes.clibobe.dto.GeminiRequest;
import com.claybytes.clibobe.dto.Part;
import com.claybytes.clibobe.service.FirebaseAuthService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai")
public class GeminiProxyController {

    private final WebClient geminiWebClient;
    private final UsageGuardrailService guardrailService;
    private final FirebaseAuthService authService; // Your existing Firebase validation

    public GeminiProxyController(WebClient geminiWebClient,
                                 UsageGuardrailService guardrailService,
                                 FirebaseAuthService authService) {
        this.geminiWebClient = geminiWebClient;
        this.guardrailService = guardrailService;
        this.authService = authService;
    }

    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> proxyGeminiStream(
            @RequestHeader("Authorization") String tokenHeader,
            @RequestBody String rawUserPrompt) {

        try {
            // 1. Authenticate the Flutter user via Firebase Admin SDK
            FirebaseToken decodedToken = authService.verifyToken(tokenHeader);
            String uid = decodedToken.getUid();

            // 2. Query Firestore to check constraints (Free tier vs Premium)
            if (!guardrailService.isUserAllowedToRequest(uid)) {
                return Flux.just("data: {\"error\": \"Limit reached. Upgrade to Premium!\"}\n\n");
            }

            // 3. Map the simple text prompt into Gemini's payload structure
            GeminiRequest geminiPayload = new GeminiRequest(
                    List.of(new Content("user", List.of(new Part(rawUserPrompt))))
            );

            // 4. Fire the async request to Gemini and forward chunks directly back to Flutter
            return this.geminiWebClient.post()
                    // Using gemini-1.5-flash as it is ultra-fast and perfect for overlay interactions
                    .uri("/models/gemini-1.5-flash:streamGenerateContent")
                    .bodyValue(geminiPayload)
                    .retrieve()
                    .bodyToFlux(String.class) // Non-blocking reactive stream chunk mapping
                    .doOnComplete(() -> guardrailService.incrementUserUsage(uid)); // Async update Firestore counter

        } catch (IllegalArgumentException e) {
            return Flux.just("data: {\"error\": \"Unauthorized access\"}\n\n");
        }
    }
}

