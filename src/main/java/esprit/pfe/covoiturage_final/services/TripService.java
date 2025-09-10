package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;

import java.util.List;

public interface TripService {
    
    // Trip Management
    TripResponse createTrip(CreateTripRequest request, Long driverId);
    TripResponse getTripById(Long tripId);
    List<TripResponse> getTripsByDriver(Long driverId);
    List<TripResponse> searchTrips(SearchTripRequest request);
    TripResponse updateTrip(Long tripId, CreateTripRequest request, Long driverId);
    void cancelTrip(Long tripId, Long driverId);
    void deleteTrip(Long tripId, Long driverId);
    
    // Trip Status Management
    TripResponse startTrip(Long tripId, Long driverId);
    TripResponse completeTrip(Long tripId, Long driverId);
    
    // Booking Management
    BookingResponse createBooking(BookingRequest request, Long passengerId);
    BookingResponse getBookingById(Long bookingId);
    List<BookingResponse> getBookingsByPassenger(Long passengerId);
    List<BookingResponse> getBookingsByTrip(Long tripId);
    BookingResponse confirmBooking(Long bookingId, Long driverId);
    BookingResponse cancelBooking(Long bookingId, Long userId);
    
    // Trip Statistics
    List<TripResponse> getAvailableTrips();
    List<TripResponse> getUpcomingTrips(Long userId);
    List<TripResponse> getCompletedTrips(Long userId);
}
