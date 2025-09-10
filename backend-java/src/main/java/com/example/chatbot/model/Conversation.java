// backend-java/src/main/java/com/example/chatbot/model/Conversation.java
package com.example.chatbot.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

@Entity
@Table(name = "conversations")
public class Conversation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, columnDefinition = "TEXT")
    @NotBlank(message = "Query is required")
    private String query;

    @Column(nullable = false, columnDefinition = "TEXT")
    @NotBlank(message = "Reply is required")
    private String reply;

    @Column(length = 64)
    private String intent;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @PrePersist
    protected void onCreate() {
        timestamp = LocalDateTime.now();
    }

    // Constructors
    public Conversation() {}

    public Conversation(User user, String query, String reply, String intent) {
        this.user = user;
        this.query = query;
        this.reply = reply;
        this.intent = intent;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getQuery() { return query; }
    public void setQuery(String query) { this.query = query; }

    public String getReply() { return reply; }
    public void setReply(String reply) { this.reply = reply; }

    public String getIntent() { return intent; }
    public void setIntent(String intent) { this.intent = intent; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
