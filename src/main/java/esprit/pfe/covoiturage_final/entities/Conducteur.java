package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;


@Entity
@DiscriminatorValue("CONDUCTEUR")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class Conducteur extends User {
    
    @Column(name = "license_number")
    private String licenseNumber;
    
    @Column(name = "vehicle_model")
    private String vehicleModel;
    
    @Column(name = "vehicle_color")
    private String vehicleColor;
    
    @Column(name = "vehicle_plate")
    private String vehiclePlate;
    
    @Column(name = "max_passengers")
    private Integer maxPassengers = 4;
    
    @Column(name = "rating")
    private Double rating = 0.0;
    
    @Column(name = "total_trips")
    private Integer totalTrips = 0;
    
    @Column(name = "is_verified")
    private Boolean isVerified = false;
    
    @Column(name = "is_available")
    private Boolean isAvailable = true;
    
    // Relationships will be managed by Voyage entity
    
    public Conducteur(String username, String email, String password, String firstName, String lastName, String phoneNumber) {
        super();
        this.setUsername(username);
        this.setEmail(email);
        this.setPassword(password);
        this.setFirstName(firstName);
        this.setLastName(lastName);
        this.setPhoneNumber(phoneNumber);
        this.setRole(UserRole.CONDUCTEUR);
    }
}
