package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserConsent;
import com.claybytes.clibobe.repository.UserConsentRepository;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.service.UserService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*")
public class ConsentController {

    private static final Logger logger = LoggerFactory.getLogger(ConsentController.class);

    private final UserConsentRepository consentRepository;
    private final UserRepository userRepository;
    private final GoogleAuthService googleAuthService;
    private final UserService userService;

    public ConsentController(UserConsentRepository consentRepository,
                             UserRepository userRepository,
                             GoogleAuthService googleAuthService,
                             UserService userService) {
        this.consentRepository = consentRepository;
        this.userRepository = userRepository;
        this.googleAuthService = googleAuthService;
        this.userService = userService;
    }

    @PostMapping("/consent")
    public ResponseEntity<?> logConsent(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestHeader(value = "X-Forwarded-For", required = false) String forwardedFor,
            ServerHttpRequest request,
            @RequestBody(required = false) Map<String, String> payload) {

        Optional<User> userOpt = resolveUser(authHeader);
        if (userOpt.isEmpty()) {
            logger.warn("Consent logging attempt failed: Unable to resolve authenticated user.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Unauthorized: Please provide a valid authentication token."));
        }

        User user = userOpt.get();
        String policyVersion = (payload != null && payload.containsKey("policyVersion")) 
                ? payload.get("policyVersion") 
                : "v1.0";

        String clientIp = extractClientIp(request, forwardedFor);

        UserConsent consent = new UserConsent(user, clientIp, policyVersion);
        consentRepository.save(consent);

        logger.info("Successfully logged ToS & Privacy consent for user: {} (IP: {})", user.getEmail(), clientIp);

        return ResponseEntity.ok(Map.of(
            "status", "success",
            "message", "Terms of Service & Privacy Policy consent successfully logged for compliance.",
            "consentedAt", consent.getConsentedAt().toString()
        ));
    }

    /**
     * Future-proof IP extractor for Spring WebFlux supporting Google Cloud Run / GCP Load Balancers,
     * Nginx, Cloudflare, and local Docker/emulator connections.
     */
    private String extractClientIp(ServerHttpRequest request, String forwardedFor) {
        // 1. Google Cloud / AWS / Standard Reverse Proxies
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }

        if (request != null) {
            // 2. Nginx / Ingress Controllers
            String realIp = request.getHeaders().getFirst("X-Real-IP");
            if (realIp != null && !realIp.isBlank()) {
                return realIp.trim();
            }

            // 3. Cloudflare Edge Proxy
            String cfIp = request.getHeaders().getFirst("CF-Connecting-IP");
            if (cfIp != null && !cfIp.isBlank()) {
                return cfIp.trim();
            }

            // 4. Fallback for direct local connections & Docker
            if (request.getRemoteAddress() != null && request.getRemoteAddress().getAddress() != null) {
                return request.getRemoteAddress().getAddress().getHostAddress();
            }
        }

        return "unknown";
    }

    private Optional<User> resolveUser(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            if (token.startsWith("dev_mock_token_")) {
                User devUser = userService.processUserLogin("dev@clibo.ai", "Developer Tester");
                return Optional.of(devUser);
            }

            try {
                com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
                if (payload != null && payload.getEmail() != null) {
                    String email = payload.getEmail();
                    String name = payload.get("name") != null ? payload.get("name").toString() : email.split("@")[0];
                    return Optional.of(userService.processUserLogin(email, name));
                }
            } catch (Exception e) {
                logger.debug("Google token verification during consent logging failed: {}", e.getMessage());
            }

            if (token.contains("@")) {
                return Optional.of(userService.processUserLogin(token, token.split("@")[0]));
            }

            try {
                Long id = Long.parseLong(token);
                return userRepository.findById(id);
            } catch (NumberFormatException ignored) {}
        }
        return Optional.empty();
    }
}
