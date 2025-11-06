package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.dto.AdminDashboardStats;
import esprit.pfe.covoiturage_final.services.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/test/sprint4")
@CrossOrigin(origins = "*")
public class Sprint4TestController {
    
    @Autowired
    private AdminService adminService;
    
    /**
     * Test Sprint 4 status
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getSprint4Status() {
        Map<String, Object> status = new HashMap<>();
        status.put("sprint", "Sprint 4: Admin Dashboard & Analytics");
        status.put("status", "IN_PROGRESS");
        status.put("version", "v2.0.0-SNAPSHOT");
        status.put("description", "Admin Dashboard with comprehensive analytics and management features");
        status.put("timestamp", java.time.LocalDateTime.now());
        
        // Test admin service
        try {
            AdminDashboardStats stats = adminService.getAdminDashboardStats();
            status.put("adminService", "WORKING");
            status.put("totalUsers", stats.getTotalUsers());
            status.put("totalTrips", stats.getTotalTrips());
            status.put("totalRevenue", stats.getTotalRevenue());
        } catch (Exception e) {
            status.put("adminService", "ERROR: " + e.getMessage());
        }
        
        return ResponseEntity.ok(status);
    }
    
    /**
     * Test admin dashboard features
     */
    @GetMapping("/features")
    public ResponseEntity<Map<String, Object>> getSprint4Features() {
        Map<String, Object> features = new HashMap<>();
        
        // Core Admin Features
        Map<String, Object> coreFeatures = new HashMap<>();
        coreFeatures.put("userManagement", "Complete user management with CRUD operations");
        coreFeatures.put("tripAnalytics", "Comprehensive trip statistics and analytics");
        coreFeatures.put("paymentAnalytics", "Revenue tracking and payment statistics");
        coreFeatures.put("ratingManagement", "Rating moderation and approval system");
        coreFeatures.put("systemMonitoring", "Real-time system health and performance monitoring");
        coreFeatures.put("notificationManagement", "System announcement and notification management");
        
        // Analytics Dashboard
        Map<String, Object> analyticsFeatures = new HashMap<>();
        analyticsFeatures.put("realTimeMetrics", "Live dashboard with key performance indicators");
        analyticsFeatures.put("financialReports", "Revenue analysis and financial reporting");
        analyticsFeatures.put("userBehavior", "User activity and engagement analytics");
        analyticsFeatures.put("performanceMetrics", "System performance and optimization metrics");
        
        // Management Tools
        Map<String, Object> managementTools = new HashMap<>();
        managementTools.put("userModeration", "User suspension, activation, and verification");
        managementTools.put("contentModeration", "Rating and review moderation system");
        managementTools.put("systemMaintenance", "Cache clearing and system optimization");
        managementTools.put("reportGeneration", "Comprehensive reporting system");
        
        // Security Features
        Map<String, Object> securityFeatures = new HashMap<>();
        securityFeatures.put("suspiciousActivity", "Detection and monitoring of suspicious activities");
        securityFeatures.put("userReporting", "User reporting and moderation system");
        securityFeatures.put("securityAlerts", "Real-time security monitoring and alerts");
        securityFeatures.put("accessControl", "Role-based access control for admin functions");
        
        features.put("coreFeatures", coreFeatures);
        features.put("analyticsFeatures", analyticsFeatures);
        features.put("managementTools", managementTools);
        features.put("securityFeatures", securityFeatures);
        features.put("apiEndpoints", getApiEndpoints());
        features.put("status", "IMPLEMENTED");
        
        return ResponseEntity.ok(features);
    }
    
