package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/user")
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;
    private final GoogleAuthService googleAuthService;

    public UserController(UserRepository userRepository, GoogleAuthService googleAuthService) {
        this.userRepository = userRepository;
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
}
