package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Point_GPS;

import java.util.List;

public interface PickupPointService {
    
    /**
     * Create pickup points for a trip
     */
    List<Point_GPS> createPickupPoints(Long tripId, List<Point_GPS> pickupPoints);
    
    /**
     * Get all pickup points for a trip
     */
    List<Point_GPS> getPickupPointsByTrip(Long tripId);
    
    /**
     * Update a pickup point
     */
    Point_GPS updatePickupPoint(Long pointId, Point_GPS updatedPoint);
    
    /**
     * Delete a pickup point
     */
    void deletePickupPoint(Long pointId);
    
    /**
     * Optimize pickup route order using Google Maps API
     */
    List<Point_GPS> optimizePickupRoute(Long tripId);
    
    /**
     * Get address from coordinates using reverse geocoding
     */
    String getAddressFromCoordinates(Double latitude, Double longitude);
}
