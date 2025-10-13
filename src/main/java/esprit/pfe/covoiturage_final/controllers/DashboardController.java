package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.DashboardStats;
import esprit.pfe.covoiturage_final.dto.TripSummary;
import esprit.pfe.covoiturage_final.dto.EarningsSummary;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.services.DashboardService;
import esprit.pfe.covoiturage_final.services.TripService;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.repositories.PaiementRepository;
import esprit.pfe.covoiturage_final.entities.Paiement;
import esprit.pfe.covoiturage_final.security.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {
    
    @Autowired
    private DashboardService dashboardService;
    
    @Autowired
    private JwtUtils jwtUtils;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private PaiementRepository paiementRepository;

    @Autowired
    private TripService tripService;
    
    /**
     * Get dashboard statistics for the current user
     */
    @GetMapping("/stats")
    public ResponseEntity<DashboardStats> getDashboardStats(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            DashboardStats stats = dashboardService.getDashboardStats(userId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get recent trips for the current user
     */
    @GetMapping("/recent-trips")
    public ResponseEntity<List<TripSummary>> getRecentTrips(
            HttpServletRequest request,
            @RequestParam(defaultValue = "5") int limit) {
        try {
            Long userId = getCurrentUserId(request);
            List<TripSummary> trips = dashboardService.getRecentTrips(userId, limit);
            return ResponseEntity.ok(trips);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get upcoming trips for the current user
     */
    @GetMapping("/upcoming-trips")
    public ResponseEntity<List<TripSummary>> getUpcomingTrips(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            List<TripSummary> trips = dashboardService.getUpcomingTrips(userId);
            return ResponseEntity.ok(trips);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get earnings summary for drivers
     */
    @GetMapping("/earnings")
    public ResponseEntity<EarningsSummary> getEarningsSummary(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            EarningsSummary earnings = dashboardService.getEarningsSummary(userId);
            return ResponseEntity.ok(earnings);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get trip history with pagination
     */
    @GetMapping("/trip-history")
    public ResponseEntity<List<TripSummary>> getTripHistory(
            HttpServletRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Long userId = getCurrentUserId(request);
            List<TripSummary> trips = dashboardService.getTripHistory(userId, page, size);
            return ResponseEntity.ok(trips);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get favorite drivers for passengers
     */
    @GetMapping("/favorite-drivers")
    public ResponseEntity<List<User>> getFavoriteDrivers(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            List<User> drivers = dashboardService.getFavoriteDrivers(userId);
            return ResponseEntity.ok(drivers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Debug endpoint to check user authentication
     */
    @GetMapping("/debug-auth")
    public ResponseEntity<Map<String, Object>> debugAuth(HttpServletRequest request) {
        try {
            String authHeader = request.getHeader("Authorization");
            Map<String, Object> debug = new java.util.HashMap<>();
            debug.put("hasAuthHeader", authHeader != null);
            if (authHeader != null) {
                debug.put("authHeader", authHeader);
                if (authHeader.startsWith("Bearer ")) {
                    String token = authHeader.substring(7);
                    debug.put("hasToken", true);
                    debug.put("tokenValid", jwtUtils.validateJwtToken(token));
                    if (jwtUtils.validateJwtToken(token)) {
                        String username = jwtUtils.getUserNameFromJwtToken(token);
                        debug.put("tokenSubject", username);
                        debug.put("userExistsByUsername", userRepository.findByUsername(username).isPresent());
                        debug.put("userExistsByEmail", userRepository.findByEmail(username).isPresent());
                    }
                }
            }
            return ResponseEntity.ok(debug);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Get dashboard overview with all key information
     */
    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getDashboardOverview(HttpServletRequest request) {
        try {
            Long userId = null;
            User currentUser = null;
            try {
                userId = getCurrentUserId(request);
                currentUser = userRepository.findById(userId).orElse(null);
            } catch (Exception ignored) {}

            Map<String, Object> stats = new java.util.HashMap<>();
            stats.put("userId", userId);

            if (currentUser == null || currentUser.getRole() == null) {
                // Unknown user/token: do NOT show admin totals; return neutral guest scope
                stats.put("scope", "GUEST");
                stats.put("totalTrips", 0L);
                stats.put("totalBookings", 0L);
                stats.put("totalEarnings", 0.0);
                stats.put("role", null);
            } else if (currentUser.getRole() == esprit.pfe.covoiturage_final.entities.UserRole.ADMIN) {
                // Admin/global view
                long totalTrips = voyageRepository.count();
                long totalBookings = reservationRepository.count();
                double totalEarnings = paiementRepository.findAll().stream()
                    .filter(p -> p.getStatus() == Paiement.PaymentStatus.COMPLETED)
                    .mapToDouble(Paiement::getAmount)
                    .sum();

                stats.put("scope", "ADMIN");
                stats.put("totalTrips", totalTrips);
                stats.put("totalBookings", totalBookings);
                stats.put("totalEarnings", Math.round(totalEarnings * 100.0) / 100.0);
                stats.put("role", "ADMIN");
            } else if (currentUser.getRole() == esprit.pfe.covoiturage_final.entities.UserRole.PASSAGER) {
                // Passenger-scoped view: count only CONFIRMED bookings whose trip departs in the future
                var allMyBookings = reservationRepository.findByPassagerId(userId);
                var now = java.time.LocalDateTime.now();
                long upcomingConfirmed = allMyBookings.stream()
                    .filter(b -> b.getStatus() == esprit.pfe.covoiturage_final.entities.Reservation.ReservationStatus.CONFIRMED)
                    .filter(b -> {
                        if (b.getVoyageId() == null) return false;
                        var tripOpt = voyageRepository.findById(b.getVoyageId());
                        return tripOpt.isPresent()
                            && tripOpt.get().getStatus() == esprit.pfe.covoiturage_final.entities.Voyage.VoyageStatus.PLANNED
                            && tripOpt.get().getDepartureTime() != null
                            && !tripOpt.get().getDepartureTime().isBefore(now);
                    })
                    .map(b -> b.getVoyageId())
                    .distinct()
                    .count();
                double myEarnings = 0.0; // passengers don’t earn; keep 0
                stats.put("scope", "PASSAGER");
                stats.put("totalTrips", upcomingConfirmed);
                stats.put("totalBookings", upcomingConfirmed);
                stats.put("totalEarnings", myEarnings);
                stats.put("role", "PASSAGER");
            } else if (currentUser.getRole() == esprit.pfe.covoiturage_final.entities.UserRole.CONDUCTEUR) {
                // Driver-scoped view: count UPCOMING trips and related bookings/earnings
                var allMyTrips = voyageRepository.findByConducteurId(userId);
                var now = java.time.LocalDateTime.now();
                
                // Filter for upcoming trips (departure time in the future)
                var myUpcomingTrips = allMyTrips.stream()
                    .filter(trip -> {
                        var dt = trip.getDepartureTime();
                        if (dt == null) {
                            // Treat PLANNED trips with no time as upcoming to avoid missing valid trips
                            return trip.getStatus() == esprit.pfe.covoiturage_final.entities.Voyage.VoyageStatus.PLANNED;
                        }
                        return !dt.isBefore(now);
                    })
                    .toList();

                long myUpcomingBookings = 0L;
                double myEarnings = 0.0;
                for (var trip : myUpcomingTrips) {
                    var bookings = reservationRepository.findByVoyageId(trip.getId());
                    // Count only confirmed bookings for stats
                    myUpcomingBookings += bookings.stream()
                        .filter(b -> b.getStatus() == esprit.pfe.covoiturage_final.entities.Reservation.ReservationStatus.CONFIRMED)
                        .count();
                    // Earnings from completed payments tied to these bookings
                    for (var b : bookings) {
                        var payments = paiementRepository.findByReservationId(b.getId());
                        for (var p : payments) {
                            if (p.getStatus() == Paiement.PaymentStatus.COMPLETED) {
                                myEarnings += p.getAmount();
                            }
                        }
                    }
                }
                
                // Add debug info
                stats.put("debug_totalTripsFound", allMyTrips.size());
                stats.put("debug_upcomingTripsCount", myUpcomingTrips.size());
                stats.put("debug_currentTime", now.toString());
                stats.put("role", "CONDUCTEUR");
                
                stats.put("scope", "CONDUCTEUR");
                stats.put("totalTrips", (long) myUpcomingTrips.size());
                stats.put("totalBookings", myUpcomingBookings);
                stats.put("totalEarnings", Math.round(myEarnings * 100.0) / 100.0);
            }

            // Populate upcoming trips for the current user (driver or passenger)
            java.util.List<Map<String, Object>> upcoming = java.util.List.of();
            if (userId != null) {
                try {
                    java.util.List<esprit.pfe.covoiturage_final.dto.TripResponse> upcomingTrips = tripService.getUpcomingTrips(userId);
                    upcoming = upcomingTrips.stream().map(tr -> {
                        Map<String, Object> m = new java.util.HashMap<>();
                        m.put("id", tr.getId());
                        m.put("departureCity", tr.getDepartureCity());
                        m.put("arrivalCity", tr.getArrivalCity());
                        m.put("departureTime", tr.getDepartureTime());
                        // Frontend expects 'price' key; map pricePerSeat to price
                        m.put("price", tr.getPricePerSeat());
                        m.put("pricePerSeat", tr.getPricePerSeat());
                        m.put("availableSeats", tr.getAvailableSeats());
                        m.put("maxSeats", tr.getMaxSeats());
                        m.put("status", tr.getStatus() != null ? tr.getStatus().name() : null);
                        return m;
                    }).toList();
                } catch (Exception ignored) {}
            }

            Map<String, Object> overview = new java.util.HashMap<>();
            overview.put("stats", stats);
            overview.put("recentTrips", java.util.List.of());
            overview.put("upcomingTrips", upcoming);
            
            return ResponseEntity.ok(overview);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    private Long getCurrentUserId(HttpServletRequest request) {
        // 1) Prefer Spring Security context (set by our JWT filter)
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            Object principal = authentication.getPrincipal();
            String identifier = null;
            if (principal instanceof org.springframework.security.core.userdetails.User userDetails) {
                identifier = userDetails.getUsername();
            } else if (principal instanceof String s && !"anonymousUser".equals(s)) {
                identifier = s;
            }
            if (identifier != null) {
                final String id = identifier;
                User user = userRepository
                        .findByUsername(id)
                        .orElseGet(() -> userRepository.findByEmail(id)
                                .orElseThrow(() -> new RuntimeException("User not found for principal: " + id)));
                return user.getId();
            }
        }

        // 2) Fallback: parse Authorization header directly
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtils.validateJwtToken(token)) {
                String subject = jwtUtils.getUserNameFromJwtToken(token).trim();
                final String sub = subject;
                User user = userRepository
                        .findByUsername(sub)
                        .orElseGet(() -> userRepository.findByEmail(sub)
                                .orElseThrow(() -> new RuntimeException("User not found for token subject: " + sub)));
                return user.getId();
            }
        }
        throw new RuntimeException("Invalid or missing token");
    }
}
