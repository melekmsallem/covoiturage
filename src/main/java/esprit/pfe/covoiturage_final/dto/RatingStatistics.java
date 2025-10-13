package esprit.pfe.covoiturage_final.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatistics {
    private Double averageRating;
    private Long totalRatings;
    private int[] ratingDistribution = new int[5]; // 1-5 stars
    
    public RatingStatistics(Double averageRating, Long totalRatings) {
        this.averageRating = averageRating;
        this.totalRatings = totalRatings;
        this.ratingDistribution = new int[5];
    }
}


