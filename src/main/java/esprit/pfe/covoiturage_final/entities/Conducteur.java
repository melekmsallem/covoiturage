package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import jakarta.validation.constraints.Pattern;
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
    @Pattern(regexp = "^\\d{3}TU\\d{4}$", message = "License plate must follow Tunisian format: 3 numbers + TU + 4 numbers (e.g., 123TU4567)")
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
    
    @Column(name = "license_image_path")
    private String licenseImagePath;
    
    @Column(name = "license_verified")
    private Boolean licenseVerified = false;
    
    @Column(name = "license_verification_date")
    private java.time.LocalDateTime licenseVerificationDate;
    
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
