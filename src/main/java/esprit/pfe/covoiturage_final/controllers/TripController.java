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
    public ResponseEntity<?> getMyTrips(
            @RequestParam(value = "page", required = false) Integer page,
            @RequestParam(value = "size", required = false) Integer size,
            @RequestParam(value = "sortBy", required = false) String sortBy,
            @RequestParam(value = "sortOrder", required = false) String sortOrder) {
        try {
            Long driverId = getCurrentUserId();
            List<TripResponse> trips = tripService.getTripsByDriver(driverId);
            trips = sortTrips(trips, sortBy, sortOrder);
            Map<String, Object> body = paginate(trips, page, size);
            return ResponseEntity.ok(body);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/search")
    public ResponseEntity<?> searchTrips(
            @Valid @RequestBody TripSearchRequest request,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size,
            @RequestParam(value = "sort", defaultValue = "departureTime,asc") String sort) {
        try {
            String[] sortParams = sort.split(",");
            String sortField = sortParams[0];
            Sort.Direction direction = sortParams.length > 1 && "desc".equalsIgnoreCase(sortParams[1]) 
                    ? Sort.Direction.DESC : Sort.Direction.ASC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));
            
            Page<TripResponse> tripsPage = tripService.searchTripsPageable(request, pageable);
            return ResponseEntity.ok(Map.of(
                "data", tripsPage.getContent(),
                "page", tripsPage.getNumber(),
                "size", tripsPage.getSize(),
                "totalPages", tripsPage.getTotalPages(),
                "totalElements", tripsPage.getTotalElements()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/available")
    public ResponseEntity<?> getAvailableTrips(
            @RequestParam(value = "page", required = false) Integer page,
            @RequestParam(value = "size", required = false) Integer size,
            @RequestParam(value = "sortBy", required = false) String sortBy,
            @RequestParam(value = "sortOrder", required = false) String sortOrder) {
        try {
            List<TripResponse> trips = tripService.getAvailableTrips();
            trips = sortTrips(trips, sortBy, sortOrder);
            Map<String, Object> body = paginate(trips, page, size);
            return ResponseEntity.ok(body);
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
    public ResponseEntity<?> getUpcomingTrips(
            @RequestParam(value = "page", required = false) Integer page,
            @RequestParam(value = "size", required = false) Integer size,
            @RequestParam(value = "sortBy", required = false) String sortBy,
            @RequestParam(value = "sortOrder", required = false) String sortOrder) {
        try {
            Long userId = getCurrentUserId();
            List<TripResponse> trips = tripService.getUpcomingTrips(userId);
            trips = sortTrips(trips, sortBy, sortOrder);
            Map<String, Object> body = paginate(trips, page, size);
            return ResponseEntity.ok(body);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/completed")
    public ResponseEntity<?> getCompletedTrips(
            @RequestParam(value = "page", required = false) Integer page,
            @RequestParam(value = "size", required = false) Integer size,
            @RequestParam(value = "sortBy", required = false) String sortBy,
            @RequestParam(value = "sortOrder", required = false) String sortOrder) {
        try {
            Long userId = getCurrentUserId();
            List<TripResponse> trips = tripService.getCompletedTrips(userId);
            trips = sortTrips(trips, sortBy, sortOrder);
            Map<String, Object> body = paginate(trips, page, size);
            return ResponseEntity.ok(body);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{tripId}/bookings")
    public ResponseEntity<?> getTripBookings(@PathVariable Long tripId,
                                             @RequestParam(value = "page", required = false) Integer page,
                                             @RequestParam(value = "size", required = false) Integer size,
                                             @RequestParam(value = "sortBy", required = false) String sortBy,
                                             @RequestParam(value = "sortOrder", required = false) String sortOrder) {
        try {
            List<BookingResponse> bookings = tripService.getBookingsByTrip(tripId);
            bookings = sortBookings(bookings, sortBy, sortOrder);
            Map<String, Object> body = paginate(bookings, page, size);
            return ResponseEntity.ok(body);
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

    private <T> Map<String, Object> paginate(List<T> items, Integer page, Integer size) {
        if (page == null || size == null || page < 0 || size <= 0) {
            return Map.of(
                "data", items,
                "page", 0,
                "size", items.size(),
                "total", items.size()
            );
        }
        int start = page * size;
        if (start >= items.size()) {
            return Map.of(
                "data", java.util.Collections.emptyList(),
                "page", page,
                "size", size,
                "total", items.size()
            );
        }
        int end = Math.min(start + size, items.size());
        List<T> slice = items.subList(start, end);
        return Map.of(
            "data", slice,
            "page", page,
            "size", size,
            "total", items.size()
        );
    }

    private List<TripResponse> sortTrips(List<TripResponse> trips, String sortBy, String sortOrder) {
        if (sortBy == null || sortBy.isBlank()) return trips;
        boolean desc = "desc".equalsIgnoreCase(sortOrder);
        java.util.Comparator<TripResponse> comparator;
        switch (sortBy.toLowerCase()) {
            case "price":
                comparator = java.util.Comparator.comparing(TripResponse::getPricePerSeat, java.util.Comparator.nullsLast(Double::compare));
                break;
            case "time":
            case "departuretime":
                comparator = java.util.Comparator.comparing(TripResponse::getDepartureTime, java.util.Comparator.nullsLast(java.time.LocalDateTime::compareTo));
                break;
            default:
                return trips;
        }
        if (desc) comparator = comparator.reversed();
        return trips.stream().sorted(comparator).toList();
    }

    private List<BookingResponse> sortBookings(List<BookingResponse> bookings, String sortBy, String sortOrder) {
        if (sortBy == null || sortBy.isBlank()) return bookings;
        boolean desc = "desc".equalsIgnoreCase(sortOrder);
        java.util.Comparator<BookingResponse> comparator;
        switch (sortBy.toLowerCase()) {
            case "date":
            case "reservationdate":
                comparator = java.util.Comparator.comparing(BookingResponse::getReservationDate, java.util.Comparator.nullsLast(java.time.LocalDateTime::compareTo));
                break;
            default:
                return bookings;
        }
        if (desc) comparator = comparator.reversed();
        return bookings.stream().sorted(comparator).toList();
    }
}
