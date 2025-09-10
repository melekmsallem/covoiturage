package esprit.pfe.covoiturage_final.dto;

import esprit.pfe.covoiturage_final.entities.Voyage;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripResponse {
    
    private Long id;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private Double pricePerSeat;
    private Integer availableSeats;
    private Integer maxSeats;
    private String description;
    private Voyage.VoyageStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Driver information
    private DriverInfo driver;
    
    // GPS Points
    private List<GPSPointInfo> points;
    
    // Options
    private List<OptionInfo> options;
    
    // Cities
    private List<CityInfo> cities;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DriverInfo {
        private Long id;
        private String username;
        private String firstName;
        private String lastName;
        private String phoneNumber;
        private String vehicleModel;
        private String vehicleColor;
        private String vehiclePlate;
        private Double rating;
        private Integer totalTrips;
        private Boolean isVerified;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GPSPointInfo {
        private Long id;
        private Double latitude;
        private Double longitude;
        private String address;
        private String pointType;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptionInfo {
        private Long id;
        private String name;
        private String description;
        private Double price;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CityInfo {
        private Long id;
        private String name;
        private String codePostal;
        private String pays;
    }
}
