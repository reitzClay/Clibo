package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.service.UsageGuardrailService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GeminiProxyControllerTest {

    @Mock
    private WebClient geminiWebClient;

    @Mock
    private UsageGuardrailService guardrailService;

    @Mock
    private GoogleAuthService googleAuthService;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private GeminiProxyController proxyController;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setEmail("user@example.com");
        sampleUser.setName("Sample User");
        sampleUser.setUserTier("FREE");
    }

    @Test
    void getUsageMetrics_Unauthorized() {
        ResponseEntity<?> response = proxyController.getUsageMetrics(null);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void getUsageMetrics_Success() {
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(sampleUser));
        when(guardrailService.getUsageStats(sampleUser)).thenReturn(Map.of("textMessagesRemaining", 25));

        ResponseEntity<?> response = proxyController.getUsageMetrics("user@example.com");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(Map.of("textMessagesRemaining", 25), response.getBody());
    }

    @Test
    void proxyGeminiStream_Unauthorized() {
        Flux<String> stream = proxyController.proxyGeminiStream(null, "Hello AI");

        StepVerifier.create(stream)
                .expectNext("data: {\"error\": \"Unauthorized: Please sign in to use Clibo AI.\"}\n\n")
                .verifyComplete();
    }

    @Test
    void proxyGeminiStream_QuotaExceeded() {
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(sampleUser));
        when(guardrailService.isUserAllowedToRequest(eq(sampleUser), any(ModalityType.class))).thenReturn(false);

        Flux<String> stream = proxyController.proxyGeminiStream("user@example.com", "Hello AI");

        StepVerifier.create(stream)
                .expectNextMatches(msg -> msg.contains("Daily limit reached"))
                .verifyComplete();
    }
}
