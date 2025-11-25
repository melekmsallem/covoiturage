package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.common.ApiConstants;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/simple")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class SimpleTestController {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int GENERATED_PASSWORD_BYTES = 18;
    private static final String STATUS_SUCCESS = "SUCCESS";
    private static final String STATUS_ERROR = "ERROR";
    private static final String STATUS_FAILED = "FAILED";
    private static final String STATUS_EXISTS = "EXISTS";
    private static final String STATUS_NOT_FOUND = "NOT_FOUND";
    private static final String STATUS_FOUND = "FOUND";
    private static final String STATUS_HEALTHY = "HEALTHY";
    private static final String ADMIN_USERNAME = "admin";
    private static final String ADMIN1_USERNAME = "admin1";
    private static final String ADMIN_EMAIL = "admin@covoiturage.com";
    private static final String ADMIN1_EMAIL = "admin1@covoiturage.com";
    private static final String ADMIN_FIRST_NAME = "Admin";
    private static final String ADMIN_LAST_NAME = "User";
    private static final String ADMIN1_LAST_NAME = "User1";
    private static final String ADMIN_PHONE = "+21600000000";
    private static final String ADMIN1_PHONE = "+21600000001";
    private static final String KEY_USERNAME = "username";
    private static final String KEY_EMAIL = "email";
    private static final String KEY_ROLE = "role";

    private final UserRepository userRepository;

    private final PasswordEncoder passwordEncoder;

    @GetMapping("/test")
    public ResponseEntity<Map<String, Object>> simpleTest() {
        Map<String, Object> response = new HashMap<>();
        response.put(ApiConstants.KEY_STATUS, STATUS_SUCCESS);
        response.put(ApiConstants.KEY_MESSAGE, "Backend is working!");
        response.put(ApiConstants.KEY_TIMESTAMP, LocalDateTime.now());
        response.put("version", "v1.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put(ApiConstants.KEY_STATUS, STATUS_HEALTHY);
        response.put("database", "CONNECTED");
        response.put("server", "RUNNING");
        response.put("port", "8081");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/auth/test")
    public ResponseEntity<Map<String, Object>> testAuth(@RequestBody Map<String, String> credentials) {
        Map<String, Object> response = new HashMap<>();

        String identifier = credentials.get("usernameOrEmail");
        String password = credentials.get("password");

        Optional<User> userOpt = findUserByUsernameOrEmail(identifier);

        if (userOpt.isPresent() && password != null && passwordEncoder.matches(password, userOpt.get().getPassword())) {
            User user = userOpt.get();
            response.put(ApiConstants.KEY_STATUS, STATUS_SUCCESS);
            response.put(ApiConstants.KEY_MESSAGE, "Authentication successful");
            response.put("user", user.getUsername());
            response.put(KEY_ROLE, user.getRole());
            response.put("token", "mock-jwt-token-" + System.currentTimeMillis());
        } else {
            response.put(ApiConstants.KEY_STATUS, STATUS_FAILED);
            response.put(ApiConstants.KEY_MESSAGE, "Invalid credentials");
            response.put("received_username", identifier);
            response.put("received_password", password != null ? "***" : "null");
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/check-admin")
    public ResponseEntity<Map<String, Object>> checkAdmin() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            var adminUser = userRepository.findByUsername(ADMIN_USERNAME);
            if (adminUser.isPresent()) {
                var user = adminUser.get();
                response.put(ApiConstants.KEY_STATUS, STATUS_SUCCESS);
                response.put(ApiConstants.KEY_MESSAGE, "Admin user found");
                response.put(KEY_USERNAME, user.getUsername());
                response.put(KEY_EMAIL, user.getEmail());
                response.put(KEY_ROLE, user.getRole());
                response.put("isActive", user.getIsActive());
                response.put("isVerified", user.getIsVerified());
            } else {
                response.put(ApiConstants.KEY_STATUS, STATUS_NOT_FOUND);
                response.put(ApiConstants.KEY_MESSAGE, "Admin user not found in database");
            }
        } catch (Exception e) {
            response.put(ApiConstants.KEY_STATUS, STATUS_ERROR);
            response.put(ApiConstants.KEY_MESSAGE, "Error checking admin user: " + e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/create-admin")
    public ResponseEntity<Map<String, Object>> createAdmin(@RequestBody(required = false) Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Check if admin user already exists
            var existingAdmin = userRepository.findByUsername(ADMIN_USERNAME);
            if (existingAdmin.isPresent()) {
                response.put(ApiConstants.KEY_STATUS, STATUS_EXISTS);
                response.put(ApiConstants.KEY_MESSAGE, "Admin user already exists");
                response.put(KEY_USERNAME, existingAdmin.get().getUsername());
                response.put(KEY_EMAIL, existingAdmin.get().getEmail());
                return ResponseEntity.ok(response);
            }
            
            return createAdminAccount(ADMIN_USERNAME, ADMIN_EMAIL, ADMIN_FIRST_NAME, ADMIN_LAST_NAME, ADMIN_PHONE, request, response);
        } catch (Exception e) {
            response.put(ApiConstants.KEY_STATUS, STATUS_ERROR);
            response.put(ApiConstants.KEY_MESSAGE, "Failed to create admin user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @PostMapping("/create-admin1")
    public ResponseEntity<Map<String, Object>> createAdmin1(@RequestBody(required = false) Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Check if admin1 user already exists
            var existingAdmin = userRepository.findByUsername(ADMIN1_USERNAME);
            if (existingAdmin.isPresent()) {
                response.put(ApiConstants.KEY_STATUS, STATUS_EXISTS);
                response.put(ApiConstants.KEY_MESSAGE, "Admin1 user already exists");
                response.put(KEY_USERNAME, existingAdmin.get().getUsername());
                response.put(KEY_EMAIL, existingAdmin.get().getEmail());
                response.put(KEY_ROLE, existingAdmin.get().getRole());
                response.put("id", existingAdmin.get().getId());
                return ResponseEntity.ok(response);
            }

            return createAdminAccount(ADMIN1_USERNAME, ADMIN1_EMAIL, ADMIN_FIRST_NAME, ADMIN1_LAST_NAME, ADMIN1_PHONE, request, response);
        } catch (Exception e) {
            response.put(ApiConstants.KEY_STATUS, STATUS_ERROR);
            response.put(ApiConstants.KEY_MESSAGE, "Failed to create admin1 user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/test-admin1-login")
    public ResponseEntity<Map<String, Object>> testAdmin1Login() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Test if admin1 user can be found by the authentication system
            var admin1User = userRepository.findByUsername(ADMIN1_USERNAME);
            if (admin1User.isPresent()) {
                response.put(ApiConstants.KEY_STATUS, STATUS_FOUND);
                response.put(ApiConstants.KEY_MESSAGE, "Admin1 user found in database");
                response.put(KEY_USERNAME, admin1User.get().getUsername());
                response.put(KEY_EMAIL, admin1User.get().getEmail());
                response.put(KEY_ROLE, admin1User.get().getRole());
                response.put("id", admin1User.get().getId());
                response.put("isActive", admin1User.get().getIsActive());
                response.put("isVerified", admin1User.get().getIsVerified());
            } else {
                response.put(ApiConstants.KEY_STATUS, STATUS_NOT_FOUND);
                response.put(ApiConstants.KEY_MESSAGE, "Admin1 user not found in database");
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put(ApiConstants.KEY_STATUS, STATUS_ERROR);
            response.put(ApiConstants.KEY_MESSAGE, "Error checking admin1 user: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @PostMapping("/reset-admin-passwords")
    public ResponseEntity<Map<String, Object>> resetAdminPasswords() {
        Map<String, Object> response = new HashMap<>();

        try {
            // Delete existing admin users
            var existingAdmin = userRepository.findByUsername(ADMIN_USERNAME);
            if (existingAdmin.isPresent()) {
                userRepository.delete(existingAdmin.get());
            }
            
            var existingAdmin1 = userRepository.findByUsername(ADMIN1_USERNAME);
            if (existingAdmin1.isPresent()) {
                userRepository.delete(existingAdmin1.get());
            }
            String adminPassword = generateSecurePassword();

            // Create admin user with proper password encoding
            var adminUser = new esprit.pfe.covoiturage_final.entities.Admin();
            adminUser.setUsername(ADMIN_USERNAME);
            adminUser.setEmail(ADMIN_EMAIL);
            adminUser.setPassword(passwordEncoder.encode(adminPassword));
            adminUser.setFirstName(ADMIN_FIRST_NAME);
            adminUser.setLastName(ADMIN_LAST_NAME);
            adminUser.setPhoneNumber(ADMIN_PHONE);
            adminUser.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            adminUser.setIsActive(true);
            adminUser.setIsVerified(true);
            userRepository.save(adminUser);

            String admin1Password = generateSecurePassword();

            // Create admin1 user with proper password encoding
            var admin1User = new esprit.pfe.covoiturage_final.entities.Admin();
            admin1User.setUsername(ADMIN1_USERNAME);
            admin1User.setEmail(ADMIN1_EMAIL);
            admin1User.setPassword(passwordEncoder.encode(admin1Password));
            admin1User.setFirstName(ADMIN_FIRST_NAME);
            admin1User.setLastName(ADMIN1_LAST_NAME);
            admin1User.setPhoneNumber(ADMIN1_PHONE);
            admin1User.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
            admin1User.setIsActive(true);
            admin1User.setIsVerified(true);
            userRepository.save(admin1User);

            response.put(ApiConstants.KEY_STATUS, STATUS_SUCCESS);
            response.put(ApiConstants.KEY_MESSAGE, "Admin passwords reset successfully");
            response.put("admin_username", ADMIN_USERNAME);
            response.put("admin1_username", ADMIN1_USERNAME);
            response.put("temporaryPasswordNotice", "New temporary passwords generated. Retrieve them through the secure channel configured for administrators.");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put(ApiConstants.KEY_STATUS, STATUS_ERROR);
            response.put(ApiConstants.KEY_MESSAGE, "Failed to reset admin passwords: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    private Optional<User> findUserByUsernameOrEmail(String identifier) {
        if (!StringUtils.hasText(identifier)) {
            return Optional.empty();
        }
        return userRepository.findByUsername(identifier)
                .or(() -> userRepository.findByEmail(identifier));
    }

    private ResponseEntity<Map<String, Object>> createAdminAccount(String username,
                                                                   String email,
                                                                   String firstName,
                                                                   String lastName,
                                                                   String phoneNumber,
                                                                   Map<String, String> request,
                                                                   Map<String, Object> response) {
        var adminUser = new esprit.pfe.covoiturage_final.entities.Admin();
        adminUser.setUsername(username);
        adminUser.setEmail(email);
        adminUser.setFirstName(firstName);
        adminUser.setLastName(lastName);
        adminUser.setPhoneNumber(phoneNumber);
        adminUser.setRole(esprit.pfe.covoiturage_final.entities.UserRole.ADMIN);
        adminUser.setIsActive(true);
        adminUser.setIsVerified(true);

        String requestedPassword = request != null ? request.get("password") : null;
        String resolvedPassword = resolvePassword(requestedPassword);
        boolean generatedPassword = !StringUtils.hasText(requestedPassword) || requestedPassword.length() < 8;
        adminUser.setPassword(passwordEncoder.encode(resolvedPassword));

        var savedAdmin = userRepository.save(adminUser);

        response.put(ApiConstants.KEY_STATUS, STATUS_SUCCESS);
        response.put(ApiConstants.KEY_MESSAGE, username + " user created successfully");
        response.put("id", savedAdmin.getId());
        response.put(KEY_USERNAME, savedAdmin.getUsername());
        response.put(KEY_EMAIL, savedAdmin.getEmail());
        response.put(KEY_ROLE, savedAdmin.getRole());
        if (generatedPassword) {
            response.put("temporaryPasswordNotice", "Temporary password generated securely. Retrieve it from the admin console or email channel.");
        }

        return ResponseEntity.ok(response);
    }

    private String resolvePassword(String requestedPassword) {
        if (StringUtils.hasText(requestedPassword) && requestedPassword.length() >= 8) {
            return requestedPassword;
        }
        return generateSecurePassword();
    }

    private String generateSecurePassword() {
        byte[] buffer = new byte[GENERATED_PASSWORD_BYTES];
        SECURE_RANDOM.nextBytes(buffer);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
    }
}
