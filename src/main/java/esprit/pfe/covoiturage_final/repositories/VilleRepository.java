package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Ville;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VilleRepository extends JpaRepository<Ville, Long> {
    
    Optional<Ville> findByName(String name);
    
    List<Ville> findByNameContainingIgnoreCase(String name);
    
    List<Ville> findByPays(String pays);
    
    List<Ville> findByCodePostal(String codePostal);
}
