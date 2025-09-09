package esprit.pfe.covoiturage_final.dto;

import esprit.pfe.covoiturage_final.entities.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SignUpRequest {
    private String username;
    private String email;
    private String password;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private UserRole role;
    
    // Driver-specific fields
    private String licenseNumber;
    private String vehicleModel;
    private String vehicleColor;
    private String vehiclePlate;
    private Integer maxPassengers;
    
    // Passenger-specific fields
    private String preferredPaymentMethod;
}
