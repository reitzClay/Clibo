package com.claybytes.clibobe.service.ai;

import com.claybytes.clibobe.dto.AiPromptRequest;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.service.ChatHistoryService;
import com.claybytes.clibobe.service.UsageGuardrailService;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class CustomAiService implements AiProviderService {

    private final OpenAiCompatibleAiService openAiService;

    public CustomAiService(UsageGuardrailService guardrailService, ChatHistoryService chatHistoryService) {
        this.openAiService = new OpenAiCompatibleAiService(guardrailService, chatHistoryService);
    }

    @Override
    public String getProviderId() {
        return "custom";
    }

    @Override
    public Flux<String> generateStream(User user, AiPromptRequest request, String prompt) {
        return openAiService.generateStream(user, request, prompt);
    }
}
