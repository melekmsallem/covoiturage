package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Passager;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PassagerRepository extends JpaRepository<Passager, Long> {
    List<Passager> findByIsVerified(Boolean isVerified);
    List<Passager> findByRatingGreaterThan(Double rating);
}
