package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Service
@Transactional
public class TripServiceImpl implements TripService {

    private static final double FUEL_PRICE_TND_PER_LITER = 1.8; // Updated price reference
    private static final double AVERAGE_FUEL_CONSUMPTION_PER_KM = 0.07; // 7L / 100km
    private static final double MAX_SEAT_PRICE_FUEL_RATIO = 0.30; // Allow up to 30% of fuel cost per seat
    private static final double FRIENDLY_PRICE_STEP = 5.0; // Round caps to the closest 5 coins
    
    @Autowired
    private VoyageRepository voyageRepository;
    
    @Autowired
    private Point_GPSRepository pointGpsRepository;
    
    @Autowired
    private OptionRepository optionRepository;
    
    @Autowired
    private VilleRepository villeRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private NotificationService notificationService;
    
    @Autowired
    private CoinService coinService;
    
    @PersistenceContext
    private EntityManager entityManager;
    
    @Override
    public TripResponse createTrip(CreateTripRequest request, Long driverId) {
        // Get driver
        User driver = userRepository.findById(driverId)
            .orElseThrow(() -> new RuntimeException("Driver not found"));
        
        if (!(driver instanceof Conducteur)) {
            throw new RuntimeException("User is not a driver");
        }
        
        // Create trip
        Voyage trip = new Voyage();
        trip.setDepartureTime(request.getDepartureTime());
        trip.setArrivalTime(request.getArrivalTime());
        trip.setPricePerSeat(request.getPricePerSeat().doubleValue());
        trip.setMaxSeats(request.getMaxSeats());
        trip.setAvailableSeats(request.getMaxSeats());
        trip.setDescription(request.getDescription());
        trip.setStatus(Voyage.VoyageStatus.PLANNED);
        trip.setConducteurId(driverId);
        
        // Set pickup mode
        if (request.getPickupMode() != null) {
            try {
                trip.setPickupMode(Voyage.PickupMode.valueOf(request.getPickupMode()));
            } catch (IllegalArgumentException e) {
                // Default to DESIGNATED_POINT if invalid mode
                trip.setPickupMode(Voyage.PickupMode.DESIGNATED_POINT);
            }
        }
        
        // Map cities (by name) to entity relations before saving (FKs may be NOT NULL)
        if (request.getDepartureCity() == null || request.getDepartureCity().trim().isEmpty()) {
            throw new RuntimeException("Departure city is required");
        }
        if (request.getArrivalCity() == null || request.getArrivalCity().trim().isEmpty()) {
            throw new RuntimeException("Arrival city is required");
        }

        Ville departureVille = resolveCityByName(request.getDepartureCity());
        Ville arrivalVille = resolveCityByName(request.getArrivalCity());
        if (departureVille == null) {
            throw new RuntimeException("Unknown departure city: " + request.getDepartureCity());
        }
        if (arrivalVille == null) {
            throw new RuntimeException("Unknown arrival city: " + request.getArrivalCity());
        }
        trip.setDepartureVille(departureVille);
        trip.setArrivalVille(arrivalVille);

        trip = voyageRepository.save(trip);
        
        // Create GPS points
        createGPSPoints(trip.getId(), request);
        
        // Create pickup points if designated mode
        if (trip.getPickupMode() == Voyage.PickupMode.DESIGNATED_POINT && 
            request.getPickupPoints() != null && !request.getPickupPoints().isEmpty()) {
            createPickupPoints(trip.getId(), request.getPickupPoints());
        }
        
        // Send notification to driver
        notificationService.notifyTripCreated(driverId, trip.getId(), trip.getDescription());
        
        // Add options if provided
        if (request.getOptionIds() != null && !request.getOptionIds().isEmpty()) {
            List<Option> options = optionRepository.findAllById(request.getOptionIds());
            trip.setOptions(options);
            voyageRepository.save(trip);
        }
        
        // Cities are already set above
        
        return convertToTripResponse(trip);
    }
    
    @Override
    public TripResponse getTripById(Long tripId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        return convertToTripResponse(trip);
    }
    
    @Override
    public List<TripResponse> getTripsByDriver(Long driverId) {
        List<Voyage> trips = voyageRepository.findByConducteurId(driverId);
        return trips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<TripResponse> searchTrips(SearchTripRequest request) {
        // For now, return available trips - in a real implementation, 
        // you would implement complex search logic with GPS calculations
        List<Voyage> trips = voyageRepository.findAvailableTrips();
        
        // Filter by date range
        if (request.getMaxDepartureTime() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime().isAfter(request.getDepartureTime()) &&
                               trip.getDepartureTime().isBefore(request.getMaxDepartureTime()))
                .collect(Collectors.toList());
        } else {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime().isAfter(request.getDepartureTime()))
                .collect(Collectors.toList());
        }
        
