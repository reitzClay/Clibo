package com.claybytes.clibobe.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_usages")
public class UserUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true, nullable = false)
    private User user;

    @Column(nullable = false)
    private int textMessagesUsed = 0;

    @Column(nullable = false)
    private int textMessagesLimit = 30;

    @Column(nullable = false)
    private int screenshotsUsed = 0;

    @Column(nullable = false)
    private int screenshotsLimit = 20;

    @Column(nullable = false)
    private int voiceNotesUsed = 0;

    @Column(nullable = false)
    private int voiceNotesLimit = 50;

    @Column(nullable = false)
    private LocalDateTime lastResetAt = LocalDateTime.now();

    public UserUsage() {
    }

    public UserUsage(User user) {
        this.user = user;
    }

    public void resetDailyCountersIfExpired() {
        LocalDate lastResetDate = lastResetAt.toLocalDate();
        LocalDate today = LocalDate.now();
        if (lastResetDate.isBefore(today)) {
            this.textMessagesUsed = 0;
            this.screenshotsUsed = 0;
            this.voiceNotesUsed = 0;
            this.lastResetAt = LocalDateTime.now();
        }
    }

    public boolean canUse(ModalityType modality) {
        resetDailyCountersIfExpired();
        return switch (modality) {
            case TEXT_MESSAGE -> textMessagesUsed < textMessagesLimit;
            case SCREENSHOT -> screenshotsUsed < screenshotsLimit;
            case VOICE_NOTE -> voiceNotesUsed < voiceNotesLimit;
        };
    }

    public void increment(ModalityType modality) {
        resetDailyCountersIfExpired();
        switch (modality) {
            case TEXT_MESSAGE -> textMessagesUsed++;
            case SCREENSHOT -> screenshotsUsed++;
            case VOICE_NOTE -> voiceNotesUsed++;
        }
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public int getTextMessagesUsed() {
        return textMessagesUsed;
    }

    public void setTextMessagesUsed(int textMessagesUsed) {
        this.textMessagesUsed = textMessagesUsed;
    }

    public int getTextMessagesLimit() {
        return textMessagesLimit;
    }

    public void setTextMessagesLimit(int textMessagesLimit) {
        this.textMessagesLimit = textMessagesLimit;
    }

    public int getScreenshotsUsed() {
        return screenshotsUsed;
    }

    public void setScreenshotsUsed(int screenshotsUsed) {
        this.screenshotsUsed = screenshotsUsed;
    }

    public int getScreenshotsLimit() {
        return screenshotsLimit;
    }

    public void setScreenshotsLimit(int screenshotsLimit) {
        this.screenshotsLimit = screenshotsLimit;
    }

    public int getVoiceNotesUsed() {
        return voiceNotesUsed;
    }

    public void setVoiceNotesUsed(int voiceNotesUsed) {
        this.voiceNotesUsed = voiceNotesUsed;
    }

    public int getVoiceNotesLimit() {
        return voiceNotesLimit;
    }

    public void setVoiceNotesLimit(int voiceNotesLimit) {
        this.voiceNotesLimit = voiceNotesLimit;
    }

    public LocalDateTime getLastResetAt() {
        return lastResetAt;
    }

    public void setLastResetAt(LocalDateTime lastResetAt) {
        this.lastResetAt = lastResetAt;
    }
}
