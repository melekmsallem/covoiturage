package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "voyages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Voyage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "departure_time", nullable = false)
    private LocalDateTime departureTime;
    
    @Column(name = "arrival_time")
    private LocalDateTime arrivalTime;
    
    @Column(name = "price_per_seat", nullable = false)
    private Double pricePerSeat;
    
    @Column(name = "available_seats", nullable = false)
    private Integer availableSeats;
    
    @Column(name = "max_seats", nullable = false)
    private Integer maxSeats;
    
    @Column(name = "description")
    private String description;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private VoyageStatus status = VoyageStatus.PLANNED;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Relationships
    @Column(name = "conducteur_id", nullable = false)
    private Long conducteurId;
    
    @OneToMany(mappedBy = "voyage", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Point_GPS> points;
    
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "voyage_options",
        joinColumns = @JoinColumn(name = "voyage_id"),
        inverseJoinColumns = @JoinColumn(name = "option_id")
    )
    private List<Option> options;
    
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "voyage_villes",
        joinColumns = @JoinColumn(name = "voyage_id"),
        inverseJoinColumns = @JoinColumn(name = "ville_id")
    )
    private List<Ville> villes;
    
    // Relationship will be managed by Reservation entity
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public enum VoyageStatus {
        PLANNED, ACTIVE, COMPLETED, CANCELLED
    }
}
