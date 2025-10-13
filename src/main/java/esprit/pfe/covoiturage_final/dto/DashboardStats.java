package esprit.pfe.covoiturage_final.dto;

import java.math.BigDecimal;

public class DashboardStats {
    private Long totalTrips;
    private Double averageRating;
    private Long totalPassengers;
    private BigDecimal totalEarnings;
    private Long completedTrips;
    private Long upcomingTrips;
    private String userType; // "DRIVER" or "PASSENGER"
    
    // Constructors
    public DashboardStats() {}
    
    public DashboardStats(Long totalTrips, Double averageRating, Long totalPassengers, 
                         BigDecimal totalEarnings, Long completedTrips, Long upcomingTrips, String userType) {
        this.totalTrips = totalTrips;
        this.averageRating = averageRating;
        this.totalPassengers = totalPassengers;
        this.totalEarnings = totalEarnings;
        this.completedTrips = completedTrips;
        this.upcomingTrips = upcomingTrips;
        this.userType = userType;
    }
    
    // Getters and Setters
    public Long getTotalTrips() {
        return totalTrips;
    }
    
    public void setTotalTrips(Long totalTrips) {
        this.totalTrips = totalTrips;
    }
    
    public Double getAverageRating() {
        return averageRating;
    }
    
    public void setAverageRating(Double averageRating) {
        this.averageRating = averageRating;
    }
    
    public Long getTotalPassengers() {
        return totalPassengers;
    }
    
    public void setTotalPassengers(Long totalPassengers) {
        this.totalPassengers = totalPassengers;
    }
    
    public BigDecimal getTotalEarnings() {
        return totalEarnings;
    }
    
    public void setTotalEarnings(BigDecimal totalEarnings) {
        this.totalEarnings = totalEarnings;
    }
    
    public Long getCompletedTrips() {
        return completedTrips;
    }
    
    public void setCompletedTrips(Long completedTrips) {
        this.completedTrips = completedTrips;
    }
    
    public Long getUpcomingTrips() {
        return upcomingTrips;
    }
    
    public void setUpcomingTrips(Long upcomingTrips) {
        this.upcomingTrips = upcomingTrips;
    }
    
    public String getUserType() {
        return userType;
    }
    
    public void setUserType(String userType) {
        this.userType = userType;
    }
}

