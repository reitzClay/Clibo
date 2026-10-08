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
import java.util.Optional;

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
        if (org == null) return null;
        try {
            org.getPlanTier();
            org.getName();
        } catch (Exception ignored) {}
        
        if (org.getId() != null) {
            Optional<OrganizationUsage> existing = orgUsageRepository.findByOrganizationId(org.getId());
            if (existing.isPresent()) {
                return existing.get();
            }
        }
        
        return orgUsageRepository.findByOrganization(org)
                .orElseGet(() -> {
                    OrganizationUsage orgUsage = new OrganizationUsage(org);
                    return orgUsageRepository.save(orgUsage);
                });
    }

    @Transactional
    public boolean isUserAllowedToRequest(User user, ModalityType modality) {
        User managedUser = getManagedUser(user);
        if (managedUser == null) return false;
        if ("PRO".equalsIgnoreCase(managedUser.getUserTier()) ||
            "PREMIUM".equalsIgnoreCase(managedUser.getUserTier()) ||
            "ADMIN".equalsIgnoreCase(managedUser.getSystemRole()) ||
            "ORG_ADMIN".equalsIgnoreCase(managedUser.getSystemRole())) {
            return true;
        }

        if (managedUser.getOrganization() != null) {
            OrganizationUsage orgUsage = getOrCreateOrgUsage(managedUser.getOrganization());
            return orgUsage.canUse(modality);
        }

        UserUsage usage = getOrCreateUsage(managedUser);
        return usage.canUse(modality);
    }

    @Transactional
    public void incrementUserUsage(User user, ModalityType modality) {
        User managedUser = getManagedUser(user);
        if (managedUser == null) return;
        if (managedUser.getOrganization() != null) {
            OrganizationUsage orgUsage = getOrCreateOrgUsage(managedUser.getOrganization());
            orgUsage.increment(modality);
            orgUsageRepository.save(orgUsage);
        } else {
            UserUsage usage = getOrCreateUsage(managedUser);
            usage.increment(modality);
            usageRepository.save(usage);
        }
    }

    @Transactional
    public Map<String, Object> getUsageStats(User user) {
        User managedUser = getManagedUser(user);
        if (managedUser == null) return new HashMap<>();

        if (managedUser.getOrganization() != null) {
            Organization org = managedUser.getOrganization();
            try {
                org.getPlanTier();
                org.getName();
            } catch (Exception ignored) {}
            OrganizationUsage orgUsage = getOrCreateOrgUsage(org);
            Map<String, Object> stats = new HashMap<>();
            stats.put("userTier", managedUser.getUserTier() + " (Org: " + (org.getName() != null ? org.getName() : "Team") + ")");
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

        UserUsage usage = getOrCreateUsage(managedUser);
        usage.resetDailyCountersIfExpired();

        Map<String, Object> stats = new HashMap<>();
        stats.put("userTier", managedUser.getUserTier());
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

    private User getManagedUser(User user) {
        if (user == null) return null;
        if (user.getId() != null) {
            return userRepository.findById(user.getId()).orElse(user);
        }
        if (user.getEmail() != null) {
            return userRepository.findByEmail(user.getEmail()).orElse(user);
        }
        return user;
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
