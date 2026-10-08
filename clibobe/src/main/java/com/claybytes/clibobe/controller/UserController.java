package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.ChatSession;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserConsent;
import com.claybytes.clibobe.entity.UserUsage;
import com.claybytes.clibobe.repository.ChatSessionRepository;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.repository.UserConsentRepository;
import com.claybytes.clibobe.repository.UserUsageRepository;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/user")
@CrossOrigin(origins = "*")
public class UserController {

    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    private final UserRepository userRepository;
    private final UserConsentRepository userConsentRepository;
    private final UserUsageRepository userUsageRepository;
    private final ChatSessionRepository chatSessionRepository;
    private final GoogleAuthService googleAuthService;

    public UserController(
            UserRepository userRepository,
            UserConsentRepository userConsentRepository,
            UserUsageRepository userUsageRepository,
            ChatSessionRepository chatSessionRepository,
            GoogleAuthService googleAuthService) {
        this.userRepository = userRepository;
        this.userConsentRepository = userConsentRepository;
        this.userUsageRepository = userUsageRepository;
        this.chatSessionRepository = chatSessionRepository;
        this.googleAuthService = googleAuthService;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || authHeader.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Missing authorization header"));
        }

        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7).trim() : authHeader.trim();

        // 1. Verify via Google OAuth
        try {
            GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
            if (payload != null && payload.getEmail() != null) {
                Optional<User> userOpt = userRepository.findByEmail(payload.getEmail());
                if (userOpt.isPresent()) {
                    return ResponseEntity.ok(userOpt.get());
                }
            }
        } catch (Exception ignored) {
        }

        // 2. Fallback check by email or ID (for testing)
        if (token.contains("@")) {
            Optional<User> userOpt = userRepository.findByEmail(token);
            if (userOpt.isPresent()) {
                return ResponseEntity.ok(userOpt.get());
            }
        }

        try {
            Long id = Long.parseLong(token);
            Optional<User> userOpt = userRepository.findById(id);
            if (userOpt.isPresent()) {
                return ResponseEntity.ok(userOpt.get());
            }
        } catch (NumberFormatException ignored) {
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Invalid or expired token"));
    }

    @DeleteMapping("/account")
    @Transactional
    public ResponseEntity<?> deleteUserAccount(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || authHeader.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Missing authorization header"));
        }

        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7).trim() : authHeader.trim();
        Optional<User> userOpt = Optional.empty();

        // 1. Verify via Google OAuth
        try {
            GoogleIdToken.Payload payload = googleAuthService.verifyToken(token);
            if (payload != null && payload.getEmail() != null) {
                userOpt = userRepository.findByEmail(payload.getEmail());
            }
        } catch (Exception ignored) {
        }

        // 2. Fallback check by email or ID
        if (userOpt.isEmpty() && token.contains("@")) {
            userOpt = userRepository.findByEmail(token);
        }

        if (userOpt.isEmpty()) {
            try {
                Long id = Long.parseLong(token);
                userOpt = userRepository.findById(id);
            } catch (NumberFormatException ignored) {
            }
        }

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid or expired token"));
        }

        User user = userOpt.get();

        // Delete all associated user records in order
        List<UserConsent> consents = userConsentRepository.findByUser(user);
        if (!consents.isEmpty()) {
            userConsentRepository.deleteAll(consents);
        }

        Optional<UserUsage> usageOpt = userUsageRepository.findByUser(user);
        usageOpt.ifPresent(userUsageRepository::delete);

        List<ChatSession> sessions = chatSessionRepository.findByUser(user);
        if (!sessions.isEmpty()) {
            chatSessionRepository.deleteAll(sessions);
        }

        userRepository.delete(user);

        logger.info("Successfully deleted user account and all associated data for: {}", user.getEmail());
        return ResponseEntity.ok(Map.of("message", "User account and all associated data have been permanently deleted."));
    }
}
