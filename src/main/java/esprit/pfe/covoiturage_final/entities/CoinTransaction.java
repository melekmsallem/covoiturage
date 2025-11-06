package esprit.pfe.covoiturage_final.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "coin_transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoinTransaction {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false)
    private TransactionType transactionType;
    
    @Column(name = "amount", nullable = false)
    private Double amount;
    
    @Column(name = "balance_before", nullable = false)
    private Double balanceBefore;
    
    @Column(name = "balance_after", nullable = false)
    private Double balanceAfter;
    
    @Column(name = "description")
    private String description;
    
    @Column(name = "reference_id") // For linking to reservations, stripe payments, etc.
    private String referenceId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TransactionStatus status = TransactionStatus.COMPLETED;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    public enum TransactionType {
        PURCHASE, // User bought coins with Stripe
        SPEND,    // User spent coins on booking
        REFUND,   // Coins refunded
        BONUS,    // Company bonus
        ADMIN_ADJ, // Admin adjustment
        TRANSFER  // Received coins from another user
    }
    
    public enum TransactionStatus {
        PENDING, COMPLETED, FAILED, CANCELLED
    }
}
