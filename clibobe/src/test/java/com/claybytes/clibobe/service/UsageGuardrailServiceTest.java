package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserUsage;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.repository.UserUsageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UsageGuardrailServiceTest {

    @Mock
    private UserUsageRepository usageRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UsageGuardrailService guardrailService;

    private User freeUser;
    private User proUser;
    private UserUsage userUsage;

    @BeforeEach
    void setUp() {
        freeUser = new User();
        freeUser.setEmail("free@example.com");
        freeUser.setName("Free User");
        freeUser.setUserTier("FREE");

        proUser = new User();
        proUser.setEmail("pro@example.com");
        proUser.setName("Pro User");
        proUser.setUserTier("PRO");

        userUsage = new UserUsage(freeUser);
        userUsage.setTextMessagesLimit(30);
        userUsage.setScreenshotsLimit(20);
        userUsage.setVoiceNotesLimit(50);
        userUsage.setLastResetAt(LocalDateTime.now());
    }

    @Test
    void isUserAllowedToRequest_ProUserAlwaysAllowed() {
        boolean allowed = guardrailService.isUserAllowedToRequest(proUser, ModalityType.TEXT_MESSAGE);
        assertTrue(allowed);
        verifyNoInteractions(usageRepository);
    }

    @Test
    void isUserAllowedToRequest_FreeUserWithinLimit() {
        when(usageRepository.findByUser(freeUser)).thenReturn(Optional.of(userUsage));

        boolean allowed = guardrailService.isUserAllowedToRequest(freeUser, ModalityType.TEXT_MESSAGE);
        assertTrue(allowed);
    }

    @Test
    void isUserAllowedToRequest_FreeUserExceededLimit() {
        userUsage.setTextMessagesUsed(30);
        when(usageRepository.findByUser(freeUser)).thenReturn(Optional.of(userUsage));

        boolean allowed = guardrailService.isUserAllowedToRequest(freeUser, ModalityType.TEXT_MESSAGE);
        assertFalse(allowed);
    }

    @Test
    void incrementUserUsage_IncrementsCorrectCounter() {
        when(usageRepository.findByUser(freeUser)).thenReturn(Optional.of(userUsage));
        when(usageRepository.save(any(UserUsage.class))).thenAnswer(i -> i.getArgument(0));

        guardrailService.incrementUserUsage(freeUser, ModalityType.SCREENSHOT);

        assertEquals(1, userUsage.getScreenshotsUsed());
        verify(usageRepository).save(userUsage);
    }

    @Test
    void getUsageStats_ReturnsAccurateRemainingQuotas() {
        userUsage.setTextMessagesUsed(5);
        userUsage.setScreenshotsUsed(2);
        userUsage.setVoiceNotesUsed(10);
        when(usageRepository.findByUser(freeUser)).thenReturn(Optional.of(userUsage));

        Map<String, Object> stats = guardrailService.getUsageStats(freeUser);

        assertEquals("FREE", stats.get("userTier"));
        assertEquals(5, stats.get("textMessagesUsed"));
        assertEquals(25, stats.get("textMessagesRemaining"));
        assertEquals(2, stats.get("screenshotsUsed"));
        assertEquals(18, stats.get("screenshotsRemaining"));
        assertEquals(10, stats.get("voiceNotesUsed"));
        assertEquals(40, stats.get("voiceNotesRemaining"));
    }
}
