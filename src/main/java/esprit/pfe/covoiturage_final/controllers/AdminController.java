package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.services.AdminServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {
    
    @Autowired
    private AdminServiceImpl adminService;
    
    @Autowired
    private esprit.pfe.covoiturage_final.services.CsvExportService csvExportService;
    
    // ==================== DASHBOARD & STATISTICS ====================
    
    /**
     * Fix city links for existing voyages
     */
    @PostMapping("/fix-city-links")
    public ResponseEntity<Map<String, Object>> fixCityLinks() {
        try {
            Map<String, Object> result = adminService.fixCityLinks();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test endpoint to check city data for a specific trip
     */
    @GetMapping("/test-trip-cities/{tripId}")
    public ResponseEntity<Map<String, Object>> testTripCities(@PathVariable Long tripId) {
        try {
            Map<String, Object> result = adminService.testTripCities(tripId);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Clean up duplicate trips from database
     */
    @PostMapping("/cleanup-duplicates")
    public ResponseEntity<Map<String, Object>> cleanupDuplicates() {
        try {
            Map<String, Object> result = adminService.cleanupDuplicateTrips();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Reset database to clean state
     */
    @PostMapping("/reset-database")
    public ResponseEntity<Map<String, Object>> resetDatabase() {
        try {
            Map<String, Object> result = adminService.resetDatabase();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Clean up and recreate trips with proper city IDs
     */
    @PostMapping("/recreate-trips")
    public ResponseEntity<Map<String, Object>> recreateTrips() {
        try {
            Map<String, Object> result = adminService.recreateTrips();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Populate database with sample data
     */
    @PostMapping("/populate-database")
    public ResponseEntity<Map<String, Object>> populateDatabase() {
        try {
            Map<String, Object> result = adminService.populateDatabase();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Reset and/or seed Tunisian cities with names, postal codes and GPS
     */
    @PostMapping("/seed-tunisia-cities")
    public ResponseEntity<Map<String, Object>> seedTunisiaCities(
            @RequestParam(defaultValue = "false") boolean reset) {
        try {
            Map<String, Object> result = adminService.seedTunisiaCities(reset);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Seed default trip options (icons + zero price)
     */
    @PostMapping("/seed-options")
    public ResponseEntity<Map<String, Object>> seedDefaultOptions(
            @RequestParam(defaultValue = "false") boolean reset) {
        try {
            Map<String, Object> result = adminService.seedDefaultOptions(reset);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get comprehensive admin dashboard statistics
     */
    @GetMapping("/dashboard/stats")
    public ResponseEntity<AdminDashboardStats> getDashboardStats() {
        try {
            AdminDashboardStats stats = adminService.getAdminDashboardStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get system health status
     */
    @GetMapping("/system/health")
    public ResponseEntity<Map<String, Object>> getSystemHealth() {
        try {
            Map<String, Object> health = adminService.getSystemHealth();
            return ResponseEntity.ok(health);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Analytics endpoints moved to AnalyticsController to avoid mapping conflicts
    
    // ==================== RECENT ACTIVITY ====================
    
    /**
     * Get recent activity for admin dashboard
     */
    @GetMapping("/recent-activity")
    public ResponseEntity<List<Map<String, Object>>> getRecentActivity() {
        try {
            List<Map<String, Object>> activity = adminService.getRecentActivity();
            return ResponseEntity.ok(activity);
        } catch (Exception e) {
            return ResponseEntity.ok(new ArrayList<>()); // Return empty list on error
        }
    }
    
    // ==================== BOOKING MANAGEMENT ====================
    
    /**
     * Get all bookings for admin dashboard
     */
    @GetMapping("/bookings")
    public ResponseEntity<List<Map<String, Object>>> getAllBookings() {
        try {
            List<Map<String, Object>> bookings = adminService.getAllBookings();
            return ResponseEntity.ok(bookings);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Delete a booking (Admin only)
     */
    @DeleteMapping("/bookings/{bookingId}")
    public ResponseEntity<?> deleteBooking(@PathVariable Long bookingId) {
        try {
            boolean deleted = adminService.deleteBooking(bookingId);
            if (deleted) {
                return ResponseEntity.ok().body(Map.of("message", "Booking deleted successfully"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    /**
     * Resolve a booking (Admin only) - PENDING -> CONFIRMED, CONFIRMED -> COMPLETED
     */
    @PutMapping("/bookings/{bookingId}/resolve")
    public ResponseEntity<?> resolveBooking(@PathVariable Long bookingId) {
        try {
            boolean resolved = adminService.resolveBooking(bookingId);
            if (resolved) {
                return ResponseEntity.ok().body(Map.of("message", "Booking resolved successfully"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    // ==================== USER MANAGEMENT ====================
    
    /**
     * Get all users with pagination
     */
    @GetMapping("/users")
    public ResponseEntity<Page<User>> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        try {
            Sort sort = sortDir.equalsIgnoreCase("desc") ? 
                Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<User> users = adminService.getAllUsers(pageable);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get users by role
     */
    @GetMapping("/users/role/{role}")
    public ResponseEntity<Page<User>> getUsersByRole(
            @PathVariable String role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<User> users = adminService.getUsersByRole(role, pageable);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get users by status
     */
    @GetMapping("/users/status/{status}")
    public ResponseEntity<Page<User>> getUsersByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<User> users = adminService.getUsersByStatus(status, pageable);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Search users
     */
    @GetMapping("/users/search")
    public ResponseEntity<List<User>> searchUsers(@RequestParam String query) {
        try {
            List<User> users = adminService.searchUsers(query);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get user by ID
     */
    @GetMapping("/users/{userId}")
    public ResponseEntity<User> getUserById(@PathVariable Long userId) {
        try {
            User user = adminService.getUserById(userId);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Update user status
     */
    @PutMapping("/users/{userId}/status")
    public ResponseEntity<User> updateUserStatus(
            @PathVariable Long userId,
            @RequestBody UserManagementRequest request) {
        try {
            User user = adminService.updateUserStatus(userId, request.getAction(), request.getReason());
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Suspend user
     */
    @PostMapping("/users/{userId}/suspend")
    public ResponseEntity<User> suspendUser(
            @PathVariable Long userId,
            @RequestBody UserManagementRequest request) {
        try {
            User user = adminService.suspendUser(userId, request.getReason(), request.getSuspensionEndDate());
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Activate user
     */
    @PostMapping("/users/{userId}/activate")
    public ResponseEntity<User> activateUser(@PathVariable Long userId) {
        try {
            User user = adminService.activateUser(userId);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Verify user
     */
    @PostMapping("/users/{userId}/verify")
    public ResponseEntity<User> verifyUser(@PathVariable Long userId) {
        try {
            User user = adminService.verifyUser(userId);
            if (user != null) {
                return ResponseEntity.ok(user);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Delete user
     */
    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Map<String, String>> deleteUser(@PathVariable Long userId) {
        try {
            boolean deleted = adminService.deleteUser(userId);
            if (deleted) {
                return ResponseEntity.ok(Map.of("message", "User deleted successfully"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get user statistics
     */
    @GetMapping("/users/statistics")
    public ResponseEntity<Map<String, Long>> getUserStatistics() {
        try {
            Map<String, Long> stats = adminService.getUserStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get recently registered users
     */
    @GetMapping("/users/recent")
    public ResponseEntity<List<User>> getRecentlyRegisteredUsers(
            @RequestParam(defaultValue = "7") int days) {
        try {
            List<User> users = adminService.getRecentlyRegisteredUsers(days);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get inactive users
     */
    @GetMapping("/users/inactive")
    public ResponseEntity<List<User>> getInactiveUsers(
            @RequestParam(defaultValue = "30") int days) {
        try {
            List<User> users = adminService.getInactiveUsers(days);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== TRIP MANAGEMENT ====================
    
    /**
     * Get all trips with pagination
     */
    @GetMapping("/trips")
    public ResponseEntity<Page<Map<String, Object>>> getAllTrips(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        try {
            Sort sort = sortDir.equalsIgnoreCase("desc") ? 
                Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<Map<String, Object>> trips = adminService.getAllTrips(pageable);
            return ResponseEntity.ok(trips);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get trip statistics
     */
    @GetMapping("/trips/statistics")
    public ResponseEntity<Map<String, Long>> getTripStatistics() {
        try {
            Map<String, Long> stats = adminService.getTripStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get trip trends
     */
    @GetMapping("/trips/trends")
    public ResponseEntity<List<Map<String, Object>>> getTripTrends(
            @RequestParam(defaultValue = "30") int days) {
        try {
            List<Map<String, Object>> trends = adminService.getTripTrends(days);
            return ResponseEntity.ok(trends);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Delete a trip (Admin only)
     */
    @DeleteMapping("/trips/{tripId}")
    public ResponseEntity<?> deleteTrip(@PathVariable Long tripId) {
        try {
            boolean deleted = adminService.deleteTrip(tripId);
            if (deleted) {
                return ResponseEntity.ok().body(Map.of("message", "Trip deleted successfully"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    /**
     * Get popular destinations
     */
    @GetMapping("/trips/popular-destinations")
    public ResponseEntity<List<Map<String, Object>>> getPopularDestinations(
            @RequestParam(defaultValue = "10") int limit) {
        try {
            List<Map<String, Object>> destinations = adminService.getPopularDestinations(limit);
            return ResponseEntity.ok(destinations);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== CITY MANAGEMENT ====================
    
    /**
     * Get all cities
     */
    @GetMapping("/cities")
    public ResponseEntity<List<Map<String, Object>>> getAllCities() {
        try {
            List<Map<String, Object>> cities = adminService.getAllCities();
            return ResponseEntity.ok(cities);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Add new city
     */
    @PostMapping("/cities")
    public ResponseEntity<Map<String, Object>> addCity(@RequestBody Map<String, Object> cityData) {
        try {
            Map<String, Object> city = adminService.addCity(cityData);
            return ResponseEntity.ok(city);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Update city
     */
    @PutMapping("/cities/{cityId}")
    public ResponseEntity<Map<String, Object>> updateCity(
            @PathVariable Long cityId,
            @RequestBody Map<String, Object> cityData) {
        try {
            Map<String, Object> city = adminService.updateCity(cityId, cityData);
            if (city != null) {
                return ResponseEntity.ok(city);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Delete city
     */
    @DeleteMapping("/cities/{cityId}")
    public ResponseEntity<Map<String, String>> deleteCity(@PathVariable Long cityId) {
        try {
            boolean deleted = adminService.deleteCity(cityId);
            if (deleted) {
                return ResponseEntity.ok(Map.of("message", "City deleted successfully"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== PAYMENT MANAGEMENT ====================
    
    /**
     * Get payment statistics
     */
    @GetMapping("/payments/statistics")
    public ResponseEntity<Map<String, Object>> getPaymentStatistics() {
        try {
            Map<String, Object> stats = adminService.getPaymentStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get payment trends
     */
    @GetMapping("/payments/trends")
    public ResponseEntity<List<Map<String, Object>>> getPaymentTrends(
            @RequestParam(defaultValue = "30") int days) {
        try {
            List<Map<String, Object>> trends = adminService.getPaymentTrends(days);
            return ResponseEntity.ok(trends);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get payment method statistics
     */
    @GetMapping("/payments/methods")
    public ResponseEntity<Map<String, Long>> getPaymentMethodStatistics() {
        try {
            Map<String, Long> stats = adminService.getPaymentMethodStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get failed payments
     */
    @GetMapping("/payments/failed")
    public ResponseEntity<List<Map<String, Object>>> getFailedPayments() {
        try {
            List<Map<String, Object>> failedPayments = adminService.getFailedPayments();
            return ResponseEntity.ok(failedPayments);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== RATING MANAGEMENT ====================
    
    /**
     * Get rating statistics
     */
    @GetMapping("/ratings/statistics")
    public ResponseEntity<Map<String, Long>> getRatingStatistics() {
        try {
            Map<String, Long> stats = adminService.getRatingStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get pending ratings
     */
    @GetMapping("/ratings/pending")
    public ResponseEntity<List<Map<String, Object>>> getPendingRatings() {
        try {
            List<Map<String, Object>> pendingRatings = adminService.getPendingRatings();
            return ResponseEntity.ok(pendingRatings);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Approve rating
     */
    @PostMapping("/ratings/{ratingId}/approve")
    public ResponseEntity<Map<String, String>> approveRating(@PathVariable Long ratingId) {
        try {
            boolean approved = adminService.approveRating(ratingId);
            if (approved) {
                return ResponseEntity.ok(Map.of("message", "Rating approved successfully"));
            } else {
                return ResponseEntity.badRequest().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Reject rating
     */
    @PostMapping("/ratings/{ratingId}/reject")
    public ResponseEntity<Map<String, String>> rejectRating(
            @PathVariable Long ratingId,
            @RequestBody Map<String, String> request) {
        try {
            String reason = request.get("reason");
            boolean rejected = adminService.rejectRating(ratingId, reason);
            if (rejected) {
                return ResponseEntity.ok(Map.of("message", "Rating rejected successfully"));
            } else {
                return ResponseEntity.badRequest().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== NOTIFICATION MANAGEMENT ====================
    
    /**
     * Get notification statistics
     */
    @GetMapping("/notifications/statistics")
    public ResponseEntity<Map<String, Long>> getNotificationStatistics() {
        try {
            Map<String, Long> stats = adminService.getNotificationStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Send system announcement
     */
    @PostMapping("/notifications/announcement")
    public ResponseEntity<Map<String, String>> sendSystemAnnouncement(
            @RequestBody SystemAnnouncementRequest request) {
        try {
            boolean sent = adminService.sendSystemAnnouncement(request);
            if (sent) {
                return ResponseEntity.ok(Map.of("message", "Announcement sent successfully"));
            } else {
                return ResponseEntity.badRequest().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get recent notifications
     */
    @GetMapping("/notifications/recent")
    public ResponseEntity<List<Map<String, Object>>> getRecentNotifications(
            @RequestParam(defaultValue = "10") int limit) {
        try {
            List<Map<String, Object>> notifications = adminService.getRecentNotifications(limit);
            return ResponseEntity.ok(notifications);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== CACHE MANAGEMENT ====================
    
    /**
     * Force cache clear - returns current timestamp for cache busting
     */
    @GetMapping("/cache/clear")
    public ResponseEntity<Map<String, Object>> clearCache() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", System.currentTimeMillis());
        response.put("message", "Cache cleared successfully");
        response.put("action", "Please refresh your browser (Ctrl+F5 or Cmd+Shift+R)");
        return ResponseEntity.ok()
                .header("Cache-Control", "no-cache, no-store, must-revalidate")
                .header("Pragma", "no-cache")
                .header("Expires", "0")
                .body(response);
    }
    
    // ==================== SYSTEM MONITORING ====================
    
    /**
     * Get system metrics
     */
    @GetMapping("/system/metrics")
    public ResponseEntity<Map<String, Object>> getSystemMetrics() {
        try {
            Map<String, Object> metrics = adminService.getSystemMetrics();
            return ResponseEntity.ok(metrics);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get error logs
     */
    @GetMapping("/system/errors")
    public ResponseEntity<List<Map<String, Object>>> getErrorLogs(
            @RequestParam(defaultValue = "50") int limit) {
        try {
            List<Map<String, Object>> errors = adminService.getErrorLogs(limit);
            return ResponseEntity.ok(errors);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Clear system cache
     */
    @PostMapping("/system/cache/clear")
    public ResponseEntity<Map<String, String>> clearSystemCache() {
        try {
            boolean cleared = adminService.clearSystemCache();
            if (cleared) {
                return ResponseEntity.ok(Map.of("message", "System cache cleared successfully"));
            } else {
                return ResponseEntity.badRequest().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== REPORTS ====================
    
    /**
     * Generate user report
     */
    @GetMapping("/reports/users")
    public ResponseEntity<Map<String, Object>> generateUserReport(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            Map<String, Object> report = adminService.generateUserReport(startDate, endDate);
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Generate trip report
     */
    @GetMapping("/reports/trips")
    public ResponseEntity<Map<String, Object>> generateTripReport(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            Map<String, Object> report = adminService.generateTripReport(startDate, endDate);
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Generate payment report
     */
    @GetMapping("/reports/payments")
    public ResponseEntity<Map<String, Object>> generatePaymentReport(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            Map<String, Object> report = adminService.generatePaymentReport(startDate, endDate);
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Generate system report
     */
    @GetMapping("/reports/system")
    public ResponseEntity<Map<String, Object>> generateSystemReport() {
        try {
            Map<String, Object> report = adminService.generateSystemReport();
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== ANALYTICS ====================
    // All analytics endpoints have been moved to AnalyticsController to avoid mapping conflicts
    
    // ==================== SECURITY & MODERATION ====================
    
    /**
     * Get suspicious activities
     */
    @GetMapping("/security/suspicious")
    public ResponseEntity<List<Map<String, Object>>> getSuspiciousActivities() {
        try {
            List<Map<String, Object>> activities = adminService.getSuspiciousActivities();
            return ResponseEntity.ok(activities);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get reported users
     */
    @GetMapping("/security/reported")
    public ResponseEntity<List<Map<String, Object>>> getReportedUsers() {
        try {
            List<Map<String, Object>> reportedUsers = adminService.getReportedUsers();
            return ResponseEntity.ok(reportedUsers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Moderate user
     */
    @PostMapping("/security/moderate/{userId}")
    public ResponseEntity<Map<String, String>> moderateUser(
            @PathVariable Long userId,
            @RequestBody Map<String, String> request) {
        try {
            String action = request.get("action");
            String reason = request.get("reason");
            boolean moderated = adminService.moderateUser(userId, action, reason);
            if (moderated) {
                return ResponseEntity.ok(Map.of("message", "User moderated successfully"));
            } else {
                return ResponseEntity.badRequest().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Get security alerts
     */
    @GetMapping("/security/alerts")
    public ResponseEntity<List<Map<String, Object>>> getSecurityAlerts() {
        try {
            List<Map<String, Object>> alerts = adminService.getSecurityAlerts();
            return ResponseEntity.ok(alerts);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // ==================== EXPORT ENDPOINTS ====================
    
    /**
     * Export users to CSV
     */
    @GetMapping(value = "/export/csv/users", produces = "text/csv")
    public ResponseEntity<String> exportUsersCSV() {
        try {
            String csv = csvExportService.exportUsers();
            return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=users.csv")
                .body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Export trips to CSV
     */
    @GetMapping(value = "/export/csv/trips", produces = "text/csv")
    public ResponseEntity<String> exportTripsCSV() {
        try {
            String csv = csvExportService.exportTrips();
            return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=trips.csv")
                .body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Export bookings to CSV
     */
    @GetMapping(value = "/export/csv/bookings", produces = "text/csv")
    public ResponseEntity<String> exportBookingsCSV() {
        try {
            String csv = csvExportService.exportBookings();
            return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=bookings.csv")
                .body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Export payments to CSV
     */
    @GetMapping(value = "/export/csv/payments", produces = "text/csv")
    public ResponseEntity<String> exportPaymentsCSV() {
        try {
            String csv = csvExportService.exportPayments();
            return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=payments.csv")
                .body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
