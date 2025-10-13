package esprit.pfe.covoiturage_final.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public class EarningsSummary {
    private BigDecimal totalEarnings;
    private BigDecimal thisMonthEarnings;
    private BigDecimal lastMonthEarnings;
    private BigDecimal thisWeekEarnings;
    private Long totalTrips;
    private Long thisMonthTrips;
    private BigDecimal averageEarningPerTrip;
    private LocalDate lastPaymentDate;
    private BigDecimal pendingEarnings;
    
    // Constructors
    public EarningsSummary() {}
    
    public EarningsSummary(BigDecimal totalEarnings, BigDecimal thisMonthEarnings,
                          BigDecimal lastMonthEarnings, BigDecimal thisWeekEarnings,
                          Long totalTrips, Long thisMonthTrips, 
                          BigDecimal averageEarningPerTrip, LocalDate lastPaymentDate,
                          BigDecimal pendingEarnings) {
        this.totalEarnings = totalEarnings;
        this.thisMonthEarnings = thisMonthEarnings;
        this.lastMonthEarnings = lastMonthEarnings;
        this.thisWeekEarnings = thisWeekEarnings;
        this.totalTrips = totalTrips;
        this.thisMonthTrips = thisMonthTrips;
        this.averageEarningPerTrip = averageEarningPerTrip;
        this.lastPaymentDate = lastPaymentDate;
        this.pendingEarnings = pendingEarnings;
    }
    
    // Getters and Setters
    public BigDecimal getTotalEarnings() {
        return totalEarnings;
    }
    
    public void setTotalEarnings(BigDecimal totalEarnings) {
        this.totalEarnings = totalEarnings;
    }
    
    public BigDecimal getThisMonthEarnings() {
        return thisMonthEarnings;
    }
    
    public void setThisMonthEarnings(BigDecimal thisMonthEarnings) {
        this.thisMonthEarnings = thisMonthEarnings;
    }
    
    public BigDecimal getLastMonthEarnings() {
        return lastMonthEarnings;
    }
    
    public void setLastMonthEarnings(BigDecimal lastMonthEarnings) {
        this.lastMonthEarnings = lastMonthEarnings;
    }
    
    public BigDecimal getThisWeekEarnings() {
        return thisWeekEarnings;
    }
    
    public void setThisWeekEarnings(BigDecimal thisWeekEarnings) {
        this.thisWeekEarnings = thisWeekEarnings;
    }
    
    public Long getTotalTrips() {
        return totalTrips;
    }
    
    public void setTotalTrips(Long totalTrips) {
        this.totalTrips = totalTrips;
    }
    
    public Long getThisMonthTrips() {
        return thisMonthTrips;
    }
    
    public void setThisMonthTrips(Long thisMonthTrips) {
        this.thisMonthTrips = thisMonthTrips;
    }
    
    public BigDecimal getAverageEarningPerTrip() {
        return averageEarningPerTrip;
    }
    
    public void setAverageEarningPerTrip(BigDecimal averageEarningPerTrip) {
        this.averageEarningPerTrip = averageEarningPerTrip;
    }
    
    public LocalDate getLastPaymentDate() {
        return lastPaymentDate;
    }
    
    public void setLastPaymentDate(LocalDate lastPaymentDate) {
        this.lastPaymentDate = lastPaymentDate;
    }
    
    public BigDecimal getPendingEarnings() {
        return pendingEarnings;
    }
    
    public void setPendingEarnings(BigDecimal pendingEarnings) {
        this.pendingEarnings = pendingEarnings;
    }
}

