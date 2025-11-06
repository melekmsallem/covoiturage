package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "reports")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Report {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "reporter_id", nullable = false)
    private Long reporterId; // User who is reporting
    
    @Column(name = "reported_user_id", nullable = false)
    private Long reportedUserId; // User being reported
    
    @Column(name = "booking_id")
    private Long bookingId; // Related booking (optional)
    
    @Column(name = "trip_id")
    private Long tripId; // Related trip (optional)
    
    @Enumerated(EnumType.STRING)
    @Column(name = "report_type", nullable = false)
    private ReportType reportType;
    
    @Column(name = "reason", nullable = false, length = 500)
    private String reason;
    
    @Column(name = "description", length = 2000)
    private String description;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ReportStatus status = ReportStatus.PENDING;
    
    @Column(name = "admin_notes", length = 1000)
    private String adminNotes;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public enum ReportType {
        HARASSMENT,
        INAPPROPRIATE_BEHAVIOR,
        NO_SHOW,
        LATE_ARRIVAL,
        UNSAFE_DRIVING,
        INAPPROPRIATE_MESSAGES,
        FRAUD,
        OTHER
    }
    
    public enum ReportStatus {
        PENDING,
        UNDER_REVIEW,
        RESOLVED,
        DISMISSED
    }
}

