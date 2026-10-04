package com.claybytes.clibobe.repository;

import com.claybytes.clibobe.entity.ChatSession;
import com.claybytes.clibobe.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatSessionRepository extends JpaRepository<ChatSession, Long> {
    List<ChatSession> findByUser(User user);
}
