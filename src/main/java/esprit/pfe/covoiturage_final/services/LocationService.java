package esprit.pfe.covoiturage_final.services;

import java.util.List;
import java.util.Map;

public interface LocationService {
    
    void updateUserLocation(Long userId, Double latitude, Double longitude, Double accuracy);
    
    List<Map<String, Object>> getPassengerLocationsForTrip(Long tripId, Long driverId);
    
    void shareLocationWithDriver(Long passengerId, Long driverId, Long tripId);
    
    void stopLocationSharing(Long userId, Long tripId);
    
    List<Map<String, Object>> getPassengersWithinPickupArea(Long tripId, Double pickupLatitude, 
                                                           Double pickupLongitude, Double radiusInMeters, Long driverId);
}















