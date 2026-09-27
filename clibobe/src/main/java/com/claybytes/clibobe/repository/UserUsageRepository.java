package com.claybytes.clibobe.repository;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserUsageRepository extends JpaRepository<UserUsage, Long> {
    Optional<UserUsage> findByUser(User user);
    Optional<UserUsage> findByUserId(Long userId);
}
