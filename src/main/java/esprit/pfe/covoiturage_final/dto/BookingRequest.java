package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BookingRequest {
    
    @NotNull(message = "Trip ID is required")
    private Long tripId;
    
    @NotNull(message = "Number of seats is required")
    @Min(value = 1, message = "Number of seats must be at least 1")
    @Max(value = 8, message = "Number of seats cannot exceed 8")
    private Integer numberOfSeats;
    
    @Size(max = 500, message = "Notes cannot exceed 500 characters")
    private String notes;
}
