// backend-java/src/main/java/com/example/chatbot/controller/ChatController.java
package com.example.chatbot.controller;

import com.example.chatbot.model.*;
import com.example.chatbot.service.ChatService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class ChatController {

    private static final Logger log = LoggerFactory.getLogger(ChatController.class);

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(
            @Valid @RequestBody ChatRequest request,
            Authentication authentication) {
        
        String username = authentication != null ? authentication.getName() : "<anonymous>";
        log.debug("/api/chat invoked by '{}' message='{}'", username, request.message());
        
        try {
            ChatResponse response = chatService.processMessage(username, request.message()).block();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error processing chat message for user '{}': {}", username, e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/history/{username}")
    public ResponseEntity<List<ConversationHistoryDto>> getHistory(
            @PathVariable String username,
            Authentication authentication) {
        
    String authenticatedUsername = authentication != null ? authentication.getName() : "<anonymous>";
    log.debug("/api/history invoked pathUser='{}' authUser='{}'", username, authenticatedUsername);
        
        // Ensure user can only access their own history
        if (!authenticatedUsername.equals(username)) {
            return ResponseEntity.status(403).build(); // Global handler could be used if throwing custom
        }
        
        try {
            List<ConversationHistoryDto> history = chatService.getChatHistory(username);
            return ResponseEntity.ok(history);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
