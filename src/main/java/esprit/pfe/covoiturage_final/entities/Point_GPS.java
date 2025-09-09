package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

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
    private PointType pointType; // START, END, INTERMEDIATE
    
    @Column(name = "voyage_id", nullable = false)
    private Long voyageId;
    
    public enum PointType {
        START, END, INTERMEDIATE
    }
}
