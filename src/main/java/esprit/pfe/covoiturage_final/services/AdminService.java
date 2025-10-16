package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface AdminService {
    
    // Dashboard Statistics
    AdminDashboardStats getAdminDashboardStats();
    Map<String, Object> getSystemHealth();
    Map<String, Object> fixCityLinks();
    Map<String, Object> testTripCities(Long tripId);
    Map<String, Object> cleanupDuplicateTrips();
    Map<String, Object> resetDatabase();
    Map<String, Object> recreateTrips();
    Map<String, Object> populateDatabase();
    Map<String, Object> seedTunisiaCities(boolean reset);
    Map<String, Object> seedDefaultOptions(boolean reset);
    List<AdminDashboardStats.PopularRoute> getPopularRoutes(int limit);
    List<AdminDashboardStats.TopDriver> getTopDrivers(int limit);
    List<AdminDashboardStats.TopPassenger> getTopPassengers(int limit);
    
    // Recent Activity
    List<Map<String, Object>> getRecentActivity();
    
    // Booking Management
    List<Map<String, Object>> getAllBookings();
    
    // User Management
    Page<User> getAllUsers(Pageable pageable);
    Page<User> getUsersByRole(String role, Pageable pageable);
    Page<User> getUsersByStatus(String status, Pageable pageable);
    List<User> searchUsers(String query);
    User getUserById(Long userId);
    User updateUserStatus(Long userId, String action, String reason);
    User suspendUser(Long userId, String reason, LocalDateTime suspensionEndDate);
    User activateUser(Long userId);
    User verifyUser(Long userId);
    boolean deleteUser(Long userId);
    Map<String, Long> getUserStatistics();
    List<User> getRecentlyRegisteredUsers(int days);
    List<User> getInactiveUsers(int days);
    
    // Trip Management
    Page<Map<String, Object>> getAllTrips(Pageable pageable);
    Map<String, Long> getTripStatistics();
    List<Map<String, Object>> getTripTrends(int days);
    List<Map<String, Object>> getPopularDestinations(int limit);
    boolean deleteTrip(Long tripId);
    boolean deleteBooking(Long bookingId);
    
    // City Management
    List<Map<String, Object>> getAllCities();
    Map<String, Object> addCity(Map<String, Object> cityData);
    Map<String, Object> updateCity(Long cityId, Map<String, Object> cityData);
    boolean deleteCity(Long cityId);
    Map<String, Double> getRevenueStatistics();
    List<Map<String, Object>> getRevenueTrends(int days);
    
    // Payment Management
    Map<String, Object> getPaymentStatistics();
    List<Map<String, Object>> getPaymentTrends(int days);
    Map<String, Long> getPaymentMethodStatistics();
    List<Map<String, Object>> getFailedPayments();
    List<Map<String, Object>> getRefundRequests();
    
    // Rating Management
    Map<String, Long> getRatingStatistics();
    List<Map<String, Object>> getPendingRatings();
    List<Map<String, Object>> getRatingTrends(int days);
    boolean approveRating(Long ratingId);
    boolean rejectRating(Long ratingId, String reason);
    
    // Notification Management
    Map<String, Long> getNotificationStatistics();
    List<Map<String, Object>> getNotificationTrends(int days);
    boolean sendSystemAnnouncement(SystemAnnouncementRequest request);
    List<Map<String, Object>> getRecentNotifications(int limit);
    
    // System Monitoring
    Map<String, Object> getSystemMetrics();
    List<Map<String, Object>> getErrorLogs(int limit);
    List<Map<String, Object>> getPerformanceMetrics();
    boolean clearSystemCache();
    Map<String, Object> getDatabaseStatistics();
    
    // Reports Generation
    Map<String, Object> generateUserReport(String startDate, String endDate);
    Map<String, Object> generateTripReport(String startDate, String endDate);
    Map<String, Object> generatePaymentReport(String startDate, String endDate);
    Map<String, Object> generateRatingReport(String startDate, String endDate);
    Map<String, Object> generateSystemReport();
    
    // Analytics
    Map<String, Object> getUserAnalytics(int days);
    Map<String, Object> getTripAnalytics(int days);
    Map<String, Object> getRevenueAnalytics(int days);
    Map<String, Object> getPerformanceAnalytics(int days);
    
    // Security and Moderation
    List<Map<String, Object>> getSuspiciousActivities();
    List<Map<String, Object>> getReportedUsers();
    boolean moderateUser(Long userId, String action, String reason);
    List<Map<String, Object>> getSecurityAlerts();
}

