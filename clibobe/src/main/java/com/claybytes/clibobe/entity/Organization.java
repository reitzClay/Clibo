package com.claybytes.clibobe.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "organizations")
public class Organization {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(name = "domain_restriction")
    private String domainRestriction;

    @Column(nullable = false)
    private String planTier = "TEAM_BASIC";

    public Organization() {
    }

    public Organization(String name, String domainRestriction, String planTier) {
        this.name = name;
        this.domainRestriction = domainRestriction;
        this.planTier = planTier;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDomainRestriction() {
        return domainRestriction;
    }

    public void setDomainRestriction(String domainRestriction) {
        this.domainRestriction = domainRestriction;
    }

    public String getPlanTier() {
        return planTier;
    }

    public void setPlanTier(String planTier) {
        this.planTier = planTier;
    }
}
