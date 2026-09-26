package com.claybytes.clibobe.utilityService;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;

@Service
public class GoogleAuthService {

    private static final Logger logger = LoggerFactory.getLogger(GoogleAuthService.class);

    private final GoogleIdTokenVerifier verifier;

    public GoogleAuthService(GoogleIdTokenVerifier verifier) {
        this.verifier = verifier;
    }

    public Payload verifyToken(String idTokenString) {
        try {
            // verifier.verify() handles expiration checks and cryptographic signature checks automatically
            GoogleIdToken idToken = verifier.verify(idTokenString);

            if (idToken != null) {
                // Token is valid! Return the user payload data
                return idToken.getPayload();
            } else {
                logger.warn("Invalid ID token received during Google authentication.");
                return null;
            }
        } catch (GeneralSecurityException | IOException e) {
            logger.error("Google token verification failed: {}", e.getMessage(), e);
            return null;
        }
    }
}
