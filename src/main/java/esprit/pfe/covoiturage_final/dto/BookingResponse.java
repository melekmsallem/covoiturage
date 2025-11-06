package esprit.pfe.covoiturage_final.dto;

import esprit.pfe.covoiturage_final.entities.Reservation;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BookingResponse {
    
    private Long id;
    private Integer numberOfSeats;
    private Double totalPrice;
    private Reservation.ReservationStatus status;
    private LocalDateTime reservationDate;
    private String notes;
    
    // Passenger pickup point for individual pickup trips
    private String passengerPickupAddress;
    private Double passengerPickupLatitude;
    private Double passengerPickupLongitude;
    
    // Trip information
    private TripInfo trip;
    
    // Passenger information
    private PassengerInfo passenger;
    
    // Driver information
    private DriverInfo driver;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TripInfo {
        private Long id;
        private LocalDateTime departureTime;
        private LocalDateTime arrivalTime;
        private Double pricePerSeat;
        private String description;
        private String status;
        
        // Location information
        private String departureCity;
        private String arrivalCity;
        
        // Driver information
        private String driverName;
        private String vehicleModel;
        private String vehicleColor;
        private String vehiclePlate;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PassengerInfo {
        private Long id;
        private String username;
        private String firstName;
        private String lastName;
        private String phoneNumber;
    }
    
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
    }
}
