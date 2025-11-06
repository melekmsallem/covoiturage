package esprit.pfe.covoiturage_final.repositories;

import esprit.pfe.covoiturage_final.entities.CoinTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CoinTransactionRepository extends JpaRepository<CoinTransaction, Long> {
    
    List<CoinTransaction> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<CoinTransaction> findByUserIdAndTransactionTypeOrderByCreatedAtDesc(Long userId, CoinTransaction.TransactionType transactionType);
    
    List<CoinTransaction> findByReferenceId(String referenceId);
}
