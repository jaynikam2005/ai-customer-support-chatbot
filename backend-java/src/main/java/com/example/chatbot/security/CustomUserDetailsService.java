// backend-java/src/main/java/com/example/chatbot/security/CustomUserDetailsService.java
package com.example.chatbot.security;

import com.example.chatbot.model.User;
import com.example.chatbot.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private static final Logger log = LoggerFactory.getLogger(CustomUserDetailsService.class);
    private final UserRepository userRepository;

    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    log.debug("Loading user by username='{}'", username);
    User user = userRepository.findByUsername(username)
        .orElseThrow(() -> {
            log.debug("User '{}' not found in repository", username);
            return new UsernameNotFoundException("User not found: " + username);
        });
    log.debug("User '{}' found, returning UserDetails", username);

        return new org.springframework.security.core.userdetails.User(
                user.getUsername(),
                user.getPasswordHash(),
                new ArrayList<>()
        );
    }
}
