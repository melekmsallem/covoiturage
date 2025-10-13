package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.AuthResponse;
import esprit.pfe.covoiturage_final.dto.SignInRequest;
import esprit.pfe.covoiturage_final.dto.SignUpRequest;
import esprit.pfe.covoiturage_final.services.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.BindingResult;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {

    @Autowired
    private UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignUpRequest signUpRequest, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            StringBuilder errorMessage = new StringBuilder("Validation errors: ");
            bindingResult.getFieldErrors().forEach(error -> 
                errorMessage.append(error.getField()).append(": ").append(error.getDefaultMessage()).append("; ")
            );
            return ResponseEntity.badRequest().body(errorMessage.toString());
        }
        
        try {
            AuthResponse response = userService.signUp(signUpRequest);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody SignInRequest signInRequest) {
        AuthResponse response = userService.signIn(signInRequest);
        return ResponseEntity.ok(response);
    }
}
