package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "avis")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Avis {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "rating", nullable = false)
    private Integer rating; // 1-5 stars
    
    @Column(name = "comment")
    private String comment;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "is_visible")
    private Boolean isVisible = true;
    
    // Relationships
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Column(name = "voyage_id")
    private Long voyageId;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
