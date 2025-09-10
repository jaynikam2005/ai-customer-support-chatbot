// backend-java/src/main/java/com/example/chatbot/security/JwtAuthenticationFilter.java
package com.example.chatbot.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;

    public JwtAuthenticationFilter(JwtUtil jwtUtil, UserDetailsService userDetailsService) {
        this.jwtUtil = jwtUtil;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        
        String authorizationHeader = request.getHeader("Authorization");
        if (authorizationHeader == null) {
            log.debug("No Authorization header present for URI: {}", request.getRequestURI());
        }

        if (authorizationHeader != null) {
            if (authorizationHeader.startsWith("Bearer ")) {
                String jwt = authorizationHeader.substring(7);
                if (jwt.isBlank()) {
                    log.debug("Blank JWT token for URI: {}", request.getRequestURI());
                } else if (jwtUtil.isTokenValid(jwt)) {
                    String username = jwtUtil.getUsernameFromToken(jwt);
                    if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                        try {
                            UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());
                            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                            SecurityContextHolder.getContext().setAuthentication(authentication);
                            log.debug("Authenticated user '{}' for URI: {}", username, request.getRequestURI());
                        } catch (Exception ex) {
                            log.warn("User details load failed for '{}' : {}", username, ex.getMessage());
                        }
                    }
                } else {
                    log.debug("Invalid JWT for URI: {}", request.getRequestURI());
                }
            } else {
                log.debug("Non-Bearer Authorization header provided for URI: {}", request.getRequestURI());
            }
        }

        filterChain.doFilter(request, response);
    }
}
