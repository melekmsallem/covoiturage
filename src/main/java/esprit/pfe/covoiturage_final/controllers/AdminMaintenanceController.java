package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.services.CleanupService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/maintenance")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminMaintenanceController {

    private final CleanupService cleanupService;

    public AdminMaintenanceController(CleanupService cleanupService) {
        this.cleanupService = cleanupService;
    }

    @PostMapping("/cleanup")
    public ResponseEntity<Map<String, Object>> triggerCleanup(@RequestParam(name = "dryRun", defaultValue = "false") boolean dryRun) {
        Map<String, Object> result = cleanupService.runCleanup(dryRun);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/cleanup/stats")
    public ResponseEntity<Map<String, Object>> getCleanupStats() {
        Map<String, Object> stats = cleanupService.getCleanupStats();
        return ResponseEntity.ok(stats);
    }
}


