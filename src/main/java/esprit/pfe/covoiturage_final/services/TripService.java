package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Map;

public interface TripService {
    
    // Trip Management
    TripResponse createTrip(CreateTripRequest request, Long driverId);
    TripResponse getTripById(Long tripId);
    List<TripResponse> getTripsByDriver(Long driverId);
    List<TripResponse> searchTrips(SearchTripRequest request);
    List<TripResponse> searchTrips(TripSearchRequest request);
    Page<TripResponse> searchTripsPageable(TripSearchRequest request, Pageable pageable);
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
    Page<BookingResponse> getBookingsByPassengerPageable(Long passengerId, Pageable pageable);
    List<BookingResponse> getBookingsByDriver(Long driverId);
    Page<BookingResponse> getBookingsByDriverPageable(Long driverId, Pageable pageable);
    List<BookingResponse> getBookingsByTrip(Long tripId);
    BookingResponse confirmBooking(Long bookingId, Long driverId);
    BookingResponse declineBooking(Long bookingId, Long driverId);
    BookingResponse cancelBooking(Long bookingId, Long userId);
    
    // Trip Statistics
    List<TripResponse> getAvailableTrips();
    List<TripResponse> getUpcomingTrips(Long userId);
    List<TripResponse> getCompletedTrips(Long userId);
    
    // Trip Creation Enhancement
    List<Map<String, Object>> getAllCities();
    List<Map<String, Object>> getAllOptions();
    Map<String, Object> validateTripCreation(CreateTripRequest request);
    Map<String, Object> estimateTrip(Map<String, Object> routeData);
    Map<String, Object> saveTripDraft(CreateTripRequest request, Long driverId);
    List<Map<String, Object>> getTripDrafts(Long driverId);
    void deleteTripDraft(Long draftId, Long driverId);
}
