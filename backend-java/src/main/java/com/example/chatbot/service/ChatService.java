// backend-java/src/main/java/com/example/chatbot/service/ChatService.java
package com.example.chatbot.service;

import com.example.chatbot.model.*;
import com.example.chatbot.exception.UserNotFoundException;
import com.example.chatbot.repository.ConversationRepository;
import com.example.chatbot.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ChatService {
        private static final Logger log = LoggerFactory.getLogger(ChatService.class);

        private final ConversationRepository conversationRepository;
        private final UserRepository userRepository;
        private final WebClient.Builder webClientBuilder;

        @Value("${ai.service.url}")
        private String aiServiceUrl;

        @Value("${ai.service.analyze-endpoint}")
        private String analyzeEndpoint;

        public ChatService(ConversationRepository conversationRepository,
                                           UserRepository userRepository,
                                           WebClient.Builder webClientBuilder) {
                this.conversationRepository = conversationRepository;
                this.userRepository = userRepository;
                this.webClientBuilder = webClientBuilder;
        }

    // Record for conversation message
    public record ConversationMessage(String role, String content) {}

    // Record for AI service request with conversation history
    public record AIServiceRequest(String message, List<ConversationMessage> conversation_history) {
        public AIServiceRequest(String message) {
            this(message, List.of());
        }
    }

    // Record for AI service response
    public record AIServiceResponse(String reply, String intent, double confidence) {}

    public Mono<ChatResponse> processMessage(String username, String message) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException(username));

        log.debug("ChatService.processMessage start user='{}' message='{}'", username, message);

        // Get recent conversation history (last 10 messages)
        List<Conversation> recentHistory = conversationRepository
                .findTop10ByUserIdOrderByTimestampDesc(user.getId());
        
        // Convert to conversation context for AI service
        List<ConversationMessage> conversationHistory = recentHistory.stream()
                .map(conv -> List.of(
                    new ConversationMessage("user", conv.getQuery()),
                    new ConversationMessage("assistant", conv.getReply())
                ))
                .flatMap(List::stream)
                .toList();

        // Call Python AI service with conversation context
        WebClient webClient = webClientBuilder.baseUrl(aiServiceUrl).build();
        
        return webClient.post()
                .uri(analyzeEndpoint)
                .bodyValue(new AIServiceRequest(message, conversationHistory))
                .exchangeToMono(clientResponse -> {
                    int statusCode = clientResponse.statusCode().value();
                    log.debug("AI HTTP status user='{}' status={}", username, statusCode);
                    if (clientResponse.statusCode().is2xxSuccessful()) {
                        return clientResponse.bodyToMono(AIServiceResponse.class);
                    } else {
                        return clientResponse.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .flatMap(body -> Mono.error(new RuntimeException("AI service error status=" + statusCode + " body=" + truncate(body))));
                    }
                })
                .doOnSubscribe(sub -> log.debug("AI call dispatch user='{}' endpoint='{}{}' historySize={}", username, aiServiceUrl, analyzeEndpoint, conversationHistory.size()))
                .doOnNext(aiResp -> log.debug("AI call success user='{}' intent='{}' confidence={} replyPreview='{}'", username, aiResp.intent(), aiResp.confidence(), truncate(aiResp.reply())))
                .doOnError(e -> log.error("AI call error user='{}' error='{}'", username, e.toString()))
                .map(aiResponse -> {
                    // Save conversation to database
                    Conversation conversation = new Conversation(
                            user, message, aiResponse.reply(), aiResponse.intent()
                    );
                    conversationRepository.save(conversation);
                    log.debug("Conversation persisted user='{}' convId='{}' intent='{}'", username, conversation.getId(), conversation.getIntent());
                    // Return response
                    return new ChatResponse(
                            aiResponse.reply(),
                            aiResponse.intent(),
                            aiResponse.confidence(),
                            LocalDateTime.now()
                    );
                })
                .onErrorResume(e -> {
                    log.error("ChatService fallback user='{}' error='{}'", username, e.toString());
                    return Mono.just(new ChatResponse(
                            "I'm sorry, I'm having trouble processing your request right now. Please try again later.",
                            "error",
                            0.0,
                            LocalDateTime.now()
                    ));
                });
    }

    public List<ConversationHistoryDto> getChatHistory(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException(username));

        return conversationRepository.findByUserIdOrderByTimestampDesc(user.getId())
                .stream()
                .map(conv -> new ConversationHistoryDto(
                        conv.getId(),
                        conv.getQuery(),
                        conv.getReply(),
                        conv.getIntent(),
                        conv.getTimestamp()
                ))
                .toList();
    }
        private static String truncate(String s) {
                if (s == null) return null;
                return s.length() > 60 ? s.substring(0, 57) + "..." : s;
        }
}
