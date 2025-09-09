package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Conducteur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ConducteurRepository extends JpaRepository<Conducteur, Long> {
    List<Conducteur> findByIsVerified(Boolean isVerified);
    List<Conducteur> findByIsAvailable(Boolean isAvailable);
    List<Conducteur> findByRatingGreaterThan(Double rating);
    List<Conducteur> findByVehicleModel(String vehicleModel);
}
