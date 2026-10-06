package com.claybytes.clibobe.repository;

import com.claybytes.clibobe.entity.Organization;
import com.claybytes.clibobe.entity.OrganizationUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrganizationUsageRepository extends JpaRepository<OrganizationUsage, Long> {
    Optional<OrganizationUsage> findByOrganization(Organization organization);
    Optional<OrganizationUsage> findByOrganizationId(Long organizationId);
}
