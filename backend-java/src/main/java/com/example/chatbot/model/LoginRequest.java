// backend-java/src/main/java/com/example/chatbot/model/LoginRequest.java
package com.example.chatbot.model;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "Username is required")
    String username,
    
    @NotBlank(message = "Password is required")
    String password
) {}
