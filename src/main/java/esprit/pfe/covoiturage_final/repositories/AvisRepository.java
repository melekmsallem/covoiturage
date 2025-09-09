package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Avis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AvisRepository extends JpaRepository<Avis, Long> {
    
    List<Avis> findByUserId(Long userId);
    
    List<Avis> findByVoyageId(Long voyageId);
    
    List<Avis> findByIsVisibleTrue();
    
    List<Avis> findByRating(Integer rating);
    
    List<Avis> findByRatingGreaterThanEqual(Integer minRating);
    
    @Query("SELECT AVG(a.rating) FROM Avis a WHERE a.userId = :userId AND a.isVisible = true")
    Double getAverageRatingByUserId(@Param("userId") Long userId);
    
    @Query("SELECT a FROM Avis a WHERE a.userId = :userId AND a.isVisible = true")
    List<Avis> findVisibleByUserId(@Param("userId") Long userId);
    
    @Query("SELECT a FROM Avis a WHERE a.voyageId = :voyageId AND a.isVisible = true")
    List<Avis> findVisibleByVoyageId(@Param("voyageId") Long voyageId);
}
