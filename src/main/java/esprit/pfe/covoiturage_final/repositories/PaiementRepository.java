package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.Paiement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaiementRepository extends JpaRepository<Paiement, Long> {
    
    List<Paiement> findByReservationId(Long reservationId);
    
    List<Paiement> findByAdminId(Long adminId);
    
    List<Paiement> findByStatus(Paiement.PaymentStatus status);
    
    List<Paiement> findByPaymentMethod(Paiement.PaymentMethod paymentMethod);
    
    List<Paiement> findByPaymentDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    Paiement findOneByReservationId(Long reservationId);
    
    List<Paiement> findByAdminIdAndStatus(Long adminId, Paiement.PaymentStatus status);
    
    @Query("SELECT SUM(p.amount) FROM Paiement p WHERE p.status = 'COMPLETED' AND p.paymentDate BETWEEN :startDate AND :endDate")
    Double getTotalRevenueBetween(@Param("startDate") LocalDateTime startDate, 
                                @Param("endDate") LocalDateTime endDate);
}
