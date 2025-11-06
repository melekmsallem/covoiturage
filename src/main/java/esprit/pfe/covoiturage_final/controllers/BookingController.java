package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.services.TripService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

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
    public ResponseEntity<?> getMyBookings(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size,
            @RequestParam(value = "sort", defaultValue = "reservationDate,desc") String sort) {
        try {
            Long passengerId = getCurrentUserId();
            String[] sortParams = sort.split(",");
            String sortField = sortParams[0];
            Sort.Direction direction = sortParams.length > 1 && "desc".equalsIgnoreCase(sortParams[1]) 
                    ? Sort.Direction.DESC : Sort.Direction.ASC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));
            
            Page<BookingResponse> bookingsPage = tripService.getBookingsByPassengerPageable(passengerId, pageable);
            return ResponseEntity.ok(Map.of(
                "data", bookingsPage.getContent(),
                "page", bookingsPage.getNumber(),
                "size", bookingsPage.getSize(),
                "totalPages", bookingsPage.getTotalPages(),
                "totalElements", bookingsPage.getTotalElements()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/my-trip-bookings")
    public ResponseEntity<?> getMyTripBookings(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size,
            @RequestParam(value = "sort", defaultValue = "reservationDate,desc") String sort) {
        try {
            Long driverId = getCurrentUserId();
            String[] sortParams = sort.split(",");
            String sortField = sortParams[0];
            Sort.Direction direction = sortParams.length > 1 && "desc".equalsIgnoreCase(sortParams[1]) 
                    ? Sort.Direction.DESC : Sort.Direction.ASC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));
            
            Page<BookingResponse> bookingsPage = tripService.getBookingsByDriverPageable(driverId, pageable);
            return ResponseEntity.ok(Map.of(
                "data", bookingsPage.getContent(),
                "page", bookingsPage.getNumber(),
                "size", bookingsPage.getSize(),
                "totalPages", bookingsPage.getTotalPages(),
                "totalElements", bookingsPage.getTotalElements()
            ));
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
    
    @PostMapping("/{bookingId}/decline")
    public ResponseEntity<?> declineBooking(@PathVariable Long bookingId) {
        try {
            Long driverId = getCurrentUserId();
            BookingResponse response = tripService.declineBooking(bookingId, driverId);
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
    
    @PostMapping("/{bookingId}/pickup-point")
    public ResponseEntity<?> setPickupPoint(@PathVariable Long bookingId, @RequestBody Map<String, Object> request) {
        try {
            Long passengerId = getCurrentUserId();
            String address = (String) request.get("address");
            Double latitude = ((Number) request.get("latitude")).doubleValue();
            Double longitude = ((Number) request.get("longitude")).doubleValue();
            
            BookingResponse response = tripService.setPassengerPickupPoint(bookingId, passengerId, address, latitude, longitude);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/trip/{tripId}/pickup-points")
    public ResponseEntity<?> getTripPickupPoints(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            List<Map<String, Object>> pickupPoints = tripService.getTripPickupPoints(tripId, userId);
            return ResponseEntity.ok(pickupPoints);
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
