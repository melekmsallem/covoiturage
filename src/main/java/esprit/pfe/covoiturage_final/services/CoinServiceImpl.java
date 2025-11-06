package esprit.pfe.covoiturage_final.services;

import esprit.pfe.covoiturage_final.entities.CoinTransaction;
import esprit.pfe.covoiturage_final.entities.UserCoin;
import esprit.pfe.covoiturage_final.repositories.CoinTransactionRepository;
import esprit.pfe.covoiturage_final.repositories.UserCoinRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class CoinServiceImpl implements CoinService {
    
    @Autowired
    private UserCoinRepository userCoinRepository;
    
    @Autowired
    private CoinTransactionRepository coinTransactionRepository;
    
    @Override
    public UserCoin getOrCreateUserCoin(Long userId) {
        return userCoinRepository.findByUserId(userId)
            .orElseGet(() -> {
                UserCoin userCoin = new UserCoin();
                userCoin.setUserId(userId);
                userCoin.setBalance(0.0);
                return userCoinRepository.save(userCoin);
            });
    }
    
    @Override
    public Double getUserBalance(Long userId) {
        System.out.println("getUserBalance called for user " + userId);
        UserCoin userCoin = getOrCreateUserCoin(userId);
        System.out.println("User coin balance: " + userCoin.getBalance());
        return userCoin.getBalance();
    }
    
    @Override
    public boolean hasSufficientBalance(Long userId, Double amount) {
        if (!validateCoinAmount(amount)) {
            return false;
        }
        Double balance = getUserBalance(userId);
        return balance >= amount;
    }
    
    @Override
    public CoinTransaction purchaseCoins(Long userId, Double amount, String stripePaymentId) {
        if (!validateCoinAmount(amount)) {
            throw new RuntimeException("Invalid coin amount");
        }
        
        UserCoin userCoin = getOrCreateUserCoin(userId);
        Double balanceBefore = userCoin.getBalance();
        Double balanceAfter = balanceBefore + amount;
        
        // Update user coin balance
        userCoin.setBalance(balanceAfter);
        userCoinRepository.save(userCoin);
        
        // Create transaction record
        CoinTransaction transaction = new CoinTransaction();
        transaction.setUserId(userId);
        transaction.setTransactionType(CoinTransaction.TransactionType.PURCHASE);
        transaction.setAmount(amount);
        transaction.setBalanceBefore(balanceBefore);
        transaction.setBalanceAfter(balanceAfter);
        transaction.setDescription("Purchased coins via Stripe");
        transaction.setReferenceId(stripePaymentId);
        transaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        return coinTransactionRepository.save(transaction);
    }
    
    @Override
    public CoinTransaction spendCoins(Long userId, Double amount, String description, String referenceId) {
        if (!canUserSpendCoins(userId, amount)) {
            throw new RuntimeException("Insufficient coin balance");
        }
        
        UserCoin userCoin = getOrCreateUserCoin(userId);
        Double balanceBefore = userCoin.getBalance();
        Double balanceAfter = balanceBefore - amount;
        
        // Update user coin balance
        userCoin.setBalance(balanceAfter);
        userCoinRepository.save(userCoin);
        
        // Create transaction record
        CoinTransaction transaction = new CoinTransaction();
        transaction.setUserId(userId);
        transaction.setTransactionType(CoinTransaction.TransactionType.SPEND);
        transaction.setAmount(amount);
        transaction.setBalanceBefore(balanceBefore);
        transaction.setBalanceAfter(balanceAfter);
        transaction.setDescription(description);
        transaction.setReferenceId(referenceId);
        transaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        return coinTransactionRepository.save(transaction);
    }
    
    @Override
    public CoinTransaction refundCoins(Long userId, Double amount, String description, String referenceId) {
        if (!validateCoinAmount(amount)) {
            throw new RuntimeException("Invalid coin amount");
        }
        
        UserCoin userCoin = getOrCreateUserCoin(userId);
        Double balanceBefore = userCoin.getBalance();
        Double balanceAfter = balanceBefore + amount;
        
        // Update user coin balance
        userCoin.setBalance(balanceAfter);
        userCoinRepository.save(userCoin);
        
        // Create transaction record
        CoinTransaction transaction = new CoinTransaction();
        transaction.setUserId(userId);
        transaction.setTransactionType(CoinTransaction.TransactionType.REFUND);
        transaction.setAmount(amount);
        transaction.setBalanceBefore(balanceBefore);
        transaction.setBalanceAfter(balanceAfter);
        transaction.setDescription(description);
        transaction.setReferenceId(referenceId);
        transaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        return coinTransactionRepository.save(transaction);
    }
    
    @Override
    public CoinTransaction addBonusCoins(Long userId, Double amount, String description) {
        System.out.println("addBonusCoins called for user " + userId + " with amount " + amount);
        
        if (!validateCoinAmount(amount)) {
            System.err.println("Invalid coin amount: " + amount);
            throw new RuntimeException("Invalid coin amount");
        }
        
        UserCoin userCoin = getOrCreateUserCoin(userId);
        System.out.println("User coin found/created: " + userCoin.getId() + ", current balance: " + userCoin.getBalance());
        
        Double balanceBefore = userCoin.getBalance();
        Double balanceAfter = balanceBefore + amount;
        
        System.out.println("Updating balance from " + balanceBefore + " to " + balanceAfter);
        
        // Update user coin balance
        userCoin.setBalance(balanceAfter);
        UserCoin savedUserCoin = userCoinRepository.save(userCoin);
        System.out.println("User coin saved with balance: " + savedUserCoin.getBalance());
        
        // Create transaction record
        CoinTransaction transaction = new CoinTransaction();
        transaction.setUserId(userId);
        transaction.setTransactionType(CoinTransaction.TransactionType.BONUS);
        transaction.setAmount(amount);
        transaction.setBalanceBefore(balanceBefore);
        transaction.setBalanceAfter(balanceAfter);
        transaction.setDescription(description);
        transaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        CoinTransaction savedTransaction = coinTransactionRepository.save(transaction);
        System.out.println("Transaction saved with ID: " + savedTransaction.getId());
        
        return savedTransaction;
    }
    
    @Override
    public List<CoinTransaction> getUserTransactionHistory(Long userId) {
        return coinTransactionRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
    
    @Override
    public List<CoinTransaction> getUserTransactionHistory(Long userId, CoinTransaction.TransactionType transactionType) {
        return coinTransactionRepository.findByUserIdAndTransactionTypeOrderByCreatedAtDesc(userId, transactionType);
    }
    
    @Override
    public CoinTransaction adminAdjustCoins(Long userId, Double amount, String description) {
        UserCoin userCoin = getOrCreateUserCoin(userId);
        Double balanceBefore = userCoin.getBalance();
        Double balanceAfter = balanceBefore + amount;
        
        // Update user coin balance
        userCoin.setBalance(balanceAfter);
        userCoinRepository.save(userCoin);
        
        // Create transaction record
        CoinTransaction transaction = new CoinTransaction();
        transaction.setUserId(userId);
        transaction.setTransactionType(CoinTransaction.TransactionType.ADMIN_ADJ);
        transaction.setAmount(amount);
        transaction.setBalanceBefore(balanceBefore);
        transaction.setBalanceAfter(balanceAfter);
        transaction.setDescription(description);
        transaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        return coinTransactionRepository.save(transaction);
    }
    
    @Override
    public List<CoinTransaction> getAllTransactions() {
        return coinTransactionRepository.findAll();
    }
    
    @Override
    public Double getTotalCoinsInSystem() {
        return userCoinRepository.findAll().stream()
            .mapToDouble(UserCoin::getBalance)
            .sum();
    }
    
    @Override
    public boolean validateCoinAmount(Double amount) {
        return amount != null && amount > 0;
    }
    
    @Override
    public boolean canUserSpendCoins(Long userId, Double amount) {
        return hasSufficientBalance(userId, amount);
    }
    
    @Override
    public void transferCoins(Long fromUserId, Long toUserId, Double amount, String description, String referenceId) {
        if (!validateCoinAmount(amount)) {
            throw new RuntimeException("Invalid coin amount");
        }
        
        if (fromUserId.equals(toUserId)) {
            throw new RuntimeException("Cannot transfer coins to yourself");
        }
        
        // Check if sender has sufficient balance
        if (!hasSufficientBalance(fromUserId, amount)) {
            throw new RuntimeException("Insufficient coin balance for transfer");
        }
        
        // Deduct coins from sender
        spendCoins(fromUserId, amount, "Transfer to user " + toUserId + " - " + description, referenceId);
        
        // Add coins to receiver
        UserCoin receiverCoin = getOrCreateUserCoin(toUserId);
        Double receiverBalanceBefore = receiverCoin.getBalance();
        Double receiverBalanceAfter = receiverBalanceBefore + amount;
        
        receiverCoin.setBalance(receiverBalanceAfter);
        userCoinRepository.save(receiverCoin);
        
        // Create transaction record for receiver
        CoinTransaction receiverTransaction = new CoinTransaction();
        receiverTransaction.setUserId(toUserId);
        receiverTransaction.setTransactionType(CoinTransaction.TransactionType.TRANSFER);
        receiverTransaction.setAmount(amount);
        receiverTransaction.setBalanceBefore(receiverBalanceBefore);
        receiverTransaction.setBalanceAfter(receiverBalanceAfter);
        receiverTransaction.setDescription("Received from user " + fromUserId + " - " + description);
        receiverTransaction.setReferenceId(referenceId);
        receiverTransaction.setStatus(CoinTransaction.TransactionStatus.COMPLETED);
        
        coinTransactionRepository.save(receiverTransaction);
    }
}
