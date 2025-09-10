package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SearchTripRequest {
    
    @NotNull(message = "Departure time is required")
    @Future(message = "Departure time must be in the future")
    private LocalDateTime departureTime;
    
    private LocalDateTime maxDepartureTime;
    
    @DecimalMin(value = "-90.0", message = "Start latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "Start latitude must be between -90 and 90")
    private Double startLatitude;
    
    @DecimalMin(value = "-180.0", message = "Start longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "Start longitude must be between -180 and 180")
    private Double startLongitude;
    
    @DecimalMin(value = "-90.0", message = "End latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "End latitude must be between -90 and 90")
    private Double endLatitude;
    
    @DecimalMin(value = "-180.0", message = "End longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "End longitude must be between -180 and 180")
    private Double endLongitude;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Min price must be greater than 0")
    private Double minPrice;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Max price must be greater than 0")
    private Double maxPrice;
    
    @Min(value = 1, message = "Number of seats must be at least 1")
    @Max(value = 8, message = "Number of seats cannot exceed 8")
    private Integer numberOfSeats = 1;
    
    @DecimalMin(value = "0.0", message = "Search radius must be non-negative")
    @DecimalMax(value = "100.0", message = "Search radius cannot exceed 100 km")
    private Double searchRadiusKm = 10.0; // Default 10km radius
    
    private String startCity;
    private String endCity;
}
