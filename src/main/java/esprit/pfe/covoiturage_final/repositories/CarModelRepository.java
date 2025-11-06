package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.CarModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CarModelRepository extends JpaRepository<CarModel, Long> {

    List<CarModel> findByIsActiveTrueOrderByBrandAscModelAsc();

    long countByIsActiveTrue();

    List<CarModel> findByBrandIgnoreCaseContainingAndIsActiveTrueOrderByModelAsc(String brand);

    List<CarModel> findByModelIgnoreCaseContainingAndIsActiveTrueOrderByBrandAscModelAsc(String model);

    @Query("SELECT DISTINCT c.brand FROM CarModel c WHERE c.isActive = true ORDER BY c.brand")
    List<String> findDistinctBrands();

    @Query("SELECT c FROM CarModel c WHERE c.isActive = true AND " +
           "(LOWER(c.brand) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(c.model) LIKE LOWER(CONCAT('%', :query, '%'))) " +
           "ORDER BY c.brand, c.model")
    List<CarModel> searchByBrandOrModel(@Param("query") String query);

    List<CarModel> findByBrandAndIsActiveTrueOrderByModelAsc(String brand);
}











