package com.claybytes.clibobe.service;

import com.claybytes.clibobe.entity.ChatMessage;
import com.claybytes.clibobe.entity.ChatSession;
import com.claybytes.clibobe.entity.User;
import com.claybytes.clibobe.repository.ChatMessageRepository;
import com.claybytes.clibobe.repository.ChatSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
        logChatInteraction(user, prompt, response, "Google Gemini");
    }

    @Transactional
    public void logChatInteraction(User user, String prompt, String response, String provider) {
        if (user == null) return;
        
        List<ChatSession> sessions = sessionRepository.findByUser(user);
        ChatSession session;
        String cleanProvider = (provider != null && !provider.isBlank()) ? provider : "Google Gemini";

        if (sessions.isEmpty()) {
            String title = prompt.length() > 30 ? prompt.substring(0, 30) + "..." : prompt;
            session = new ChatSession(user, title, cleanProvider);
            session = sessionRepository.save(session);
        } else {
            session = sessions.get(sessions.size() - 1);
            if (provider != null && !provider.isBlank()) {
                session.setProvider(cleanProvider);
                sessionRepository.save(session);
            }
        }

        ChatMessage userMsg = new ChatMessage(session, "user", prompt);
        messageRepository.save(userMsg);

        ChatMessage modelMsg = new ChatMessage(session, "model", response);
        messageRepository.save(modelMsg);
    }
}
