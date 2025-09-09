package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Option;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OptionRepository extends JpaRepository<Option, Long> {
    
    List<Option> findByIsActiveTrue();
    
    List<Option> findByNameContainingIgnoreCase(String name);
    
    List<Option> findByPriceBetween(Double minPrice, Double maxPrice);
}
