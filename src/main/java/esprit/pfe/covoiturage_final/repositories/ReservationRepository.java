package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    
    List<Reservation> findByPassagerId(Long passagerId);
    
    List<Reservation> findByVoyageId(Long voyageId);
    
    List<Reservation> findByStatus(Reservation.ReservationStatus status);
    
    List<Reservation> findByReservationDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    List<Reservation> findByPassagerIdAndStatus(Long passagerId, Reservation.ReservationStatus status);
    
    List<Reservation> findByVoyageIdAndStatus(Long voyageId, Reservation.ReservationStatus status);
    
    List<Reservation> findByVoyageIdAndPassagerId(Long voyageId, Long passagerId);
    
    @Query("SELECT COUNT(r) FROM Reservation r WHERE r.voyageId = :voyageId AND r.status = 'CONFIRMED'")
    Long countConfirmedReservationsByVoyageId(@Param("voyageId") Long voyageId);
    
    // Admin dashboard methods
    Long countByStatus(Reservation.ReservationStatus status);

    @Modifying
    void deleteByVoyageIdIn(List<Long> voyageIds);
    
    @Query("SELECT r.passagerId, u.firstName, u.lastName " +
           "FROM Reservation r " +
           "JOIN User u ON r.passagerId = u.id " +
           "WHERE r.voyageId = :voyageId AND r.status = 'CONFIRMED'")
    List<Object[]> findPassengersForTrip(@Param("voyageId") Long voyageId);
}
