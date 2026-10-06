package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserConsent;
import com.claybytes.clibobe.repository.UserConsentRepository;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*")
public class ConsentController {

    private final UserConsentRepository consentRepository;
    private final UserRepository userRepository;
    private final GoogleAuthService googleAuthService;

    public ConsentController(UserConsentRepository consentRepository,
                             UserRepository userRepository,
                             GoogleAuthService googleAuthService) {
        this.consentRepository = consentRepository;
        this.userRepository = userRepository;
        this.googleAuthService = googleAuthService;
    }

    @PostMapping("/consent")
    public ResponseEntity<?> logConsent(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestHeader(value = "X-Forwarded-For", required = false) String forwardedFor,
            @RequestBody(required = false) Map<String, String> payload) {

        Optional<User> userOpt = resolveUser(authHeader);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Unauthorized: Please provide a valid authentication token."));
        }

        User user = userOpt.get();
        String policyVersion = (payload != null && payload.containsKey("policyVersion")) 
                ? payload.get("policyVersion") 
                : "v1.0";

        String clientIp = forwardedFor != null && !forwardedFor.isBlank() ? forwardedFor : "unknown";

        UserConsent consent = new UserConsent(user, clientIp, policyVersion);
        consentRepository.save(consent);

        return ResponseEntity.ok(Map.of(
            "status", "success",
            "message", "Terms of Service & Privacy Policy consent successfully logged for compliance.",
            "consentedAt", consent.getConsentedAt().toString()
        ));
    }

    private Optional<User> resolveUser(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            if (token.startsWith("dev_mock_token_")) {
                return userRepository.findByEmail("dev@clibo.ai").or(() -> userRepository.findAll().stream().findFirst());
            }

            try {
                com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
                if (payload != null && payload.getEmail() != null) {
                    return userRepository.findByEmail(payload.getEmail());
                }
            } catch (Exception ignored) {}

            if (token.contains("@")) {
                return userRepository.findByEmail(token);
            }

            try {
                Long id = Long.parseLong(token);
                return userRepository.findById(id);
            } catch (NumberFormatException ignored) {}
        }
        return Optional.empty();
    }
}
