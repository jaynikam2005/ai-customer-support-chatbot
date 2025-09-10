// backend-java/src/main/java/com/example/chatbot/model/AIServiceResponse.java
package com.example.chatbot.model;

public record AIServiceResponse(
    String intent,
    String reply,
    Double confidence
) {}
