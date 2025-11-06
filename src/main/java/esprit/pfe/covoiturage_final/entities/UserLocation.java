package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_locations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserLocation {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;
    
    @Column(name = "latitude")
    private Double latitude;
    
    @Column(name = "longitude")
    private Double longitude;
    
    @Column(name = "accuracy")
    private Double accuracy; // in meters
    
    @Column(name = "altitude")
    private Double altitude;
    
    @Column(name = "speed")
    private Double speed; // in meters per second
    
    @Column(name = "heading")
    private Double heading; // in degrees
    
    @Column(name = "is_sharing", nullable = false)
    private Boolean isSharing = false;
    
    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        lastUpdated = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        lastUpdated = LocalDateTime.now();
    }
}















