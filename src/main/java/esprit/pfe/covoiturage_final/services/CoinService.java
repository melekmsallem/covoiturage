package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.CoinTransaction;
import esprit.pfe.covoiturage_final.entities.UserCoin;

import java.util.List;

public interface CoinService {
    
    // Coin balance management
    UserCoin getOrCreateUserCoin(Long userId);
    Double getUserBalance(Long userId);
    boolean hasSufficientBalance(Long userId, Double amount);
    
    // Coin transactions
    CoinTransaction purchaseCoins(Long userId, Double amount, String stripePaymentId);
    CoinTransaction spendCoins(Long userId, Double amount, String description, String referenceId);
    CoinTransaction refundCoins(Long userId, Double amount, String description, String referenceId);
    CoinTransaction addBonusCoins(Long userId, Double amount, String description);
    void transferCoins(Long fromUserId, Long toUserId, Double amount, String description, String referenceId);
    
    // Transaction history
    List<CoinTransaction> getUserTransactionHistory(Long userId);
    List<CoinTransaction> getUserTransactionHistory(Long userId, CoinTransaction.TransactionType transactionType);
    
    // Admin functions
    CoinTransaction adminAdjustCoins(Long userId, Double amount, String description);
    List<CoinTransaction> getAllTransactions();
    Double getTotalCoinsInSystem();
    
    // Validation
    boolean validateCoinAmount(Double amount);
    boolean canUserSpendCoins(Long userId, Double amount);
}
