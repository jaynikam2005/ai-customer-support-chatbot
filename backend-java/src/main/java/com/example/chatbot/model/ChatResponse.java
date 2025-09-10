// backend-java/src/main/java/com/example/chatbot/model/ChatResponse.java
package com.example.chatbot.model;

import java.time.LocalDateTime;

public record ChatResponse(
    String reply,
    String intent,
    Double confidence,
    LocalDateTime timestamp
) {}
