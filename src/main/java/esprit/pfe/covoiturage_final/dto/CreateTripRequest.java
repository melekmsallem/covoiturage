package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateTripRequest {
    
    @NotNull(message = "Departure time is required")
    @Future(message = "Departure time must be in the future")
    private LocalDateTime departureTime;
    
    private LocalDateTime arrivalTime;
    
    @NotNull(message = "Price per seat is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
    private Double pricePerSeat;
    
    @NotNull(message = "Maximum seats is required")
    @Min(value = 1, message = "Maximum seats must be at least 1")
    @Max(value = 8, message = "Maximum seats cannot exceed 8")
    private Integer maxSeats;
    
    @Size(max = 500, message = "Description cannot exceed 500 characters")
    private String description;
    
    @NotNull(message = "Start point is required")
    private GPSPointRequest startPoint;
    
    @NotNull(message = "End point is required")
    private GPSPointRequest endPoint;
    
    private List<GPSPointRequest> intermediatePoints;
    
    private List<Long> optionIds;
    
    private List<Long> villeIds;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GPSPointRequest {
        @NotNull(message = "Latitude is required")
        @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
        @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
        private Double latitude;
        
        @NotNull(message = "Longitude is required")
        @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
        @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
        private Double longitude;
        
        @Size(max = 255, message = "Address cannot exceed 255 characters")
        private String address;
    }
}
