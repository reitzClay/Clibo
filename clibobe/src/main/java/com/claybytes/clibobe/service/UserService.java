package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public User processUserLogin(String email, String name) {
        // Look for the user by email. If they don't exist, build and persist a new record.
        return userRepository.findByEmail(email)
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(email);
                    newUser.setName(name);
                    newUser.setUserTier("FREE"); // Default out-of-the-box tier
                    newUser.setSystemRole("USER");
                    return userRepository.save(newUser);
                });
    }
}
