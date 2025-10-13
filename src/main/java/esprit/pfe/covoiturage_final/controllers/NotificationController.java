package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Notification;
import esprit.pfe.covoiturage_final.services.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*", maxAge = 3600)
public class NotificationController {
    
    @Autowired
    private NotificationService notificationService;
    
    @GetMapping
    public ResponseEntity<?> getUserNotifications() {
        try {
            Long userId = getCurrentUserId();
            List<Notification> notifications = notificationService.getUserNotifications(userId);
            return ResponseEntity.ok(notifications);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/unread")
    public ResponseEntity<?> getUnreadNotifications() {
        try {
            Long userId = getCurrentUserId();
            List<Notification> notifications = notificationService.getUnreadNotifications(userId);
            return ResponseEntity.ok(notifications);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/count")
    public ResponseEntity<?> getUnreadCount() {
        try {
            Long userId = getCurrentUserId();
            Long count = notificationService.getUnreadCount(userId);
            return ResponseEntity.ok(count);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{notificationId}")
    public ResponseEntity<?> getNotification(@PathVariable Long notificationId) {
        try {
            Notification notification = notificationService.getNotificationById(notificationId);
            return ResponseEntity.ok(notification);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/{notificationId}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long notificationId) {
        try {
            Long userId = getCurrentUserId();
            Notification notification = notificationService.markAsRead(notificationId, userId);
            return ResponseEntity.ok(notification);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/mark-all-read")
    public ResponseEntity<?> markAllAsRead() {
        try {
            Long userId = getCurrentUserId();
            notificationService.markAllAsRead(userId);
            return ResponseEntity.ok("All notifications marked as read");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @DeleteMapping("/{notificationId}")
    public ResponseEntity<?> deleteNotification(@PathVariable Long notificationId) {
        try {
            Long userId = getCurrentUserId();
            notificationService.deleteNotification(notificationId, userId);
            return ResponseEntity.ok("Notification deleted successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    // Admin endpoints for system announcements
    @PostMapping("/announcement")
    public ResponseEntity<?> sendSystemAnnouncement(@RequestBody SystemAnnouncementRequest request) {
        try {
            notificationService.sendRealTimeNotificationToAll(request.getMessage());
            return ResponseEntity.ok("System announcement sent successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/announcement/drivers")
    public ResponseEntity<?> sendDriverAnnouncement(@RequestBody SystemAnnouncementRequest request) {
        try {
            notificationService.sendRealTimeNotificationToDrivers(request.getMessage());
            return ResponseEntity.ok("Driver announcement sent successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/announcement/passengers")
    public ResponseEntity<?> sendPassengerAnnouncement(@RequestBody SystemAnnouncementRequest request) {
        try {
            notificationService.sendRealTimeNotificationToPassengers(request.getMessage());
            return ResponseEntity.ok("Passenger announcement sent successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            return user.getId();
        }
        throw new RuntimeException("User not authenticated");
    }
    
    public static class SystemAnnouncementRequest {
        private String message;
        
        public String getMessage() {
            return message;
        }
        
        public void setMessage(String message) {
            this.message = message;
        }
    }
}





