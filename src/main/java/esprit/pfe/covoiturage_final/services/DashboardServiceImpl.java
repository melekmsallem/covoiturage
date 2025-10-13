package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.DashboardStats;
import esprit.pfe.covoiturage_final.dto.TripSummary;
import esprit.pfe.covoiturage_final.dto.EarningsSummary;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.Conducteur;
import esprit.pfe.covoiturage_final.entities.Voyage;
import esprit.pfe.covoiturage_final.entities.Reservation;
import esprit.pfe.covoiturage_final.entities.Avis;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.VoyageRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.repositories.AvisRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class DashboardServiceImpl implements DashboardService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private AvisRepository avisRepository;
    
    @Override
    public DashboardStats getDashboardStats(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Check if user is a driver (Conducteur)
        if (user instanceof Conducteur) {
            return getDriverStats(userId);
        } else {
            return getPassengerStats(userId);
        }
    }
    
    private DashboardStats getDriverStats(Long driverId) {
        // Get driver's trips
        List<Voyage> driverTrips = voyageRepository.findByConducteurId(driverId);
        
        // Calculate stats
        Long totalTrips = (long) driverTrips.size();
        Long completedTrips = driverTrips.stream()
            .filter(trip -> Voyage.VoyageStatus.COMPLETED.equals(trip.getStatus()))
            .count();
        
        Long upcomingTrips = driverTrips.stream()
            .filter(trip -> trip.getDepartureTime().isAfter(LocalDateTime.now()))
            .count();
        
        // For now, we'll use simplified calculations
        Long totalPassengers = 0L; // TODO: Calculate from reservations
        BigDecimal totalEarnings = BigDecimal.ZERO; // TODO: Calculate from completed trips
        
        // Get driver's rating
        User driver = userRepository.findById(driverId).orElse(null);
        Double averageRating = 0.0;
        if (driver instanceof Conducteur) {
            averageRating = ((Conducteur) driver).getRating();
        }
        
        return new DashboardStats(totalTrips, averageRating, totalPassengers, 
                                totalEarnings, completedTrips, upcomingTrips, "DRIVER");
    }
    
    private DashboardStats getPassengerStats(Long passengerId) {
        // Get passenger's reservations
        List<Reservation> reservations = reservationRepository.findByPassagerId(passengerId);
        
        Long totalTrips = (long) reservations.size();
        Long completedTrips = reservations.stream()
            .filter(res -> Reservation.ReservationStatus.CONFIRMED.equals(res.getStatus()))
            .count();
        
        Long upcomingTrips = reservations.stream()
            .filter(res -> res.getReservationDate().isAfter(LocalDateTime.now().minusDays(1)))
            .count();
        
        // For passengers, we don't track earnings or passengers carried
        return new DashboardStats(totalTrips, 0.0, 0L, BigDecimal.ZERO, 
                                completedTrips, upcomingTrips, "PASSENGER");
    }
    
    @Override
    public List<TripSummary> getRecentTrips(Long userId, int limit) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        if (user instanceof Conducteur) {
            return getDriverRecentTrips(userId, limit);
        } else {
            return getPassengerRecentTrips(userId, limit);
        }
    }
    
    private List<TripSummary> getDriverRecentTrips(Long driverId, int limit) {
        List<Voyage> trips = voyageRepository.findByConducteurId(driverId)
            .stream()
            .limit(limit)
            .collect(Collectors.toList());
        
        return trips.stream()
            .map(this::convertVoyageToTripSummary)
            .collect(Collectors.toList());
    }
    
    private List<TripSummary> getPassengerRecentTrips(Long passengerId, int limit) {
        List<Reservation> reservations = reservationRepository.findByPassagerId(passengerId)
            .stream()
            .limit(limit)
            .collect(Collectors.toList());
        
        return reservations.stream()
            .map(this::convertReservationToTripSummary)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<TripSummary> getUpcomingTrips(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        if (user instanceof Conducteur) {
            return getDriverUpcomingTrips(userId);
        } else {
            return getPassengerUpcomingTrips(userId);
        }
    }
    
    private List<TripSummary> getDriverUpcomingTrips(Long driverId) {
        return voyageRepository.findByConducteurId(driverId)
            .stream()
            .filter(trip -> trip.getDepartureTime().isAfter(LocalDateTime.now()))
            .map(this::convertVoyageToTripSummary)
            .collect(Collectors.toList());
    }
    
    private List<TripSummary> getPassengerUpcomingTrips(Long passengerId) {
        return reservationRepository.findByPassagerId(passengerId)
            .stream()
            .filter(res -> res.getReservationDate().isAfter(LocalDateTime.now().minusDays(1)))
            .map(this::convertReservationToTripSummary)
            .collect(Collectors.toList());
    }
    
    @Override
    public EarningsSummary getEarningsSummary(Long driverId) {
        List<Voyage> trips = voyageRepository.findByConducteurId(driverId);
        
        // Simplified earnings calculation for now
        BigDecimal totalEarnings = BigDecimal.ZERO;
        BigDecimal thisMonthEarnings = BigDecimal.ZERO;
        BigDecimal lastMonthEarnings = BigDecimal.ZERO;
        BigDecimal thisWeekEarnings = BigDecimal.ZERO;
        
        Long totalTrips = (long) trips.size();
        Long thisMonthTrips = 0L;
        
        // Calculate average earnings per trip
        BigDecimal averageEarningPerTrip = BigDecimal.ZERO;
        
        return new EarningsSummary(totalEarnings, thisMonthEarnings, lastMonthEarnings,
                                thisWeekEarnings, totalTrips, thisMonthTrips,
                                averageEarningPerTrip, null, BigDecimal.ZERO);
    }
    
    @Override
    public List<TripSummary> getTripHistory(Long userId, int page, int size) {
        // Implementation for paginated trip history
        return getRecentTrips(userId, page * size);
    }
    
    @Override
    public List<User> getFavoriteDrivers(Long passengerId) {
        // Simplified implementation - return empty list for now
        return List.of();
    }
    
    private TripSummary convertVoyageToTripSummary(Voyage voyage) {
        User driver = userRepository.findById(voyage.getConducteurId()).orElse(null);
        String driverName = "Unknown Driver";
        String driverPhone = "";
        Double driverRating = 0.0;
        String vehicleModel = "";
        String vehicleColor = "";
        String vehiclePlate = "";
        
        if (driver != null) {
            driverName = driver.getFirstName() + " " + driver.getLastName();
            driverPhone = driver.getPhoneNumber() != null ? driver.getPhoneNumber() : "";
            
            if (driver instanceof Conducteur) {
                Conducteur conducteur = (Conducteur) driver;
                driverRating = conducteur.getRating();
                vehicleModel = conducteur.getVehicleModel() != null ? conducteur.getVehicleModel() : "";
                vehicleColor = conducteur.getVehicleColor() != null ? conducteur.getVehicleColor() : "";
                vehiclePlate = conducteur.getVehiclePlate() != null ? conducteur.getVehiclePlate() : "";
            }
        }
        
        return new TripSummary(
            voyage.getId(),
            "Departure City", // TODO: Get from villes relationship
            "Arrival City",   // TODO: Get from villes relationship
            voyage.getDepartureTime(),
            voyage.getArrivalTime(),
            BigDecimal.valueOf(voyage.getPricePerSeat()),
            voyage.getAvailableSeats(),
            voyage.getStatus().name(),
            driverName,
            driverPhone,
            driverRating,
            vehicleModel,
            vehicleColor,
            vehiclePlate,
            "DRIVER",
            voyage.getCreatedAt()
        );
    }
    
    private TripSummary convertReservationToTripSummary(Reservation reservation) {
        // Simplified implementation for now
        return new TripSummary(
            reservation.getId(),
            "Departure City",
            "Arrival City",
            LocalDateTime.now(),
            LocalDateTime.now().plusHours(2),
            BigDecimal.valueOf(25.0),
            1,
            reservation.getStatus().name(),
            "Driver Name",
            "123456789",
            4.5,
            "Toyota",
            "Blue",
            "ABC123",
            "PASSENGER",
            reservation.getReservationDate()
        );
    }
}
