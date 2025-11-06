package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserRole;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UserController {

    @Autowired
    private UserService userService;
    
    @Autowired
    private UserRepository userRepository;

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        try {
            User user = userService.getUserById(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/username/{username}")
    @PreAuthorize("hasRole('ADMIN') or #username == authentication.principal.username")
    public ResponseEntity<User> getUserByUsername(@PathVariable String username) {
        try {
            User user = userService.getUserByUsername(username);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<User>> getAllUsers() {
        List<User> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/role/{role}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<User>> getUsersByRole(@PathVariable UserRole role) {
        List<User> users = userService.getUsersByRole(role);
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @RequestBody User userDetails) {
        try {
            User updatedUser = userService.updateUser(id, userDetails);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/check-username/{username}")
    public ResponseEntity<Boolean> checkUsernameExists(@PathVariable String username) {
        boolean exists = userService.existsByUsername(username);
        return ResponseEntity.ok(exists);
    }

    @GetMapping("/check-email/{email}")
    public ResponseEntity<Boolean> checkEmailExists(@PathVariable String email) {
        boolean exists = userService.existsByEmail(email);
        return ResponseEntity.ok(exists);
    }

    @GetMapping("/verification-status")
    public ResponseEntity<Map<String, Object>> getVerificationStatus() {
        try {
            User currentUser = userService.getCurrentUser();
            Map<String, Object> status = new java.util.HashMap<>();
            status.put("isVerified", currentUser.getIsVerified() != null && currentUser.getIsVerified());
            status.put("needsVerification", currentUser.getRole() == UserRole.CONDUCTEUR && 
                (currentUser.getIsVerified() == null || !currentUser.getIsVerified()));
            status.put("email", currentUser.getEmail());
            status.put("firstName", currentUser.getFirstName());
            status.put("lastName", currentUser.getLastName());
            
            // If driver, include license info
            if (currentUser instanceof esprit.pfe.covoiturage_final.entities.Conducteur) {
                esprit.pfe.covoiturage_final.entities.Conducteur driver = 
                    (esprit.pfe.covoiturage_final.entities.Conducteur) currentUser;
                status.put("licenseNumber", driver.getLicenseNumber());
            }
            
            return ResponseEntity.ok(status);
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).build();
        }
    }

    @PutMapping("/submit-verification")
    @PreAuthorize("hasRole('CONDUCTEUR')")
    public ResponseEntity<?> submitVerification(@RequestBody java.util.Map<String, Object> request) {
        try {
            User currentUser;
            try {
                currentUser = userService.getCurrentUser();
            } catch (RuntimeException e) {
                return ResponseEntity.status(401).body(java.util.Map.of("error", "User not authenticated. Please login again."));
            }
            
            if (currentUser.getRole() != UserRole.CONDUCTEUR) {
                return ResponseEntity.badRequest().body(java.util.Map.of("error", "Only drivers can submit verification"));
            }
            
            // Update user information
            if (request.containsKey("email")) {
                String email = (String) request.get("email");
                if (userService.existsByEmail(email) && !currentUser.getEmail().equals(email)) {
                    return ResponseEntity.badRequest().body(java.util.Map.of("error", "Email already in use"));
                }
                currentUser.setEmail(email);
            }
            
            if (request.containsKey("firstName")) {
                currentUser.setFirstName((String) request.get("firstName"));
            }
            
            if (request.containsKey("lastName")) {
                currentUser.setLastName((String) request.get("lastName"));
            }
            
            // Update driver-specific fields
            if (currentUser instanceof esprit.pfe.covoiturage_final.entities.Conducteur) {
                esprit.pfe.covoiturage_final.entities.Conducteur driver = 
                    (esprit.pfe.covoiturage_final.entities.Conducteur) currentUser;
                
                if (request.containsKey("licenseNumber")) {
                    driver.setLicenseNumber((String) request.get("licenseNumber"));
                }
                
                // Handle license image path if provided
                if (request.containsKey("licenseImagePath")) {
                    // Normalize path separators (Windows backslashes to forward slashes)
                    String imagePath = (String) request.get("licenseImagePath");
                    if (imagePath != null) {
                        imagePath = imagePath.replace('\\', '/');
                        driver.setLicenseImagePath(imagePath);
                        driver.setLicenseVerified(false); // Reset license verification when new image uploaded
                    }
                }
                
                // Set verification status to pending (admin will verify)
                driver.setIsVerified(false);
            }
            
            try {
                // Ensure vehiclePlate is valid before saving (fix validation error)
                if (currentUser instanceof esprit.pfe.covoiturage_final.entities.Conducteur) {
                    esprit.pfe.covoiturage_final.entities.Conducteur driver = 
                        (esprit.pfe.covoiturage_final.entities.Conducteur) currentUser;
                    // If vehiclePlate exists but is invalid, set it to null to avoid validation error
                    if (driver.getVehiclePlate() != null && 
                        !driver.getVehiclePlate().matches("^\\d{3}TU\\d{4}$")) {
                        System.out.println("Warning: Invalid vehiclePlate format, setting to null: " + driver.getVehiclePlate());
                        driver.setVehiclePlate(null);
                    }
                }
                // Save directly using repository - currentUser is already attached to JPA session
                userRepository.save(currentUser);
            } catch (Exception e) {
                System.err.println("Error saving user: " + e.getMessage());
                if (e.getCause() != null) {
                    System.err.println("Caused by: " + e.getCause().getMessage());
                    e.getCause().printStackTrace();
                }
                e.printStackTrace();
                return ResponseEntity.status(500).body(java.util.Map.of("error", 
                    "Failed to save user data: " + (e.getCause() != null ? e.getCause().getMessage() : e.getMessage())));
            }
            
            return ResponseEntity.ok(java.util.Map.of(
                "message", "Verification data submitted successfully. Please wait for admin approval.",
                "isVerified", currentUser.getIsVerified() != null && currentUser.getIsVerified()
            ));
        } catch (RuntimeException e) {
            System.err.println("Error in submitVerification: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.badRequest().body(java.util.Map.of("error", 
                e.getCause() != null ? e.getCause().getMessage() : e.getMessage()));
        } catch (Exception e) {
            System.err.println("Unexpected error in submitVerification: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).body(java.util.Map.of("error", 
                "Unexpected error: " + (e.getCause() != null ? e.getCause().getMessage() : e.getMessage())));
        }
    }
}
