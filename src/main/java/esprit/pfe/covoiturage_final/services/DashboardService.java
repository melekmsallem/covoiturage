package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.DashboardStats;
import esprit.pfe.covoiturage_final.dto.TripSummary;
import esprit.pfe.covoiturage_final.dto.EarningsSummary;
import esprit.pfe.covoiturage_final.entities.User;

import java.util.List;

public interface DashboardService {
    
    /**
     * Get dashboard statistics for a user
     */
    DashboardStats getDashboardStats(Long userId);
    
    /**
     * Get recent trips for a user (as driver or passenger)
     */
    List<TripSummary> getRecentTrips(Long userId, int limit);
    
    /**
     * Get upcoming trips for a user
     */
    List<TripSummary> getUpcomingTrips(Long userId);
    
    /**
     * Get earnings summary for a driver
     */
    EarningsSummary getEarningsSummary(Long driverId);
    
    /**
     * Get trip history for a user
     */
    List<TripSummary> getTripHistory(Long userId, int page, int size);
    
    /**
     * Get user's favorite drivers (for passengers)
     */
    List<User> getFavoriteDrivers(Long passengerId);
}

