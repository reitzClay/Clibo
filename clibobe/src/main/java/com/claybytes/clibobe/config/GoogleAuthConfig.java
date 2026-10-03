package com.claybytes.clibobe.config;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Collections;

@Configuration
public class GoogleAuthConfig {

    private static final Logger logger = LoggerFactory.getLogger(GoogleAuthConfig.class);

    @Value("${spring.security.oauth2.client.registration.google.client-id:${GOOGLE_CLIENT_ID:277710406862-k1h0jcnngg5k64q5semb3pqvs295qe9v.apps.googleusercontent.com}}")
    private String clientId;

    @Bean
    public GoogleIdTokenVerifier googleIdTokenVerifier() {
        logger.info("Initializing GoogleIdTokenVerifier with client ID audience: {}", clientId);
        return new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                .setAudience(Collections.singletonList(clientId))
                .build();
    }
}
