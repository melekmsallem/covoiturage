package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.services.TripService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/trips")
@CrossOrigin(origins = "*", maxAge = 3600)
public class TripController {
    
    @Autowired
    private TripService tripService;
    
    @PostMapping
    public ResponseEntity<?> createTrip(@Valid @RequestBody CreateTripRequest request) {
        try {
            Long driverId = getCurrentUserId();
            TripResponse response = tripService.createTrip(request, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{tripId}")
    public ResponseEntity<?> getTrip(@PathVariable Long tripId) {
        try {
            TripResponse response = tripService.getTripById(tripId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/my-trips")
    public ResponseEntity<?> getMyTrips() {
        try {
            Long driverId = getCurrentUserId();
            List<TripResponse> response = tripService.getTripsByDriver(driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/search")
    public ResponseEntity<?> searchTrips(@Valid @RequestBody SearchTripRequest request) {
        try {
            List<TripResponse> response = tripService.searchTrips(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/available")
    public ResponseEntity<?> getAvailableTrips() {
        try {
            List<TripResponse> response = tripService.getAvailableTrips();
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/{tripId}")
    public ResponseEntity<?> updateTrip(@PathVariable Long tripId, @Valid @RequestBody CreateTripRequest request) {
        try {
            Long driverId = getCurrentUserId();
            TripResponse response = tripService.updateTrip(tripId, request, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{tripId}/cancel")
    public ResponseEntity<?> cancelTrip(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            tripService.cancelTrip(tripId, driverId);
            return ResponseEntity.ok("Trip cancelled successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @DeleteMapping("/{tripId}")
    public ResponseEntity<?> deleteTrip(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            tripService.deleteTrip(tripId, driverId);
            return ResponseEntity.ok("Trip deleted successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{tripId}/start")
    public ResponseEntity<?> startTrip(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            TripResponse response = tripService.startTrip(tripId, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{tripId}/complete")
    public ResponseEntity<?> completeTrip(@PathVariable Long tripId) {
        try {
            Long driverId = getCurrentUserId();
            TripResponse response = tripService.completeTrip(tripId, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/upcoming")
    public ResponseEntity<?> getUpcomingTrips() {
        try {
            Long userId = getCurrentUserId();
            List<TripResponse> response = tripService.getUpcomingTrips(userId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/completed")
    public ResponseEntity<?> getCompletedTrips() {
        try {
            Long userId = getCurrentUserId();
            List<TripResponse> response = tripService.getCompletedTrips(userId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
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
