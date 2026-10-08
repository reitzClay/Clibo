package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.ChatMessage;
import com.claybytes.clibobe.entity.ChatSession;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.ChatMessageRepository;
import com.claybytes.clibobe.repository.ChatSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class ChatHistoryService {

    private final ChatSessionRepository sessionRepository;
    private final ChatMessageRepository messageRepository;

    public ChatHistoryService(ChatSessionRepository sessionRepository, ChatMessageRepository messageRepository) {
        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
    }

    @Transactional
    public void logChatInteraction(User user, String prompt, String response) {
        logChatInteraction(user, prompt, response, "Google Gemini", null);
    }

    @Transactional
    public void logChatInteraction(User user, String prompt, String response, String provider) {
        logChatInteraction(user, prompt, response, provider, null);
    }

    @Transactional
    public void logChatInteraction(User user, String prompt, String response, String provider, String sessionIdStr) {
        if (user == null) return;
        
        ChatSession session = null;
        String cleanProvider = (provider != null && !provider.isBlank()) ? provider : "Google Gemini";

        if (sessionIdStr != null && !sessionIdStr.isBlank()) {
            try {
                Long sessionId = Long.parseLong(sessionIdStr.trim());
                Optional<ChatSession> sessionOpt = sessionRepository.findById(sessionId);
                if (sessionOpt.isPresent() && sessionOpt.get().getUser().getId().equals(user.getId())) {
                    session = sessionOpt.get();
                }
            } catch (NumberFormatException ignored) {}
        }

        if (session == null) {
            String title = prompt.length() > 30 ? prompt.substring(0, 30) + "..." : prompt;
            session = new ChatSession(user, title, cleanProvider);
            session = sessionRepository.save(session);
        }

        ChatMessage userMsg = new ChatMessage(session, "user", prompt);
        messageRepository.save(userMsg);

        ChatMessage modelMsg = new ChatMessage(session, "model", response);
        messageRepository.save(modelMsg);
    }
}
