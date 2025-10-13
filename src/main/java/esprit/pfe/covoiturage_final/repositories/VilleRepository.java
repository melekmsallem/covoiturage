package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Ville;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VilleRepository extends JpaRepository<Ville, Long> {
    
    Optional<Ville> findByName(String name);
    
    List<Ville> findByNameContainingIgnoreCase(String name);
    
    List<Ville> findByPays(String pays);
    
    List<Ville> findByCodePostal(String codePostal);
    
    @Query(value = "SELECT v.* FROM villes v JOIN voyage_villes vv ON v.id = vv.ville_id WHERE vv.voyage_id = :voyageId", nativeQuery = true)
    List<Ville> findByVoyageId(@Param("voyageId") Long voyageId);
}
