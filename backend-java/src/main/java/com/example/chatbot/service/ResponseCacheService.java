// backend-java/src/main/java/com/example/chatbot/service/ResponseCacheService.java
package com.example.chatbot.service;

import com.example.chatbot.model.ChatResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Cache service for chat responses to improve response time for repeated queries
 */
@Service
public class ResponseCacheService {
    private static final Logger log = LoggerFactory.getLogger(ResponseCacheService.class);
    
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private final ScheduledExecutorService cleanupScheduler = Executors.newScheduledThreadPool(1);
    
    @Value("${cache.response.enabled:true}")
    private boolean cacheEnabled;
    
    @Value("${cache.response.ttl-minutes:60}")
    private int cacheTtlMinutes;
    
    @Value("${cache.response.max-size:500}")
    private int maxCacheSize;
    
    // Key normalization weight factors for similar queries
    private static final double WEIGHT_EXACT_MATCH = 1.0;
    private static final double MIN_SIMILARITY_THRESHOLD = 0.8;
    
    public ResponseCacheService() {
        // Schedule periodic cache cleanup
        cleanupScheduler.scheduleAtFixedRate(
            this::cleanupExpiredEntries, 
            10, 
            10, 
            TimeUnit.MINUTES
        );
    }
    
    /**
     * Store a response in the cache
     * 
     * @param message The user's message
     * @param response The generated response
     */
    public void cacheResponse(String message, ChatResponse response) {
        if (!cacheEnabled || message == null || message.isBlank()) {
            return;
        }
        
        try {
            // Avoid caching error responses
            if ("error".equals(response.intent())) {
                return;
            }
            
            // Normalize the message for cache key
            String key = normalizeKey(message);
            
            synchronized(cache) {
                // Ensure cache size limit
                if (cache.size() >= maxCacheSize && !cache.containsKey(key)) {
                    evictOldestEntry();
                }
                
                // Store in cache with current timestamp
                cache.put(key, new CacheEntry(response, LocalDateTime.now()));
                log.debug("Cached response for query: '{}'", truncate(message));
            }
        } catch (Exception e) {
            log.warn("Failed to cache response: {}", e.getMessage());
        }
    }
    
    /**
     * Retrieve a response from cache if available
     * 
     * @param message The user's message
     * @return Optional containing the cached response if found, empty otherwise
     */
    public Optional<ChatResponse> getCachedResponse(String message) {
        if (!cacheEnabled || message == null || message.isBlank()) {
            return Optional.empty();
        }
        
        try {
            String key = normalizeKey(message);
            CacheEntry entry = cache.get(key);
            
            if (entry != null && !isExpired(entry)) {
                log.debug("Cache hit for query: '{}'", truncate(message));
                return Optional.of(entry.response);
            }
        } catch (Exception e) {
            log.warn("Error retrieving from cache: {}", e.getMessage());
        }
        
        return Optional.empty();
    }
    
    /**
     * Normalize the user message to improve cache hit rate for similar queries
     */
    private String normalizeKey(String message) {
        return message.trim().toLowerCase();
    }
    
    /**
     * Check if a cache entry has expired
     */
    private boolean isExpired(CacheEntry entry) {
        return entry.timestamp.plusMinutes(cacheTtlMinutes).isBefore(LocalDateTime.now());
    }
    
    /**
     * Remove the oldest entry from the cache
     */
    private void evictOldestEntry() {
        cache.entrySet().stream()
            .min((e1, e2) -> e1.getValue().timestamp.compareTo(e2.getValue().timestamp))
            .ifPresent(entry -> {
                cache.remove(entry.getKey());
                log.debug("Evicted oldest cache entry: {}", entry.getKey());
            });
    }
    
    /**
     * Clean up expired entries
     */
    private void cleanupExpiredEntries() {
        int beforeSize = cache.size();
        
        cache.entrySet().removeIf(entry -> isExpired(entry.getValue()));
        
        int removedCount = beforeSize - cache.size();
        if (removedCount > 0) {
            log.debug("Cleaned up {} expired cache entries", removedCount);
        }
    }
    
    private String truncate(String s) {
        if (s == null) return null;
        return s.length() > 30 ? s.substring(0, 27) + "..." : s;
    }
    
    /**
     * Cache entry with response and timestamp
     */
    private static class CacheEntry {
        final ChatResponse response;
        final LocalDateTime timestamp;
        
        CacheEntry(ChatResponse response, LocalDateTime timestamp) {
            this.response = response;
            this.timestamp = timestamp;
        }
    }
}