package com.claybytes.clibobe.controller;

import com.claybytes.clibobe.entity.Organization;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.OrganizationRepository;
import com.claybytes.clibobe.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/organizations")
@CrossOrigin(origins = "*")
public class OrganizationController {

    private static final Logger logger = LoggerFactory.getLogger(OrganizationController.class);

    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;

    @Autowired
    public OrganizationController(OrganizationRepository organizationRepository, UserRepository userRepository) {
        this.organizationRepository = organizationRepository;
        this.userRepository = userRepository;
    }

    @PostMapping("/register")
    @Transactional
    public ResponseEntity<?> registerOrganization(@RequestBody Map<String, String> payload) {
        String name = payload.get("name");
        String domain = payload.get("domain");
        String planTier = payload.getOrDefault("planTier", "TEAM_BASIC");
        String adminEmail = payload.get("adminEmail");
        String adminName = payload.get("adminName");

        if (name == null || name.trim().isEmpty() || adminEmail == null || adminEmail.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Organization name and admin email are required"));
        }

        try {
            // 1. Create Organization
            Organization org = new Organization(name.trim(), domain != null ? domain.trim() : null, planTier);
            org = organizationRepository.save(org);

            // 2. Find or create admin user and assign to organization
            User adminUser = userRepository.findByEmail(adminEmail.trim())
                    .orElseGet(() -> {
                        User newUser = new User();
                        newUser.setEmail(adminEmail.trim());
                        newUser.setName(adminName != null ? adminName.trim() : "Org Admin");
                        newUser.setUserTier("PRO");
                        return newUser;
                    });

            adminUser.setOrganization(org);
            adminUser.setSystemRole("ORG_ADMIN");
            adminUser = userRepository.save(adminUser);

            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                    "organization", org,
                    "admin", adminUser,
                    "message", "Organization registered successfully"
            ));
        } catch (Exception e) {
            logger.error("Failed to register organization: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to register organization: " + e.getMessage()));
        }
    }
}
