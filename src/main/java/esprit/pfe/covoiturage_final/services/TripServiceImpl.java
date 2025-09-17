package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Service
@Transactional
public class TripServiceImpl implements TripService {
    
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
        
        trip = voyageRepository.save(trip);
        
        // Create GPS points
        createGPSPoints(trip.getId(), request);
        
        // Send notification to driver
        notificationService.notifyTripCreated(driverId, trip.getId(), trip.getDescription());
        
        // Add options if provided
        if (request.getOptionIds() != null && !request.getOptionIds().isEmpty()) {
            List<Option> options = optionRepository.findAllById(request.getOptionIds());
            trip.setOptions(options);
            voyageRepository.save(trip);
        }
        
        // Add cities if provided - using city names instead of IDs
        if (request.getDepartureCity() != null && request.getArrivalCity() != null) {
            // In a real implementation, you would find cities by name
            // For now, we'll skip this as the relationship is complex
        }
        
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
        
        trip.setStatus(Voyage.VoyageStatus.COMPLETED);
        trip = voyageRepository.save(trip);
        
        return convertToTripResponse(trip);
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
        
        // Create reservation
        Reservation reservation = new Reservation();
        reservation.setVoyageId(request.getTripId());
        reservation.setPassagerId(passengerId);
        reservation.setNumberOfSeats(request.getNumberOfSeats());
        reservation.setTotalPrice(trip.getPricePerSeat() * request.getNumberOfSeats());
        reservation.setStatus(Reservation.ReservationStatus.PENDING);
        reservation.setNotes(request.getNotes());
        
        reservation = reservationRepository.save(reservation);
        
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
    public List<BookingResponse> getBookingsByTrip(Long tripId) {
        List<Reservation> reservations = reservationRepository.findByVoyageId(tripId);
        return reservations.stream()
            .map(this::convertToBookingResponse)
            .collect(Collectors.toList());
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
        
        reservation.setStatus(Reservation.ReservationStatus.CONFIRMED);
        reservation = reservationRepository.save(reservation);
        
        // Send notification to passenger
        notificationService.notifyBookingConfirmed(reservation.getPassagerId(), bookingId);
        
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
        // Get trips where user is driver or has confirmed bookings
        List<Voyage> driverTrips = voyageRepository.findByConducteurIdAndStatus(userId, Voyage.VoyageStatus.PLANNED);
        List<Reservation> passengerBookings = reservationRepository.findByPassagerIdAndStatus(userId, Reservation.ReservationStatus.CONFIRMED);
        
        List<Long> tripIds = passengerBookings.stream()
            .map(Reservation::getVoyageId)
            .collect(Collectors.toList());
        
        List<Voyage> passengerTrips = voyageRepository.findAllById(tripIds).stream()
            .filter(trip -> trip.getStatus() == Voyage.VoyageStatus.PLANNED)
            .collect(Collectors.toList());
        
        driverTrips.addAll(passengerTrips);
        
        return driverTrips.stream()
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
        response.setCreatedAt(trip.getCreatedAt());
        response.setUpdatedAt(trip.getUpdatedAt());
        
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
            
            // Get driver information
            User driver = userRepository.findById(trip.getConducteurId()).orElse(null);
            if (driver instanceof Conducteur) {
                Conducteur conducteur = (Conducteur) driver;
                tripInfo.setDriverName(conducteur.getFirstName() + " " + conducteur.getLastName());
                tripInfo.setVehicleModel(conducteur.getVehicleModel());
                tripInfo.setVehicleColor(conducteur.getVehicleColor());
                tripInfo.setVehiclePlate(conducteur.getVehiclePlate());
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
        Map<String, Double> departureCoords = (Map<String, Double>) routeInfo.get("departureCoords");
        Map<String, Double> arrivalCoords = (Map<String, Double>) routeInfo.get("arrivalCoords");
        
        // Calculate duration based on realistic average speed (80 km/h for highways)
        int duration = (int) (distance / 80 * 60); // Convert to minutes
        
        estimation.put("distance", Math.round(distance * 100.0) / 100.0);
        estimation.put("duration", duration);
        estimation.put("durationFormatted", formatDuration(duration));
        // Convert fuel cost to Tunisian dinars (1 EUR ≈ 3.2 TND, fuel cost 0.15 EUR/km)
        double fuelCostInTND = distance * 0.15 * 3.2; // Convert EUR to TND
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
                
                // Calculate distance using Haversine formula
                double distance = calculateHaversineDistance(
                    departureCity.getLatitude(), departureCity.getLongitude(),
                    arrivalCity.getLatitude(), arrivalCity.getLongitude()
                );
                
                System.out.println("DEBUG: Found cities in DB: " + departureCity.getName() + " -> " + arrivalCity.getName());
                System.out.println("DEBUG: Calculated distance: " + distance + " km");
                
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
}
