package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.UserService;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*") // Allows your Flutter app/emulators to connect without CORS blocking
public class AuthController {

    private final UserService userService;
    private final GoogleAuthService googleAuthService;

    @Autowired
    public AuthController(UserService userService, GoogleAuthService googleAuthService) {
        this.userService = userService;
        this.googleAuthService = googleAuthService;
    }

    @PostMapping("/google")
    public ResponseEntity<?> verifyGoogleToken(@RequestBody Map<String, String> payload) {
        String idTokenString = payload.get("token");

        if (idTokenString == null || idTokenString.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing token payload"));
        }

        try {
            Payload tokenPayload = googleAuthService.verifyToken(idTokenString);

            if (tokenPayload != null) {
                String email = tokenPayload.getEmail();
                String name = (String) tokenPayload.get("name");
                String pictureUrl = (String) tokenPayload.get("picture");

                // Route through our database service layer
                User user = userService.processUserLogin(email, name, pictureUrl);

                // Return authenticated profile data back to Flutter
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Invalid security token signature"));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Token verification engine failure: " + e.getMessage()));
        }
    }

    @PostMapping("/email")
    public ResponseEntity<?> loginWithEmail(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");

        if (email == null || email.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
        }

        try {
            String cleanEmail = email.trim();
            String name = cleanEmail.contains("@") ? cleanEmail.substring(0, cleanEmail.indexOf("@")) : "Company User";
            User user = userService.processUserLogin(cleanEmail, name);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Company login failed: " + e.getMessage()));
        }
    }
}