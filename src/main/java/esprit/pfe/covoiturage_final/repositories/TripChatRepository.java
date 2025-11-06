package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.TripChat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TripChatRepository extends JpaRepository<TripChat, Long> {
    Optional<TripChat> findByVoyageIdAndIsActiveTrue(Long voyageId);
}









