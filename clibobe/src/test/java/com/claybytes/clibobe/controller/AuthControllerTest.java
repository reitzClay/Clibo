package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.UserService;
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

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private UserService userService;

    @Mock
    private GoogleAuthService googleAuthService;

    @InjectMocks
    private AuthController authController;

    private GoogleIdToken.Payload samplePayload;

    @BeforeEach
    void setUp() {
        samplePayload = new GoogleIdToken.Payload();
        samplePayload.setEmail("test@example.com");
        samplePayload.set("name", "Test User");
    }

    @Test
    void verifyGoogleToken_Success() {
        when(googleAuthService.verifyToken("valid-token")).thenReturn(samplePayload);

        User mockUser = new User();
        mockUser.setEmail("test@example.com");
        mockUser.setName("Test User");
        when(userService.processUserLogin("test@example.com", "Test User")).thenReturn(mockUser);

        ResponseEntity<?> response = authController.verifyGoogleToken(Map.of("token", "valid-token"));

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(mockUser, response.getBody());
        verify(userService).processUserLogin("test@example.com", "Test User");
    }

    @Test
    void verifyGoogleToken_MissingToken() {
        ResponseEntity<?> response = authController.verifyGoogleToken(Map.of());

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    void verifyGoogleToken_BlankToken() {
        ResponseEntity<?> response = authController.verifyGoogleToken(Map.of("token", "   "));

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    void verifyGoogleToken_InvalidToken() {
        when(googleAuthService.verifyToken(anyString())).thenReturn(null);

        ResponseEntity<?> response = authController.verifyGoogleToken(Map.of("token", "invalid-token"));

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }
}
