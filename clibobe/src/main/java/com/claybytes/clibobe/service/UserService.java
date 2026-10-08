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
        return processUserLogin(email, name, null);
    }

    @Transactional
    public User processUserLogin(String email, String name, String pictureUrl) {
        User user = userRepository.findByEmail(email)
                .map(existingUser -> {
                    boolean updated = false;
                    if (pictureUrl != null && !pictureUrl.isBlank() && !pictureUrl.equals(existingUser.getPictureUrl())) {
                        existingUser.setPictureUrl(pictureUrl);
                        updated = true;
                    }
                    if (existingUser.getOrganization() == null && email.contains("@")) {
                        String domain = email.substring(email.indexOf("@") + 1).trim();
                        organizationRepository.findByDomainRestriction(domain)
                                .ifPresent(existingUser::setOrganization);
                        updated = true;
                    }
                    return updated ? userRepository.save(existingUser) : existingUser;
                })
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(email);
                    newUser.setName(name);
                    newUser.setPictureUrl(pictureUrl);
                    newUser.setUserTier("FREE");
                    newUser.setSystemRole("USER");

                    if (email.contains("@")) {
                        String domain = email.substring(email.indexOf("@") + 1).trim();
                        organizationRepository.findByDomainRestriction(domain)
                                .ifPresent(newUser::setOrganization);
                    }

                    return userRepository.save(newUser);
                });

        if (user.getOrganization() != null) {
            user.getOrganization().getName();
        }

        return user;
    }
}
