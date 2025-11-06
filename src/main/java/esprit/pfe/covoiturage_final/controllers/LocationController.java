package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.services.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/location")
@CrossOrigin(origins = "*", maxAge = 3600)
public class LocationController {

    @Autowired
    private LocationService locationService;

    @PostMapping("/update")
    public ResponseEntity<?> updateLocation(
            @RequestBody Map<String, Object> locationData,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            Double latitude = Double.valueOf(locationData.get("latitude").toString());
            Double longitude = Double.valueOf(locationData.get("longitude").toString());
            Double accuracy = locationData.get("accuracy") != null ? 
                Double.valueOf(locationData.get("accuracy").toString()) : null;
            
            locationService.updateUserLocation(userId, latitude, longitude, accuracy);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Location updated successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to update location: " + e.getMessage());
        }
    }

    @GetMapping("/passengers/{tripId}")
    public ResponseEntity<?> getPassengerLocations(
            @PathVariable Long tripId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            List<Map<String, Object>> passengerLocations = locationService.getPassengerLocationsForTrip(tripId, userId);
            
            return ResponseEntity.ok(passengerLocations);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get passenger locations: " + e.getMessage());
        }
    }

    @PostMapping("/share")
    public ResponseEntity<?> shareLocationWithDriver(
            @RequestParam Long tripId,
            @RequestParam Long driverId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            locationService.shareLocationWithDriver(userId, driverId, tripId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Location sharing started");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to share location: " + e.getMessage());
        }
    }

    @PostMapping("/stop-sharing")
    public ResponseEntity<?> stopLocationSharing(
            @RequestParam Long tripId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            locationService.stopLocationSharing(userId, tripId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Location sharing stopped");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to stop location sharing: " + e.getMessage());
        }
    }

    @GetMapping("/within-area")
    public ResponseEntity<?> checkPassengersWithinPickupArea(
            @RequestParam Long tripId,
            @RequestParam Double pickupLatitude,
            @RequestParam Double pickupLongitude,
            @RequestParam Double radiusInMeters,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            List<Map<String, Object>> passengersInArea = locationService.getPassengersWithinPickupArea(
                tripId, pickupLatitude, pickupLongitude, radiusInMeters, userId);
            
            return ResponseEntity.ok(passengersInArea);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to check pickup area: " + e.getMessage());
        }
    }

    private Long getUserIdFromAuthentication(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof User) {
            User user = (User) authentication.getPrincipal();
            return user.getId();
        }
        return 1L; // Fallback to admin user
    }
}















