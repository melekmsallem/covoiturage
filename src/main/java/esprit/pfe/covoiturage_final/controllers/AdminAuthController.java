package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.JwtResponse;
import esprit.pfe.covoiturage_final.dto.LoginRequest;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserRole;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.security.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/auth")
@CrossOrigin(origins = "*")
public class AdminAuthController {

    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    UserRepository userRepository;

    @Autowired
    PasswordEncoder encoder;

    @Autowired
    JwtUtils jwtUtils;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateAdmin(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            // Authenticate user
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getUsernameOrEmail(), loginRequest.getPassword())
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);

            User userDetails = (User) authentication.getPrincipal();
            List<String> roles = userDetails.getAuthorities().stream()
                    .map(item -> item.getAuthority())
                    .collect(Collectors.toList());

            // Check if user has ADMIN role
            if (!roles.contains("ROLE_ADMIN")) {
                return ResponseEntity.badRequest()
                        .body("Access denied. Admin privileges required.");
            }

            return ResponseEntity.ok(new JwtResponse(jwt,
                    userDetails.getId(),
                    userDetails.getUsername(),
                    userDetails.getEmail(),
                    roles));

        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body("Invalid credentials");
        }
    }

    @PostMapping("/signup")
    public ResponseEntity<?> registerAdmin(@Valid @RequestBody AdminSignupRequest signUpRequest) {
        if (userRepository.existsByUsername(signUpRequest.getUsername())) {
            return ResponseEntity.badRequest().body("Error: Username is already taken!");
        }

        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            return ResponseEntity.badRequest().body("Error: Email is already in use!");
        }

        // Create new admin user
        User admin = new User();
        admin.setUsername(signUpRequest.getUsername());
        admin.setEmail(signUpRequest.getEmail());
        admin.setPassword(encoder.encode(signUpRequest.getPassword()));
        admin.setFirstName(signUpRequest.getFirstName());
        admin.setLastName(signUpRequest.getLastName());
        admin.setPhoneNumber(signUpRequest.getPhoneNumber());
        admin.setRole(UserRole.ADMIN);
        admin.setIsActive(true);
        admin.setIsVerified(true);

        userRepository.save(admin);

        return ResponseEntity.ok("Admin registered successfully!");
    }

    @GetMapping("/verify")
    public ResponseEntity<?> verifyAdminToken(@RequestHeader("Authorization") String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String jwt = authHeader.substring(7);
            if (jwtUtils.validateJwtToken(jwt)) {
                String username = jwtUtils.getUserNameFromJwtToken(jwt);
                User user = userRepository.findByUsername(username).orElse(null);
                if (user != null && user.getRole() == UserRole.ADMIN) {
                    return ResponseEntity.ok().body("Valid admin token");
                }
            }
        }
        return ResponseEntity.badRequest().body("Invalid or expired token");
    }

    // DTO for admin signup
    public static class AdminSignupRequest {
        private String username;
        private String email;
        private String password;
        private String firstName;
        private String lastName;
        private String phoneNumber;

        // Getters and setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }
        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }
        public String getPhoneNumber() { return phoneNumber; }
        public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    }
}
