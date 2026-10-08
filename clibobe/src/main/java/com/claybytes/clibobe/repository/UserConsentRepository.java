package com.claybytes.clibobe.repository;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.entity.UserConsent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserConsentRepository extends JpaRepository<UserConsent, Long> {
    List<UserConsent> findByUser(User user);
}
