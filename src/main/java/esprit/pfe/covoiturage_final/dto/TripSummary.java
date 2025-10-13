package esprit.pfe.covoiturage_final.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TripSummary {
    private Long id;
    private String departureCity;
    private String arrivalCity;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private BigDecimal price;
    private Integer availableSeats;
    private String status;
    private String driverName;
    private String driverPhone;
    private Double driverRating;
    private String vehicleModel;
    private String vehicleColor;
    private String vehiclePlate;
    private String userRole; // "DRIVER" or "PASSENGER"
    private LocalDateTime bookingTime;
    
    // Constructors
    public TripSummary() {}
    
    public TripSummary(Long id, String departureCity, String arrivalCity, 
                      LocalDateTime departureTime, LocalDateTime arrivalTime,
                      BigDecimal price, Integer availableSeats, String status,
                      String driverName, String driverPhone, Double driverRating,
                      String vehicleModel, String vehicleColor, String vehiclePlate,
                      String userRole, LocalDateTime bookingTime) {
        this.id = id;
        this.departureCity = departureCity;
        this.arrivalCity = arrivalCity;
        this.departureTime = departureTime;
        this.arrivalTime = arrivalTime;
        this.price = price;
        this.availableSeats = availableSeats;
        this.status = status;
        this.driverName = driverName;
        this.driverPhone = driverPhone;
        this.driverRating = driverRating;
        this.vehicleModel = vehicleModel;
        this.vehicleColor = vehicleColor;
        this.vehiclePlate = vehiclePlate;
        this.userRole = userRole;
        this.bookingTime = bookingTime;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
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
    
    public BigDecimal getPrice() {
        return price;
    }
    
    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    
    public Integer getAvailableSeats() {
        return availableSeats;
    }
    
    public void setAvailableSeats(Integer availableSeats) {
        this.availableSeats = availableSeats;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getDriverName() {
        return driverName;
    }
    
    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }
    
    public String getDriverPhone() {
        return driverPhone;
    }
    
    public void setDriverPhone(String driverPhone) {
        this.driverPhone = driverPhone;
    }
    
    public Double getDriverRating() {
        return driverRating;
    }
    
    public void setDriverRating(Double driverRating) {
        this.driverRating = driverRating;
    }
    
    public String getVehicleModel() {
        return vehicleModel;
    }
    
    public void setVehicleModel(String vehicleModel) {
        this.vehicleModel = vehicleModel;
    }
    
    public String getVehicleColor() {
        return vehicleColor;
    }
    
    public void setVehicleColor(String vehicleColor) {
        this.vehicleColor = vehicleColor;
    }
    
    public String getVehiclePlate() {
        return vehiclePlate;
    }
    
    public void setVehiclePlate(String vehiclePlate) {
        this.vehiclePlate = vehiclePlate;
    }
    
    public String getUserRole() {
        return userRole;
    }
    
    public void setUserRole(String userRole) {
        this.userRole = userRole;
    }
    
    public LocalDateTime getBookingTime() {
        return bookingTime;
    }
    
    public void setBookingTime(LocalDateTime bookingTime) {
        this.bookingTime = bookingTime;
    }
}

