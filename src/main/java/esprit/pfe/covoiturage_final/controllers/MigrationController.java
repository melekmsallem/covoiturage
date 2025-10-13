package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.services.DatabaseMigrationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/migration")
@CrossOrigin(origins = "*")
public class MigrationController {
    
    @Autowired
    private DatabaseMigrationService migrationService;
    
    @PostMapping("/voyage-cities")
    public ResponseEntity<Map<String, Object>> migrateVoyageCities() {
        try {
            migrationService.migrateVoyageCities();
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", "Voyage cities migration completed successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "ERROR");
            response.put("message", "Migration failed: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getMigrationStatus() {
        try {
            migrationService.checkMigrationStatus();
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", "Migration status checked");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "ERROR");
            response.put("message", "Status check failed: " + e.getMessage());
            
            return ResponseEntity.badRequest().body(response);
        }
    }
}

















