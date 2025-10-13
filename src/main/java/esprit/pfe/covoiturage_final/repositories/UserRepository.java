package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.User;
import esprit.pfe.covoiturage_final.entities.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByUsernameOrEmail(String username, String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    List<User> findByRole(UserRole role);
    List<User> findByIsActive(Boolean isActive);
    
    // Admin dashboard methods
    Long countByIsActive(Boolean isActive);
    Long countByCreatedAtAfter(LocalDateTime date);
    Long countByRole(UserRole role);
    Long countByIsVerified(Boolean isVerified);
    
    // Pagination support
    Page<User> findByRole(UserRole role, Pageable pageable);
    Page<User> findByIsActive(Boolean isActive, Pageable pageable);
    
    // Search methods
    List<User> findByUsernameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(
        String username, String email, String firstName, String lastName);
    
    // Date-based queries
    List<User> findByCreatedAtAfter(LocalDateTime date);
    List<User> findByLastLoginBeforeAndIsActiveTrue(LocalDateTime date);
}
