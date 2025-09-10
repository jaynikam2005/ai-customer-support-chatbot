// backend-java/src/main/java/com/example/chatbot/repository/ConversationRepository.java
package com.example.chatbot.repository;

import com.example.chatbot.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    
    @Query("SELECT c FROM Conversation c WHERE c.user.id = :userId ORDER BY c.timestamp DESC")
    List<Conversation> findByUserIdOrderByTimestampDesc(@Param("userId") Long userId);
    
    @Query("SELECT c FROM Conversation c WHERE c.user.id = :userId ORDER BY c.timestamp DESC LIMIT 10")
    List<Conversation> findTop10ByUserIdOrderByTimestampDesc(@Param("userId") Long userId);
}
