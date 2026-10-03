package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.Organization;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.OrganizationRepository;
import com.claybytes.clibobe.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OrganizationRepository organizationRepository;

    @Transactional
    public User processUserLogin(String email, String name) {
        return userRepository.findByEmail(email)
                .map(existingUser -> {
                    if (existingUser.getOrganization() == null && email.contains("@")) {
                        String domain = email.substring(email.indexOf("@") + 1).trim();
                        organizationRepository.findByDomainRestriction(domain)
                                .ifPresent(existingUser::setOrganization);
                        return userRepository.save(existingUser);
                    }
                    return existingUser;
                })
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(email);
                    newUser.setName(name);
                    newUser.setUserTier("FREE");
                    newUser.setSystemRole("USER");

                    if (email.contains("@")) {
                        String domain = email.substring(email.indexOf("@") + 1).trim();
                        organizationRepository.findByDomainRestriction(domain)
                                .ifPresent(newUser::setOrganization);
                    }

                    return userRepository.save(newUser);
                });
    }
}