    /**
     * Test admin dashboard statistics
     */
    @GetMapping("/dashboard-test")
    public ResponseEntity<AdminDashboardStats> testDashboardStats() {
        try {
            AdminDashboardStats stats = adminService.getAdminDashboardStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test system health
     */
    @GetMapping("/system-health")
    public ResponseEntity<Map<String, Object>> testSystemHealth() {
        try {
            Map<String, Object> health = adminService.getSystemHealth();
            return ResponseEntity.ok(health);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test popular routes
     */
    @GetMapping("/popular-routes")
    public ResponseEntity<List<AdminDashboardStats.PopularRoute>> testPopularRoutes() {
        try {
            List<AdminDashboardStats.PopularRoute> routes = adminService.getPopularRoutes(5);
            return ResponseEntity.ok(routes);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test top drivers
     */
    @GetMapping("/top-drivers")
    public ResponseEntity<List<AdminDashboardStats.TopDriver>> testTopDrivers() {
        try {
            List<AdminDashboardStats.TopDriver> drivers = adminService.getTopDrivers(5);
            return ResponseEntity.ok(drivers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test user statistics
     */
    @GetMapping("/user-stats")
    public ResponseEntity<Map<String, Long>> testUserStatistics() {
        try {
            Map<String, Long> stats = adminService.getUserStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test trip statistics
     */
    @GetMapping("/trip-stats")
    public ResponseEntity<Map<String, Long>> testTripStatistics() {
        try {
            Map<String, Long> stats = adminService.getTripStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test payment statistics
     */
    @GetMapping("/payment-stats")
    public ResponseEntity<Map<String, Object>> testPaymentStatistics() {
        try {
            Map<String, Object> stats = adminService.getPaymentStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test rating statistics
     */
    @GetMapping("/rating-stats")
    public ResponseEntity<Map<String, Long>> testRatingStatistics() {
        try {
            Map<String, Long> stats = adminService.getRatingStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test notification statistics
     */
    @GetMapping("/notification-stats")
    public ResponseEntity<Map<String, Long>> testNotificationStatistics() {
        try {
            Map<String, Long> stats = adminService.getNotificationStatistics();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    /**
     * Test system metrics
     */
    @GetMapping("/system-metrics")
    public ResponseEntity<Map<String, Object>> testSystemMetrics() {
        try {
            Map<String, Object> metrics = adminService.getSystemMetrics();
            return ResponseEntity.ok(metrics);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    private Map<String, Object> getApiEndpoints() {
        Map<String, Object> endpoints = new HashMap<>();
        
        // Dashboard endpoints
        Map<String, String> dashboardEndpoints = new HashMap<>();
        dashboardEndpoints.put("GET /api/admin/dashboard/stats", "Get comprehensive dashboard statistics");
        dashboardEndpoints.put("GET /api/admin/system/health", "Get system health status");
        dashboardEndpoints.put("GET /api/admin/analytics/popular-routes", "Get popular routes");
        dashboardEndpoints.put("GET /api/admin/analytics/top-drivers", "Get top performing drivers");
        dashboardEndpoints.put("GET /api/admin/analytics/top-passengers", "Get top passengers");
        
        // User management endpoints
        Map<String, String> userEndpoints = new HashMap<>();
        userEndpoints.put("GET /api/admin/users", "Get all users with pagination");
        userEndpoints.put("GET /api/admin/users/role/{role}", "Get users by role");
        userEndpoints.put("GET /api/admin/users/status/{status}", "Get users by status");
        userEndpoints.put("GET /api/admin/users/search", "Search users");
        userEndpoints.put("PUT /api/admin/users/{userId}/status", "Update user status");
        userEndpoints.put("POST /api/admin/users/{userId}/suspend", "Suspend user");
        userEndpoints.put("POST /api/admin/users/{userId}/activate", "Activate user");
        userEndpoints.put("POST /api/admin/users/{userId}/verify", "Verify user");
        userEndpoints.put("DELETE /api/admin/users/{userId}", "Delete user");
        
        // Analytics endpoints
        Map<String, String> analyticsEndpoints = new HashMap<>();
        analyticsEndpoints.put("GET /api/admin/trips/statistics", "Get trip statistics");
        analyticsEndpoints.put("GET /api/admin/trips/trends", "Get trip trends");
        analyticsEndpoints.put("GET /api/admin/payments/statistics", "Get payment statistics");
        analyticsEndpoints.put("GET /api/admin/payments/trends", "Get payment trends");
        analyticsEndpoints.put("GET /api/admin/ratings/statistics", "Get rating statistics");
        analyticsEndpoints.put("GET /api/admin/notifications/statistics", "Get notification statistics");
        
        // Management endpoints
        Map<String, String> managementEndpoints = new HashMap<>();
        managementEndpoints.put("POST /api/admin/ratings/{ratingId}/approve", "Approve rating");
        managementEndpoints.put("POST /api/admin/ratings/{ratingId}/reject", "Reject rating");
        managementEndpoints.put("POST /api/admin/notifications/announcement", "Send system announcement");
        managementEndpoints.put("POST /api/admin/system/cache/clear", "Clear system cache");
        
        // Report endpoints
        Map<String, String> reportEndpoints = new HashMap<>();
        reportEndpoints.put("GET /api/admin/reports/users", "Generate user report");
        reportEndpoints.put("GET /api/admin/reports/trips", "Generate trip report");
        reportEndpoints.put("GET /api/admin/reports/payments", "Generate payment report");
        reportEndpoints.put("GET /api/admin/reports/system", "Generate system report");
        
        // Security endpoints
        Map<String, String> securityEndpoints = new HashMap<>();
        securityEndpoints.put("GET /api/admin/security/suspicious", "Get suspicious activities");
        securityEndpoints.put("GET /api/admin/security/reported", "Get reported users");
        securityEndpoints.put("POST /api/admin/security/moderate/{userId}", "Moderate user");
        securityEndpoints.put("GET /api/admin/security/alerts", "Get security alerts");
        
        endpoints.put("dashboard", dashboardEndpoints);
        endpoints.put("userManagement", userEndpoints);
        endpoints.put("analytics", analyticsEndpoints);
        endpoints.put("management", managementEndpoints);
        endpoints.put("reports", reportEndpoints);
        endpoints.put("security", securityEndpoints);
        
        return endpoints;
    }
}






































































