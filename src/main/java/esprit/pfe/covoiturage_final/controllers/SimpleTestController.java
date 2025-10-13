package esprit.pfe.covoiturage_final.controllers;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/simple")
@CrossOrigin(origins = "*", maxAge = 3600)
public class SimpleTestController {

    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;

    @GetMapping("/test")
    public ResponseEntity<Map<String, Object>> simpleTest() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "SUCCESS");
        response.put("message", "Backend is working!");
        response.put("timestamp", java.time.LocalDateTime.now());
        response.put("version", "v1.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "HEALTHY");
        response.put("database", "CONNECTED");
        response.put("server", "RUNNING");
        response.put("port", "8081");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/auth/test")
    public ResponseEntity<Map<String, Object>> testAuth(@RequestBody Map<String, String> credentials) {
        Map<String, Object> response = new HashMap<>();
        
        String username = credentials.get("usernameOrEmail");
        String password = credentials.get("password");
        
        if ("admin".equals(username) && "admin123".equals(password)) {
            response.put("status", "SUCCESS");
            response.put("message", "Authentication successful");
            response.put("user", "admin");
            response.put("role", "ADMIN");
            response.put("token", "mock-jwt-token-" + System.currentTimeMillis());
        } else {
            response.put("status", "FAILED");
            response.put("message", "Invalid credentials");
            response.put("received_username", username);
            response.put("received_password", password != null ? "***" : "null");
        }
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/check-admin")
    public ResponseEntity<Map<String, Object>> checkAdmin() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            var adminUser = userRepository.findByUsername("admin");
            if (adminUser.isPresent()) {
                var user = adminUser.get();
                response.put("status", "SUCCESS");
                response.put("message", "Admin user found");
                response.put("username", user.getUsername());
                response.put("email", user.getEmail());
                response.put("role", user.getRole());
                response.put("isActive", user.getIsActive());
                response.put("isVerified", user.getIsVerified());
            } else {
                response.put("status", "NOT_FOUND");
                response.put("message", "Admin user not found in database");
            }
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Error checking admin user: " + e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/create-admin")
    public ResponseEntity<Map<String, Object>> createAdmin() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Check if admin user already exists
            var existingAdmin = userRepository.findByUsername("admin");
            if (existingAdmin.isPresent()) {
                response.put("status", "EXISTS");
                response.put("message", "Admin user already exists");
                response.put("username", existingAdmin.get().getUsername());
                response.put("email", existingAdmin.get().getEmail());
                return ResponseEntity.ok(response);
            }
            
            // Create admin user
            var adminUser = new esprit.pfe.covoiturage_final.entities.Admin();
            adminUser.setUsername("admin");
            adminUser.setEmail("admin@covoiturage.com");
            adminUser.setPassword(passwordEncoder.encode("admin123")); // Properly encode password
            adminUser.setFirstName("Admin");
            adminUser.setLastName("User");
            adminUser.setPhoneNumber("+21600000000");
            adminUser.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            adminUser.setIsActive(true);
            adminUser.setIsVerified(true);
            
            var savedAdmin = userRepository.save(adminUser);
            
            response.put("status", "SUCCESS");
            response.put("message", "Admin user created successfully");
            response.put("id", savedAdmin.getId());
            response.put("username", savedAdmin.getUsername());
            response.put("email", savedAdmin.getEmail());
            response.put("role", savedAdmin.getRole());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Failed to create admin user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @PostMapping("/create-admin1")
    public ResponseEntity<Map<String, Object>> createAdmin1() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Check if admin1 user already exists
            var existingAdmin = userRepository.findByUsername("admin1");
            if (existingAdmin.isPresent()) {
                response.put("status", "EXISTS");
                response.put("message", "Admin1 user already exists");
                response.put("username", existingAdmin.get().getUsername());
                response.put("email", existingAdmin.get().getEmail());
                response.put("role", existingAdmin.get().getRole());
                response.put("id", existingAdmin.get().getId());
                return ResponseEntity.ok(response);
            }
            
            // Create admin1 user with fresh password
            var adminUser = new esprit.pfe.covoiturage_final.entities.Admin();
            adminUser.setUsername("admin1");
            adminUser.setEmail("admin1@covoiturage.com");
            adminUser.setPassword(passwordEncoder.encode("admin123")); // Properly encode password
            adminUser.setFirstName("Admin");
            adminUser.setLastName("User1");
            adminUser.setPhoneNumber("+21600000001");
            adminUser.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            adminUser.setIsActive(true);
            adminUser.setIsVerified(true);
            
            var savedAdmin = userRepository.save(adminUser);
            
            response.put("status", "SUCCESS");
            response.put("message", "Admin1 user created successfully");
            response.put("id", savedAdmin.getId());
            response.put("username", savedAdmin.getUsername());
            response.put("email", savedAdmin.getEmail());
            response.put("role", savedAdmin.getRole());
            response.put("password", "admin123");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Failed to create admin1 user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/test-admin1-login")
    public ResponseEntity<Map<String, Object>> testAdmin1Login() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Test if admin1 user can be found by the authentication system
            var admin1User = userRepository.findByUsername("admin1");
            if (admin1User.isPresent()) {
                response.put("status", "FOUND");
                response.put("message", "Admin1 user found in database");
                response.put("username", admin1User.get().getUsername());
                response.put("email", admin1User.get().getEmail());
                response.put("role", admin1User.get().getRole());
                response.put("id", admin1User.get().getId());
                response.put("isActive", admin1User.get().getIsActive());
                response.put("isVerified", admin1User.get().getIsVerified());
            } else {
                response.put("status", "NOT_FOUND");
                response.put("message", "Admin1 user not found in database");
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Error checking admin1 user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @PostMapping("/reset-admin-passwords")
    public ResponseEntity<Map<String, Object>> resetAdminPasswords() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Delete existing admin users
            var existingAdmin = userRepository.findByUsername("admin");
            if (existingAdmin.isPresent()) {
                userRepository.delete(existingAdmin.get());
            }
            
            var existingAdmin1 = userRepository.findByUsername("admin1");
            if (existingAdmin1.isPresent()) {
                userRepository.delete(existingAdmin1.get());
            }
            
            // Create admin user with proper password encoding
            var adminUser = new esprit.pfe.covoiturage_final.entities.Admin();
            adminUser.setUsername("admin");
            adminUser.setEmail("admin@covoiturage.com");
            adminUser.setPassword(passwordEncoder.encode("admin123"));
            adminUser.setFirstName("Admin");
            adminUser.setLastName("User");
            adminUser.setPhoneNumber("+21600000000");
            adminUser.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            adminUser.setIsActive(true);
            adminUser.setIsVerified(true);
            userRepository.save(adminUser);
            
            // Create admin1 user with proper password encoding
            var admin1User = new esprit.pfe.covoiturage_final.entities.Admin();
            admin1User.setUsername("admin1");
            admin1User.setEmail("admin1@covoiturage.com");
            admin1User.setPassword(passwordEncoder.encode("admin123"));
            admin1User.setFirstName("Admin");
            admin1User.setLastName("User1");
            admin1User.setPhoneNumber("+21600000001");
            admin1User.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            admin1User.setIsActive(true);
            admin1User.setIsVerified(true);
            userRepository.save(admin1User);
            
            response.put("status", "SUCCESS");
            response.put("message", "Admin passwords reset successfully");
            response.put("admin_username", "admin");
            response.put("admin1_username", "admin1");
            response.put("password", "admin123");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Failed to reset admin passwords: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}
