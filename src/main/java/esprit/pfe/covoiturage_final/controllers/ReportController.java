package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Report;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.services.ReportService;
import esprit.pfe.covoiturage_final.security.JwtUtils;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
@CrossOrigin(origins = "*")
public class ReportController {
    
    @Autowired
    private ReportService reportService;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private JwtUtils jwtUtils;
    
    @PostMapping
    public ResponseEntity<?> createReport(@RequestBody Map<String, Object> request, HttpServletRequest httpRequest) {
        try {
            Long reporterId = getCurrentUserId(httpRequest);
            Long reportedUserId = Long.valueOf(request.get("reportedUserId").toString());
            Long bookingId = request.get("bookingId") != null ? 
                Long.valueOf(request.get("bookingId").toString()) : null;
            Long tripId = request.get("tripId") != null ? 
                Long.valueOf(request.get("tripId").toString()) : null;
            String reportTypeStr = request.get("reportType").toString();
            String reason = request.get("reason").toString();
            String description = request.get("description") != null ? 
                request.get("description").toString() : "";
            
            Report.ReportType reportType;
            try {
                reportType = Report.ReportType.valueOf(reportTypeStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(Map.of("error", "Invalid report type"));
            }
            
            Report report = reportService.createReport(
                reporterId, reportedUserId, bookingId, tripId, 
                reportType, reason, description
            );
            
            return ResponseEntity.ok(Map.of(
                "message", "Report submitted successfully",
                "reportId", report.getId()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to create report"));
        }
    }
    
    @GetMapping("/my-reports")
    public ResponseEntity<?> getMyReports(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            List<Report> reports = reportService.getReportsByReporter(userId);
            return ResponseEntity.ok(reports);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/has-reported")
    public ResponseEntity<?> hasReported(@RequestParam Long reportedUserId, 
                                         @RequestParam(required = false) Long bookingId,
                                         HttpServletRequest request) {
        try {
            Long reporterId = getCurrentUserId(request);
            boolean hasReported = reportService.hasReportedUser(reporterId, reportedUserId, bookingId);
            return ResponseEntity.ok(Map.of("hasReported", hasReported));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    // Admin endpoints
    @GetMapping("/admin/all")
    public ResponseEntity<?> getAllReports(HttpServletRequest request) {
        try {
            // Only admins can access this
            Long userId = getCurrentUserId(request);
            var user = userRepository.findById(userId);
            if (user.isEmpty() || user.get().getRole() != esprit.pfe.covoiturage_final.entities.UserRole.ADMIN) {
                return ResponseEntity.status(403).body(Map.of("error", "Admin access required"));
            }
            
            List<Report> reports = reportService.getAllReports();
            return ResponseEntity.ok(reports);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/admin/pending")
    public ResponseEntity<?> getPendingReports(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            var user = userRepository.findById(userId);
            if (user.isEmpty() || user.get().getRole() != esprit.pfe.covoiturage_final.entities.UserRole.ADMIN) {
                return ResponseEntity.status(403).body(Map.of("error", "Admin access required"));
            }
            
            List<Report> reports = reportService.getPendingReports();
            return ResponseEntity.ok(reports);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @PutMapping("/admin/{reportId}/status")
    public ResponseEntity<?> updateReportStatus(@PathVariable Long reportId,
                                               @RequestBody Map<String, Object> request,
                                               HttpServletRequest httpRequest) {
        try {
            Long userId = getCurrentUserId(httpRequest);
            var user = userRepository.findById(userId);
            if (user.isEmpty() || user.get().getRole() != esprit.pfe.covoiturage_final.entities.UserRole.ADMIN) {
                return ResponseEntity.status(403).body(Map.of("error", "Admin access required"));
            }
            
            String statusStr = request.get("status").toString();
            String adminNotes = request.get("adminNotes") != null ? 
                request.get("adminNotes").toString() : "";
            
            Report.ReportStatus status;
            try {
                status = Report.ReportStatus.valueOf(statusStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(Map.of("error", "Invalid status"));
            }
            
            Report report = reportService.updateReportStatus(reportId, status, adminNotes);
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    private Long getCurrentUserId(HttpServletRequest request) {
        // 1) Prefer Spring Security context (set by our JWT filter)
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            Object principal = authentication.getPrincipal();
            String identifier = null;
            if (principal instanceof org.springframework.security.core.userdetails.User userDetails) {
                identifier = userDetails.getUsername();
            } else if (principal instanceof String s && !"anonymousUser".equals(s)) {
                identifier = s;
            }
            if (identifier != null) {
                final String id = identifier;
                User user = userRepository
                    .findByUsername(id)
                    .orElseGet(() -> userRepository.findByEmail(id)
                        .orElseThrow(() -> new RuntimeException("User not found for principal: " + id)));
                return user.getId();
            }
        }

        // 2) Fallback: parse Authorization header directly
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtils.validateJwtToken(token)) {
                String subject = jwtUtils.getUserNameFromJwtToken(token).trim();
                final String sub = subject;
                User user = userRepository
                    .findByUsername(sub)
                    .orElseGet(() -> userRepository.findByEmail(sub)
                        .orElseThrow(() -> new RuntimeException("User not found for token subject: " + sub)));
                return user.getId();
            }
        }
        throw new RuntimeException("User not authenticated");
    }
}

