package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.UserLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserLocationRepository extends JpaRepository<UserLocation, Long> {
    
    Optional<UserLocation> findByUserId(Long userId);
    
    List<UserLocation> findByIsSharingTrue();
    
    @Query("SELECT ul FROM UserLocation ul WHERE ul.userId IN :userIds AND ul.isSharing = true")
    List<UserLocation> findByUserIdsAndIsSharingTrue(@Param("userIds") List<Long> userIds);
    
    @Query("SELECT ul FROM UserLocation ul WHERE ul.isSharing = true AND ul.lastUpdated >= :since")
    List<UserLocation> findActiveLocationShares(@Param("since") java.time.LocalDateTime since);
}