        // Filter by price range
        if (request.getMinPrice() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getPricePerSeat() >= request.getMinPrice())
                .collect(Collectors.toList());
        }
        
        if (request.getMaxPrice() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getPricePerSeat() <= request.getMaxPrice())
                .collect(Collectors.toList());
        }
        
        // Filter by available seats
        trips = trips.stream()
            .filter(trip -> trip.getAvailableSeats() >= request.getNumberOfSeats())
            .collect(Collectors.toList());
        
        return trips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<TripResponse> searchTrips(TripSearchRequest request) {
        // Get available trips
        List<Voyage> trips = voyageRepository.findAvailableTrips();
        
        // Filter by date (day window)
        if (request.getDate() != null && !request.getDate().trim().isEmpty()) {
            try {
                java.time.LocalDate day = java.time.LocalDate.parse(request.getDate().substring(0, Math.min(10, request.getDate().length())));
                java.time.LocalDateTime startOfDay = day.atStartOfDay();
                java.time.LocalDateTime endOfDay = day.atTime(23, 59, 59);
                trips = trips.stream()
                    .filter(trip -> trip.getDepartureTime() != null
                        && !trip.getDepartureTime().isBefore(startOfDay)
                        && !trip.getDepartureTime().isAfter(endOfDay))
                    .collect(java.util.stream.Collectors.toList());
            } catch (Exception ignored) { /* fallback to time filters below */ }
        }

        // Filter by departure time range
        if (request.getDepartureTime() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime().isAfter(request.getDepartureTime()))
                .collect(Collectors.toList());
        }
        
        // Filter by max departure time
        if (request.getMaxDepartureTime() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime().isBefore(request.getMaxDepartureTime()))
                .collect(Collectors.toList());
        }
        
        // Filter by price range
        if (request.getMinPrice() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getPricePerSeat() >= request.getMinPrice())
                .collect(Collectors.toList());
        }
        
        if (request.getMaxPrice() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getPricePerSeat() <= request.getMaxPrice())
                .collect(Collectors.toList());
        }
        
        // Filter by number of seats
        if (request.getNumberOfSeats() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getAvailableSeats() >= request.getNumberOfSeats())
                .collect(Collectors.toList());
        }
        
        // Filter by cities if provided (check direct departure/arrival fields first, then fallback to villes list)
        if (request.getDepartureCity() != null && !request.getDepartureCity().trim().isEmpty()) {
            trips = trips.stream()
                .filter(trip -> {
                    String needle = request.getDepartureCity().toLowerCase();
                    // Direct mapping
                    if (trip.getDepartureVille() != null && trip.getDepartureVille().getName() != null) {
                        if (trip.getDepartureVille().getName().toLowerCase().contains(needle)) return true;
                    }
                    // Fallback: any villes linked
                    if (trip.getVilles() != null) {
                        return trip.getVilles().stream()
                            .anyMatch(ville -> ville.getName() != null && ville.getName().toLowerCase().contains(needle));
                    }
                    return false;
                })
                .collect(Collectors.toList());
        }
        
        if (request.getArrivalCity() != null && !request.getArrivalCity().trim().isEmpty()) {
            trips = trips.stream()
                .filter(trip -> {
                    String needle = request.getArrivalCity().toLowerCase();
                    // Direct mapping
                    if (trip.getArrivalVille() != null && trip.getArrivalVille().getName() != null) {
                        if (trip.getArrivalVille().getName().toLowerCase().contains(needle)) return true;
                    }
                    // Fallback: any villes linked
                    if (trip.getVilles() != null) {
                        return trip.getVilles().stream()
                            .anyMatch(ville -> ville.getName() != null && ville.getName().toLowerCase().contains(needle));
                    }
                    return false;
                })
                .collect(Collectors.toList());
        }
        
        // Apply sorting
        if (request.getSortBy() != null) {
            switch (request.getSortBy().toLowerCase()) {
                case "price":
                    trips = trips.stream()
                        .sorted((t1, t2) -> {
                            int comparison = Double.compare(t1.getPricePerSeat(), t2.getPricePerSeat());
                            return "desc".equalsIgnoreCase(request.getSortOrder()) ? -comparison : comparison;
                        })
                        .collect(Collectors.toList());
                    break;
                case "time":
                    trips = trips.stream()
                        .sorted((t1, t2) -> {
                            int comparison = t1.getDepartureTime().compareTo(t2.getDepartureTime());
                            return "desc".equalsIgnoreCase(request.getSortOrder()) ? -comparison : comparison;
                        })
                        .collect(Collectors.toList());
                    break;
            }
        }
        
        // Apply pagination if specified
        if (request.getPage() != null && request.getSize() != null) {
            int start = request.getPage() * request.getSize();
            int end = Math.min(start + request.getSize(), trips.size());
            if (start < trips.size()) {
                trips = trips.subList(start, end);
            } else {
                trips = new ArrayList<>();
            }
        }
        
        return trips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }

    @Override
    public Page<TripResponse> searchTripsPageable(TripSearchRequest request, Pageable pageable) {
        // Reuse existing logic from searchTrips but apply Pageable for sorting/pagination
        List<Voyage> trips = voyageRepository.findByStatus(Voyage.VoyageStatus.PLANNED);
        
        // Apply same filters as in searchTrips(TripSearchRequest)
        if (request.getDepartureTime() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime() != null && !trip.getDepartureTime().isBefore(request.getDepartureTime()))
                .collect(Collectors.toList());
        }
        if (request.getMaxDepartureTime() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getDepartureTime() != null && !trip.getDepartureTime().isAfter(request.getMaxDepartureTime()))
                .collect(Collectors.toList());
        }
        if (request.getMaxPrice() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getPricePerSeat() != null && trip.getPricePerSeat() <= request.getMaxPrice())
                .collect(Collectors.toList());
        }
        if (request.getNumberOfSeats() != null) {
            trips = trips.stream()
                .filter(trip -> trip.getAvailableSeats() >= request.getNumberOfSeats())
                .collect(Collectors.toList());
        }
        if (request.getDepartureCity() != null && !request.getDepartureCity().trim().isEmpty()) {
            trips = trips.stream()
                .filter(trip -> {
                    String needle = request.getDepartureCity().toLowerCase();
                    if (trip.getDepartureVille() != null && trip.getDepartureVille().getName() != null) {
                        if (trip.getDepartureVille().getName().toLowerCase().contains(needle)) return true;
                    }
                    if (trip.getVilles() != null) {
                        return trip.getVilles().stream()
                            .anyMatch(ville -> ville.getName() != null && ville.getName().toLowerCase().contains(needle));
                    }
                    return false;
                })
                .collect(Collectors.toList());
        }
        if (request.getArrivalCity() != null && !request.getArrivalCity().trim().isEmpty()) {
            trips = trips.stream()
                .filter(trip -> {
                    String needle = request.getArrivalCity().toLowerCase();
                    if (trip.getArrivalVille() != null && trip.getArrivalVille().getName() != null) {
                        if (trip.getArrivalVille().getName().toLowerCase().contains(needle)) return true;
                    }
                    if (trip.getVilles() != null) {
                        return trip.getVilles().stream()
                            .anyMatch(ville -> ville.getName() != null && ville.getName().toLowerCase().contains(needle));
                    }
                    return false;
                })
                .collect(Collectors.toList());
        }

        // Convert to responses
        List<TripResponse> responses = trips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());

        // Apply pageable manually (in-memory pagination)
        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), responses.size());
        List<TripResponse> pageContent = start < responses.size() ? responses.subList(start, end) : new ArrayList<>();

        return new PageImpl<>(pageContent, pageable, responses.size());
    }
    
    @Override
    public TripResponse updateTrip(Long tripId, CreateTripRequest request, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only update your own trips");
        }
        
        if (trip.getStatus() != Voyage.VoyageStatus.PLANNED) {
            throw new RuntimeException("Can only update planned trips");
        }
        
        // Update trip details
        trip.setDepartureTime(request.getDepartureTime());
        trip.setArrivalTime(request.getArrivalTime());
        trip.setPricePerSeat(request.getPricePerSeat().doubleValue());
        trip.setDescription(request.getDescription());
        
        // Update max seats (but not available seats if there are existing bookings)
        int currentBookings = reservationRepository.countConfirmedReservationsByVoyageId(tripId).intValue();
        if (request.getMaxSeats() < currentBookings) {
            throw new RuntimeException("Cannot reduce seats below current bookings");
        }
        
        trip.setMaxSeats(request.getMaxSeats());
        trip.setAvailableSeats(request.getMaxSeats() - currentBookings);
        
        // Update cities if provided
        if (request.getDepartureCity() != null && !request.getDepartureCity().trim().isEmpty()) {
            Ville departureVille = resolveCityByName(request.getDepartureCity());
            if (departureVille == null) {
                throw new RuntimeException("Unknown departure city: " + request.getDepartureCity());
            }
            trip.setDepartureVille(departureVille);
        }
        if (request.getArrivalCity() != null && !request.getArrivalCity().trim().isEmpty()) {
            Ville arrivalVille = resolveCityByName(request.getArrivalCity());
            if (arrivalVille == null) {
                throw new RuntimeException("Unknown arrival city: " + request.getArrivalCity());
            }
            trip.setArrivalVille(arrivalVille);
        }

        trip = voyageRepository.save(trip);
        
        // Update GPS points
        updateGPSPoints(tripId, request);
        
        return convertToTripResponse(trip);
    }
    
    @Override
    public void cancelTrip(Long tripId, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only cancel your own trips");
        }
        
        if (trip.getStatus() == Voyage.VoyageStatus.COMPLETED) {
            throw new RuntimeException("Cannot cancel completed trips");
        }
        
        trip.setStatus(Voyage.VoyageStatus.CANCELLED);
        voyageRepository.save(trip);
        
        // Cancel all pending reservations
        List<Reservation> reservations = reservationRepository.findByVoyageIdAndStatus(tripId, Reservation.ReservationStatus.PENDING);
        List<Long> passengerIds = reservations.stream()
            .map(Reservation::getPassagerId)
            .collect(Collectors.toList());
        
        reservations.forEach(reservation -> {
            reservation.setStatus(Reservation.ReservationStatus.CANCELLED);
            reservationRepository.save(reservation);
        });
        
        // Send notifications
        notificationService.notifyTripCancelled(driverId, passengerIds, tripId, "Trip cancelled by driver");
    }
    
    @Override
    public void deleteTrip(Long tripId, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only delete your own trips");
        }
        
        if (trip.getStatus() != Voyage.VoyageStatus.PLANNED) {
            throw new RuntimeException("Can only delete planned trips");
        }
        
        // Check if there are any reservations
        List<Reservation> reservations = reservationRepository.findByVoyageId(tripId);
        if (!reservations.isEmpty()) {
            throw new RuntimeException("Cannot delete trip with existing reservations");
        }
        
        voyageRepository.delete(trip);
    }
    
    @Override
    public TripResponse startTrip(Long tripId, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only start your own trips");
        }
        
        if (trip.getStatus() != Voyage.VoyageStatus.PLANNED) {
            throw new RuntimeException("Can only start planned trips");
        }
        
        trip.setStatus(Voyage.VoyageStatus.ACTIVE);
        trip = voyageRepository.save(trip);
        
        return convertToTripResponse(trip);
    }
    
    @Override
    public TripResponse completeTrip(Long tripId, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only complete your own trips");
        }
        
        if (trip.getStatus() != Voyage.VoyageStatus.ACTIVE) {
            throw new RuntimeException("Can only complete active trips");
        }
        
        // Update trip status to COMPLETED
        trip.setStatus(Voyage.VoyageStatus.COMPLETED);
        trip = voyageRepository.save(trip);
        
        // Update all confirmed reservations for this trip to COMPLETED status
        List<Reservation> reservations = reservationRepository.findByVoyageId(tripId);
        for (Reservation reservation : reservations) {
            if (reservation.getStatus() == Reservation.ReservationStatus.CONFIRMED) {
                reservation.setStatus(Reservation.ReservationStatus.COMPLETED);
                reservationRepository.save(reservation);
            }
        }
        
        // Flush changes to ensure they are immediately persisted
        entityManager.flush();
        
        return convertToTripResponse(trip);
    }
    
    @Override
    public TripStartReminderResponse getTripStartDetails(Long tripId, Long driverId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only view details for your own trips");
        }
        
        TripStartReminderResponse response = new TripStartReminderResponse();
        response.setTripId(trip.getId());
        response.setDepartureCity(trip.getDepartureVille() != null ? trip.getDepartureVille().getName() : "Unknown");
        response.setArrivalCity(trip.getArrivalVille() != null ? trip.getArrivalVille().getName() : "Unknown");
        response.setPickupMode(trip.getPickupMode() != null ? trip.getPickupMode().name() : "DESIGNATED_POINT");
        
        List<TripStartReminderResponse.OptimizedPickupPoint> pickupPoints = new ArrayList<>();
        
        if (trip.getPickupMode() == Voyage.PickupMode.DESIGNATED_POINT) {
            // Get designated pickup points for the trip
            List<Point_GPS> points = pointGpsRepository.findByVoyageIdAndPointType(tripId, Point_GPS.PointType.PICKUP);
            for (Point_GPS point : points) {
                TripStartReminderResponse.OptimizedPickupPoint pp = new TripStartReminderResponse.OptimizedPickupPoint();
                pp.setPointId(point.getId());
                pp.setAddress(point.getAddress());
                pp.setLatitude(point.getLatitude());
                pp.setLongitude(point.getLongitude());
                pp.setOrder(point.getPickupOrder());
                pp.setMaxWaitingTime(point.getMaxWaitingTime());
                pickupPoints.add(pp);
            }
        } else if (trip.getPickupMode() == Voyage.PickupMode.INDIVIDUAL_PICKUP) {
            // Get confirmed bookings with individual pickup points
            List<Reservation> confirmedBookings = reservationRepository.findByVoyageIdAndStatus(tripId, Reservation.ReservationStatus.CONFIRMED);
            List<TripStartReminderResponse.OptimizedPickupPoint> tempPoints = new ArrayList<>();
            
            for (Reservation booking : confirmedBookings) {
                if (booking.getPassengerPickupAddress() != null) {
                    TripStartReminderResponse.OptimizedPickupPoint pp = new TripStartReminderResponse.OptimizedPickupPoint();
                    pp.setAddress(booking.getPassengerPickupAddress());
                    pp.setLatitude(booking.getPassengerPickupLatitude());
                    pp.setLongitude(booking.getPassengerPickupLongitude());
                    pp.setSeats(booking.getNumberOfSeats());
                    
                    // Get passenger name
                    User passenger = userRepository.findById(booking.getPassagerId()).orElse(null);
                    if (passenger != null) {
                        pp.setPassengerName(passenger.getFirstName() + " " + passenger.getLastName());
                    }
                    
                    tempPoints.add(pp);
                }
            }
            
            // Optimize route: find START point and sort by distance from START
            List<Point_GPS> startPoints = pointGpsRepository.findByVoyageIdAndPointType(tripId, Point_GPS.PointType.START);
            if (!startPoints.isEmpty() && tempPoints.size() > 1) {
                Point_GPS startPoint = startPoints.get(0);
                double startLat = startPoint.getLatitude();
                double startLon = startPoint.getLongitude();
                
                // Sort by distance from start point (nearest first)
                tempPoints.sort((p1, p2) -> {
                    double dist1 = calculateDistance(startLat, startLon, p1.getLatitude(), p1.getLongitude());
                    double dist2 = calculateDistance(startLat, startLon, p2.getLatitude(), p2.getLongitude());
                    return Double.compare(dist1, dist2);
                });
            }
            
            pickupPoints.addAll(tempPoints);
        }
        
        response.setPickupPoints(pickupPoints);
        return response;
    }
    
    @Override
    public BookingResponse createBooking(BookingRequest request, Long passengerId) {
        // Get trip
        Voyage trip = voyageRepository.findById(request.getTripId())
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getStatus() != Voyage.VoyageStatus.PLANNED) {
            throw new RuntimeException("Can only book planned trips");
        }
        
        if (trip.getAvailableSeats() < request.getNumberOfSeats()) {
            throw new RuntimeException("Not enough available seats");
        }
        
        // Get passenger
        User passenger = userRepository.findById(passengerId)
            .orElseThrow(() -> new RuntimeException("Passenger not found"));
        
        if (!(passenger instanceof Passager)) {
            throw new RuntimeException("User is not a passenger");
        }
        
        // Calculate total price
        Double totalPrice = trip.getPricePerSeat() * request.getNumberOfSeats();
        
        // Validate passenger has sufficient coin balance BEFORE creating booking
        if (!coinService.hasSufficientBalance(passengerId, totalPrice)) {
            throw new RuntimeException("Insufficient coin balance. Please purchase coins to make this booking.");
        }
        
        // Create reservation
        Reservation reservation = new Reservation();
        reservation.setVoyageId(request.getTripId());
        reservation.setPassagerId(passengerId);
        reservation.setNumberOfSeats(request.getNumberOfSeats());
        reservation.setTotalPrice(totalPrice);
        reservation.setStatus(Reservation.ReservationStatus.PENDING);
        reservation.setNotes(request.getNotes());
        
        // Set pickup point for individual pickup trips
        if (trip.getPickupMode() == Voyage.PickupMode.INDIVIDUAL_PICKUP) {
            reservation.setPassengerPickupAddress(request.getPickupAddress());
            reservation.setPassengerPickupLatitude(request.getPickupLatitude());
            reservation.setPassengerPickupLongitude(request.getPickupLongitude());
        }
        
        reservation = reservationRepository.save(reservation);
        
        // Deduct coins from passenger immediately when booking is created
        try {
            coinService.spendCoins(
                passengerId,
                totalPrice,
                "Payment for trip booking #" + reservation.getId(),
                "booking_" + reservation.getId()
            );
        } catch (Exception e) {
            // If coin deduction fails, delete the booking and restore seats
            reservationRepository.delete(reservation);
            trip.setAvailableSeats(trip.getAvailableSeats() + request.getNumberOfSeats());
            voyageRepository.save(trip);
            throw new RuntimeException("Payment failed: " + e.getMessage());
        }
        
        // Update available seats
        trip.setAvailableSeats(trip.getAvailableSeats() - request.getNumberOfSeats());
        voyageRepository.save(trip);
        
        // Send notification to driver
        notificationService.notifyBookingCreated(trip.getConducteurId(), passengerId, reservation.getId(), request.getNumberOfSeats());
        
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public BookingResponse getBookingById(Long bookingId) {
        Reservation reservation = reservationRepository.findById(bookingId)
            .orElseThrow(() -> new RuntimeException("Booking not found"));
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public List<BookingResponse> getBookingsByPassenger(Long passengerId) {
        List<Reservation> reservations = reservationRepository.findByPassagerId(passengerId);
        return reservations.stream()
            .map(this::convertToBookingResponse)
            .collect(Collectors.toList());
    }

    @Override
    public Page<BookingResponse> getBookingsByPassengerPageable(Long passengerId, Pageable pageable) {
        List<Reservation> reservations = reservationRepository.findByPassagerId(passengerId);
        List<BookingResponse> responses = reservations.stream()
            .map(this::convertToBookingResponse)
            .collect(Collectors.toList());
        
        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), responses.size());
        List<BookingResponse> pageContent = start < responses.size() ? responses.subList(start, end) : new ArrayList<>();
        
        return new PageImpl<>(pageContent, pageable, responses.size());
    }
    
    @Override
    public List<BookingResponse> getBookingsByTrip(Long tripId) {
        List<Reservation> reservations = reservationRepository.findByVoyageId(tripId);
        return reservations.stream()
            .map(this::convertToBookingResponse)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<BookingResponse> getBookingsByDriver(Long driverId) {
        List<Voyage> driverTrips = voyageRepository.findByConducteurId(driverId);
        List<BookingResponse> bookingResponses = new ArrayList<>();
        for (Voyage trip : driverTrips) {
            List<Reservation> reservations = reservationRepository.findByVoyageId(trip.getId());
            for (Reservation reservation : reservations) {
                bookingResponses.add(convertToBookingResponse(reservation));
            }
        }
        return bookingResponses;
    }

    @Override
    public Page<BookingResponse> getBookingsByDriverPageable(Long driverId, Pageable pageable) {
        List<BookingResponse> bookingResponses = getBookingsByDriver(driverId);
        
        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), bookingResponses.size());
        List<BookingResponse> pageContent = start < bookingResponses.size() ? bookingResponses.subList(start, end) : new ArrayList<>();
        
        return new PageImpl<>(pageContent, pageable, bookingResponses.size());
    }

    @Override
    public BookingResponse confirmBooking(Long bookingId, Long driverId) {
        Reservation reservation = reservationRepository.findById(bookingId)
            .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        Voyage trip = voyageRepository.findById(reservation.getVoyageId())
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only confirm bookings for your own trips");
        }
        
        if (reservation.getStatus() != Reservation.ReservationStatus.PENDING) {
            throw new RuntimeException("Can only confirm pending bookings");
        }
        
        // Coins are already deducted from passenger when booking was created
        // Now add them to the driver's balance
        Double totalPrice = reservation.getTotalPrice();
        if (totalPrice != null && totalPrice > 0) {
            try {
                coinService.refundCoins(
                    trip.getConducteurId(),
                    totalPrice,
                    "Payment received for trip booking #" + bookingId,
                    "booking_" + bookingId
                );
            } catch (Exception e) {
                // Log error but don't fail the confirmation
                System.err.println("Failed to transfer coins to driver: " + e.getMessage());
            }
        }
        
        // Update reservation status
        reservation.setStatus(Reservation.ReservationStatus.CONFIRMED);
        reservation = reservationRepository.save(reservation);
        
        // Send notification to passenger
        notificationService.notifyBookingConfirmed(reservation.getPassagerId(), bookingId);
        
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public BookingResponse declineBooking(Long bookingId, Long driverId) {
        Reservation reservation = reservationRepository.findById(bookingId)
            .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        Voyage trip = voyageRepository.findById(reservation.getVoyageId())
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (!trip.getConducteurId().equals(driverId)) {
            throw new RuntimeException("You can only decline bookings for your own trips");
        }
        
        if (reservation.getStatus() != Reservation.ReservationStatus.PENDING) {
            throw new RuntimeException("Can only decline pending bookings");
        }
        
        // Refund coins to passenger since booking is declined
        Double totalPrice = reservation.getTotalPrice();
        if (totalPrice != null && totalPrice > 0) {
            try {
                coinService.refundCoins(
                    reservation.getPassagerId(),
                    totalPrice,
                    "Refund for declined trip booking #" + bookingId,
                    "booking_refund_" + bookingId
                );
            } catch (Exception e) {
                // Log error but don't fail the decline
                System.err.println("Failed to refund coins to passenger: " + e.getMessage());
            }
        }
        
        // Mark booking as cancelled (declined) and restore seats
        reservation.setStatus(Reservation.ReservationStatus.CANCELLED);
        reservation = reservationRepository.save(reservation);
        
        trip.setAvailableSeats(trip.getAvailableSeats() + reservation.getNumberOfSeats());
        voyageRepository.save(trip);
        
        // Notify passenger
        notificationService.notifyBookingDeclined(reservation.getPassagerId(), bookingId);
        
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public BookingResponse cancelBooking(Long bookingId, Long userId) {
        Reservation reservation = reservationRepository.findById(bookingId)
            .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        Voyage trip = voyageRepository.findById(reservation.getVoyageId())
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        // Check if user is the passenger or the driver
        if (!reservation.getPassagerId().equals(userId) && !trip.getConducteurId().equals(userId)) {
            throw new RuntimeException("You can only cancel your own bookings or bookings for your trips");
        }
        
        if (reservation.getStatus() == Reservation.ReservationStatus.CANCELLED) {
            throw new RuntimeException("Booking is already cancelled");
        }
        
        if (reservation.getStatus() == Reservation.ReservationStatus.COMPLETED) {
            throw new RuntimeException("Cannot cancel completed bookings");
        }
        
        // Refund coins if booking was confirmed (coins were transferred to driver)
        if (reservation.getStatus() == Reservation.ReservationStatus.CONFIRMED) {
            Double totalPrice = reservation.getTotalPrice();
            if (totalPrice != null && totalPrice > 0) {
                try {
                    // Transfer coins back from driver to passenger
                    coinService.transferCoins(
                        trip.getConducteurId(),
                        reservation.getPassagerId(),
                        totalPrice,
                        "Refund for cancelled booking #" + bookingId,
                        "booking_" + bookingId + "_refund"
                    );
                } catch (Exception e) {
                    // Log error but don't fail the cancellation
                    System.err.println("Failed to refund coins for cancelled booking " + bookingId + ": " + e.getMessage());
                }
            }
        }
        
        reservation.setStatus(Reservation.ReservationStatus.CANCELLED);
        reservation = reservationRepository.save(reservation);
        
        // Update available seats
        trip.setAvailableSeats(trip.getAvailableSeats() + reservation.getNumberOfSeats());
        voyageRepository.save(trip);
        
        // Send notifications
        if (userId.equals(reservation.getPassagerId())) {
            // Passenger cancelled
            notificationService.notifyBookingCancelled(trip.getConducteurId(), null, bookingId, "Cancelled by passenger");
        } else {
            // Driver cancelled
            notificationService.notifyBookingCancelled(null, reservation.getPassagerId(), bookingId, "Cancelled by driver");
        }
        
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public List<TripResponse> getAvailableTrips() {
        List<Voyage> trips = voyageRepository.findAvailableTrips();
        return trips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<TripResponse> getUpcomingTrips(Long userId) {
        // Upcoming = future trips where user is driver (PLANNED or ACTIVE) or passenger with CONFIRMED booking (trip PLANNED or ACTIVE)
        java.time.LocalDateTime now = java.time.LocalDateTime.now();

        // Driver upcoming trips: include PLANNED or ACTIVE with departure in the future (or null departure treated as upcoming)
        List<Voyage> allDriverTrips = voyageRepository.findByConducteurId(userId);
        List<Voyage> driverUpcoming = allDriverTrips.stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.PLANNED || trip.getStatus() == Voyage.VoyageStatus.ACTIVE)
            .filter(trip -> trip.getDepartureTime() == null || !trip.getDepartureTime().isBefore(now))
            .collect(Collectors.toList());

        // Passenger upcoming trips: CONFIRMED bookings, trip PLANNED or ACTIVE and in the future
        List<Reservation> passengerBookingsAll = reservationRepository.findByPassagerId(userId);
        List<Long> upcomingTripIdsForPassenger = passengerBookingsAll.stream()
            .filter(b -> b.getStatus() == Reservation.ReservationStatus.CONFIRMED)
            .map(Reservation::getVoyageId)
            .collect(Collectors.toList());

        List<Voyage> passengerUpcoming = voyageRepository.findAllById(upcomingTripIdsForPassenger).stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.PLANNED || trip.getStatus() == Voyage.VoyageStatus.ACTIVE)
            .filter(trip -> trip.getDepartureTime() == null || !trip.getDepartureTime().isBefore(now))
            .collect(Collectors.toList());

        // Merge and de-duplicate
        java.util.Map<Long, Voyage> unique = new java.util.HashMap<>();
        for (Voyage v : driverUpcoming) unique.put(v.getId(), v);
        for (Voyage v : passengerUpcoming) unique.put(v.getId(), v);

        return unique.values().stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<TripResponse> getCompletedTrips(Long userId) {
        // Similar logic for completed trips
        List<Voyage> driverTrips = voyageRepository.findByConducteurIdAndStatus(userId, Voyage.VoyageStatus.COMPLETED);
        List<Reservation> passengerBookings = reservationRepository.findByPassagerIdAndStatus(userId, Reservation.ReservationStatus.COMPLETED);
        
        List<Long> tripIds = passengerBookings.stream()
            .map(Reservation::getVoyageId)
            .collect(Collectors.toList());
        
        List<Voyage> passengerTrips = voyageRepository.findAllById(tripIds).stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.COMPLETED)
            .collect(Collectors.toList());
        
        driverTrips.addAll(passengerTrips);
        
        return driverTrips.stream()
            .map(this::convertToTripResponse)
            .collect(Collectors.toList());
    }
    
    // Helper methods
    private Ville resolveCityByName(String name) {
        if (name == null) return null;
        String trimmed = name.trim();
        // Try exact match first
        return villeRepository.findByName(trimmed)
            .orElseGet(() -> {
                List<Ville> matches = villeRepository.findByNameContainingIgnoreCase(trimmed);
                return matches.isEmpty() ? null : matches.get(0);
            });
    }
    private void createGPSPoints(Long tripId, CreateTripRequest request) {
        // Create start point
        if (request.getDeparturePoint() != null) {
            Point_GPS startPoint = new Point_GPS();
            startPoint.setVoyageId(tripId);
            startPoint.setLatitude(request.getDeparturePoint().getLatitude());
            startPoint.setLongitude(request.getDeparturePoint().getLongitude());
            startPoint.setAddress(request.getDeparturePoint().getAddress());
            startPoint.setPointType(Point_GPS.PointType.START);
            pointGpsRepository.save(startPoint);
        }
        
        // Create end point
        if (request.getArrivalPoint() != null) {
            Point_GPS endPoint = new Point_GPS();
            endPoint.setVoyageId(tripId);
            endPoint.setLatitude(request.getArrivalPoint().getLatitude());
            endPoint.setLongitude(request.getArrivalPoint().getLongitude());
            endPoint.setAddress(request.getArrivalPoint().getAddress());
            endPoint.setPointType(Point_GPS.PointType.END);
            pointGpsRepository.save(endPoint);
        }
        
        // Note: Intermediate points would be handled separately if needed
    }
    
    private void updateGPSPoints(Long tripId, CreateTripRequest request) {
        // Delete existing points
        List<Point_GPS> existingPoints = pointGpsRepository.findByVoyageId(tripId);
        pointGpsRepository.deleteAll(existingPoints);
        
        // Create new points
        createGPSPoints(tripId, request);
    }
    
    private TripResponse convertToTripResponse(Voyage trip) {
        TripResponse response = new TripResponse();
        response.setId(trip.getId());
        response.setDepartureTime(trip.getDepartureTime());
        response.setArrivalTime(trip.getArrivalTime());
        response.setPricePerSeat(trip.getPricePerSeat());
        response.setAvailableSeats(trip.getAvailableSeats());
        response.setMaxSeats(trip.getMaxSeats());
        response.setDescription(trip.getDescription());
        response.setStatus(trip.getStatus());
        response.setPickupMode(trip.getPickupMode());
        response.setCreatedAt(trip.getCreatedAt());
        response.setUpdatedAt(trip.getUpdatedAt());
        
        // Populate direct city names for convenience in clients
        if (trip.getDepartureVille() != null && trip.getDepartureVille().getName() != null) {
            response.setDepartureCity(trip.getDepartureVille().getName());
        } else {
            response.setDepartureCity("Unknown Departure");
        }
        if (trip.getArrivalVille() != null && trip.getArrivalVille().getName() != null) {
            response.setArrivalCity(trip.getArrivalVille().getName());
        } else {
            response.setArrivalCity("Unknown Arrival");
        }

        // Get driver information
        User driver = userRepository.findById(trip.getConducteurId()).orElse(null);
        if (driver instanceof Conducteur) {
            Conducteur conducteur = (Conducteur) driver;
            TripResponse.DriverInfo driverInfo = new TripResponse.DriverInfo();
            driverInfo.setId(conducteur.getId());
            driverInfo.setUsername(conducteur.getUsername());
            driverInfo.setFirstName(conducteur.getFirstName());
            driverInfo.setLastName(conducteur.getLastName());
            driverInfo.setPhoneNumber(conducteur.getPhoneNumber());
            driverInfo.setVehicleModel(conducteur.getVehicleModel());
            driverInfo.setVehicleColor(conducteur.getVehicleColor());
            driverInfo.setVehiclePlate(conducteur.getVehiclePlate());
            driverInfo.setRating(conducteur.getRating());
            driverInfo.setTotalTrips(conducteur.getTotalTrips());
            driverInfo.setIsVerified(conducteur.getIsVerified());
            response.setDriver(driverInfo);
        }
        
        // Get GPS points
        List<Point_GPS> points = pointGpsRepository.findByVoyageId(trip.getId());
        List<TripResponse.GPSPointInfo> pointInfos = points.stream()
            .map(point -> {
                TripResponse.GPSPointInfo info = new TripResponse.GPSPointInfo();
                info.setId(point.getId());
                info.setLatitude(point.getLatitude());
                info.setLongitude(point.getLongitude());
                info.setAddress(point.getAddress());
                info.setPointType(point.getPointType().name());
                return info;
            })
            .collect(Collectors.toList());
        response.setPoints(pointInfos);
        
        // Get options
        if (trip.getOptions() != null) {
            List<TripResponse.OptionInfo> optionInfos = trip.getOptions().stream()
                .map(option -> {
                    TripResponse.OptionInfo info = new TripResponse.OptionInfo();
                    info.setId(option.getId());
                    info.setName(option.getName());
                    info.setDescription(option.getDescription());
                    info.setPrice(option.getPrice());
                    return info;
                })
                .collect(Collectors.toList());
            response.setOptions(optionInfos);
        }
        
        // Get cities
        if (trip.getVilles() != null) {
            List<TripResponse.CityInfo> cityInfos = trip.getVilles().stream()
                .map(ville -> {
                    TripResponse.CityInfo info = new TripResponse.CityInfo();
                    info.setId(ville.getId());
                    info.setName(ville.getName());
                    info.setCodePostal(ville.getCodePostal());
                    info.setPays(ville.getPays());
                    return info;
                })
                .collect(Collectors.toList());
            response.setCities(cityInfos);
        }
        
        // Get reservations and passengers (for completed trips - useful for rating)
        List<Reservation> reservations = reservationRepository.findByVoyageId(trip.getId());
        if (reservations != null && !reservations.isEmpty()) {
            // Filter to only CONFIRMED or COMPLETED reservations
            List<Reservation> validReservations = reservations.stream()
                .filter(res -> res.getStatus() == Reservation.ReservationStatus.CONFIRMED || 
                              res.getStatus() == Reservation.ReservationStatus.COMPLETED)
                .collect(Collectors.toList());
            
            List<TripResponse.ReservationInfo> reservationInfos = new ArrayList<>();
            List<TripResponse.PassengerInfo> passengerInfos = new ArrayList<>();
            
            for (Reservation res : validReservations) {
                // Create reservation info
                TripResponse.ReservationInfo resInfo = new TripResponse.ReservationInfo();
                resInfo.setId(res.getId());
                resInfo.setPassengerId(res.getPassagerId());
                resInfo.setNumberOfSeats(res.getNumberOfSeats());
                resInfo.setStatus(res.getStatus().name());
                
                // Get passenger information
                User passenger = userRepository.findById(res.getPassagerId()).orElse(null);
                if (passenger != null) {
                    TripResponse.PassengerInfo passengerInfo = new TripResponse.PassengerInfo();
                    passengerInfo.setId(passenger.getId());
                    passengerInfo.setUsername(passenger.getUsername());
                    passengerInfo.setFirstName(passenger.getFirstName());
                    passengerInfo.setLastName(passenger.getLastName());
                    passengerInfo.setPhoneNumber(passenger.getPhoneNumber());
                    
                    resInfo.setPassenger(passengerInfo);
                    reservationInfos.add(resInfo);
                    
                    // Add to passengers list (avoid duplicates)
                    if (passengerInfos.stream().noneMatch(p -> p.getId().equals(passenger.getId()))) {
                        passengerInfos.add(passengerInfo);
                    }
                } else {
                    reservationInfos.add(resInfo);
                }
            }
            
            response.setReservations(reservationInfos);
            response.setPassengers(passengerInfos);
        }
        
        return response;
    }
    
    private BookingResponse convertToBookingResponse(Reservation reservation) {
        BookingResponse response = new BookingResponse();
        response.setId(reservation.getId());
        response.setNumberOfSeats(reservation.getNumberOfSeats());
        response.setTotalPrice(reservation.getTotalPrice());
        response.setStatus(reservation.getStatus());
        response.setReservationDate(reservation.getReservationDate());
        response.setNotes(reservation.getNotes());
        
        // Set passenger pickup point information
        response.setPassengerPickupAddress(reservation.getPassengerPickupAddress());
        response.setPassengerPickupLatitude(reservation.getPassengerPickupLatitude());
        response.setPassengerPickupLongitude(reservation.getPassengerPickupLongitude());
        
        // Get trip information
        Voyage trip = voyageRepository.findById(reservation.getVoyageId()).orElse(null);
        if (trip != null) {
            BookingResponse.TripInfo tripInfo = new BookingResponse.TripInfo();
            tripInfo.setId(trip.getId());
            tripInfo.setDepartureTime(trip.getDepartureTime());
            tripInfo.setArrivalTime(trip.getArrivalTime());
            tripInfo.setPricePerSeat(trip.getPricePerSeat());
            tripInfo.setDescription(trip.getDescription());
            tripInfo.setStatus(trip.getStatus().name());

            // Populate trip city names
            if (trip.getDepartureVille() != null && trip.getDepartureVille().getName() != null) {
                tripInfo.setDepartureCity(trip.getDepartureVille().getName());
            } else {
                tripInfo.setDepartureCity("Unknown Departure");
            }
            if (trip.getArrivalVille() != null && trip.getArrivalVille().getName() != null) {
                tripInfo.setArrivalCity(trip.getArrivalVille().getName());
            } else {
                tripInfo.setArrivalCity("Unknown Arrival");
            }
            
            // Get driver information
            User driver = userRepository.findById(trip.getConducteurId()).orElse(null);
            if (driver instanceof Conducteur) {
                Conducteur conducteur = (Conducteur) driver;
                tripInfo.setDriverName(conducteur.getFirstName() + " " + conducteur.getLastName());
                tripInfo.setVehicleModel(conducteur.getVehicleModel());
                tripInfo.setVehicleColor(conducteur.getVehicleColor());
                tripInfo.setVehiclePlate(conducteur.getVehiclePlate());
                
                // Set driver information separately
                BookingResponse.DriverInfo driverInfo = new BookingResponse.DriverInfo();
                driverInfo.setId(conducteur.getId());
                driverInfo.setUsername(conducteur.getUsername());
                driverInfo.setFirstName(conducteur.getFirstName());
                driverInfo.setLastName(conducteur.getLastName());
                driverInfo.setPhoneNumber(conducteur.getPhoneNumber());
                driverInfo.setVehicleModel(conducteur.getVehicleModel());
                driverInfo.setVehicleColor(conducteur.getVehicleColor());
                driverInfo.setVehiclePlate(conducteur.getVehiclePlate());
                response.setDriver(driverInfo);
            }
            
            response.setTrip(tripInfo);
        }
        
        // Get passenger information
        User passenger = userRepository.findById(reservation.getPassagerId()).orElse(null);
        if (passenger != null) {
            BookingResponse.PassengerInfo passengerInfo = new BookingResponse.PassengerInfo();
            passengerInfo.setId(passenger.getId());
            passengerInfo.setUsername(passenger.getUsername());
            passengerInfo.setFirstName(passenger.getFirstName());
            passengerInfo.setLastName(passenger.getLastName());
            passengerInfo.setPhoneNumber(passenger.getPhoneNumber());
            response.setPassenger(passengerInfo);
        }
        
        return response;
    }
    
    @Override
    public BookingResponse setPassengerPickupPoint(Long bookingId, Long passengerId, String address, Double latitude, Double longitude) {
        Reservation reservation = reservationRepository.findById(bookingId)
            .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        // Check if user is the passenger
        if (!reservation.getPassagerId().equals(passengerId)) {
            throw new RuntimeException("You can only set pickup point for your own bookings");
        }
        
        // Check if booking is confirmed
        if (reservation.getStatus() != Reservation.ReservationStatus.CONFIRMED) {
            throw new RuntimeException("You can only set pickup point for confirmed bookings");
        }
        
        // Get trip to check pickup mode
        Voyage trip = voyageRepository.findById(reservation.getVoyageId())
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getPickupMode() != Voyage.PickupMode.INDIVIDUAL_PICKUP) {
            throw new RuntimeException("Pickup point can only be set for individual pickup trips");
        }
        
        // Validate pickup point is within departure city
        if (trip.getDepartureVille() != null) {
            double cityLat = trip.getDepartureVille().getLatitude();
            double cityLng = trip.getDepartureVille().getLongitude();
            
            // Calculate distance between pickup point and city center
            double distance = calculateDistance(cityLat, cityLng, latitude, longitude);
            
            // Allow pickup within 20km of city center
            if (distance > 20.0) {
                throw new RuntimeException("Pickup point must be within " + trip.getDepartureVille().getName() + " city limits");
            }
        }
        
        // Set pickup point
        reservation.setPassengerPickupAddress(address);
        reservation.setPassengerPickupLatitude(latitude);
        reservation.setPassengerPickupLongitude(longitude);
        
        reservation = reservationRepository.save(reservation);
        
        return convertToBookingResponse(reservation);
    }
    
    @Override
    public List<Map<String, Object>> getTripPickupPoints(Long tripId, Long userId) {
        Voyage trip = voyageRepository.findById(tripId)
            .orElseThrow(() -> new RuntimeException("Trip not found"));
        
        // Check if user is the driver or has a confirmed booking for this trip
        boolean isDriver = trip.getConducteurId().equals(userId);
        boolean hasConfirmedBooking = false;
        
        if (!isDriver) {
            List<Reservation> userBookings = reservationRepository.findByVoyageIdAndPassagerId(tripId, userId);
            hasConfirmedBooking = userBookings.stream()
                .anyMatch(booking -> booking.getStatus() == Reservation.ReservationStatus.CONFIRMED);
        }
        
        if (!isDriver && !hasConfirmedBooking) {
            throw new RuntimeException("You can only view pickup points for your own trips or confirmed bookings");
        }
        
        List<Map<String, Object>> pickupPoints = new ArrayList<>();
        
        if (trip.getPickupMode() == Voyage.PickupMode.DESIGNATED_POINT) {
            // Get designated pickup points
            List<Point_GPS> designatedPoints = pointGpsRepository.findByVoyageIdAndPointType(tripId, Point_GPS.PointType.PICKUP);
            for (Point_GPS point : designatedPoints) {
                Map<String, Object> pointData = new HashMap<>();
                pointData.put("id", point.getId());
                pointData.put("address", point.getAddress());
                pointData.put("latitude", point.getLatitude());
                pointData.put("longitude", point.getLongitude());
                pointData.put("pickupTime", point.getPickupTime());
                pointData.put("maxWaitingTime", point.getMaxWaitingTime());
                pointData.put("pickupOrder", point.getPickupOrder());
                pointData.put("type", "DESIGNATED");
                pickupPoints.add(pointData);
            }
        } else if (trip.getPickupMode() == Voyage.PickupMode.INDIVIDUAL_PICKUP) {
            // Get passenger pickup points from confirmed bookings
            List<Reservation> confirmedBookings = reservationRepository.findByVoyageId(tripId).stream()
                .filter(booking -> booking.getStatus() == Reservation.ReservationStatus.CONFIRMED)
                .filter(booking -> booking.getPassengerPickupAddress() != null)
                .collect(Collectors.toList());
            
            for (Reservation booking : confirmedBookings) {
                Map<String, Object> pointData = new HashMap<>();
                pointData.put("id", booking.getId());
                pointData.put("address", booking.getPassengerPickupAddress());
                pointData.put("latitude", booking.getPassengerPickupLatitude());
                pointData.put("longitude", booking.getPassengerPickupLongitude());
                pointData.put("passengerId", booking.getPassagerId());
                pointData.put("numberOfSeats", booking.getNumberOfSeats());
                pointData.put("type", "PASSENGER");
                
                // Get passenger info
                User passenger = userRepository.findById(booking.getPassagerId()).orElse(null);
                if (passenger != null) {
                    pointData.put("passengerName", passenger.getFirstName() + " " + passenger.getLastName());
                    pointData.put("passengerPhone", passenger.getPhoneNumber());
                }
                
                pickupPoints.add(pointData);
            }
        }
        
        return pickupPoints;
    }
    
    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        final double EARTH_RADIUS_KM = 6371.0;
        
        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);
        double deltaLatRad = Math.toRadians(lat2 - lat1);
        double deltaLngRad = Math.toRadians(lng2 - lng1);
        
        double a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return EARTH_RADIUS_KM * c;
    }
    
    // Trip Creation Enhancement Methods
    @Override
    public List<Map<String, Object>> getAllCities() {
        List<Ville> cities = villeRepository.findAll();
        return cities.stream()
            .map(ville -> {
                Map<String, Object> cityMap = new HashMap<>();
                cityMap.put("id", ville.getId());
                cityMap.put("name", ville.getName());
                cityMap.put("codePostal", ville.getCodePostal());
                cityMap.put("pays", ville.getPays());
                cityMap.put("latitude", ville.getLatitude());
                cityMap.put("longitude", ville.getLongitude());
                return cityMap;
            })
            .collect(Collectors.toList());
    }
    
    @Override
    public List<Map<String, Object>> getAllOptions() {
        List<Option> options = optionRepository.findByIsActiveTrue();
        return options.stream()
            .map(option -> {
                Map<String, Object> optionMap = new HashMap<>();
                optionMap.put("id", option.getId());
                optionMap.put("name", option.getName());
                optionMap.put("description", option.getDescription());
                optionMap.put("price", option.getPrice());
                optionMap.put("isActive", option.getIsActive());
                optionMap.put("icon_name", option.getIconName());
                return optionMap;
            })
            .collect(Collectors.toList());
    }
    
    @Override
    public Map<String, Object> validateTripCreation(CreateTripRequest request) {
        Map<String, Object> validation = new HashMap<>();
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        
        // Validate departure time
        if (request.getDepartureTime().isBefore(java.time.LocalDateTime.now())) {
            errors.add("Departure time must be in the future");
        }
        
        // Validate arrival time
        if (request.getArrivalTime() != null && request.getArrivalTime().isBefore(request.getDepartureTime())) {
            errors.add("Arrival time must be after departure time");
        }
        
        // Validate price
        if (request.getPricePerSeat().doubleValue() <= 0) {
            errors.add("Price per seat must be greater than 0");
        }
        
        if (request.getPricePerSeat().doubleValue() > 320) { // 320 TND ≈ 100 EUR
            warnings.add("Price per seat is quite high (over 320 TND)");
        }

        Double estimatedFuelCost = null;
        Double maxRecommendedSeatPrice = null;
        if (request.getDepartureCity() != null && request.getArrivalCity() != null &&
            !request.getDepartureCity().trim().isEmpty() && !request.getArrivalCity().trim().isEmpty()) {
            estimatedFuelCost = estimateFuelCostForRoute(request.getDepartureCity(), request.getArrivalCity());
            if (estimatedFuelCost != null && estimatedFuelCost > 0) {
                double computedCap = calculateSeatPriceCap(estimatedFuelCost);
                if (computedCap > 0) {
                    maxRecommendedSeatPrice = computedCap;
                }
                if (maxRecommendedSeatPrice != null && maxRecommendedSeatPrice > 0 &&
                    request.getPricePerSeat().doubleValue() > maxRecommendedSeatPrice) {
                    errors.add(String.format(
                        "Price per seat cannot exceed %.0f coins for this route (estimated fuel cost %.2f TND)",
                        maxRecommendedSeatPrice,
                        estimatedFuelCost
                    ));
                }
            }
        }

        if (request.getPricePerSeat().doubleValue() >= FRIENDLY_PRICE_STEP &&
            !isMultipleOfStep(request.getPricePerSeat().doubleValue(), FRIENDLY_PRICE_STEP)) {
            errors.add("Price per seat must be rounded to 5-coin steps (e.g., 10, 15, 20, 25, 30)");
        }
        
        // Validate seats
        if (request.getMaxSeats() <= 0 || request.getMaxSeats() > 8) {
            errors.add("Maximum seats must be between 1 and 8");
        }
        
        // Validate cities
        if (request.getDepartureCity() == null || request.getDepartureCity().trim().isEmpty()) {
            errors.add("Departure city is required");
        }
        
        if (request.getArrivalCity() == null || request.getArrivalCity().trim().isEmpty()) {
            errors.add("Arrival city is required");
        }
        
        if (request.getDepartureCity() != null && request.getArrivalCity() != null &&
            request.getDepartureCity().equals(request.getArrivalCity())) {
            warnings.add("Departure and arrival cities are the same");
        }
        
        validation.put("valid", errors.isEmpty());
        validation.put("errors", errors);
        validation.put("warnings", warnings);
        validation.put("estimatedFuelCost", estimatedFuelCost);
        validation.put("maxRecommendedPricePerSeat", maxRecommendedSeatPrice);
        
        return validation;
    }
    
    @Override
    public Map<String, Object> estimateTrip(Map<String, Object> routeData) {
        Map<String, Object> estimation = new HashMap<>();
        
        String departureAddress = (String) routeData.get("departureAddress");
        String arrivalAddress = (String) routeData.get("arrivalAddress");
        
        // Get actual GPS coordinates and calculate real distance
        Map<String, Object> routeInfo = calculateRealDistanceBetweenCities(departureAddress, arrivalAddress);
        double distance = (Double) routeInfo.get("distance");
        Map<String, Double> departureCoords = extractCoordinateMap(routeInfo.get("departureCoords"));
        Map<String, Double> arrivalCoords = extractCoordinateMap(routeInfo.get("arrivalCoords"));
        
        // Calculate duration based on realistic average speed for Tunisia
        // Shorter distances: slower average speed (50-60 km/h due to city traffic)
        // Longer distances: higher average speed (80-90 km/h due to highways)
        double averageSpeed;
        if (distance < 100) {
            averageSpeed = 55; // City-to-city with some highway
        } else if (distance < 200) {
            averageSpeed = 75; // Mix of city and highway
        } else {
            averageSpeed = 85; // Mostly highway driving
        }
        
        int duration = (int) (distance / averageSpeed * 60); // Convert to minutes
        
        estimation.put("distance", Math.round(distance * 100.0) / 100.0);
        estimation.put("duration", duration);
        estimation.put("durationFormatted", formatDuration(duration));
        // More accurate fuel cost calculation for Tunisia (1.8 TND/liter, 7L/100km average)
        double fuelCostInTND = distance * FUEL_PRICE_TND_PER_LITER * AVERAGE_FUEL_CONSUMPTION_PER_KM;
        estimation.put("estimatedFuelCost", Math.round(fuelCostInTND * 100.0) / 100.0);
        estimation.put("currency", "TND");
        estimation.put("route", Map.of(
            "departure", departureAddress,
            "arrival", arrivalAddress,
            "departureCoords", departureCoords,
            "arrivalCoords", arrivalCoords,
            "waypoints", new ArrayList<>()
        ));
        
        return estimation;
    }
    
    private Map<String, Object> calculateRealDistanceBetweenCities(String departure, String arrival) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Find cities in database by name (case-insensitive)
            List<Ville> departureCities = villeRepository.findByNameContainingIgnoreCase(departure.trim());
            List<Ville> arrivalCities = villeRepository.findByNameContainingIgnoreCase(arrival.trim());
            
            Ville departureCity = null;
            Ville arrivalCity = null;
            
            // Find exact match or best match
            for (Ville city : departureCities) {
                if (city.getName().equalsIgnoreCase(departure.trim())) {
                    departureCity = city;
                    break;
                }
            }
            if (departureCity == null && !departureCities.isEmpty()) {
                departureCity = departureCities.get(0); // Take first match
            }
            
            for (Ville city : arrivalCities) {
                if (city.getName().equalsIgnoreCase(arrival.trim())) {
                    arrivalCity = city;
                    break;
                }
            }
            if (arrivalCity == null && !arrivalCities.isEmpty()) {
                arrivalCity = arrivalCities.get(0); // Take first match
            }
            
            if (departureCity != null && arrivalCity != null && 
                departureCity.getLatitude() != null && departureCity.getLongitude() != null &&
                arrivalCity.getLatitude() != null && arrivalCity.getLongitude() != null) {
                
                // Calculate straight-line distance using Haversine formula
                double straightLineDistance = calculateHaversineDistance(
                    departureCity.getLatitude(), departureCity.getLongitude(),
                    arrivalCity.getLatitude(), arrivalCity.getLongitude()
                );
                
                // Convert straight-line distance to realistic driving distance
                // For Tunisia, driving distance is typically 1.4-2.2x the straight-line distance
                // depending on road conditions and route availability
                double distanceMultiplier = calculateDrivingDistanceMultiplier(straightLineDistance);
                double distance = straightLineDistance * distanceMultiplier;
                
                System.out.println("DEBUG: Found cities in DB: " + departureCity.getName() + " -> " + arrivalCity.getName());
                System.out.println("DEBUG: Straight-line distance: " + straightLineDistance + " km");
                System.out.println("DEBUG: Distance multiplier: " + distanceMultiplier + "x");
                System.out.println("DEBUG: Final driving distance: " + distance + " km");
                
                result.put("distance", distance);
                result.put("departureCoords", Map.of(
                    "latitude", departureCity.getLatitude(),
                    "longitude", departureCity.getLongitude()
                ));
                result.put("arrivalCoords", Map.of(
                    "latitude", arrivalCity.getLatitude(),
                    "longitude", arrivalCity.getLongitude()
                ));
                
                return result;
            }
            
            System.out.println("DEBUG: Cities not found in database, using fallback");
            
        } catch (Exception e) {
            System.out.println("DEBUG: Error calculating distance: " + e.getMessage());
        }
        
        // Fallback to default distance
        result.put("distance", 100.0);
        result.put("departureCoords", Map.of("latitude", 0.0, "longitude", 0.0));
        result.put("arrivalCoords", Map.of("latitude", 0.0, "longitude", 0.0));
        
        return result;
    }

    private Double estimateFuelCostForRoute(String departureCity, String arrivalCity) {
        try {
            Map<String, Object> routeInfo = calculateRealDistanceBetweenCities(departureCity, arrivalCity);
            Object distanceObj = routeInfo.get("distance");
            if (distanceObj instanceof Double distance && distance > 0) {
                double fuelCost = distance * FUEL_PRICE_TND_PER_LITER * AVERAGE_FUEL_CONSUMPTION_PER_KM;
                return Math.round(fuelCost * 100.0) / 100.0;
            }
        } catch (Exception e) {
            System.out.println("DEBUG: Unable to estimate fuel cost: " + e.getMessage());
        }
        return null;
    }

    private double calculateSeatPriceCap(double estimatedFuelCost) {
        double rawLimit = estimatedFuelCost * MAX_SEAT_PRICE_FUEL_RATIO;
        if (rawLimit <= 0) {
            return 0;
        }
        if (rawLimit < FRIENDLY_PRICE_STEP) {
            return Math.round(rawLimit * 100.0) / 100.0;
        }
        double rounded = Math.floor(rawLimit / FRIENDLY_PRICE_STEP) * FRIENDLY_PRICE_STEP;
        if (rounded < FRIENDLY_PRICE_STEP) {
            rounded = FRIENDLY_PRICE_STEP;
        }
        return rounded;
    }

    private boolean isMultipleOfStep(double value, double step) {
        double remainder = value % step;
        return Math.abs(remainder) < 0.0001 || Math.abs(remainder - step) < 0.0001;
    }
    
    private Map<String, Double> extractCoordinateMap(Object value) {
        Map<String, Double> fallback = new HashMap<>();
        fallback.put("latitude", 0.0);
        fallback.put("longitude", 0.0);

        if (value instanceof Map<?, ?> rawMap) {
            Object lat = rawMap.get("latitude");
            Object lon = rawMap.get("longitude");

            if (lat instanceof Number && lon instanceof Number) {
                Map<String, Double> coords = new HashMap<>();
                coords.put("latitude", ((Number) lat).doubleValue());
                coords.put("longitude", ((Number) lon).doubleValue());
                return coords;
            }
        }

        return fallback;
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Radius of the earth in km
        
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = R * c; // convert to kilometers
        
        return distance;
    }
    
    /**
     * Calculate driving distance multiplier based on straight-line distance
     * For Tunisia, this accounts for road infrastructure and typical routing
     */
    private double calculateDrivingDistanceMultiplier(double straightLineDistance) {
        // For short distances (< 50km), roads are more direct: 1.3-1.5x
        if (straightLineDistance < 50) {
            return 1.4;
        }
        // For medium distances (50-150km), factor in highway access: 1.5-1.8x
        else if (straightLineDistance < 150) {
            return 1.65;
        }
        // For long distances (> 150km), highways become more efficient: 1.6-2.0x
        else if (straightLineDistance < 300) {
            return 1.8;
        }
        // For very long distances, highways are most efficient: 1.7-2.2x
        else {
            return 1.95;
        }
    }
    
    @SuppressWarnings("unused")
    private String normalizeCityName(String cityName) {
        if (cityName == null) return "";
        return cityName.toLowerCase()
            .replace("é", "e")
            .replace("è", "e")
            .replace("ê", "e")
            .replace("à", "a")
            .replace("â", "a")
            .replace("ô", "o")
            .replace("ù", "u")
            .replace("û", "u")
            .replace("ç", "c")
            .trim();
    }
    
    @SuppressWarnings("unused")
    private double getDefaultDistanceForCity(String departure, String arrival) {
        // For unknown city combinations, use a reasonable default
        // This could be enhanced with a more sophisticated distance calculation
        return 100.0; // Default 100km for unknown routes
    }
    
    @Override
    public Map<String, Object> saveTripDraft(CreateTripRequest request, Long driverId) {
        Map<String, Object> draft = new HashMap<>();
        
        // In a real implementation, you would save this to a draft table
        // For now, we'll just return the data with a timestamp
        draft.put("id", System.currentTimeMillis()); // Mock ID
        draft.put("driverId", driverId);
        draft.put("data", request);
        draft.put("savedAt", java.time.LocalDateTime.now());
        draft.put("status", "DRAFT");
        
        return draft;
    }
    
    @Override
    public List<Map<String, Object>> getTripDrafts(Long driverId) {
        // Mock implementation - in a real app, you'd query a draft table
        List<Map<String, Object>> drafts = new ArrayList<>();
        
        // Return empty list for now
        return drafts;
    }
    
    @Override
    public void deleteTripDraft(Long draftId, Long driverId) {
        // Mock implementation - in a real app, you'd delete from draft table
        // For now, just return successfully
    }
    
    private String formatDuration(int minutes) {
        int hours = minutes / 60;
        int mins = minutes % 60;
        if (hours > 0) {
            return String.format("%dh %dm", hours, mins);
        } else {
            return String.format("%dm", mins);
        }
    }
    
    private void createPickupPoints(Long tripId, List<GPSPointRequest> pickupPoints) {
        List<Point_GPS> points = new ArrayList<>();
        
        for (int i = 0; i < pickupPoints.size(); i++) {
            GPSPointRequest pointRequest = pickupPoints.get(i);
            
            Point_GPS point = new Point_GPS();
            point.setVoyageId(tripId);
            point.setLatitude(pointRequest.getLatitude());
            point.setLongitude(pointRequest.getLongitude());
            point.setAddress(pointRequest.getAddress());
            point.setPointType(Point_GPS.PointType.PICKUP);
            point.setPickupOrder(i + 1);
            point.setMaxWaitingTime(5); // Default 5 minutes
            
            points.add(point);
        }
        
        pointGpsRepository.saveAll(points);
    }
}
