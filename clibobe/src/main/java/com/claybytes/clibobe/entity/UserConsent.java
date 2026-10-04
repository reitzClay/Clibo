package com.claybytes.clibobe.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_consents")
public class UserConsent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "policy_version", nullable = false)
    private String policyVersion = "v1.0";

    @Column(name = "consented_at", nullable = false)
    private LocalDateTime consentedAt = LocalDateTime.now();

    public UserConsent() {}

    public UserConsent(User user, String ipAddress, String policyVersion) {
        this.user = user;
        this.ipAddress = ipAddress;
        if (policyVersion != null && !policyVersion.isBlank()) {
            this.policyVersion = policyVersion;
        }
    }

    public Long getId() { return id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
    public String getPolicyVersion() { return policyVersion; }
    public void setPolicyVersion(String policyVersion) { this.policyVersion = policyVersion; }
    public LocalDateTime getConsentedAt() { return consentedAt; }
}
