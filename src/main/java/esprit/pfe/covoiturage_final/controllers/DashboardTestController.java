package esprit.pfe.covoiturage_final.controllers;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/dashboard-test")
@CrossOrigin(origins = "*")
public class DashboardTestController {
    
    @GetMapping("/status")
    public Map<String, Object> getDashboardStatus() {
        return Map.of(
            "status", "success",
            "message", "Sprint 5: User Dashboard - API is running!",
            "timestamp", java.time.Instant.now().toString(),
            "version", "1.0.0",
            "features", Map.of(
                "dashboard_stats", "✅ Ready",
                "recent_trips", "✅ Ready", 
                "upcoming_trips", "✅ Ready",
                "earnings_summary", "✅ Ready",
                "trip_history", "✅ Ready",
                "favorite_drivers", "✅ Ready"
            )
        );
    }
}
