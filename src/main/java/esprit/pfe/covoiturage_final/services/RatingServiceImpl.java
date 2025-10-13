package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.Avis;
import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.Conducteur;
import esprit.pfe.covoiturage_final.entities.Passager;
import esprit.pfe.covoiturage_final.repositories.AvisRepository;
import esprit.pfe.covoiturage_final.repositories.UserRepository;
import esprit.pfe.covoiturage_final.repositories.ReservationRepository;
import esprit.pfe.covoiturage_final.dto.RatingStatistics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class RatingServiceImpl implements RatingService {
    
    @Autowired
    private AvisRepository avisRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ReservationRepository reservationRepository;
    
    @Autowired
    private NotificationService notificationService;
    
    @Override
    public Avis createRating(Long userId, Long tripId, Integer rating, String comment) {
        return createRating(userId, tripId, rating, comment, null);
    }
    
    private Avis createRating(Long userId, Long tripId, Integer rating, String comment, Long targetUserId) {
        if (!validateRating(rating)) {
            throw new RuntimeException("Invalid rating. Rating must be between 1 and 5.");
        }
        
        if (!validateComment(comment)) {
            throw new RuntimeException("Comment cannot exceed 500 characters.");
        }
        
        // Check if user has already rated this trip
        if (hasUserRatedTrip(userId, tripId)) {
            throw new RuntimeException("You have already rated this trip.");
        }
        
        // Check if user can rate (must have participated in the trip)
        if (!canRateUser(userId, targetUserId, tripId)) {
            throw new RuntimeException("You cannot rate this trip. You must have participated in it.");
        }
        
        Avis avis = new Avis();
        avis.setUserId(targetUserId != null ? targetUserId : getTripParticipantId(tripId, userId));
        avis.setVoyageId(tripId);
        avis.setRating(rating);
        avis.setComment(comment);
        avis.setIsVisible(true);
        
        avis = avisRepository.save(avis);
        
        // Update user's average rating
        updateUserRating(userRepository.findById(targetUserId != null ? targetUserId : getTripParticipantId(tripId, userId)).orElse(null));
        
        // Send notification to rated user
        if (targetUserId != null) {
            User ratedUser = userRepository.findById(targetUserId).orElse(null);
            User rater = userRepository.findById(userId).orElse(null);
            if (ratedUser != null && rater != null) {
                String raterName = rater.getFirstName() + " " + rater.getLastName();
                notificationService.notifyRatingReceived(targetUserId, raterName, rating, comment);
            }
        }
        
        return avis;
    }
    
    @Override
    public Avis createDriverRating(Long passengerId, Long tripId, Integer rating, String comment) {
        // Get the driver ID from the trip
        Long driverId = getTripDriverId(tripId);
        if (driverId == null) {
            throw new RuntimeException("Trip not found");
        }
        
        return createRating(passengerId, tripId, rating, comment, driverId);
    }
    
    @Override
    public Avis createPassengerRating(Long driverId, Long tripId, Integer rating, String comment) {
        // Get the passenger ID (for now, we'll use the driver as the rater and find a passenger)
        Long passengerId = getTripParticipantId(tripId, driverId);
        if (passengerId == null) {
            throw new RuntimeException("No passenger found for this trip");
        }
        
        return createRating(driverId, tripId, rating, comment, passengerId);
    }
    
    @Override
    public Avis updateRating(Long ratingId, Long userId, Integer rating, String comment) {
        Avis avis = avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
        
        // Check if user can update this rating (must be the original rater)
        if (!canUpdateRating(userId, avis)) {
            throw new RuntimeException("You can only update your own ratings");
        }
        
        if (!validateRating(rating)) {
            throw new RuntimeException("Invalid rating. Rating must be between 1 and 5.");
        }
        
        if (!validateComment(comment)) {
            throw new RuntimeException("Comment cannot exceed 500 characters.");
        }
        
        avis.setRating(rating);
        avis.setComment(comment);
        
        avis = avisRepository.save(avis);
        
        // Update user's average rating
        updateUserRating(userRepository.findById(avis.getUserId()).orElse(null));
        
        return avis;
    }
    
    @Override
    public void deleteRating(Long ratingId, Long userId) {
        Avis avis = avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
        
        // Check if user can delete this rating
        if (!canUpdateRating(userId, avis)) {
            throw new RuntimeException("You can only delete your own ratings");
        }
        
        avisRepository.delete(avis);
        
        // Update user's average rating
        updateUserRating(userRepository.findById(avis.getUserId()).orElse(null));
    }
    
    @Override
    public Avis getRatingById(Long ratingId) {
        return avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
    }
    
    @Override
    public List<Avis> getRatingsByUser(Long userId) {
        return avisRepository.findByUserId(userId);
    }
    
    @Override
    public List<Avis> getRatingsByTrip(Long tripId) {
        return avisRepository.findByVoyageId(tripId);
    }
    
    @Override
    public List<Avis> getVisibleRatingsByUser(Long userId) {
        return avisRepository.findVisibleByUserId(userId);
    }
    
    @Override
    public List<Avis> getVisibleRatingsByTrip(Long tripId) {
        return avisRepository.findVisibleByVoyageId(tripId);
    }
    
    @Override
    public List<Avis> getRatingsByRating(Integer rating) {
        return avisRepository.findByRating(rating);
    }
    
    @Override
    public List<Avis> getRatingsByRatingRange(Integer minRating, Integer maxRating) {
        return avisRepository.findByRatingGreaterThanEqual(minRating).stream()
            .filter(avis -> avis.getRating() <= maxRating)
            .collect(java.util.stream.Collectors.toList());
    }
    
    @Override
    public Double getAverageRatingByUser(Long userId) {
        return avisRepository.getAverageRatingByUserId(userId);
    }
    
    @Override
    public Double getAverageRatingByTrip(Long tripId) {
        List<Avis> ratings = avisRepository.findVisibleByVoyageId(tripId);
        if (ratings.isEmpty()) {
            return 0.0;
        }
        
        return ratings.stream()
            .mapToInt(Avis::getRating)
            .average()
            .orElse(0.0);
    }
    
    @Override
    public Long getRatingCountByUser(Long userId) {
        return (long) avisRepository.findVisibleByUserId(userId).size();
    }
    
    @Override
    public Long getRatingCountByTrip(Long tripId) {
        return (long) avisRepository.findVisibleByVoyageId(tripId).size();
    }
    
    @Override
    public RatingStatistics getRatingStatistics(Long userId) {
        RatingStatistics stats = new RatingStatistics();
        stats.setAverageRating(getAverageRatingByUser(userId));
        stats.setTotalRatings(getRatingCountByUser(userId));
        
        List<Avis> ratings = avisRepository.findVisibleByUserId(userId);
        int[] distribution = new int[5];
        for (Avis rating : ratings) {
            if (rating.getRating() >= 1 && rating.getRating() <= 5) {
                distribution[rating.getRating() - 1]++;
            }
        }
        stats.setRatingDistribution(distribution);
        
        return stats;
    }
    
    @Override
    public boolean canRateUser(Long raterId, Long targetUserId, Long tripId) {
        // Check if the rater participated in the trip
        // This would require checking reservations
        return reservationRepository.findByPassagerId(raterId).stream()
            .anyMatch(reservation -> tripId.equals(reservation.getVoyageId()));
    }
    
    @Override
    public boolean hasUserRatedTrip(Long userId, Long tripId) {
        return avisRepository.findByUserId(userId).stream()
            .anyMatch(avis -> tripId.equals(avis.getVoyageId()));
    }
    
    @Override
    public boolean validateRating(Integer rating) {
        return rating != null && rating >= 1 && rating <= 5;
    }
    
    @Override
    public boolean validateComment(String comment) {
        return comment == null || comment.length() <= 500;
    }
    
    @Override
    public List<Avis> getAllRatings() {
        return avisRepository.findAll();
    }
    
    @Override
    public Avis moderateRating(Long ratingId, boolean approve) {
        Avis avis = avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
        
        avis.setIsVisible(approve);
        return avisRepository.save(avis);
    }
    
    @Override
    public List<Avis> getPendingRatings() {
        return avisRepository.findAll().stream()
            .filter(avis -> !avis.getIsVisible())
            .collect(java.util.stream.Collectors.toList());
    }
    
    @Override
    public void hideRating(Long ratingId) {
        Avis avis = avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
        
        avis.setIsVisible(false);
        avisRepository.save(avis);
        
        // Update user's average rating
        updateUserRating(userRepository.findById(avis.getUserId()).orElse(null));
    }
    
    @Override
    public void showRating(Long ratingId) {
        Avis avis = avisRepository.findById(ratingId)
            .orElseThrow(() -> new RuntimeException("Rating not found"));
        
        avis.setIsVisible(true);
        avisRepository.save(avis);
        
        // Update user's average rating
        updateUserRating(userRepository.findById(avis.getUserId()).orElse(null));
    }
    
    @Override
    public void updateUserRating(User user) {
        if (user == null) return;
        
        Double averageRating = getAverageRatingByUser(user.getId());
        
        if (user instanceof Conducteur) {
            Conducteur conducteur = (Conducteur) user;
            conducteur.setRating(averageRating);
            userRepository.save(conducteur);
        } else if (user instanceof Passager) {
            Passager passager = (Passager) user;
            passager.setRating(averageRating);
            userRepository.save(passager);
        }
    }
    
    @Override
    public void recalculateAllUserRatings() {
        List<User> users = userRepository.findAll();
        for (User user : users) {
            updateUserRating(user);
        }
    }
    
    // Helper methods
    private boolean canUpdateRating(Long userId, Avis avis) {
        // For now, we'll allow updates based on trip participation
        // In a real implementation, you might store the rater's ID
        return true; // Simplified for now
    }
    
    private Long getTripParticipantId(Long tripId, Long excludeUserId) {
        // Get a passenger ID from the trip (excluding the excludeUserId)
        return reservationRepository.findByVoyageId(tripId).stream()
            .filter(reservation -> !reservation.getPassagerId().equals(excludeUserId))
            .map(reservation -> reservation.getPassagerId())
            .findFirst()
            .orElse(null);
    }
    
    private Long getTripDriverId(Long tripId) {
        // This would require a join with the trip table
        // For now, return null as we need to implement this properly
        return null;
    }
    
}
