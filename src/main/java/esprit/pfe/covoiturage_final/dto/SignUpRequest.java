package esprit.pfe.covoiturage_final.dto;

import esprit.pfe.covoiturage_final.entities.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Email;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SignUpRequest {
    @NotBlank(message = "Username is required")
    private String username;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email should be valid")
    private String email;
    
    @NotBlank(message = "Password is required")
    private String password;
    
    @NotBlank(message = "First name is required")
    private String firstName;
    
    @NotBlank(message = "Last name is required")
    private String lastName;
    
    private String phoneNumber;
    
    @NotNull(message = "Role is required")
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
