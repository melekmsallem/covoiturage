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
import esprit.pfe.covoiturage_final.repositories.PaiementRepository;
import esprit.pfe.covoiturage_final.entities.Paiement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
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

    @Autowired
    private PaiementRepository paiementRepository;
    
    @Override
    public DashboardStats getDashboardStats(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Check if user has created any trips as a driver (more reliable than instanceof check)
        List<Voyage> driverTrips = voyageRepository.findByConducteurId(userId);
        boolean hasDriverTrips = driverTrips != null && !driverTrips.isEmpty();
        
        // Check if user is a driver (Conducteur) OR has driver trips
        if (user instanceof Conducteur || hasDriverTrips) {
            return getDriverStats(userId);
        } else {
            return getPassengerStats(userId);
        }
    }
    
    private DashboardStats getDriverStats(Long driverId) {
        // Get all driver's trips (total trips = all trips created by driver)
        List<Voyage> driverTrips = voyageRepository.findByConducteurId(driverId);
        
        LocalDateTime now = LocalDateTime.now();
        
        // Total trips: all trips created by driver (any status)
        Long totalTrips = (long) driverTrips.size();
        
        // Completed trips: use direct database query for accuracy
        Long completedTrips = voyageRepository.countByConducteurIdAndStatus(
            driverId, Voyage.VoyageStatus.COMPLETED);
        
        // Upcoming trips: PLANNED or ACTIVE trips with departure time in the future
        Long upcomingTrips = driverTrips.stream()
            .filter(trip -> {
                Voyage.VoyageStatus status = trip.getStatus();
                if (!Voyage.VoyageStatus.PLANNED.equals(status) && 
                    !Voyage.VoyageStatus.ACTIVE.equals(status)) {
                    return false;
                }
                LocalDateTime departureTime = trip.getDepartureTime();
                if (departureTime == null) {
                    // If no departure time but status is PLANNED or ACTIVE, consider it upcoming
                    return Voyage.VoyageStatus.PLANNED.equals(status) || 
                           Voyage.VoyageStatus.ACTIVE.equals(status);
                }
                return !departureTime.isBefore(now);
            })
            .count();
        
        // Calculate total passengers from confirmed reservations
        Long totalPassengers = 0L;
        for (Voyage trip : driverTrips) {
            List<Reservation> reservations = reservationRepository.findByVoyageId(trip.getId());
            totalPassengers += reservations.stream()
                .filter(res -> Reservation.ReservationStatus.CONFIRMED.equals(res.getStatus()))
                .count();
        }
        
        // Calculate total earnings from completed payments tied to this driver's trips
        BigDecimal totalEarnings = BigDecimal.ZERO;
        for (Voyage trip : driverTrips) {
            List<Reservation> reservations = reservationRepository.findByVoyageId(trip.getId());
            for (Reservation res : reservations) {
                List<Paiement> payments = paiementRepository.findByReservationId(res.getId());
                if (payments != null && !payments.isEmpty()) {
                    double sum = payments.stream()
                        .filter(p -> p.getStatus() == Paiement.PaymentStatus.COMPLETED)
                        .mapToDouble(Paiement::getAmount)
                        .sum();
                    totalEarnings = totalEarnings.add(BigDecimal.valueOf(sum));
                }
            }
        }
        
        // Get driver's rating from actual reviews/ratings received
        Double averageRating = 0.0;
        User driver = userRepository.findById(driverId).orElse(null);
        if (driver instanceof Conducteur) {
            // Get all visible ratings/reviews for this driver (userId in Avis = the user being rated)
            List<Avis> ratings = avisRepository.findVisibleByUserId(driverId);
            if (!ratings.isEmpty()) {
                double sum = ratings.stream()
                    .mapToInt(Avis::getRating)
                    .mapToDouble(r -> (double) r)
                    .sum();
                averageRating = sum / ratings.size();
                
                // Update driver's rating in the Conducteur entity
                ((Conducteur) driver).setRating(averageRating);
                userRepository.save(driver);
            } else {
                // Fallback to stored rating if no reviews yet
                averageRating = ((Conducteur) driver).getRating();
                if (averageRating == null) {
                    averageRating = 0.0;
                }
            }
        }
        
        return new DashboardStats(totalTrips, averageRating, totalPassengers, 
                                totalEarnings, completedTrips, upcomingTrips, "DRIVER");
    }
    
    private DashboardStats getPassengerStats(Long passengerId) {
        // Get all passenger's reservations
        List<Reservation> allReservations = reservationRepository.findByPassagerId(passengerId);
        
        LocalDateTime now = LocalDateTime.now();
        
        // Total trips: all CONFIRMED bookings (these are the trips passenger is part of)
        Long totalTrips = allReservations.stream()
            .filter(res -> Reservation.ReservationStatus.CONFIRMED.equals(res.getStatus()))
            .count();
        
        // Completed trips: CONFIRMED bookings where the trip is COMPLETED
        Long completedTrips = allReservations.stream()
            .filter(res -> Reservation.ReservationStatus.CONFIRMED.equals(res.getStatus()))
            .filter(res -> {
                if (res.getVoyageId() == null) return false;
                Voyage trip = voyageRepository.findById(res.getVoyageId()).orElse(null);
                return trip != null && Voyage.VoyageStatus.COMPLETED.equals(trip.getStatus());
            })
            .count();
        
        // Upcoming trips: CONFIRMED bookings where trip is PLANNED or ACTIVE and departure is in future
        Long upcomingTrips = allReservations.stream()
            .filter(res -> Reservation.ReservationStatus.CONFIRMED.equals(res.getStatus()))
            .filter(res -> {
                if (res.getVoyageId() == null) return false;
                Voyage trip = voyageRepository.findById(res.getVoyageId()).orElse(null);
                if (trip == null) return false;
                
                Voyage.VoyageStatus status = trip.getStatus();
                if (!Voyage.VoyageStatus.PLANNED.equals(status) && 
                    !Voyage.VoyageStatus.ACTIVE.equals(status)) {
                    return false;
                }
                
                LocalDateTime departureTime = trip.getDepartureTime();
                if (departureTime == null) {
                    return Voyage.VoyageStatus.PLANNED.equals(status) || 
                           Voyage.VoyageStatus.ACTIVE.equals(status);
                }
                return !departureTime.isBefore(now);
            })
            .count();
        
        // Get passenger's rating from actual reviews/ratings received
        Double averageRating = 0.0;
        List<Avis> ratings = avisRepository.findVisibleByUserId(passengerId);
        if (!ratings.isEmpty()) {
            double sum = ratings.stream()
                .mapToInt(Avis::getRating)
                .mapToDouble(r -> (double) r)
                .sum();
            averageRating = sum / ratings.size();
        }
        
        // For passengers, we don't track earnings or passengers carried
        return new DashboardStats(totalTrips, averageRating, 0L, BigDecimal.ZERO, 
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
