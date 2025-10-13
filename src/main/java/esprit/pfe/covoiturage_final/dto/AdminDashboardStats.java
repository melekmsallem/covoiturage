package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AdminDashboardStats {
    
    // User Statistics
    private long totalUsers;
    private long activeUsers;
    private long newUsersToday;
    private long newUsersThisWeek;
    private long newUsersThisMonth;
    private long totalDrivers;
    private long totalPassengers;
    private long verifiedUsers;
    private long suspendedUsers;
    
    // Trip Statistics
    private long totalTrips;
    private long activeTrips;
    private long completedTrips;
    private long cancelledTrips;
    private long tripsToday;
    private long tripsThisWeek;
    private long tripsThisMonth;
    private double averageTripRating;
    private double tripCompletionRate;
    
    // Booking Statistics
    private long totalBookings;
    private long pendingBookings;
    private long confirmedBookings;
    private long cancelledBookings;
    private long completedBookings;
    private double bookingSuccessRate;
    
    // Payment Statistics
    private double totalRevenue;
    private double revenueToday;
    private double revenueThisWeek;
    private double revenueThisMonth;
    private long totalPayments;
    private long successfulPayments;
    private long failedPayments;
    private double paymentSuccessRate;
    private double averagePaymentAmount;
    
    // Rating Statistics
    private long totalRatings;
    private double averageRating;
    private long pendingRatings;
    private long approvedRatings;
    private long rejectedRatings;
    
    // Notification Statistics
    private long totalNotifications;
    private long unreadNotifications;
    private long notificationsToday;
    private long notificationsThisWeek;
    
    // System Health
    private boolean systemHealthy;
    private String lastSystemCheck;
    private long activeConnections;
    private double systemUptime;
    
    // Popular Routes
    private List<PopularRoute> popularRoutes;
    
    // User Activity Trends
    private Map<String, Long> userActivityByDay;
    private Map<String, Long> tripActivityByDay;
    private Map<String, Double> revenueByDay;
    
    // Top Performers
    private List<TopDriver> topDrivers;
    private List<TopPassenger> topPassengers;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PopularRoute {
        private String fromCity;
        private String toCity;
        private long tripCount;
        private double averagePrice;
        private double averageRating;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopDriver {
        private Long userId;
        private String username;
        private String fullName;
        private long totalTrips;
        private double averageRating;
        private double totalEarnings;
        private long totalPassengers;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopPassenger {
        private Long userId;
        private String username;
        private String fullName;
        private long totalBookings;
        private double averageRating;
        private double totalSpent;
        private long completedTrips;
    }
}
