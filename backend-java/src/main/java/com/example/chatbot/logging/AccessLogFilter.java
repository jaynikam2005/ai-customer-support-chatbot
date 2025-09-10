package com.example.chatbot.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;

@Component
public class AccessLogFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(AccessLogFilter.class);

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain) throws ServletException, IOException {
        Instant start = Instant.now();
        try {
            filterChain.doFilter(request, response);
        } finally {
            long ms = Duration.between(start, Instant.now()).toMillis();
            String principal = (request.getUserPrincipal() != null) ? request.getUserPrincipal().getName() : "-";
            log.info("ACCESS method={} uri={} status={} user={} {}ms", request.getMethod(), request.getRequestURI(), response.getStatus(), principal, ms);
        }
    }
}
