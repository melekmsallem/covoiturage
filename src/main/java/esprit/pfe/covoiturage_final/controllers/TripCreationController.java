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
import java.util.Map;

@RestController
@RequestMapping("/api/trip-creation")
@CrossOrigin(origins = "*")
public class TripCreationController {
    
    @Autowired
    private TripService tripService;
    
    /**
     * Create a new trip with enhanced validation and GPS points
     */
    @PostMapping("/create")
    public ResponseEntity<?> createTrip(@Valid @RequestBody CreateTripRequest request) {
        try {
            Long driverId = getCurrentUserId();
            System.out.println("DEBUG: Creating trip for driver ID: " + driverId);
            TripResponse response = tripService.createTrip(request, driverId);
            System.out.println("DEBUG: Trip created successfully with ID: " + response.getId());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            System.out.println("DEBUG: Trip creation failed: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    /**
     * Get trip creation form data (cities, options, etc.)
     */
    @GetMapping("/form-data")
    public ResponseEntity<?> getTripCreationFormData() {
        try {
            Map<String, Object> formData = Map.of(
                "cities", tripService.getAllCities(),
                "options", tripService.getAllOptions(),
                "vehicleTypes", List.of("SEDAN", "SUV", "HATCHBACK", "CONVERTIBLE", "TRUCK"),
                "priceRanges", List.of(
                    Map.of("min", 16, "max", 32, "label", "Budget (16-32 TND)"),
                    Map.of("min", 32, "max", 64, "label", "Standard (32-64 TND)"),
                    Map.of("min", 64, "max", 160, "label", "Premium (64-160 TND)")
                )
            );
            return ResponseEntity.ok(formData);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    /**
     * Validate trip creation request before submission
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateTripCreation(@Valid @RequestBody CreateTripRequest request) {
        try {
            Map<String, Object> validation = tripService.validateTripCreation(request);
            return ResponseEntity.ok(validation);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    /**
     * Get estimated trip duration and distance
     */
    @PostMapping("/estimate")
    public ResponseEntity<?> estimateTrip(@RequestBody Map<String, Object> routeData) {
        try {
            System.out.println("DEBUG: Trip estimation request: " + routeData);
            Map<String, Object> estimation = tripService.estimateTrip(routeData);
            System.out.println("DEBUG: Trip estimation result: " + estimation);
            return ResponseEntity.ok(estimation);
        } catch (RuntimeException e) {
            System.out.println("DEBUG: Trip estimation error: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "error", true,
                "message", e.getMessage()
            ));
        }
    }
    
    /**
     * Debug endpoint to test authentication
     */
    @PostMapping("/debug-estimate")
    public ResponseEntity<?> debugEstimateTrip(@RequestBody Map<String, Object> routeData) {
        try {
            // Mock response with the expected structure for Flutter app
            Map<String, Object> debugResponse = Map.of(
                "distance", "120.5",
                "durationFormatted", "2h 15min",
                "estimatedFuelCost", "15.2",
                "route", Map.of(
                    "departure", routeData.getOrDefault("departureCity", "Unknown"),
                    "arrival", routeData.getOrDefault("arrivalCity", "Unknown")
                ),
                "debug", true,
                "message", "Debug estimation endpoint working - using mock data"
            );
            return ResponseEntity.ok(debugResponse);
        } catch (Exception e) {
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


