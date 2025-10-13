package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notification {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "title", nullable = false)
    private String title;
    
    @Column(name = "message", nullable = false, length = 1000)
    private String message;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private NotificationType type;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private NotificationStatus status = NotificationStatus.UNREAD;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
    
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Column(name = "related_entity_type")
    private String relatedEntityType; // TRIP, BOOKING, PAYMENT, etc.
    
    @Column(name = "related_entity_id")
    private Long relatedEntityId;
    
    @Column(name = "is_email_sent")
    private Boolean isEmailSent = false;
    
    @Column(name = "is_push_sent")
    private Boolean isPushSent = false;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    public enum NotificationType {
        TRIP_CREATED,
        TRIP_CANCELLED,
        TRIP_STARTED,
        TRIP_COMPLETED,
        BOOKING_CREATED,
        BOOKING_CONFIRMED,
        BOOKING_CANCELLED,
        PAYMENT_PENDING,
        PAYMENT_COMPLETED,
        PAYMENT_FAILED,
        RATING_RECEIVED,
        SYSTEM_ANNOUNCEMENT,
        REMINDER
    }
    
    public enum NotificationStatus {
        UNREAD,
        READ,
        ARCHIVED
    }
}





