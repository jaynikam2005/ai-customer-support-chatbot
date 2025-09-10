// backend-java/src/main/java/com/example/chatbot/controller/AuthController.java
package com.example.chatbot.controller;

import com.example.chatbot.model.*;
import com.example.chatbot.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        String token = authService.register(request.username(), request.password());
        return ResponseEntity.ok(new AuthResponse(token, request.username()));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        String token = authService.login(request.username(), request.password());
        return ResponseEntity.ok(new AuthResponse(token, request.username()));
    }
}
