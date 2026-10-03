package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.ModalityType;
import com.claybytes.clibobe.entity.Organization;
import com.claybytes.clibobe.entity.OrganizationUsage;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserUsage;
import com.claybytes.clibobe.repository.OrganizationUsageRepository;
import com.claybytes.clibobe.repository.UserRepository;
import com.claybytes.clibobe.repository.UserUsageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class UsageGuardrailService {

    private final UserUsageRepository usageRepository;
    private final OrganizationUsageRepository orgUsageRepository;
    private final UserRepository userRepository;

    public UsageGuardrailService(UserUsageRepository usageRepository,
                                 OrganizationUsageRepository orgUsageRepository,
                                 UserRepository userRepository) {
        this.usageRepository = usageRepository;
        this.orgUsageRepository = orgUsageRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public UserUsage getOrCreateUsage(User user) {
        return usageRepository.findByUser(user)
                .orElseGet(() -> {
                    UserUsage usage = new UserUsage(user);
                    return usageRepository.save(usage);
                });
    }

    @Transactional
    public OrganizationUsage getOrCreateOrgUsage(Organization org) {
        return orgUsageRepository.findByOrganization(org)
                .orElseGet(() -> {
                    OrganizationUsage orgUsage = new OrganizationUsage(org);
                    return orgUsageRepository.save(orgUsage);
                });
    }

    @Transactional
    public boolean isUserAllowedToRequest(User user, ModalityType modality) {
        if ("PRO".equalsIgnoreCase(user.getUserTier()) ||
            "PREMIUM".equalsIgnoreCase(user.getUserTier()) ||
            "ADMIN".equalsIgnoreCase(user.getSystemRole()) ||
            "ORG_ADMIN".equalsIgnoreCase(user.getSystemRole())) {
            return true;
        }

        if (user.getOrganization() != null) {
            OrganizationUsage orgUsage = getOrCreateOrgUsage(user.getOrganization());
            return orgUsage.canUse(modality);
        }

        UserUsage usage = getOrCreateUsage(user);
        return usage.canUse(modality);
    }

    @Transactional
    public void incrementUserUsage(User user, ModalityType modality) {
        if (user.getOrganization() != null) {
            OrganizationUsage orgUsage = getOrCreateOrgUsage(user.getOrganization());
            orgUsage.increment(modality);
            orgUsageRepository.save(orgUsage);
        } else {
            UserUsage usage = getOrCreateUsage(user);
            usage.increment(modality);
            usageRepository.save(usage);
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getUsageStats(User user) {
        if (user.getOrganization() != null) {
            OrganizationUsage orgUsage = getOrCreateOrgUsage(user.getOrganization());
            Map<String, Object> stats = new HashMap<>();
            stats.put("userTier", user.getUserTier() + " (Org: " + user.getOrganization().getName() + ")");
            stats.put("textMessagesUsed", orgUsage.getTextMessagesUsed());
            stats.put("textMessagesLimit", orgUsage.getTextMessagesLimit());
            stats.put("textMessagesRemaining", Math.max(0, orgUsage.getTextMessagesLimit() - orgUsage.getTextMessagesUsed()));

            stats.put("screenshotsUsed", orgUsage.getScreenshotsUsed());
            stats.put("screenshotsLimit", orgUsage.getScreenshotsLimit());
            stats.put("screenshotsRemaining", Math.max(0, orgUsage.getScreenshotsLimit() - orgUsage.getScreenshotsUsed()));

            stats.put("voiceNotesUsed", orgUsage.getVoiceNotesUsed());
            stats.put("voiceNotesLimit", orgUsage.getVoiceNotesLimit());
            stats.put("voiceNotesRemaining", Math.max(0, orgUsage.getVoiceNotesLimit() - orgUsage.getVoiceNotesUsed()));

            stats.put("lastResetAt", orgUsage.getLastResetAt());
            return stats;
        }

        UserUsage usage = getOrCreateUsage(user);
        usage.resetDailyCountersIfExpired();

        Map<String, Object> stats = new HashMap<>();
        stats.put("userTier", user.getUserTier());
        stats.put("textMessagesUsed", usage.getTextMessagesUsed());
        stats.put("textMessagesLimit", usage.getTextMessagesLimit());
        stats.put("textMessagesRemaining", Math.max(0, usage.getTextMessagesLimit() - usage.getTextMessagesUsed()));

        stats.put("screenshotsUsed", usage.getScreenshotsUsed());
        stats.put("screenshotsLimit", usage.getScreenshotsLimit());
        stats.put("screenshotsRemaining", Math.max(0, usage.getScreenshotsLimit() - usage.getScreenshotsUsed()));

        stats.put("voiceNotesUsed", usage.getVoiceNotesUsed());
        stats.put("voiceNotesLimit", usage.getVoiceNotesLimit());
        stats.put("voiceNotesRemaining", Math.max(0, usage.getVoiceNotesLimit() - usage.getVoiceNotesUsed()));

        stats.put("lastResetAt", usage.getLastResetAt());
        return stats;
    }

    @Transactional
    public boolean isUserAllowedToRequest(String emailOrId) {
        return resolveUser(emailOrId)
                .map(user -> isUserAllowedToRequest(user, ModalityType.TEXT_MESSAGE))
                .orElse(false);
    }

    @Transactional
    public void incrementUserUsage(String emailOrId) {
        resolveUser(emailOrId)
                .ifPresent(user -> incrementUserUsage(user, ModalityType.TEXT_MESSAGE));
    }

    private java.util.Optional<User> resolveUser(String emailOrId) {
        if (emailOrId == null || emailOrId.isBlank()) return java.util.Optional.empty();
        try {
            Long id = Long.parseLong(emailOrId);
            return userRepository.findById(id);
        } catch (NumberFormatException e) {
            return userRepository.findByEmail(emailOrId);
        }
    }
}
