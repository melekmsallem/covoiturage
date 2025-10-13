package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Avis;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.dto.RatingStatistics;

import java.util.List;

public interface RatingService {
    
    // Rating Management
    Avis createRating(Long userId, Long tripId, Integer rating, String comment);
    Avis createDriverRating(Long passengerId, Long tripId, Integer rating, String comment);
    Avis createPassengerRating(Long driverId, Long tripId, Integer rating, String comment);
    Avis updateRating(Long ratingId, Long userId, Integer rating, String comment);
    void deleteRating(Long ratingId, Long userId);
    
    // Rating Retrieval
    Avis getRatingById(Long ratingId);
    List<Avis> getRatingsByUser(Long userId);
    List<Avis> getRatingsByTrip(Long tripId);
    List<Avis> getVisibleRatingsByUser(Long userId);
    List<Avis> getVisibleRatingsByTrip(Long tripId);
    List<Avis> getRatingsByRating(Integer rating);
    List<Avis> getRatingsByRatingRange(Integer minRating, Integer maxRating);
    
    // Rating Statistics
    Double getAverageRatingByUser(Long userId);
    Double getAverageRatingByTrip(Long tripId);
    Long getRatingCountByUser(Long userId);
    Long getRatingCountByTrip(Long tripId);
    RatingStatistics getRatingStatistics(Long userId);
    
    // Rating Validation
    boolean canRateUser(Long raterId, Long targetUserId, Long tripId);
    boolean hasUserRatedTrip(Long userId, Long tripId);
    boolean validateRating(Integer rating);
    boolean validateComment(String comment);
    
    // Admin Functions
    List<Avis> getAllRatings();
    Avis moderateRating(Long ratingId, boolean approve);
    List<Avis> getPendingRatings();
    void hideRating(Long ratingId);
    void showRating(Long ratingId);
    
    // Rating Updates
    void updateUserRating(User user);
    void recalculateAllUserRatings();
}
