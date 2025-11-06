package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Voyage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface VoyageRepository extends JpaRepository<Voyage, Long> {
    
    List<Voyage> findByConducteurId(Long conducteurId);
    
    List<Voyage> findByStatus(Voyage.VoyageStatus status);
    
    List<Voyage> findByDepartureTimeAfter(LocalDateTime departureTime);
    
    List<Voyage> findByPricePerSeatBetween(Double minPrice, Double maxPrice);
    
    List<Voyage> findByAvailableSeatsGreaterThan(Integer minSeats);
    
    @Query("SELECT v FROM Voyage v JOIN v.villes ville WHERE ville.id = :villeId")
    List<Voyage> findByVilleId(@Param("villeId") Long villeId);
    
    @Query("SELECT v FROM Voyage v WHERE v.departureTime BETWEEN :startDate AND :endDate")
    List<Voyage> findByDepartureTimeBetween(@Param("startDate") LocalDateTime startDate, 
                                           
                                           
    @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT v FROM Voyage v WHERE v.departureTime BETWEEN :startDate AND :endDate AND v.status = :status")
    List<Voyage> findByDepartureTimeBetweenAndStatus(@Param("startDate") LocalDateTime startDate, 
                                                      @Param("endDate") LocalDateTime endDate,
                                                      @Param("status") Voyage.VoyageStatus status);
    
    List<Voyage> findByConducteurIdAndStatus(Long conducteurId, Voyage.VoyageStatus status);
    
    @Query("SELECT v FROM Voyage v WHERE v.availableSeats > 0 AND v.status = 'PLANNED'")
    List<Voyage> findAvailableTrips();
    
    // Admin dashboard methods
    Long countByStatus(Voyage.VoyageStatus status);
    Long countByCreatedAtAfter(LocalDateTime date);
    
    // Count completed trips for a specific driver
    Long countByConducteurIdAndStatus(Long conducteurId, Voyage.VoyageStatus status);

    @Modifying
    void deleteByIdIn(List<Long> voyageIds);
}
