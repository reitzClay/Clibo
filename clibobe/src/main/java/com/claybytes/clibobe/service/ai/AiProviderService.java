package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.User;
import reactor.core.publisher.Flux;

public interface AiProviderService {
    String getProviderId();
    Flux<String> generateStream(User user, AiPromptRequest request, String prompt);
}
