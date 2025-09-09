package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Reservation {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "number_of_seats", nullable = false)
    private Integer numberOfSeats;
    
    @Column(name = "total_price", nullable = false)
    private Double totalPrice;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ReservationStatus status = ReservationStatus.PENDING;
    
    @Column(name = "reservation_date", nullable = false)
    private LocalDateTime reservationDate;
    
    @Column(name = "notes")
    private String notes;
    
    // Relationships
    @Column(name = "voyage_id", nullable = false)
    private Long voyageId;
    
    @Column(name = "passager_id", nullable = false)
    private Long passagerId;
    
    // Relationship will be managed by Paiement entity
    
    @PrePersist
    protected void onCreate() {
        reservationDate = LocalDateTime.now();
    }
    
    public enum ReservationStatus {
        PENDING, CONFIRMED, CANCELLED, COMPLETED
    }
}
