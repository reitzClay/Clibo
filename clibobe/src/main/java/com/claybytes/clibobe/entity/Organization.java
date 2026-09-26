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

    // e.g., "company.com" to auto-route corporate Google logins
    @Column(name = "domain_restriction")
    private String domainRestriction;

    // e.g., "ENTERPRISE", "TEAM_BASIC"
    @Column(nullable = false)
    private String planTier;

    // Getters, Setters, Constructors
}
