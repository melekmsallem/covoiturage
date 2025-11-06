package esprit.pfe.covoiturage_final.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class CreateTripRequest {
    
    @NotNull(message = "Departure time is required")
    @Future(message = "Departure time must be in the future")
    private LocalDateTime departureTime;
    
    private LocalDateTime arrivalTime;
    
    @NotNull(message = "Price per seat is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private BigDecimal pricePerSeat;
    
    @NotNull(message = "Maximum seats is required")
    @Min(value = 1, message = "Maximum seats must be at least 1")
    @Max(value = 8, message = "Maximum seats cannot exceed 8")
    private Integer maxSeats;
    
    @Size(max = 500, message = "Description cannot exceed 500 characters")
    private String description;
    
    @NotEmpty(message = "Departure city is required")
    private String departureCity;
    
    @NotEmpty(message = "Arrival city is required")
    private String arrivalCity;
    
    private List<Long> optionIds;
    
    // GPS coordinates for departure and arrival
    private GPSPointRequest departurePoint;
    private GPSPointRequest arrivalPoint;
    
    // Pickup mode fields
    private String pickupMode; // DESIGNATED_POINT or INDIVIDUAL_PICKUP
    private List<GPSPointRequest> pickupPoints;
    private Boolean allowLocationSharing;
    private Boolean flexiblePickupTimes;
    
    // Constructors
    public CreateTripRequest() {}
    
    public CreateTripRequest(LocalDateTime departureTime, LocalDateTime arrivalTime,
                           BigDecimal pricePerSeat, Integer maxSeats, String description,
                           String departureCity, String arrivalCity, List<Long> optionIds,
                           GPSPointRequest departurePoint, GPSPointRequest arrivalPoint) {
        this.departureTime = departureTime;
        this.arrivalTime = arrivalTime;
        this.pricePerSeat = pricePerSeat;
        this.maxSeats = maxSeats;
        this.description = description;
        this.departureCity = departureCity;
        this.arrivalCity = arrivalCity;
        this.optionIds = optionIds;
        this.departurePoint = departurePoint;
        this.arrivalPoint = arrivalPoint;
    }
    
    // Getters and Setters
    public LocalDateTime getDepartureTime() {
        return departureTime;
    }
    
    public void setDepartureTime(LocalDateTime departureTime) {
        this.departureTime = departureTime;
    }
    
    public LocalDateTime getArrivalTime() {
        return arrivalTime;
    }
    
    public void setArrivalTime(LocalDateTime arrivalTime) {
        this.arrivalTime = arrivalTime;
    }
    
    public BigDecimal getPricePerSeat() {
        return pricePerSeat;
    }
    
    public void setPricePerSeat(BigDecimal pricePerSeat) {
        this.pricePerSeat = pricePerSeat;
    }
    
    public Integer getMaxSeats() {
        return maxSeats;
    }
    
    public void setMaxSeats(Integer maxSeats) {
        this.maxSeats = maxSeats;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getDepartureCity() {
        return departureCity;
    }
    
    public void setDepartureCity(String departureCity) {
        this.departureCity = departureCity;
    }
    
    public String getArrivalCity() {
        return arrivalCity;
    }
    
    public void setArrivalCity(String arrivalCity) {
        this.arrivalCity = arrivalCity;
    }
    
    public List<Long> getOptionIds() {
        return optionIds;
    }
    
    public void setOptionIds(List<Long> optionIds) {
        this.optionIds = optionIds;
    }
    
    public GPSPointRequest getDeparturePoint() {
        return departurePoint;
    }
    
    public void setDeparturePoint(GPSPointRequest departurePoint) {
        this.departurePoint = departurePoint;
    }
    
    public GPSPointRequest getArrivalPoint() {
        return arrivalPoint;
    }
    
    public void setArrivalPoint(GPSPointRequest arrivalPoint) {
        this.arrivalPoint = arrivalPoint;
    }
    
    public String getPickupMode() {
        return pickupMode;
    }
    
    public void setPickupMode(String pickupMode) {
        this.pickupMode = pickupMode;
    }
    
    public List<GPSPointRequest> getPickupPoints() {
        return pickupPoints;
    }
    
    public void setPickupPoints(List<GPSPointRequest> pickupPoints) {
        this.pickupPoints = pickupPoints;
    }
    
    public Boolean getAllowLocationSharing() {
        return allowLocationSharing;
    }
    
    public void setAllowLocationSharing(Boolean allowLocationSharing) {
        this.allowLocationSharing = allowLocationSharing;
    }
    
    public Boolean getFlexiblePickupTimes() {
        return flexiblePickupTimes;
    }
    
    public void setFlexiblePickupTimes(Boolean flexiblePickupTimes) {
        this.flexiblePickupTimes = flexiblePickupTimes;
    }
}