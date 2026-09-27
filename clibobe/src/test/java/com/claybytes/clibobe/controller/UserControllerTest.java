package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.utilityService.GoogleAuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private GoogleAuthService googleAuthService;

    @InjectMocks
    private UserController userController;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setEmail("clayton@clibo.ai");
        sampleUser.setName("Clayton");
        sampleUser.setUserTier("FREE");
    }

    @Test
    void getCurrentUser_MissingHeader() {
        ResponseEntity<?> response = userController.getCurrentUser(null);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void getCurrentUser_SuccessWithEmailToken() {
        when(userRepository.findByEmail("clayton@clibo.ai")).thenReturn(Optional.of(sampleUser));

        ResponseEntity<?> response = userController.getCurrentUser("clayton@clibo.ai");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(sampleUser, response.getBody());
    }
}
