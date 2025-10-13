package esprit.pfe.covoiturage_final.controllers;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/test")
@CrossOrigin(origins = "*", maxAge = 3600)
public class TestController {
    
    @GetMapping("/health")
    public java.util.Map<String, Object> healthCheck() {
        return java.util.Map.of(
            "status", "success",
            "message", "Sprint 2: Core Carpooling Features - API is running!",
            "timestamp", java.time.Instant.now().toString(),
            "version", "1.0.0"
        );
    }
    
    @GetMapping("/sprint2")
    public String sprint2Status() {
        return "Sprint 2 Features Implemented:\n" +
               "✅ Trip Creation and Management\n" +
               "✅ Trip Search and Filtering\n" +
               "✅ Booking System\n" +
               "✅ Driver and Passenger Operations\n" +
               "✅ Trip Status Management\n" +
               "✅ GPS Point Management\n" +
               "✅ Options and Cities Management\n" +
               "✅ Input Validation\n" +
               "✅ Error Handling\n" +
               "\nReady for testing!";
    }
}