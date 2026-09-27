package com.claybytes.clibobe.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class GeminiConfig {

    // Inject your secret Gemini Key from application.properties or system environment variables
    @Value("${gemini.api.key:}")
    private String geminiApiKey;

    @Bean
    public WebClient geminiWebClient(WebClient.Builder builder) {
        return builder
                .baseUrl("https://googleapis.com")
                .defaultHeader("x-goog-api-key", geminiApiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }
}