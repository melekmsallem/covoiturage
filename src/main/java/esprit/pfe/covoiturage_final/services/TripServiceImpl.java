package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import esprit.pfe.covoiturage_final.entities.*;
import esprit.pfe.covoiturage_final.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
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
        trip.setPricePerSeat(request.getPricePerSeat());
        trip.setMaxSeats(request.getMaxSeats());
        trip.setAvailableSeats(request.getMaxSeats());
        trip.setDescription(request.getDescription());
        trip.setStatus(Voyage.VoyageStatus.PLANNED);
        trip.setConducteurId(driverId);
        
        trip = voyageRepository.save(trip);
        
        // Create GPS points
        createGPSPoints(trip.getId(), request);
        
        // Add options if provided
        if (request.getOptionIds() != null && !request.getOptionIds().isEmpty()) {
            List<Option> options = optionRepository.findAllById(request.getOptionIds());
            trip.setOptions(options);
            voyageRepository.save(trip);
        }
        
        // Add cities if provided
        if (request.getVilleIds() != null && !request.getVilleIds().isEmpty()) {
            List<Ville> cities = villeRepository.findAllById(request.getVilleIds());
            trip.setVilles(cities);
            voyageRepository.save(trip);
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
        trip.setPricePerSeat(request.getPricePerSeat());
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
        reservations.forEach(reservation -> {
            reservation.setStatus(Reservation.ReservationStatus.CANCELLED);
            reservationRepository.save(reservation);
        });
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
        Point_GPS startPoint = new Point_GPS();
        startPoint.setVoyageId(tripId);
        startPoint.setLatitude(request.getStartPoint().getLatitude());
        startPoint.setLongitude(request.getStartPoint().getLongitude());
        startPoint.setAddress(request.getStartPoint().getAddress());
        startPoint.setPointType(Point_GPS.PointType.START);
        pointGpsRepository.save(startPoint);
        
        // Create end point
        Point_GPS endPoint = new Point_GPS();
        endPoint.setVoyageId(tripId);
        endPoint.setLatitude(request.getEndPoint().getLatitude());
        endPoint.setLongitude(request.getEndPoint().getLongitude());
        endPoint.setAddress(request.getEndPoint().getAddress());
        endPoint.setPointType(Point_GPS.PointType.END);
        pointGpsRepository.save(endPoint);
        
        // Create intermediate points if provided
        if (request.getIntermediatePoints() != null) {
            for (CreateTripRequest.GPSPointRequest point : request.getIntermediatePoints()) {
                Point_GPS intermediatePoint = new Point_GPS();
                intermediatePoint.setVoyageId(tripId);
                intermediatePoint.setLatitude(point.getLatitude());
                intermediatePoint.setLongitude(point.getLongitude());
                intermediatePoint.setAddress(point.getAddress());
                intermediatePoint.setPointType(Point_GPS.PointType.INTERMEDIATE);
                pointGpsRepository.save(intermediatePoint);
            }
        }
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
}
