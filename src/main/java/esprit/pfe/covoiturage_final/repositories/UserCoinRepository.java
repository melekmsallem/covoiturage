package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.UserCoin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserCoinRepository extends JpaRepository<UserCoin, Long> {
    
    Optional<UserCoin> findByUserId(Long userId);
    
    boolean existsByUserId(Long userId);
}
