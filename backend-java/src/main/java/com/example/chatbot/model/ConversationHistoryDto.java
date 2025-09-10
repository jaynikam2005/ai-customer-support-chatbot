// backend-java/src/main/java/com/example/chatbot/model/ConversationHistoryDto.java
package com.example.chatbot.model;

import java.time.LocalDateTime;

public record ConversationHistoryDto(
    Long id,
    String query,
    String reply,
    String intent,
    LocalDateTime timestamp
) {}
