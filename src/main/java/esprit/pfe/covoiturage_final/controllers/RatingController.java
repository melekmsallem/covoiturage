package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.Avis;
import esprit.pfe.covoiturage_final.services.RatingService;
import esprit.pfe.covoiturage_final.dto.RatingStatistics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ratings")
@CrossOrigin(origins = "*", maxAge = 3600)
public class RatingController {
    
    @Autowired
    private RatingService ratingService;
    
    @PostMapping
    public ResponseEntity<?> createRating(@Valid @RequestBody CreateRatingRequest request) {
        try {
            Long userId = getCurrentUserId();
            Avis rating = ratingService.createRating(
                userId,
                request.getTripId(),
                request.getRating(),
                request.getComment()
            );
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/driver")
    public ResponseEntity<?> rateDriver(@Valid @RequestBody RateDriverRequest request) {
        try {
            Long userId = getCurrentUserId();
            Avis rating = ratingService.createDriverRating(
                userId,
                request.getTripId(),
                request.getRating(),
                request.getComment()
            );
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/passenger")
    public ResponseEntity<?> ratePassenger(@Valid @RequestBody RatePassengerRequest request) {
        try {
            Long userId = getCurrentUserId();
            Avis rating = ratingService.createPassengerRating(
                userId,
                request.getTripId(),
                request.getRating(),
                request.getComment()
            );
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/{ratingId}")
    public ResponseEntity<?> updateRating(@PathVariable Long ratingId, @Valid @RequestBody UpdateRatingRequest request) {
        try {
            Long userId = getCurrentUserId();
            Avis rating = ratingService.updateRating(
                ratingId,
                userId,
                request.getRating(),
                request.getComment()
            );
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @DeleteMapping("/{ratingId}")
    public ResponseEntity<?> deleteRating(@PathVariable Long ratingId) {
        try {
            Long userId = getCurrentUserId();
            ratingService.deleteRating(ratingId, userId);
            return ResponseEntity.ok("Rating deleted successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/{ratingId}")
    public ResponseEntity<?> getRating(@PathVariable Long ratingId) {
        try {
            Avis rating = ratingService.getRatingById(ratingId);
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserRatings(@PathVariable Long userId) {
        try {
            List<Avis> ratings = ratingService.getVisibleRatingsByUser(userId);
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/trip/{tripId}")
    public ResponseEntity<?> getTripRatings(@PathVariable Long tripId) {
        try {
            List<Avis> ratings = ratingService.getVisibleRatingsByTrip(tripId);
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/rating/{rating}")
    public ResponseEntity<?> getRatingsByRating(@PathVariable @Min(1) @Max(5) Integer rating) {
        try {
            List<Avis> ratings = ratingService.getRatingsByRating(rating);
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/range")
    public ResponseEntity<?> getRatingsByRange(@RequestParam @Min(1) Integer minRating, 
                                              @RequestParam @Max(5) Integer maxRating) {
        try {
            List<Avis> ratings = ratingService.getRatingsByRatingRange(minRating, maxRating);
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/user/{userId}/average")
    public ResponseEntity<?> getUserAverageRating(@PathVariable Long userId) {
        try {
            Double averageRating = ratingService.getAverageRatingByUser(userId);
            return ResponseEntity.ok(new AverageRatingResponse(averageRating));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/trip/{tripId}/average")
    public ResponseEntity<?> getTripAverageRating(@PathVariable Long tripId) {
        try {
            Double averageRating = ratingService.getAverageRatingByTrip(tripId);
            return ResponseEntity.ok(new AverageRatingResponse(averageRating));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/user/{userId}/statistics")
    public ResponseEntity<?> getUserRatingStatistics(@PathVariable Long userId) {
        try {
            RatingStatistics statistics = ratingService.getRatingStatistics(userId);
            return ResponseEntity.ok(statistics);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/count/user/{userId}")
    public ResponseEntity<?> getUserRatingCount(@PathVariable Long userId) {
        try {
            Long count = ratingService.getRatingCountByUser(userId);
            return ResponseEntity.ok(new RatingCountResponse(count));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/count/trip/{tripId}")
    public ResponseEntity<?> getTripRatingCount(@PathVariable Long tripId) {
        try {
            Long count = ratingService.getRatingCountByTrip(tripId);
            return ResponseEntity.ok(new RatingCountResponse(count));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/can-rate/{tripId}")
    public ResponseEntity<?> canRateTrip(@PathVariable Long tripId) {
        try {
            Long userId = getCurrentUserId();
            boolean canRate = !ratingService.hasUserRatedTrip(userId, tripId);
            return ResponseEntity.ok(new CanRateResponse(canRate));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/my-ratings")
    public ResponseEntity<?> getMyRatings() {
        try {
            Long userId = getCurrentUserId();
            List<Avis> ratings = ratingService.getRatingsByUser(userId);
            return ResponseEntity.ok(Map.of("data", ratings));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    // Admin endpoints
    @GetMapping("/admin/all")
    public ResponseEntity<?> getAllRatings() {
        try {
            List<Avis> ratings = ratingService.getAllRatings();
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/admin/pending")
    public ResponseEntity<?> getPendingRatings() {
        try {
            List<Avis> ratings = ratingService.getPendingRatings();
            return ResponseEntity.ok(ratings);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/admin/{ratingId}/moderate")
    public ResponseEntity<?> moderateRating(@PathVariable Long ratingId, @RequestBody ModerateRatingRequest request) {
        try {
            Avis rating = ratingService.moderateRating(ratingId, request.isApprove());
            return ResponseEntity.ok(rating);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/admin/{ratingId}/hide")
    public ResponseEntity<?> hideRating(@PathVariable Long ratingId) {
        try {
            ratingService.hideRating(ratingId);
            return ResponseEntity.ok("Rating hidden successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PutMapping("/admin/{ratingId}/show")
    public ResponseEntity<?> showRating(@PathVariable Long ratingId) {
        try {
            ratingService.showRating(ratingId);
            return ResponseEntity.ok("Rating shown successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @PostMapping("/admin/recalculate-all")
    public ResponseEntity<?> recalculateAllRatings() {
        try {
            ratingService.recalculateAllUserRatings();
            return ResponseEntity.ok("All user ratings recalculated successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            return user.getId();
        }
        throw new RuntimeException("User not authenticated");
    }
    
    // Request/Response classes
    public static class CreateRatingRequest {
        @Min(1) @Max(5)
        private Integer rating;
        private String comment;
        private Long tripId;
        
        public Integer getRating() { return rating; }
        public void setRating(Integer rating) { this.rating = rating; }
        
        public String getComment() { return comment; }
        public void setComment(String comment) { this.comment = comment; }
        
        public Long getTripId() { return tripId; }
        public void setTripId(Long tripId) { this.tripId = tripId; }
    }
    
    public static class RateDriverRequest {
        @Min(1) @Max(5)
        private Integer rating;
        private String comment;
        private Long tripId;
        
        public Integer getRating() { return rating; }
        public void setRating(Integer rating) { this.rating = rating; }
        
        public String getComment() { return comment; }
        public void setComment(String comment) { this.comment = comment; }
        
        public Long getTripId() { return tripId; }
        public void setTripId(Long tripId) { this.tripId = tripId; }
    }
    
    public static class RatePassengerRequest {
        @Min(1) @Max(5)
        private Integer rating;
        private String comment;
        private Long tripId;
        
        public Integer getRating() { return rating; }
        public void setRating(Integer rating) { this.rating = rating; }
        
        public String getComment() { return comment; }
        public void setComment(String comment) { this.comment = comment; }
        
        public Long getTripId() { return tripId; }
        public void setTripId(Long tripId) { this.tripId = tripId; }
    }
    
    public static class UpdateRatingRequest {
        @Min(1) @Max(5)
        private Integer rating;
        private String comment;
        
        public Integer getRating() { return rating; }
        public void setRating(Integer rating) { this.rating = rating; }
        
        public String getComment() { return comment; }
        public void setComment(String comment) { this.comment = comment; }
    }
    
    public static class ModerateRatingRequest {
        private boolean approve;
        
        public boolean isApprove() { return approve; }
        public void setApprove(boolean approve) { this.approve = approve; }
    }
    
    public static class AverageRatingResponse {
        private Double averageRating;
        
        public AverageRatingResponse(Double averageRating) {
            this.averageRating = averageRating;
        }
        
        public Double getAverageRating() { return averageRating; }
        public void setAverageRating(Double averageRating) { this.averageRating = averageRating; }
    }
    
    public static class RatingCountResponse {
        private Long count;
        
        public RatingCountResponse(Long count) {
            this.count = count;
        }
        
        public Long getCount() { return count; }
        public void setCount(Long count) { this.count = count; }
    }
    
    public static class CanRateResponse {
        private boolean canRate;
        
        public CanRateResponse(boolean canRate) {
            this.canRate = canRate;
        }
        
        public boolean isCanRate() { return canRate; }
        public void setCanRate(boolean canRate) { this.canRate = canRate; }
    }
}
