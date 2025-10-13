package esprit.pfe.covoiturage_final.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripSearchRequest {
    
    private String departureCity;
    private String arrivalCity;
    private String date; // Format: "2024-01-15" or "2024-01-15T10:00"
    private LocalDateTime departureTime;
    private LocalDateTime maxDepartureTime;
    private Double minPrice;
    private Double maxPrice;
    private Integer numberOfSeats;
    private List<String> options; // Option names to filter by
    private String sortBy; // "price", "time", "distance"
    private String sortOrder; // "asc", "desc"
    private Integer page;
    private Integer size;
    
    // Additional filters
    private Boolean petFriendly;
    private Boolean smokingAllowed;
    private Boolean hasWifi;
    private Boolean hasBluetooth;
    private Boolean hasHeating;
    private Boolean hasLuggageSpace;
    
    // Driver preferences
    private Double minDriverRating;
    private Boolean verifiedDriverOnly;
    
    // Convenience methods
    public boolean hasDateFilter() {
        return date != null && !date.trim().isEmpty();
    }
    
    public boolean hasPriceFilter() {
        return minPrice != null || maxPrice != null;
    }
    
    public boolean hasLocationFilter() {
        return (departureCity != null && !departureCity.trim().isEmpty()) ||
               (arrivalCity != null && !arrivalCity.trim().isEmpty());
    }
    
    public boolean hasOptionFilters() {
        return petFriendly != null || smokingAllowed != null || hasWifi != null ||
               hasBluetooth != null || hasHeating != null || hasLuggageSpace != null;
    }
}


