package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;


@Entity
@DiscriminatorValue("PASSAGER")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class Passager extends User {
    
    @Column(name = "preferred_payment_method")
    private String preferredPaymentMethod;
    
    @Column(name = "rating")
    private Double rating = 0.0;
    
    @Column(name = "total_rides")
    private Integer totalRides = 0;
    
    @Column(name = "is_verified")
    private Boolean isVerified = false;
    
    // Relationships will be managed by Reservation entity
    
    public Passager(String username, String email, String password, String firstName, String lastName, String phoneNumber) {
        super();
        this.setUsername(username);
        this.setEmail(email);
        this.setPassword(password);
        this.setFirstName(firstName);
        this.setLastName(lastName);
        this.setPhoneNumber(phoneNumber);
        this.setRole(UserRole.PASSAGER);
    }
}
