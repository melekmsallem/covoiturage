package esprit.pfe.covoiturage_final.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/monitoring")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class SystemMonitoringController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${stripe.secret-key:}")
    private String stripeSecretKey;

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> getSystemHealth() {
        Map<String, Object> health = new HashMap<>();
        
        // Database health
        Map<String, Object> dbHealth = new HashMap<>();
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            dbHealth.put("status", "UP");
            dbHealth.put("message", "Database connection successful");
        } catch (Exception e) {
            dbHealth.put("status", "DOWN");
            dbHealth.put("message", "Database connection failed: " + e.getMessage());
        }
        health.put("database", dbHealth);

        // Stripe health
        Map<String, Object> stripeHealth = new HashMap<>();
        if (stripeSecretKey != null && !stripeSecretKey.isBlank()) {
            stripeHealth.put("status", "CONFIGURED");
            stripeHealth.put("message", "Stripe API key is configured");
        } else {
            stripeHealth.put("status", "NOT_CONFIGURED");
            stripeHealth.put("message", "Stripe API key is missing");
        }
        health.put("stripe", stripeHealth);

        // Email health
        Map<String, Object> emailHealth = new HashMap<>();
        if (mailSender != null) {
            emailHealth.put("status", "CONFIGURED");
            emailHealth.put("message", "Email service is configured");
        } else {
            emailHealth.put("status", "NOT_CONFIGURED");
            emailHealth.put("message", "Email service is not configured");
        }
        health.put("email", emailHealth);

        // Overall status
        boolean allUp = dbHealth.get("status").equals("UP") && 
                        stripeHealth.get("status").equals("CONFIGURED");
        health.put("overallStatus", allUp ? "HEALTHY" : "DEGRADED");

        return ResponseEntity.ok(health);
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getSystemStats() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            // Database stats
            Integer userCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM users", Integer.class);
            Integer tripCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM voyages", Integer.class);
            Integer bookingCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM reservations", Integer.class);
            Integer paymentCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM paiements", Integer.class);
            
            stats.put("totalUsers", userCount);
            stats.put("totalTrips", tripCount);
            stats.put("totalBookings", bookingCount);
            stats.put("totalPayments", paymentCount);
            
            // Active items (today)
            Integer todayTrips = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM voyages WHERE DATE(departure_time) = CURDATE()", Integer.class);
            Integer todayBookings = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM reservations WHERE DATE(reservation_date) = CURDATE()", Integer.class);
            
            stats.put("todayTrips", todayTrips);
            stats.put("todayBookings", todayBookings);
            
        } catch (Exception e) {
            stats.put("error", "Failed to fetch stats: " + e.getMessage());
        }
        
        return ResponseEntity.ok(stats);
    }
}


