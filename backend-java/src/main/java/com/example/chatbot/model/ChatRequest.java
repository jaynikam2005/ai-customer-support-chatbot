// backend-java/src/main/java/com/example/chatbot/model/ChatRequest.java
package com.example.chatbot.model;

import jakarta.validation.constraints.NotBlank;

public record ChatRequest(
    @NotBlank(message = "Message is required") 
    String message
) {}
