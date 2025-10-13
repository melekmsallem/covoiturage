package esprit.pfe.covoiturage_final.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/test")
@CrossOrigin(origins = "*", maxAge = 3600)
public class Sprint3TestController {

    @GetMapping("/sprint3")
    public ResponseEntity<String> sprint3Status() {
        return ResponseEntity.ok("Sprint 3: Advanced Features - All endpoints implemented!");
    }
    
    @GetMapping("/sprint3/features")
    public ResponseEntity<String> sprint3Features() {
        String features = """
            Sprint 3 Features Implemented:
            ✅ Real-time Notifications System
            ✅ Payment Integration and Processing
            ✅ Rating and Review System
            ✅ Email Notifications (Mock)
            ✅ WebSocket Configuration (Ready)
            ✅ Advanced Trip Management
            ✅ User Rating Statistics
            ✅ Payment Statistics
            ✅ Admin Moderation Tools
            """;
        return ResponseEntity.ok(features);
    }
}


