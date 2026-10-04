package com.claybytes.clibobe.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "organization_usages")
public class OrganizationUsage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false)
    private int textMessagesUsed = 0;

    @Column(nullable = false)
    private int textMessagesLimit = 500;

    @Column(nullable = false)
    private int screenshotsUsed = 0;

    @Column(nullable = false)
    private int screenshotsLimit = 100;

    @Column(nullable = false)
    private int voiceNotesUsed = 0;

    @Column(nullable = false)
    private int voiceNotesLimit = 200;

    @Column(nullable = false)
    private LocalDateTime lastResetAt = LocalDateTime.now();

    public OrganizationUsage() {}

    public OrganizationUsage(Organization organization) {
        this.organization = organization;
        String planTier = "TEAM_BASIC";
        try {
            if (organization != null) {
                planTier = organization.getPlanTier();
            }
        } catch (Exception ignored) {}
        if ("ENTERPRISE".equalsIgnoreCase(planTier)) {
            this.textMessagesLimit = 5000;
            this.screenshotsLimit = 1000;
            this.voiceNotesLimit = 2000;
        } else {
            this.textMessagesLimit = 500;
            this.screenshotsLimit = 100;
            this.voiceNotesLimit = 200;
        }
    }

    public boolean canUse(ModalityType modality) {
        switch (modality) {
            case TEXT_MESSAGE:
                return textMessagesUsed < textMessagesLimit;
            case SCREENSHOT:
                return screenshotsUsed < screenshotsLimit;
            case VOICE_NOTE:
                return voiceNotesUsed < voiceNotesLimit;
            default:
                return true;
        }
    }

    public void increment(ModalityType modality) {
        switch (modality) {
            case TEXT_MESSAGE:
                textMessagesUsed++;
                break;
            case SCREENSHOT:
                screenshotsUsed++;
                break;
            case VOICE_NOTE:
                voiceNotesUsed++;
                break;
        }
    }

    public Long getId() { return id; }
    public Organization getOrganization() { return organization; }
    public void setOrganization(Organization organization) { this.organization = organization; }
    public int getTextMessagesUsed() { return textMessagesUsed; }
    public int getTextMessagesLimit() { return textMessagesLimit; }
    public int getScreenshotsUsed() { return screenshotsUsed; }
    public int getScreenshotsLimit() { return screenshotsLimit; }
    public int getVoiceNotesUsed() { return voiceNotesUsed; }
    public int getVoiceNotesLimit() { return voiceNotesLimit; }
    public LocalDateTime getLastResetAt() { return lastResetAt; }
}
