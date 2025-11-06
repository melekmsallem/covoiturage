package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserLocation;
import esprit.pfe.covoiturage_final.repositories.UserLocationRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class LocationServiceImpl implements LocationService {

    @Autowired
    private UserLocationRepository userLocationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ReservationRepository reservationRepository;

    @Override
    @Transactional
    public void updateUserLocation(Long userId, Double latitude, Double longitude, Double accuracy) {
        UserLocation userLocation = userLocationRepository.findByUserId(userId)
            .orElse(new UserLocation());
        
        userLocation.setUserId(userId);
        userLocation.setLatitude(latitude);
        userLocation.setLongitude(longitude);
        userLocation.setAccuracy(accuracy);
        userLocation.setLastUpdated(LocalDateTime.now());
        userLocation.setIsSharing(true);
        
        userLocationRepository.save(userLocation);
    }

    @Override
    public List<Map<String, Object>> getPassengerLocationsForTrip(Long tripId, Long driverId) {
        List<Map<String, Object>> passengerLocations = new ArrayList<>();
        
        // Get all passengers for this trip
        List<Object[]> passengers = reservationRepository.findPassengersForTrip(tripId);
        
        for (Object[] passenger : passengers) {
            Long passengerId = (Long) passenger[0];
            String firstName = (String) passenger[1];
            String lastName = (String) passenger[2];
            
            // Get passenger's current location
            Optional<UserLocation> locationOpt = userLocationRepository.findByUserId(passengerId);
            
            Map<String, Object> passengerData = new HashMap<>();
            passengerData.put("id", passengerId);
            passengerData.put("firstName", firstName);
            passengerData.put("lastName", lastName);
            
            if (locationOpt.isPresent() && locationOpt.get().getIsSharing()) {
                UserLocation location = locationOpt.get();
                passengerData.put("latitude", location.getLatitude());
                passengerData.put("longitude", location.getLongitude());
                passengerData.put("accuracy", location.getAccuracy());
                passengerData.put("lastUpdated", location.getLastUpdated());
                passengerData.put("isSharing", true);
            } else {
                passengerData.put("isSharing", false);
                passengerData.put("message", "Location sharing not active");
            }
            
            passengerLocations.add(passengerData);
        }
        
        return passengerLocations;
    }

    @Override
    @Transactional
    public void shareLocationWithDriver(Long passengerId, Long driverId, Long tripId) {
        // Enable location sharing for this passenger
        UserLocation userLocation = userLocationRepository.findByUserId(passengerId)
            .orElse(new UserLocation());
        
        userLocation.setUserId(passengerId);
        userLocation.setIsSharing(true);
        userLocation.setLastUpdated(LocalDateTime.now());
        
        userLocationRepository.save(userLocation);
    }

    @Override
    @Transactional
    public void stopLocationSharing(Long userId, Long tripId) {
        Optional<UserLocation> userLocationOpt = userLocationRepository.findByUserId(userId);
        if (userLocationOpt.isPresent()) {
            UserLocation userLocation = userLocationOpt.get();
            userLocation.setIsSharing(false);
            userLocationRepository.save(userLocation);
        }
    }

    @Override
    public List<Map<String, Object>> getPassengersWithinPickupArea(Long tripId, Double pickupLatitude, 
                                                                  Double pickupLongitude, Double radiusInMeters, Long driverId) {
        List<Map<String, Object>> passengersInArea = new ArrayList<>();
        
        // Get all passenger locations for this trip
        List<Map<String, Object>> allPassengers = getPassengerLocationsForTrip(tripId, driverId);
        
        for (Map<String, Object> passenger : allPassengers) {
            if (passenger.get("isSharing") != null && (Boolean) passenger.get("isSharing")) {
                Double passengerLat = (Double) passenger.get("latitude");
                Double passengerLng = (Double) passenger.get("longitude");
                
                if (passengerLat != null && passengerLng != null) {
                    double distance = calculateDistance(pickupLatitude, pickupLongitude, passengerLat, passengerLng);
                    
                    Map<String, Object> passengerInArea = new HashMap<>(passenger);
                    passengerInArea.put("distanceFromPickup", distance);
                    passengerInArea.put("isWithinArea", distance <= radiusInMeters);
                    
                    passengersInArea.add(passengerInArea);
                }
            }
        }
        
        return passengersInArea;
    }

    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Radius of the earth in km
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = R * c * 1000; // convert to meters
        
        return distance;
    }
}















