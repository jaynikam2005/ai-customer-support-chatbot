// backend-java/src/main/java/com/example/chatbot/service/AuthService.java
package com.example.chatbot.service;

import com.example.chatbot.model.User;
import com.example.chatbot.repository.UserRepository;
import com.example.chatbot.security.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       AuthenticationManager authenticationManager) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
    }

    public String register(String username, String password) {
        if (userRepository.existsByUsername(username)) {
            throw new UsernameAlreadyExistsException(username);
        }

        User user = new User(username, passwordEncoder.encode(password));
    userRepository.saveAndFlush(user);
    log.debug("Registered new user '{}', issuing JWT", username);

        return jwtUtil.generateToken(username);
    }

    public String login(String username, String password) {
    authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(username, password));
    log.debug("User '{}' authenticated, issuing JWT", username);
        return jwtUtil.generateToken(username);
    }

    public static class UsernameAlreadyExistsException extends RuntimeException {
        public UsernameAlreadyExistsException(String username) {
            super("Username already exists: " + username);
        }
    }
}
