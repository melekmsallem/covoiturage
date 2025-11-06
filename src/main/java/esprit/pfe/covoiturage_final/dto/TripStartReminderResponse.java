package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TripStartReminderResponse {
    
    private Long tripId;
    private String departureCity;
    private String arrivalCity;
    private String pickupMode;
    private List<OptimizedPickupPoint> pickupPoints;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OptimizedPickupPoint {
        private Long pointId;
        private String address;
        private Double latitude;
        private Double longitude;
        private Integer order;
        private Integer maxWaitingTime;
        private String passengerName;
        private Integer seats;
    }
}

