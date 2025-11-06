package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Conducteur;
import esprit.pfe.covoiturage_final.services.LicenseVerificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/license")
@CrossOrigin(origins = "*", maxAge = 3600)
public class AdminLicenseController {

    @Autowired
    private LicenseVerificationService licenseVerificationService;

    /**
     * Get all drivers pending license verification with detailed information
     */
    @GetMapping("/pending")
    public ResponseEntity<List<Map<String, Object>>> getPendingVerifications() {
        try {
            List<Conducteur> pendingDrivers = licenseVerificationService.getDriversPendingVerification();
            List<Map<String, Object>> enrichedDrivers = new java.util.ArrayList<>();
            
            for (Conducteur driver : pendingDrivers) {
                Map<String, Object> driverData = new java.util.HashMap<>();
                driverData.put("id", driver.getId());
                driverData.put("username", driver.getUsername());
                driverData.put("email", driver.getEmail());
                driverData.put("firstName", driver.getFirstName());
                driverData.put("lastName", driver.getLastName());
                driverData.put("phoneNumber", driver.getPhoneNumber());
                driverData.put("licenseNumber", driver.getLicenseNumber());
                driverData.put("licenseImagePath", driver.getLicenseImagePath());
                driverData.put("isVerified", driver.getIsVerified());
                driverData.put("licenseVerified", driver.getLicenseVerified());
                driverData.put("vehicleModel", driver.getVehicleModel());
                driverData.put("vehiclePlate", driver.getVehiclePlate());
                driverData.put("createdAt", driver.getCreatedAt());
                
                enrichedDrivers.add(driverData);
            }
            
            return ResponseEntity.ok(enrichedDrivers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get all verified drivers
     */
    @GetMapping("/verified")
    public ResponseEntity<List<Conducteur>> getVerifiedDrivers() {
        try {
            List<Conducteur> verifiedDrivers = licenseVerificationService.getVerifiedDrivers();
            return ResponseEntity.ok(verifiedDrivers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Verify or reject a driver's license
     */
    @PostMapping("/{driverId}/verify")
    public ResponseEntity<?> verifyLicense(@PathVariable Long driverId, @RequestBody Map<String, Boolean> request) {
        try {
            Boolean verified = request.get("verified");
            if (verified == null) {
                return ResponseEntity.badRequest().body("Missing 'verified' field in request body");
            }

            licenseVerificationService.verifyLicense(driverId, verified);
            
            String message = verified ? "License verified successfully" : "License verification rejected";
            return ResponseEntity.ok().body(Map.of("message", message));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    /**
     * Check if a driver's license is verified
     */
    @GetMapping("/{driverId}/status")
    public ResponseEntity<?> getLicenseStatus(@PathVariable Long driverId) {
        try {
            boolean isVerified = licenseVerificationService.isLicenseVerified(driverId);
            String imagePath = licenseVerificationService.getLicenseImagePath(driverId);
            
            return ResponseEntity.ok(Map.of(
                "driverId", driverId,
                "isVerified", isVerified,
                "hasImage", imagePath != null
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error checking license status: " + e.getMessage());
        }
    }
}








