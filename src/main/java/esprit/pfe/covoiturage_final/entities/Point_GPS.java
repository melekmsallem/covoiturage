package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "point_gps")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Point_GPS {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "latitude", nullable = false)
    private Double latitude;
    
    @Column(name = "longitude", nullable = false)
    private Double longitude;
    
    @Column(name = "address")
    private String address;
    
    @Column(name = "point_type")
    @Enumerated(EnumType.STRING)
    private PointType pointType; // START, END, INTERMEDIATE, PICKUP
    
    @Column(name = "voyage_id", nullable = false)
    private Long voyageId;
    
    // New fields for pickup points
    @Column(name = "pickup_time")
    private LocalDateTime pickupTime;
    
    @Column(name = "max_waiting_time")
    private Integer maxWaitingTime; // in minutes
    
    @Column(name = "pickup_order")
    private Integer pickupOrder; // for ordering pickup points
    
    public enum PointType {
        START, END, INTERMEDIATE, PICKUP
    }
}
