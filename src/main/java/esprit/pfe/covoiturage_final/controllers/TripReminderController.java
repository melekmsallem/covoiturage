package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.TripStartReminderResponse;
import esprit.pfe.covoiturage_final.services.TripService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/trip-reminder")
@CrossOrigin(origins = "*")
public class TripReminderController {
    
    @Autowired
    private TripService tripService;
    
    /**
     * Get optimized route and pickup points for a trip about to start
     * Called 1 hour before trip departure
     */
    @GetMapping("/{tripId}")
    public ResponseEntity<?> getTripStartDetails(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            TripStartReminderResponse response = tripService.getTripStartDetails(tripId, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    /**
     * Start the trip (change status from PLANNED to ACTIVE)
     */
    @PostMapping("/{tripId}/start")
    public ResponseEntity<?> startTrip(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            tripService.startTrip(tripId, driverId);
            return ResponseEntity.ok(Map.of("success", true, "message", "Trip started successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            return user.getId();
        }
        throw new RuntimeException("User not authenticated");
    }
}

