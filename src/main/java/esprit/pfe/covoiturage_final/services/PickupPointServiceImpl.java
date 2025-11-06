package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Point_GPS;
import esprit.pfe.covoiturage_final.repositories.Point_GPSRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class PickupPointServiceImpl implements PickupPointService {

    @Autowired
    private Point_GPSRepository pointGpsRepository;

    @Override
    @Transactional
    public List<Point_GPS> createPickupPoints(Long tripId, List<Point_GPS> pickupPoints) {
        // Set trip ID and pickup type for all points
        pickupPoints.forEach(point -> {
            point.setVoyageId(tripId);
            point.setPointType(Point_GPS.PointType.PICKUP);
        });
        
        return pointGpsRepository.saveAll(pickupPoints);
    }

    @Override
    public List<Point_GPS> getPickupPointsByTrip(Long tripId) {
        return pointGpsRepository.findByVoyageIdAndPointType(tripId, Point_GPS.PointType.PICKUP);
    }

    @Override
    @Transactional
    public Point_GPS updatePickupPoint(Long pointId, Point_GPS updatedPoint) {
        Optional<Point_GPS> existingPoint = pointGpsRepository.findById(pointId);
        if (existingPoint.isPresent()) {
            Point_GPS point = existingPoint.get();
            point.setLatitude(updatedPoint.getLatitude());
            point.setLongitude(updatedPoint.getLongitude());
            point.setAddress(updatedPoint.getAddress());
            point.setPickupTime(updatedPoint.getPickupTime());
            point.setMaxWaitingTime(updatedPoint.getMaxWaitingTime());
            point.setPickupOrder(updatedPoint.getPickupOrder());
            return pointGpsRepository.save(point);
        }
        throw new RuntimeException("Pickup point not found with id: " + pointId);
    }

    @Override
    @Transactional
    public void deletePickupPoint(Long pointId) {
        pointGpsRepository.deleteById(pointId);
    }

    @Override
    public List<Point_GPS> optimizePickupRoute(Long tripId) {
        // TODO: Implement Google Maps route optimization
        // For now, just return points in current order
        List<Point_GPS> points = getPickupPointsByTrip(tripId);
        // Sort by pickup order if available
        points.sort((p1, p2) -> {
            if (p1.getPickupOrder() == null) return 1;
            if (p2.getPickupOrder() == null) return -1;
            return p1.getPickupOrder().compareTo(p2.getPickupOrder());
        });
        return points;
    }

    @Override
    public String getAddressFromCoordinates(Double latitude, Double longitude) {
        // TODO: Implement reverse geocoding with Google Maps API
        // For now, return a placeholder
        return String.format("Lat: %.6f, Lng: %.6f", latitude, longitude);
    }
}
