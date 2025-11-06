package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "trip_chats", indexes = {
    @Index(name = "idx_trip_chat_voyage_id", columnList = "voyage_id"),
    @Index(name = "idx_trip_chat_created_at", columnList = "created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripChat {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "voyage_id", nullable = false)
    private Long voyageId;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
