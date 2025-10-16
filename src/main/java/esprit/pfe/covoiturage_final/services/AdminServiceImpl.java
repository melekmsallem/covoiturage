package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.entities.Voyage.VoyageStatus;
import esprit.pfe.covoiturage_final.repositories.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminServiceImpl implements AdminService {
    
    private static final Logger logger = LoggerFactory.getLogger(AdminServiceImpl.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private VilleRepository villeRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private PaiementRepository paiementRepository;
    
    @Autowired
    private AvisRepository avisRepository;
    
    @Autowired
    private NotificationRepository notificationRepository;
    
    @Autowired
    private OptionRepository optionRepository;
    
    @Autowired
    private Point_GPSRepository pointGPSRepository;
    
    @Autowired(required = false)
    private EmailService emailService;
    
    @Override
    public AdminDashboardStats getAdminDashboardStats() {
        AdminDashboardStats stats = new AdminDashboardStats();
        
        // User Statistics
        stats.setTotalUsers(userRepository.count());
        stats.setActiveUsers(userRepository.countByIsActive(true));
        stats.setNewUsersToday(userRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(1)));
        stats.setNewUsersThisWeek(userRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(7)));
        stats.setNewUsersThisMonth(userRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(30)));
        stats.setTotalDrivers(userRepository.countByRole(UserRole.CONDUCTEUR));
        stats.setTotalPassengers(userRepository.countByRole(UserRole.PASSAGER));
        stats.setVerifiedUsers(userRepository.countByIsVerified(true));
        stats.setSuspendedUsers(userRepository.countByIsActive(false));
        
        // Trip Statistics
        stats.setTotalTrips(voyageRepository.count());
        stats.setActiveTrips(voyageRepository.countByStatus(Voyage.VoyageStatus.ACTIVE));
        stats.setCompletedTrips(voyageRepository.countByStatus(Voyage.VoyageStatus.COMPLETED));
        stats.setCancelledTrips(voyageRepository.countByStatus(Voyage.VoyageStatus.CANCELLED));
        stats.setTripsToday(voyageRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(1)));
        stats.setTripsThisWeek(voyageRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(7)));
        stats.setTripsThisMonth(voyageRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(30)));
        
        // Calculate average rating and completion rate
        List<Voyage> allTrips = voyageRepository.findAll();
        double totalRating = allTrips.stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.COMPLETED)
            .mapToDouble(trip -> 4.5) // Mock rating - replace with actual rating calculation
            .average()
            .orElse(0.0);
        stats.setAverageTripRating(totalRating);
        
        long completedCount = allTrips.stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.COMPLETED)
            .count();
        stats.setTripCompletionRate(allTrips.isEmpty() ? 0.0 : (double) completedCount / allTrips.size() * 100);
        
        // Booking Statistics
        stats.setTotalBookings(reservationRepository.count());
        stats.setPendingBookings(reservationRepository.countByStatus(Reservation.ReservationStatus.PENDING));
        stats.setConfirmedBookings(reservationRepository.countByStatus(Reservation.ReservationStatus.CONFIRMED));
        stats.setCancelledBookings(reservationRepository.countByStatus(Reservation.ReservationStatus.CANCELLED));
        stats.setCompletedBookings(reservationRepository.countByStatus(Reservation.ReservationStatus.COMPLETED));
        
        long successfulBookings = stats.getConfirmedBookings() + stats.getCompletedBookings();
        stats.setBookingSuccessRate(stats.getTotalBookings() == 0 ? 0.0 : 
            (double) successfulBookings / stats.getTotalBookings() * 100);
        
        // Payment Statistics
        List<Paiement> allPayments = paiementRepository.findAll();
        stats.setTotalPayments(allPayments.size());
        stats.setSuccessfulPayments(allPayments.stream()
            .filter(p -> p.getStatus() == Paiement.PaymentStatus.COMPLETED)
            .count());
        stats.setFailedPayments(allPayments.stream()
            .filter(p -> p.getStatus() == Paiement.PaymentStatus.FAILED)
            .count());
        
        double totalRevenue = allPayments.stream()
            .filter(p -> p.getStatus() == Paiement.PaymentStatus.COMPLETED)
            .mapToDouble(Paiement::getAmount)
            .sum();
        stats.setTotalRevenue(totalRevenue);
        stats.setRevenueToday(calculateRevenueForPeriod(1));
        stats.setRevenueThisWeek(calculateRevenueForPeriod(7));
        stats.setRevenueThisMonth(calculateRevenueForPeriod(30));
        
        stats.setPaymentSuccessRate(stats.getTotalPayments() == 0 ? 0.0 : 
            (double) stats.getSuccessfulPayments() / stats.getTotalPayments() * 100);
        stats.setAveragePaymentAmount(stats.getSuccessfulPayments() == 0 ? 0.0 : 
            totalRevenue / stats.getSuccessfulPayments());
        
        // Rating Statistics
        List<Avis> allRatings = avisRepository.findAll();
        stats.setTotalRatings(allRatings.size());
        stats.setPendingRatings(allRatings.stream()
            .filter(r -> r.getStatus() == null || r.getStatus().equals("PENDING"))
            .count());
        stats.setApprovedRatings(allRatings.stream()
            .filter(r -> r.getStatus() != null && r.getStatus().equals("APPROVED"))
            .count());
        stats.setRejectedRatings(allRatings.stream()
            .filter(r -> r.getStatus() != null && r.getStatus().equals("REJECTED"))
            .count());
        
        double avgRating = allRatings.stream()
            .filter(r -> r.getStatus() == null || r.getStatus().equals("APPROVED"))
            .mapToDouble(Avis::getRating)
            .average()
            .orElse(0.0);
        stats.setAverageRating(avgRating);
        
        // Notification Statistics
        stats.setTotalNotifications(notificationRepository.count());
        stats.setUnreadNotifications(notificationRepository.countByStatus(Notification.NotificationStatus.UNREAD));
        stats.setNotificationsToday(notificationRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(1)));
        stats.setNotificationsThisWeek(notificationRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(7)));
        
        // System Health
        stats.setSystemHealthy(true); // Mock - implement actual health checks
        stats.setLastSystemCheck(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        stats.setActiveConnections(50); // Mock - implement actual connection tracking
        stats.setSystemUptime(99.9); // Mock - implement actual uptime calculation
        
        // Popular Routes (Mock data - implement actual calculation)
        stats.setPopularRoutes(getPopularRoutes(5));
        
        // Top Performers
        stats.setTopDrivers(getTopDrivers(5));
        stats.setTopPassengers(getTopPassengers(5));
        
        return stats;
    }
    
    private double calculateRevenueForPeriod(int days) {
        LocalDateTime startDate = LocalDateTime.now().minusDays(days);
        return paiementRepository.findByPaymentDateAfter(startDate).stream()
            .filter(p -> p.getStatus() == Paiement.PaymentStatus.COMPLETED)
            .mapToDouble(Paiement::getAmount)
            .sum();
    }
    
    @Override
    public Map<String, Object> getSystemHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "HEALTHY");
        health.put("timestamp", LocalDateTime.now());
        health.put("database", "CONNECTED");
        health.put("memory_usage", "75%");
        health.put("cpu_usage", "45%");
        health.put("disk_usage", "60%");
        health.put("active_connections", 50);
        health.put("response_time", "120ms");
        return health;
    }
    
    @Override
    public Map<String, Object> fixCityLinks() {
        Map<String, Object> result = new HashMap<>();
        try {
            // Fix existing voyage records to have proper departure and arrival city IDs
            List<Voyage> voyages = voyageRepository.findAll();
            int updatedCount = 0;
            
            for (Voyage voyage : voyages) {
                boolean updated = false;
                
                // Set departure city to Tunis (ID 1) if not set
                if (voyage.getDepartureVille() == null) {
                    Ville tunis = villeRepository.findById(1L).orElse(null);
                    if (tunis != null) {
                        voyage.setDepartureVille(tunis);
                        updated = true;
                    }
                }
                
                // Set arrival city based on voyage ID (matching the data.sql pattern)
                if (voyage.getArrivalVille() == null) {
                    Long arrivalCityId = null;
                    switch (voyage.getId().intValue()) {
                        case 1: arrivalCityId = 2L; break; // Sfax
                        case 2: arrivalCityId = 3L; break; // Sousse
                        case 3: arrivalCityId = 4L; break; // Kairouan
                        case 4: arrivalCityId = 5L; break; // Bizerte
                        case 5: arrivalCityId = 6L; break; // Gabès
                        case 6: arrivalCityId = 2L; break; // Sfax (meh's trip)
                        case 7: arrivalCityId = 3L; break; // Sousse (meh's trip)
                        default: arrivalCityId = 2L; break; // Default to Sfax
                    }
                    
                    Ville arrivalCity = villeRepository.findById(arrivalCityId).orElse(null);
                    if (arrivalCity != null) {
                        voyage.setArrivalVille(arrivalCity);
                        updated = true;
                    }
                }
                
                if (updated) {
                    voyageRepository.save(voyage);
                    updatedCount++;
                }
            }
            
            result.put("success", true);
            result.put("message", "City links fixed successfully");
            result.put("updatedVoyages", updatedCount);
            result.put("totalVoyages", voyages.size());
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error fixing city links: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        
        return result;
    }
    
    @Override
    public Map<String, Object> testTripCities(Long tripId) {
        Map<String, Object> result = new HashMap<>();
        try {
            Voyage voyage = voyageRepository.findById(tripId).orElse(null);
            if (voyage == null) {
                result.put("error", "Trip not found");
                return result;
            }
            
            result.put("tripId", voyage.getId());
            result.put("departureVille", voyage.getDepartureVille() != null ? voyage.getDepartureVille().getName() : "NULL");
            result.put("arrivalVille", voyage.getArrivalVille() != null ? voyage.getArrivalVille().getName() : "NULL");
            result.put("voyageCities", voyage.getVilles() != null ? voyage.getVilles().stream().map(Ville::getName).toList() : "NULL");
            result.put("gpsPoints", voyage.getPoints() != null ? voyage.getPoints().stream().map(p -> p.getAddress() + " (" + p.getPointType() + ")").toList() : "NULL");
            
        } catch (Exception e) {
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    @Override
    public Map<String, Object> cleanupDuplicateTrips() {
        Map<String, Object> result = new HashMap<>();
        try {
            // Get all trips and keep only the first 7 (original ones)
            List<Voyage> allTrips = voyageRepository.findAll();
            int originalCount = allTrips.size();
            
            // Find trips with ID > 7 to delete
            List<Voyage> tripsToDelete = allTrips.stream()
                .filter(trip -> trip.getId() > 7)
                .collect(Collectors.toList());
            
            // Delete trips one by one to handle foreign key constraints
            int deletedCount = 0;
            for (Voyage trip : tripsToDelete) {
                try {
                    // First, delete related records
                    // Delete GPS points
                    if (trip.getPoints() != null) {
                        trip.getPoints().clear();
                    }
                    
                    // Delete voyage-ville relationships
                    if (trip.getVilles() != null) {
                        trip.getVilles().clear();
                    }
                    
                    // Delete voyage-option relationships
                    if (trip.getOptions() != null) {
                        trip.getOptions().clear();
                    }
                    
                    // Save the trip to update relationships
                    voyageRepository.save(trip);
                    
                    // Now delete the trip
                    voyageRepository.delete(trip);
                    deletedCount++;
                    
                } catch (Exception e) {
                    // If individual deletion fails, continue with others
                    System.err.println("Failed to delete trip " + trip.getId() + ": " + e.getMessage());
                }
            }
            
            int remainingCount = originalCount - deletedCount;
            
            result.put("success", true);
            result.put("message", "Duplicate trips cleaned up successfully");
            result.put("originalCount", originalCount);
            result.put("deletedCount", deletedCount);
            result.put("remainingCount", remainingCount);
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error cleaning up duplicates: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        
        return result;
    }
    
    @Override
    public Map<String, Object> resetDatabase() {
        Map<String, Object> result = new HashMap<>();
        try {
            // Delete all trips and related data
            voyageRepository.deleteAll();
            
            result.put("success", true);
            result.put("message", "Database reset successfully. All trips have been deleted.");
            result.put("remainingTrips", 0);
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error resetting database: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        
        return result;
    }
    
    @Override
    public Map<String, Object> recreateTrips() {
        Map<String, Object> result = new HashMap<>();
        try {
            // Delete all existing trips
            voyageRepository.deleteAll();
            
            // Create new trips with proper city IDs
            List<Voyage> newTrips = new ArrayList<>();
            
            // Trip 1: Tunis to Sfax
            Voyage trip1 = new Voyage();
            trip1.setConducteurId(1L);
            trip1.setDepartureTime(LocalDateTime.of(2024, 9, 19, 8, 0));
            trip1.setArrivalTime(LocalDateTime.of(2024, 9, 19, 10, 30));
            trip1.setPricePerSeat(15.0);
            trip1.setMaxSeats(4);
            trip1.setAvailableSeats(3);
            trip1.setDescription("Comfortable ride from Tunis to Sfax");
            trip1.setStatus(Voyage.VoyageStatus.PLANNED);
            trip1.setDepartureVille(villeRepository.findById(1L).orElse(null)); // Tunis
            trip1.setArrivalVille(villeRepository.findById(2L).orElse(null)); // Sfax
            newTrips.add(trip1);
            
            // Trip 2: Tunis to Sousse
            Voyage trip2 = new Voyage();
            trip2.setConducteurId(2L);
            trip2.setDepartureTime(LocalDateTime.of(2024, 9, 19, 14, 0));
            trip2.setArrivalTime(LocalDateTime.of(2024, 9, 19, 16, 0));
            trip2.setPricePerSeat(12.0);
            trip2.setMaxSeats(3);
            trip2.setAvailableSeats(2);
            trip2.setDescription("Quick trip to Sousse");
            trip2.setStatus(Voyage.VoyageStatus.PLANNED);
            trip2.setDepartureVille(villeRepository.findById(1L).orElse(null)); // Tunis
            trip2.setArrivalVille(villeRepository.findById(3L).orElse(null)); // Sousse
            newTrips.add(trip2);
            
            // Trip 3: Tunis to Kairouan
            Voyage trip3 = new Voyage();
            trip3.setConducteurId(3L);
            trip3.setDepartureTime(LocalDateTime.of(2024, 9, 20, 9, 30));
            trip3.setArrivalTime(LocalDateTime.of(2024, 9, 20, 11, 45));
            trip3.setPricePerSeat(18.0);
            trip3.setMaxSeats(4);
            trip3.setAvailableSeats(4);
            trip3.setDescription("Premium service to Kairouan");
            trip3.setStatus(Voyage.VoyageStatus.PLANNED);
            trip3.setDepartureVille(villeRepository.findById(1L).orElse(null)); // Tunis
            trip3.setArrivalVille(villeRepository.findById(4L).orElse(null)); // Kairouan
            newTrips.add(trip3);
            
            // Trip 4: Tunis to Bizerte
            Voyage trip4 = new Voyage();
            trip4.setConducteurId(1L);
            trip4.setDepartureTime(LocalDateTime.of(2024, 9, 20, 16, 0));
            trip4.setArrivalTime(LocalDateTime.of(2024, 9, 20, 18, 30));
            trip4.setPricePerSeat(20.0);
            trip4.setMaxSeats(4);
            trip4.setAvailableSeats(1);
            trip4.setDescription("Evening trip to Bizerte");
            trip4.setStatus(Voyage.VoyageStatus.PLANNED);
            trip4.setDepartureVille(villeRepository.findById(1L).orElse(null)); // Tunis
            trip4.setArrivalVille(villeRepository.findById(5L).orElse(null)); // Bizerte
            newTrips.add(trip4);
            
            // Trip 5: Tunis to Gabès
            Voyage trip5 = new Voyage();
            trip5.setConducteurId(2L);
            trip5.setDepartureTime(LocalDateTime.of(2024, 9, 21, 7, 0));
            trip5.setArrivalTime(LocalDateTime.of(2024, 9, 21, 9, 15));
            trip5.setPricePerSeat(14.0);
            trip5.setMaxSeats(3);
            trip5.setAvailableSeats(3);
            trip5.setDescription("Early morning to Gabès");
            trip5.setStatus(Voyage.VoyageStatus.PLANNED);
            trip5.setDepartureVille(villeRepository.findById(1L).orElse(null)); // Tunis
            trip5.setArrivalVille(villeRepository.findById(6L).orElse(null)); // Gabès
            newTrips.add(trip5);
            
            // Save all trips
            voyageRepository.saveAll(newTrips);
            
            result.put("success", true);
            result.put("message", "Trips recreated successfully with proper city IDs");
            result.put("tripCount", newTrips.size());
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error recreating trips: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        
        return result;
    }
    
    @Override
    public Map<String, Object> populateDatabase() {
        Map<String, Object> result = new HashMap<>();
        try {
            // Create cities
            List<Ville> cities = new ArrayList<>();
            cities.add(new Ville(1L, "Tunis", "1000", "Tunisia", 36.8065, 10.1815));
            cities.add(new Ville(2L, "Sfax", "3000", "Tunisia", 34.7406, 10.7603));
            cities.add(new Ville(3L, "Sousse", "4000", "Tunisia", 35.8256, 10.6411));
            cities.add(new Ville(4L, "Kairouan", "3100", "Tunisia", 35.6711, 10.1006));
            cities.add(new Ville(5L, "Bizerte", "7000", "Tunisia", 37.2744, 9.8739));
            cities.add(new Ville(6L, "Gabès", "6000", "Tunisia", 33.8869, 10.0982));
            
            for (Ville city : cities) {
                villeRepository.save(city);
            }
            
            // Create users
            List<User> users = new ArrayList<>();
            User user1 = new User();
            user1.setId(1L);
            user1.setUsername("adem");
            user1.setEmail("adem@example.com");
            user1.setFirstName("adem");
            user1.setLastName("adem");
            user1.setPassword("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK");
            user1.setRole(UserRole.CONDUCTEUR);
            user1.setIsActive(true);
            user1.setIsVerified(true);
            user1.setCreatedAt(LocalDateTime.now());
            user1.setUpdatedAt(LocalDateTime.now());
            users.add(user1);
            
            User user2 = new User();
            user2.setId(2L);
            user2.setUsername("ali");
            user2.setEmail("ali@example.com");
            user2.setFirstName("ali");
            user2.setLastName("ali");
            user2.setPassword("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK");
            user2.setRole(UserRole.CONDUCTEUR);
            user2.setIsActive(true);
            user2.setIsVerified(true);
            user2.setCreatedAt(LocalDateTime.now());
            user2.setUpdatedAt(LocalDateTime.now());
            users.add(user2);
            
            User user3 = new User();
            user3.setId(3L);
            user3.setUsername("malek");
            user3.setEmail("malek@example.com");
            user3.setFirstName("malek");
            user3.setLastName("msallem");
            user3.setPassword("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK");
            user3.setRole(UserRole.CONDUCTEUR);
            user3.setIsActive(true);
            user3.setIsVerified(true);
            user3.setCreatedAt(LocalDateTime.now());
            user3.setUpdatedAt(LocalDateTime.now());
            users.add(user3);
            
            User user4 = new User();
            user4.setId(4L);
            user4.setUsername("testuser");
            user4.setEmail("test@example.com");
            user4.setFirstName("Test");
            user4.setLastName("User");
            user4.setPassword("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK");
            user4.setRole(UserRole.CONDUCTEUR);
            user4.setIsActive(true);
            user4.setIsVerified(true);
            user4.setCreatedAt(LocalDateTime.now());
            user4.setUpdatedAt(LocalDateTime.now());
            users.add(user4);
            
            User user5 = new User();
            user5.setId(5L);
            user5.setUsername("admin");
            user5.setEmail("admin@example.com");
            user5.setFirstName("Admin");
            user5.setLastName("User");
            user5.setPassword("$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK");
            user5.setRole(UserRole.ADMIN);
            user5.setIsActive(true);
            user5.setIsVerified(true);
            user5.setCreatedAt(LocalDateTime.now());
            user5.setUpdatedAt(LocalDateTime.now());
            users.add(user5);
            
            for (User user : users) {
                userRepository.save(user);
            }
            
            // Create trips
            List<Voyage> trips = new ArrayList<>();
            
            Voyage trip1 = new Voyage();
            trip1.setId(1L);
            trip1.setConducteurId(1L);
            trip1.setDepartureTime(LocalDateTime.of(2024, 9, 19, 8, 0));
            trip1.setArrivalTime(LocalDateTime.of(2024, 9, 19, 10, 30));
            trip1.setPricePerSeat(15.0);
            trip1.setMaxSeats(4);
            trip1.setAvailableSeats(3);
            trip1.setDescription("Comfortable ride from Tunis to Sfax");
            trip1.setStatus(Voyage.VoyageStatus.PLANNED);
            trip1.setCreatedAt(LocalDateTime.now());
            trip1.setUpdatedAt(LocalDateTime.now());
            trip1.setDepartureVille(villeRepository.findById(1L).orElse(null));
            trip1.setArrivalVille(villeRepository.findById(2L).orElse(null));
            trips.add(trip1);
            
            Voyage trip2 = new Voyage();
            trip2.setId(2L);
            trip2.setConducteurId(2L);
            trip2.setDepartureTime(LocalDateTime.of(2024, 9, 19, 14, 0));
            trip2.setArrivalTime(LocalDateTime.of(2024, 9, 19, 16, 0));
            trip2.setPricePerSeat(12.0);
            trip2.setMaxSeats(3);
            trip2.setAvailableSeats(2);
            trip2.setDescription("Quick trip to Sousse");
            trip2.setStatus(Voyage.VoyageStatus.PLANNED);
            trip2.setCreatedAt(LocalDateTime.now());
            trip2.setUpdatedAt(LocalDateTime.now());
            trip2.setDepartureVille(villeRepository.findById(1L).orElse(null));
            trip2.setArrivalVille(villeRepository.findById(3L).orElse(null));
            trips.add(trip2);
            
            Voyage trip3 = new Voyage();
            trip3.setId(3L);
            trip3.setConducteurId(3L);
            trip3.setDepartureTime(LocalDateTime.of(2024, 9, 20, 9, 30));
            trip3.setArrivalTime(LocalDateTime.of(2024, 9, 20, 11, 45));
            trip3.setPricePerSeat(18.0);
            trip3.setMaxSeats(4);
            trip3.setAvailableSeats(4);
            trip3.setDescription("Premium service to Kairouan");
            trip3.setStatus(Voyage.VoyageStatus.PLANNED);
            trip3.setCreatedAt(LocalDateTime.now());
            trip3.setUpdatedAt(LocalDateTime.now());
            trip3.setDepartureVille(villeRepository.findById(1L).orElse(null));
            trip3.setArrivalVille(villeRepository.findById(4L).orElse(null));
            trips.add(trip3);
            
            Voyage trip4 = new Voyage();
            trip4.setId(4L);
            trip4.setConducteurId(1L);
            trip4.setDepartureTime(LocalDateTime.of(2024, 9, 20, 16, 0));
            trip4.setArrivalTime(LocalDateTime.of(2024, 9, 20, 18, 30));
            trip4.setPricePerSeat(20.0);
            trip4.setMaxSeats(4);
            trip4.setAvailableSeats(1);
            trip4.setDescription("Evening trip to Bizerte");
            trip4.setStatus(Voyage.VoyageStatus.PLANNED);
            trip4.setCreatedAt(LocalDateTime.now());
            trip4.setUpdatedAt(LocalDateTime.now());
            trip4.setDepartureVille(villeRepository.findById(1L).orElse(null));
            trip4.setArrivalVille(villeRepository.findById(5L).orElse(null));
            trips.add(trip4);
            
            Voyage trip5 = new Voyage();
            trip5.setId(5L);
            trip5.setConducteurId(2L);
            trip5.setDepartureTime(LocalDateTime.of(2024, 9, 21, 7, 0));
            trip5.setArrivalTime(LocalDateTime.of(2024, 9, 21, 9, 15));
            trip5.setPricePerSeat(14.0);
            trip5.setMaxSeats(3);
            trip5.setAvailableSeats(3);
            trip5.setDescription("Early morning to Gabès");
            trip5.setStatus(Voyage.VoyageStatus.PLANNED);
            trip5.setCreatedAt(LocalDateTime.now());
            trip5.setUpdatedAt(LocalDateTime.now());
            trip5.setDepartureVille(villeRepository.findById(1L).orElse(null));
            trip5.setArrivalVille(villeRepository.findById(6L).orElse(null));
            trips.add(trip5);
            
            for (Voyage trip : trips) {
                voyageRepository.save(trip);
            }
            
            result.put("success", true);
            result.put("message", "Database populated successfully with 5 trips, 6 cities, and 5 users");
            result.put("tripsCreated", trips.size());
            result.put("citiesCreated", cities.size());
            result.put("usersCreated", users.size());
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error populating database: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        
        return result;
    }

    @Override
    public Map<String, Object> seedTunisiaCities(boolean reset) {
        Map<String, Object> result = new HashMap<>();
        try {
            if (reset) {
                villeRepository.deleteAll();
            }

            // Try to load extended dataset from classpath JSON if available
            List<Ville> toInsert = new ArrayList<>();
            List<Ville> seed = new ArrayList<>();
            try {
                var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                var is = this.getClass().getResourceAsStream("/tunisia_cities_extended.json");
                if (is != null) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> cities = mapper.readValue(is, List.class);
                    for (Map<String, Object> c : cities) {
                        String name = String.valueOf(c.get("name"));
                        String codePostal = String.valueOf(c.getOrDefault("codePostal", ""));
                        String pays = String.valueOf(c.getOrDefault("pays", "Tunisia"));
                        Double lat = c.get("latitude") != null ? Double.valueOf(c.get("latitude").toString()) : null;
                        Double lon = c.get("longitude") != null ? Double.valueOf(c.get("longitude").toString()) : null;
                        seed.add(new Ville(null, name, codePostal, pays, lat, lon));
                    }
                }
            } catch (Exception ignored) { }

            // Fallback to built-in minimal list if extended file not found
            if (seed.isEmpty()) {
                seed = List.of(
                    new Ville(null, "Tunis", "1000", "Tunisia", 36.8065, 10.1815),
                    new Ville(null, "Sfax", "3000", "Tunisia", 34.7406, 10.7603),
                    new Ville(null, "Sousse", "4000", "Tunisia", 35.8256, 10.6411),
                    new Ville(null, "Kairouan", "3100", "Tunisia", 35.6711, 10.1008),
                    new Ville(null, "Bizerte", "7000", "Tunisia", 37.2744, 9.8739),
                    new Ville(null, "Gabès", "6000", "Tunisia", 33.8869, 10.0982),
                    new Ville(null, "Ariana", "2080", "Tunisia", 36.8625, 10.1956),
                    new Ville(null, "Gafsa", "2100", "Tunisia", 34.4258, 8.7842),
                    new Ville(null, "Monastir", "5000", "Tunisia", 35.7771, 10.8262),
                    new Ville(null, "Ben Arous", "2013", "Tunisia", 36.7531, 10.2189),
                    new Ville(null, "Nabeul", "8000", "Tunisia", 36.4561, 10.7376),
                    new Ville(null, "Medenine", "4100", "Tunisia", 33.3548, 10.5053),
                    new Ville(null, "Kasserine", "1200", "Tunisia", 35.1673, 8.8365),
                    new Ville(null, "Mahdia", "5100", "Tunisia", 35.5047, 11.0622),
                    new Ville(null, "Zaghouan", "1100", "Tunisia", 36.4028, 10.1428),
                    new Ville(null, "Manouba", "2010", "Tunisia", 36.8081, 10.0972),
                    new Ville(null, "Tozeur", "2200", "Tunisia", 33.9197, 8.1336),
                    new Ville(null, "El Kef", "7100", "Tunisia", 36.1822, 8.7147),
                    new Ville(null, "Hammamet", "8050", "Tunisia", 36.4000, 10.6167),
                    new Ville(null, "Djerba", "4180", "Tunisia", 33.8667, 10.8667)
                );
            }

            for (Ville v : seed) {
                if (v.getName() != null && villeRepository.findByName(v.getName()).isEmpty()) {
                    toInsert.add(v);
                }
            }

            if (!toInsert.isEmpty()) {
                villeRepository.saveAll(toInsert);
            }

            result.put("success", true);
            result.put("inserted", toInsert.size());
            result.put("total", villeRepository.count());
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error seeding Tunisian cities: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        return result;
    }

    @Override
    public Map<String, Object> seedDefaultOptions(boolean reset) {
        Map<String, Object> result = new HashMap<>();
        try {
            if (reset) {
                // Clear existing options
                optionRepository.deleteAll();
            }

            List<Option> toInsert = new ArrayList<>();
            // Define default options with icons and zero price
            List<Option> seed = List.of(
                new Option(null, "Air Conditioning", "Climatisation disponible", 0.0, Option.OptionCategory.COMFORT, "ac_unit", true, 10),
                new Option(null, "Heating", "Chauffage disponible", 0.0, Option.OptionCategory.COMFORT, "thermostat", true, 20),
                new Option(null, "Smoking Allowed", "Fumeurs acceptés (zones dédiées)", 0.0, Option.OptionCategory.OTHER, "smoking_rooms", true, 30),
                new Option(null, "Pet Friendly", "Animaux acceptés", 0.0, Option.OptionCategory.PETS, "pets", true, 40)
            );

            for (Option op : seed) {
                boolean exists = optionRepository.findByNameContainingIgnoreCase(op.getName()).stream()
                    .anyMatch(o -> o.getName().equalsIgnoreCase(op.getName()));
                if (!exists) {
                    toInsert.add(op);
                }
            }

            if (!toInsert.isEmpty()) {
                optionRepository.saveAll(toInsert);
            }

            result.put("success", true);
            result.put("inserted", toInsert.size());
            result.put("total", optionRepository.count());
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error seeding default options: " + e.getMessage());
            result.put("error", e.getClass().getSimpleName());
        }
        return result;
    }
    
    @Override
    public List<AdminDashboardStats.PopularRoute> getPopularRoutes(int limit) {
        // Mock data - implement actual calculation based on trip data
        List<AdminDashboardStats.PopularRoute> routes = new ArrayList<>();
        routes.add(new AdminDashboardStats.PopularRoute("Tunis", "Sfax", 45, 15.0, 4.5));
        routes.add(new AdminDashboardStats.PopularRoute("Tunis", "Sousse", 38, 12.0, 4.3));
        routes.add(new AdminDashboardStats.PopularRoute("Tunis", "Kairouan", 25, 18.0, 4.7));
        routes.add(new AdminDashboardStats.PopularRoute("Sfax", "Tunis", 32, 15.0, 4.4));
        routes.add(new AdminDashboardStats.PopularRoute("Sousse", "Tunis", 28, 12.0, 4.2));
        return routes.stream().limit(limit).collect(Collectors.toList());
    }
    
    @Override
    public List<AdminDashboardStats.TopDriver> getTopDrivers(int limit) {
        // Mock data - implement actual calculation
        List<AdminDashboardStats.TopDriver> drivers = new ArrayList<>();
        drivers.add(new AdminDashboardStats.TopDriver(1L, "driver1", "Ahmed Ben Ali", 25, 4.5, 375.0, 89));
        drivers.add(new AdminDashboardStats.TopDriver(2L, "driver2", "Fatma Trabelsi", 18, 4.2, 216.0, 54));
        drivers.add(new AdminDashboardStats.TopDriver(3L, "driver3", "Mohamed Khelil", 32, 4.8, 576.0, 128));
        return drivers.stream().limit(limit).collect(Collectors.toList());
    }
    
    @Override
    public List<AdminDashboardStats.TopPassenger> getTopPassengers(int limit) {
        // Mock data - implement actual calculation
        List<AdminDashboardStats.TopPassenger> passengers = new ArrayList<>();
        passengers.add(new AdminDashboardStats.TopPassenger(5L, "passenger1", "Sara Ben Ammar", 15, 4.6, 195.0, 12));
        return passengers.stream().limit(limit).collect(Collectors.toList());
    }
    
    @Override
    public List<Map<String, Object>> getRecentActivity() {
        List<Map<String, Object>> activities = new ArrayList<>();
        
        // Get recent bookings
        List<Reservation> recentBookings = reservationRepository.findAll().stream()
            .sorted((a, b) -> b.getReservationDate().compareTo(a.getReservationDate()))
            .limit(10)
            .collect(Collectors.toList());
        
        for (Reservation r : recentBookings) {
            Map<String, Object> activity = new HashMap<>();
            activity.put("type", "booking");
            activity.put("id", r.getId());
            
            // Get passenger details
            User passenger = userRepository.findById(r.getPassagerId()).orElse(null);
            String passengerName = passenger != null ? passenger.getFirstName() + " " + passenger.getLastName() : "Unknown";
            
            activity.put("description", "New booking by " + passengerName);
            activity.put("timestamp", r.getReservationDate().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            activity.put("status", r.getStatus().name());
            activities.add(activity);
        }
        
        // Get recent payments
        List<Paiement> recentPayments = paiementRepository.findAll().stream()
            .sorted((a, b) -> b.getPaymentDate().compareTo(a.getPaymentDate()))
            .limit(10)
            .collect(Collectors.toList());
        
        for (Paiement p : recentPayments) {
            Map<String, Object> activity = new HashMap<>();
            activity.put("type", "payment");
            activity.put("id", p.getId());
            activity.put("description", "Payment of " + p.getAmount() + " TND via " + p.getPaymentMethod());
            activity.put("timestamp", p.getPaymentDate().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            activity.put("status", p.getStatus().name());
            activities.add(activity);
        }
        
        // Sort all activities by timestamp
        activities.sort((a, b) -> {
            String timeA = (String) a.get("timestamp");
            String timeB = (String) b.get("timestamp");
            return timeB.compareTo(timeA);
        });
        
        return activities.stream().limit(20).collect(Collectors.toList());
    }
    
    @Override
    public List<Map<String, Object>> getAllBookings() {
        List<Reservation> allReservations = reservationRepository.findAll();
        return allReservations.stream().map(r -> {
            Map<String, Object> booking = new HashMap<>();
            booking.put("id", r.getId());
            booking.put("voyageId", r.getVoyageId());
            booking.put("passagerId", r.getPassagerId());
            
            // Get passenger details
            User passenger = userRepository.findById(r.getPassagerId()).orElse(null);
            booking.put("passengerName", passenger != null ? 
                passenger.getFirstName() + " " + passenger.getLastName() : "Unknown");
            
            booking.put("status", r.getStatus().name());
            booking.put("seatsReserved", r.getNumberOfSeats());
            booking.put("totalPrice", r.getTotalPrice());
            booking.put("reservationDate", r.getReservationDate() != null ? 
                r.getReservationDate().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null);
            
            // Add trip details if available
            Voyage voyage = voyageRepository.findById(r.getVoyageId()).orElse(null);
            if (voyage != null) {
                booking.put("departureCity", voyage.getDepartureVille() != null ? voyage.getDepartureVille().getName() : "Unknown");
                booking.put("arrivalCity", voyage.getArrivalVille() != null ? voyage.getArrivalVille().getName() : "Unknown");
                booking.put("departureTime", voyage.getDepartureTime() != null ? 
                    voyage.getDepartureTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null);
                booking.put("tripStatus", voyage.getStatus().name());
            }
            
            return booking;
        }).collect(Collectors.toList());
    }
    
    @Override
    public Page<User> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable);
    }
    
    @Override
    public Page<User> getUsersByRole(String role, Pageable pageable) {
        UserRole userRole = UserRole.valueOf(role.toUpperCase());
        return userRepository.findByRole(userRole, pageable);
    }
    
    @Override
    public Page<User> getUsersByStatus(String status, Pageable pageable) {
        boolean isActive = "ACTIVE".equalsIgnoreCase(status);
        return userRepository.findByIsActive(isActive, pageable);
    }
    
    @Override
    public List<User> searchUsers(String query) {
        return userRepository.findByUsernameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(
            query, query, query, query);
    }
    
    @Override
    public User getUserById(Long userId) {
        return userRepository.findById(userId).orElse(null);
    }
    
    @Override
    public User updateUserStatus(Long userId, String action, String reason) {
        User user = getUserById(userId);
        if (user == null) {
            return null;
        }
        
        switch (action.toUpperCase()) {
            case "SUSPEND":
                user.setIsActive(false);
                break;
            case "ACTIVATE":
                user.setIsActive(true);
                break;
            case "VERIFY":
                user.setIsVerified(true);
                break;
            default:
                break;
        }
        
        return userRepository.save(user);
    }
    
    @Override
    public User suspendUser(Long userId, String reason, LocalDateTime suspensionEndDate) {
        User user = getUserById(userId);
        if (user != null) {
            user.setIsActive(false);
            user.setSuspensionReason(reason);
            user.setSuspensionEndDate(suspensionEndDate);
            userRepository.save(user);
        }
        return user;
    }
    
    @Override
    public User activateUser(Long userId) {
        User user = getUserById(userId);
        if (user != null) {
            user.setIsActive(true);
            user.setSuspensionReason(null);
            user.setSuspensionEndDate(null);
            userRepository.save(user);
        }
        return user;
    }
    
    @Override
    public User verifyUser(Long userId) {
        User user = getUserById(userId);
        if (user != null) {
            user.setIsVerified(true);
            userRepository.save(user);
        }
        return user;
    }
    
    @Override
    public boolean deleteUser(Long userId) {
        if (userRepository.existsById(userId)) {
            userRepository.deleteById(userId);
            return true;
        }
        return false;
    }
    
    @Override
    public Map<String, Long> getUserStatistics() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", userRepository.count());
        stats.put("active", userRepository.countByIsActive(true));
        stats.put("drivers", userRepository.countByRole(UserRole.CONDUCTEUR));
        stats.put("passengers", userRepository.countByRole(UserRole.PASSAGER));
        stats.put("verified", userRepository.countByIsVerified(true));
        return stats;
    }
    
    @Override
    public List<User> getRecentlyRegisteredUsers(int days) {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
        return userRepository.findByCreatedAtAfter(cutoff);
    }
    
    @Override
    public List<User> getInactiveUsers(int days) {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
        return userRepository.findByLastLoginBeforeAndIsActiveTrue(cutoff);
    }
    
    @Override
    public Page<Map<String, Object>> getAllTrips(Pageable pageable) {
        Page<Voyage> voyages = voyageRepository.findAll(pageable);
        return voyages.map(voyage -> {
            Map<String, Object> tripData = new HashMap<>();
            tripData.put("id", voyage.getId());
            tripData.put("departureTime", voyage.getDepartureTime());
            tripData.put("arrivalTime", voyage.getArrivalTime());
            tripData.put("status", voyage.getStatus());
            tripData.put("availableSeats", voyage.getAvailableSeats());
            tripData.put("maxSeats", voyage.getMaxSeats());
            tripData.put("pricePerSeat", voyage.getPricePerSeat());
            tripData.put("description", voyage.getDescription());
            tripData.put("createdAt", voyage.getCreatedAt());
            tripData.put("updatedAt", voyage.getUpdatedAt());
            
            // Add driver information - fetch from database
            try {
                User driver = userRepository.findById(voyage.getConducteurId()).orElse(null);
                if (driver != null) {
                    Map<String, Object> driverInfo = new HashMap<>();
                    driverInfo.put("firstName", driver.getFirstName() != null ? driver.getFirstName() : "Unknown");
                    driverInfo.put("lastName", driver.getLastName() != null ? driver.getLastName() : "Driver");
                    tripData.put("driver", driverInfo);
                } else {
                    Map<String, Object> driverInfo = new HashMap<>();
                    driverInfo.put("firstName", "Unknown");
                    driverInfo.put("lastName", "Driver");
                    tripData.put("driver", driverInfo);
                }
            } catch (Exception e) {
                Map<String, Object> driverInfo = new HashMap<>();
                driverInfo.put("firstName", "Unknown");
                driverInfo.put("lastName", "Driver");
                tripData.put("driver", driverInfo);
            }
            
            // Add points information - get actual city names from database
            List<Map<String, Object>> points = new ArrayList<>();
            
            // Get departure city - try direct relationship first, then fallback to junction table
            String departureCityName = "Unknown Departure";
            if (voyage.getDepartureVille() != null) {
                departureCityName = voyage.getDepartureVille().getName();
            } else {
                // Try to get from voyage_villes junction table
                try {
                    List<Ville> voyageCities = voyage.getVilles();
                    if (voyageCities != null && !voyageCities.isEmpty()) {
                        // Assuming first city is departure, second is arrival
                        departureCityName = voyageCities.get(0).getName();
                    }
                } catch (Exception e) {
                    // If junction table fails, try to get from GPS points
                    try {
                        List<Point_GPS> gpsPoints = voyage.getPoints();
                        if (gpsPoints != null && !gpsPoints.isEmpty()) {
                            Point_GPS startPoint = gpsPoints.stream()
                                .filter(p -> "START".equals(p.getPointType()))
                                .findFirst()
                                .orElse(null);
                            if (startPoint != null) {
                                departureCityName = startPoint.getAddress();
                            }
                        }
                    } catch (Exception ex) {
                        // Keep default "Unknown Departure"
                    }
                }
            }
            
            Map<String, Object> departurePoint = new HashMap<>();
            departurePoint.put("address", departureCityName);
            points.add(departurePoint);
            
            // Get arrival city - try direct relationship first, then fallback to junction table
            String arrivalCityName = "Unknown Arrival";
            if (voyage.getArrivalVille() != null) {
                arrivalCityName = voyage.getArrivalVille().getName();
            } else {
                // Try to get from voyage_villes junction table
                try {
                    List<Ville> voyageCities = voyage.getVilles();
                    if (voyageCities != null && voyageCities.size() > 1) {
                        // Assuming second city is arrival
                        arrivalCityName = voyageCities.get(1).getName();
                    }
                } catch (Exception e) {
                    // If junction table fails, try to get from GPS points
                    try {
                        List<Point_GPS> gpsPoints = voyage.getPoints();
                        if (gpsPoints != null && !gpsPoints.isEmpty()) {
                            Point_GPS endPoint = gpsPoints.stream()
                                .filter(p -> "END".equals(p.getPointType()))
                                .findFirst()
                                .orElse(null);
                            if (endPoint != null) {
                                arrivalCityName = endPoint.getAddress();
                            }
                        }
                    } catch (Exception ex) {
                        // Keep default "Unknown Arrival"
                    }
                }
            }
            
            Map<String, Object> arrivalPoint = new HashMap<>();
            arrivalPoint.put("address", arrivalCityName);
            points.add(arrivalPoint);
            
            tripData.put("points", points);
            
            return tripData;
        });
    }
    
    // Additional methods with mock implementations
    @Override
    public Map<String, Long> getTripStatistics() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", voyageRepository.count());
        stats.put("active", voyageRepository.countByStatus(Voyage.VoyageStatus.ACTIVE));
        stats.put("completed", voyageRepository.countByStatus(Voyage.VoyageStatus.COMPLETED));
        stats.put("cancelled", voyageRepository.countByStatus(Voyage.VoyageStatus.CANCELLED));
        return stats;
    }
    
    @Override
    public List<Map<String, Object>> getTripTrends(int days) {
        // Mock implementation
        List<Map<String, Object>> trends = new ArrayList<>();
        for (int i = days; i >= 0; i--) {
            Map<String, Object> day = new HashMap<>();
            day.put("date", LocalDateTime.now().minusDays(i).toLocalDate());
            day.put("trips", 10 + (int)(Math.random() * 20));
            day.put("bookings", 15 + (int)(Math.random() * 30));
            trends.add(day);
        }
        return trends;
    }
    
    @Override
    public List<Map<String, Object>> getPopularDestinations(int limit) {
        // Mock implementation
        List<Map<String, Object>> destinations = new ArrayList<>();
        destinations.add(Map.of("city", "Sfax", "trips", 45, "bookings", 89));
        destinations.add(Map.of("city", "Sousse", "trips", 38, "bookings", 76));
        destinations.add(Map.of("city", "Kairouan", "trips", 25, "bookings", 50));
        return destinations.stream().limit(limit).collect(Collectors.toList());
    }
    
    @Override
    public boolean deleteTrip(Long tripId) {
        try {
            if (voyageRepository.existsById(tripId)) {
                // Delete all related entities first to avoid foreign key constraints
                
                // 1. Delete all avis (reviews) related to this trip
                List<Avis> avisToDelete = avisRepository.findAll().stream()
                    .filter(avis -> avis.getVoyageId() != null && avis.getVoyageId().equals(tripId))
                    .collect(Collectors.toList());
                avisRepository.deleteAll(avisToDelete);
                
                // 2. Delete all notifications related to this trip
                List<Notification> notificationsToDelete = notificationRepository.findAll().stream()
                    .filter(notif -> notif.getMessage() != null && notif.getMessage().contains("Trip #" + tripId))
                    .collect(Collectors.toList());
                notificationRepository.deleteAll(notificationsToDelete);
                
                // 3. Get all reservations for this trip
                List<Reservation> reservations = reservationRepository.findAll().stream()
                    .filter(res -> res.getVoyageId() != null && res.getVoyageId().equals(tripId))
                    .collect(Collectors.toList());
                
                // 4. Delete all payments related to these reservations
                for (Reservation reservation : reservations) {
                    List<Paiement> payments = paiementRepository.findAll().stream()
                        .filter(payment -> payment.getReservationId() != null && 
                                payment.getReservationId().equals(reservation.getId()))
                        .collect(Collectors.toList());
                    paiementRepository.deleteAll(payments);
                }
                
                // 5. Delete all reservations for this trip
                reservationRepository.deleteAll(reservations);
                
                // 6. Delete all GPS points for this trip (IMPORTANT: must be deleted before the trip)
                List<Point_GPS> pointsGPS = pointGPSRepository.findByVoyageId(tripId);
                pointGPSRepository.deleteAll(pointsGPS);
                
                // 7. Finally, delete the trip itself
                voyageRepository.deleteById(tripId);
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new RuntimeException("Error deleting trip: " + e.getMessage());
        }
    }
    
    // City Management
    @Override
    public List<Map<String, Object>> getAllCities() {
        List<Ville> all = villeRepository.findAll();
        List<Map<String, Object>> out = new ArrayList<>(all.size());
        for (Ville v : all) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", v.getId());
            m.put("name", v.getName());
            // Provide both key styles to satisfy differing frontends
            m.put("codePostal", v.getCodePostal());
            m.put("code_postal", v.getCodePostal());
            m.put("pays", v.getPays());
            m.put("latitude", v.getLatitude());
            m.put("longitude", v.getLongitude());
            out.add(m);
        }
        return out;
    }
    
    @Override
    public Map<String, Object> addCity(Map<String, Object> cityData) {
        // Mock implementation - return the added city with an ID
        Map<String, Object> city = new HashMap<>(cityData);
        city.put("id", System.currentTimeMillis()); // Generate a mock ID
        return city;
    }
    
    @Override
    public Map<String, Object> updateCity(Long cityId, Map<String, Object> cityData) {
        // Mock implementation - return the updated city
        Map<String, Object> city = new HashMap<>(cityData);
        city.put("id", cityId);
        return city;
    }
    
    @Override
    public boolean deleteCity(Long cityId) {
        // Mock implementation - always return true
        return true;
    }
    
    @Override
    public Map<String, Double> getRevenueStatistics() {
        Map<String, Double> stats = new HashMap<>();
        stats.put("total", 1250.0);
        stats.put("today", 85.0);
        stats.put("week", 450.0);
        stats.put("month", 1250.0);
        return stats;
    }
    
    @Override
    public List<Map<String, Object>> getRevenueTrends(int days) {
        // Mock implementation
        List<Map<String, Object>> trends = new ArrayList<>();
        for (int i = days; i >= 0; i--) {
            Map<String, Object> day = new HashMap<>();
            day.put("date", LocalDateTime.now().minusDays(i).toLocalDate());
            day.put("revenue", 50.0 + (Math.random() * 100));
            trends.add(day);
        }
        return trends;
    }
    
    // Additional mock implementations for remaining methods
    @Override
    public Map<String, Object> getPaymentStatistics() {
        return Map.of(
            "total", paiementRepository.count(),
            "successful", paiementRepository.findAll().stream().filter(p -> p.getStatus().equals("COMPLETED")).count(),
            "failed", paiementRepository.findAll().stream().filter(p -> p.getStatus().equals("FAILED")).count()
        );
    }
    
    @Override
    public List<Map<String, Object>> getPaymentTrends(int days) {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public Map<String, Long> getPaymentMethodStatistics() {
        return Map.of("CREDIT_CARD", 45L, "BANK_TRANSFER", 30L, "CASH", 20L, "MOBILE_MONEY", 15L);
    }
    
    @Override
    public List<Map<String, Object>> getFailedPayments() {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public List<Map<String, Object>> getRefundRequests() {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public Map<String, Long> getRatingStatistics() {
        return Map.of(
            "total", avisRepository.count(),
            "pending", avisRepository.findAll().stream().filter(r -> r.getStatus() == null || r.getStatus().equals("PENDING")).count(),
            "approved", avisRepository.findAll().stream().filter(r -> r.getStatus() != null && r.getStatus().equals("APPROVED")).count()
        );
    }
    
    @Override
    public List<Map<String, Object>> getPendingRatings() {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public List<Map<String, Object>> getRatingTrends(int days) {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public boolean approveRating(Long ratingId) {
        return true; // Mock implementation
    }
    
    @Override
    public boolean rejectRating(Long ratingId, String reason) {
        return true; // Mock implementation
    }
    
    @Override
    public Map<String, Long> getNotificationStatistics() {
        return Map.of(
            "total", notificationRepository.count(),
            "unread", notificationRepository.countByStatus(Notification.NotificationStatus.UNREAD),
            "today", notificationRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(1))
        );
    }
    
    @Override
    public List<Map<String, Object>> getNotificationTrends(int days) {
        return new ArrayList<>(); // Mock implementation
    }
    
    @Override
    public boolean sendSystemAnnouncement(SystemAnnouncementRequest request) {
        try {
            List<User> targetUsers = new ArrayList<>();
            
            // Determine target users based on request
            if (request.getTargetUserType() == null || "ALL".equals(request.getTargetUserType())) {
                targetUsers = userRepository.findAll();
            } else if ("DRIVER".equals(request.getTargetUserType()) || "CONDUCTEUR".equals(request.getTargetUserType())) {
                targetUsers = userRepository.findByRole(UserRole.CONDUCTEUR);
            } else if ("PASSENGER".equals(request.getTargetUserType()) || "PASSAGER".equals(request.getTargetUserType())) {
                targetUsers = userRepository.findByRole(UserRole.PASSAGER);
            }
            
            // Create notification for each target user
            for (User user : targetUsers) {
                Notification notification = new Notification();
                notification.setUserId(user.getId());
                notification.setTitle(request.getTitle());
                notification.setMessage(request.getMessage());
                notification.setType(Notification.NotificationType.SYSTEM_ANNOUNCEMENT);
                notification.setStatus(Notification.NotificationStatus.UNREAD);
                notification.setCreatedAt(LocalDateTime.now());
                
                notificationRepository.save(notification);
                
                // Optionally send email notification
                try {
                    emailService.sendSystemAnnouncementEmail(
                        user.getEmail(),
                        request.getTitle(),
                        request.getMessage()
                    );
                    notification.setIsEmailSent(true);
                    notificationRepository.save(notification);
                } catch (Exception e) {
                    logger.error("Failed to send email notification to user: " + user.getId(), e);
                }
            }
            
            logger.info("System announcement sent to {} users", targetUsers.size());
            return true;
        } catch (Exception e) {
            logger.error("Error sending system announcement", e);
            return false;
        }
    }
    
    @Override
    public List<Map<String, Object>> getRecentNotifications(int limit) {
        try {
            // Get recent notifications ordered by creation date
            List<Notification> notifications = notificationRepository.findAll()
                .stream()
                .sorted((n1, n2) -> n2.getCreatedAt().compareTo(n1.getCreatedAt()))
                .limit(limit)
                .collect(Collectors.toList());
            
            return notifications.stream().map(notif -> {
                Map<String, Object> notifMap = new HashMap<>();
                notifMap.put("id", notif.getId());
                notifMap.put("title", notif.getTitle());
                notifMap.put("message", notif.getMessage());
                notifMap.put("type", notif.getType().toString());
                notifMap.put("status", notif.getStatus().toString());
                notifMap.put("createdAt", notif.getCreatedAt());
                notifMap.put("userId", notif.getUserId());
                notifMap.put("isEmailSent", notif.getIsEmailSent());
                return notifMap;
            }).collect(Collectors.toList());
        } catch (Exception e) {
            logger.error("Error fetching recent notifications", e);
            return new ArrayList<>();
        }
    }
    
    // Additional mock implementations for remaining methods
    @Override
    public Map<String, Object> getSystemMetrics() {
        return Map.of("cpu", "45%", "memory", "75%", "disk", "60%");
    }
    
    @Override
    public List<Map<String, Object>> getErrorLogs(int limit) {
        return new ArrayList<>();
    }
    
    @Override
    public List<Map<String, Object>> getPerformanceMetrics() {
        return new ArrayList<>();
    }
    
    @Override
    public boolean clearSystemCache() {
        return true;
    }
    
    @Override
    public Map<String, Object> getDatabaseStatistics() {
        return Map.of("connections", 25, "queries_per_second", 150);
    }
    
    // Report generation methods
    @Override
    public Map<String, Object> generateUserReport(String startDate, String endDate) {
        return Map.of("users", userRepository.count(), "period", startDate + " to " + endDate);
    }
    
    @Override
    public Map<String, Object> generateTripReport(String startDate, String endDate) {
        return Map.of("trips", voyageRepository.count(), "period", startDate + " to " + endDate);
    }
    
    @Override
    public Map<String, Object> generatePaymentReport(String startDate, String endDate) {
        return Map.of("payments", paiementRepository.count(), "period", startDate + " to " + endDate);
    }
    
    @Override
    public Map<String, Object> generateRatingReport(String startDate, String endDate) {
        return Map.of("ratings", avisRepository.count(), "period", startDate + " to " + endDate);
    }
    
    @Override
    public Map<String, Object> generateSystemReport() {
        return Map.of("system", "healthy", "timestamp", LocalDateTime.now());
    }
    
    // Analytics methods
    @Override
    public Map<String, Object> getUserAnalytics(int days) {
        return Map.of("new_users", userRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(days)));
    }
    
    @Override
    public Map<String, Object> getTripAnalytics(int days) {
        return Map.of("new_trips", voyageRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(days)));
    }
    
    @Override
    public Map<String, Object> getRevenueAnalytics(int days) {
        return Map.of("revenue", calculateRevenueForPeriod(days));
    }
    
    @Override
    public Map<String, Object> getPerformanceAnalytics(int days) {
        return Map.of("performance", "good", "days", days);
    }
    
    // Security and moderation methods
    @Override
    public List<Map<String, Object>> getSuspiciousActivities() {
        return new ArrayList<>();
    }
    
    @Override
    public List<Map<String, Object>> getReportedUsers() {
        return new ArrayList<>();
    }
    
    @Override
    public boolean moderateUser(Long userId, String action, String reason) {
        return updateUserStatus(userId, action, reason) != null;
    }
    
    @Override
    public List<Map<String, Object>> getSecurityAlerts() {
        return new ArrayList<>();
    }
    
    @Override
    public boolean deleteBooking(Long bookingId) {
        try {
            if (reservationRepository.existsById(bookingId)) {
                reservationRepository.deleteById(bookingId);
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete booking: " + e.getMessage());
        }
    }
}
