package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.services.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/analytics")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AnalyticsController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private PaymentService paymentService;

    @GetMapping("/revenue")
    public ResponseEntity<Map<String, Object>> getRevenueAnalytics(
            @RequestParam(required = false) String period) {
        
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            // Total revenue
            Double totalRevenue = paymentService.getTotalRevenue();
            analytics.put("totalRevenue", totalRevenue != null ? totalRevenue : 0.0);
            
            // Revenue by period
            LocalDateTime startDate;
            String periodLabel;
            
            switch (period != null ? period.toLowerCase() : "month") {
                case "week":
                    startDate = LocalDateTime.now().minusDays(7);
                    periodLabel = "Last 7 Days";
                    break;
                case "year":
                    startDate = LocalDateTime.now().minusYears(1);
                    periodLabel = "Last Year";
                    break;
                default:
                    startDate = LocalDateTime.now().minusMonths(1);
                    periodLabel = "Last 30 Days";
            }
            
            Double periodRevenue = paymentService.getRevenueByDateRange(startDate, LocalDateTime.now());
            analytics.put("periodRevenue", periodRevenue != null ? periodRevenue : 0.0);
            analytics.put("periodLabel", periodLabel);
            
            // Transaction counts
            analytics.put("totalTransactions", paymentService.getTotalTransactions());
            analytics.put("successfulTransactions", paymentService.getSuccessfulTransactions());
            analytics.put("failedTransactions", paymentService.getFailedTransactions());
            
        } catch (Exception e) {
            analytics.put("error", e.getMessage());
        }
        
        return ResponseEntity.ok(analytics);
    }

    // Temporarily commented out to avoid mapping conflict
    // @GetMapping("/popular-routes")
    // public ResponseEntity<List<Map<String, Object>>> getPopularRoutes() {
    //     try {
    //         String sql = """
    //             SELECT 
    //                 dv.name as departure_city,
    //                 av.name as arrival_city,
    //                 COUNT(*) as trip_count,
    //                 AVG(v.price_per_seat) as avg_price,
    //                 SUM(v.max_seats - v.available_seats) as total_passengers
    //             FROM voyages v
    //             LEFT JOIN villes dv ON v.departure_ville_id = dv.id
    //             LEFT JOIN villes av ON v.arrival_ville_id = av.id
    //             WHERE v.status IN ('COMPLETED', 'ACTIVE', 'PLANNED')
    //             GROUP BY dv.name, av.name
    //             ORDER BY trip_count DESC
    //             LIMIT 10
    //             """;
    //         
    //         List<Map<String, Object>> routes = jdbcTemplate.queryForList(sql);
    //         return ResponseEntity.ok(routes);
    //     } catch (Exception e) {
    //         return ResponseEntity.badRequest().body(null);
    //     }
    // }

    @GetMapping("/user-stats")
    public ResponseEntity<Map<String, Object>> getUserStats() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            Integer totalDrivers = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE user_type = 'CONDUCTEUR'", Integer.class);
            Integer totalPassengers = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE user_type = 'PASSAGER'", Integer.class);
            Integer activeUsers = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE is_active = true", Integer.class);
            Integer verifiedUsers = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE is_verified = true", Integer.class);
            
            stats.put("totalDrivers", totalDrivers);
            stats.put("totalPassengers", totalPassengers);
            stats.put("activeUsers", activeUsers);
            stats.put("verifiedUsers", verifiedUsers);
            stats.put("totalUsers", totalDrivers + totalPassengers);
            
        } catch (Exception e) {
            stats.put("error", e.getMessage());
        }
        
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/trip-trends")
    public ResponseEntity<List<Map<String, Object>>> getTripTrends(@RequestParam(defaultValue = "30") int days) {
        try {
            String sql = """
                SELECT 
                    DATE(departure_time) as trip_date,
                    COUNT(*) as trip_count,
                    SUM(max_seats - available_seats) as passengers,
                    AVG(price_per_seat) as avg_price
                FROM voyages
                WHERE departure_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
                GROUP BY DATE(departure_time)
                ORDER BY trip_date DESC
                """;
            
            List<Map<String, Object>> trends = jdbcTemplate.queryForList(sql, days);
            return ResponseEntity.ok(trends);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(null);
        }
    }
}


