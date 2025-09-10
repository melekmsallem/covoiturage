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
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*", maxAge = 3600)
public class BookingController {
    
    @Autowired
    private TripService tripService;
    
    @PostMapping
    public ResponseEntity<?> createBooking(@Valid @RequestBody BookingRequest request) {
        try {
            Long passengerId = getCurrentUserId();
            BookingResponse response = tripService.createBooking(request, passengerId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{bookingId}")
    public ResponseEntity<?> getBooking(@PathVariable Long bookingId) {
        try {
            BookingResponse response = tripService.getBookingById(bookingId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/my-bookings")
    public ResponseEntity<?> getMyBookings() {
        try {
            Long passengerId = getCurrentUserId();
            List<BookingResponse> response = tripService.getBookingsByPassenger(passengerId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/trip/{tripId}")
    public ResponseEntity<?> getBookingsByTrip(@PathVariable Long tripId) {
        try {
            List<BookingResponse> response = tripService.getBookingsByTrip(tripId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{bookingId}/confirm")
    public ResponseEntity<?> confirmBooking(@PathVariable Long bookingId) {
        try {
            Long driverId = getCurrentUserId();
            BookingResponse response = tripService.confirmBooking(bookingId, driverId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/{bookingId}/cancel")
    public ResponseEntity<?> cancelBooking(@PathVariable Long bookingId) {
        try {
            Long userId = getCurrentUserId();
            BookingResponse response = tripService.cancelBooking(bookingId, userId);
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
