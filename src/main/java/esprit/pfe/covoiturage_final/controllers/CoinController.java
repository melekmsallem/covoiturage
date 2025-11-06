package esprit.pfe.covoiturage_final.controllers;

import esprit.pfe.covoiturage_final.entities.CoinTransaction;
import esprit.pfe.covoiturage_final.entities.UserCoin;
import esprit.pfe.covoiturage_final.services.CoinService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/coins")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CoinController {
    
    @Autowired
    private CoinService coinService;
    
    @GetMapping("/balance")
    public ResponseEntity<?> getUserBalance(Authentication authentication) {
        try {
            String username = authentication.getName();
            Long userId = getUserIdFromAuthentication(authentication);
            
            Double balance = coinService.getUserBalance(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("username", username);
            response.put("balance", balance);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get balance: " + e.getMessage());
        }
    }
    
    @GetMapping("/transactions")
    public ResponseEntity<?> getUserTransactions(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            List<CoinTransaction> transactions = coinService.getUserTransactionHistory(userId);
            
            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get transactions: " + e.getMessage());
        }
    }
    
    @PostMapping("/purchase")
    public ResponseEntity<?> purchaseCoins(
            @RequestParam Double amount,
            @RequestParam String stripePaymentId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            if (!coinService.validateCoinAmount(amount)) {
                return ResponseEntity.badRequest().body("Invalid coin amount");
            }
            
            CoinTransaction transaction = coinService.purchaseCoins(userId, amount, stripePaymentId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("transaction", transaction);
            response.put("newBalance", coinService.getUserBalance(userId));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to purchase coins: " + e.getMessage());
        }
    }
    
    @PostMapping("/spend")
    public ResponseEntity<?> spendCoins(
            @RequestParam Double amount,
            @RequestParam String description,
            @RequestParam String referenceId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            if (!coinService.canUserSpendCoins(userId, amount)) {
                return ResponseEntity.badRequest().body("Insufficient coin balance");
            }
            
            CoinTransaction transaction = coinService.spendCoins(userId, amount, description, referenceId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("transaction", transaction);
            response.put("newBalance", coinService.getUserBalance(userId));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to spend coins: " + e.getMessage());
        }
    }
    
    @PostMapping("/refund")
    public ResponseEntity<?> refundCoins(
            @RequestParam Double amount,
            @RequestParam String description,
            @RequestParam String referenceId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuthentication(authentication);
            
            CoinTransaction transaction = coinService.refundCoins(userId, amount, description, referenceId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("transaction", transaction);
            response.put("newBalance", coinService.getUserBalance(userId));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to refund coins: " + e.getMessage());
        }
    }
    
    // Admin endpoints
    @PostMapping("/admin/adjust")
    public ResponseEntity<?> adminAdjustCoins(
            @RequestParam Long userId,
            @RequestParam Double amount,
            @RequestParam String description,
            Authentication authentication) {
        try {
            // Check if user is admin
            if (!isAdmin(authentication)) {
                return ResponseEntity.status(403).body("Admin access required");
            }
            
            CoinTransaction transaction = coinService.adminAdjustCoins(userId, amount, description);
            
            Map<String, Object> response = new HashMap<>();
            response.put("transaction", transaction);
            response.put("newBalance", coinService.getUserBalance(userId));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to adjust coins: " + e.getMessage());
        }
    }
    
    @GetMapping("/admin/all-transactions")
    public ResponseEntity<?> getAllTransactions(Authentication authentication) {
        try {
            // Check if user is admin
            if (!isAdmin(authentication)) {
                return ResponseEntity.status(403).body("Admin access required");
            }
            
            List<CoinTransaction> transactions = coinService.getAllTransactions();
            
            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get all transactions: " + e.getMessage());
        }
    }
    
    @GetMapping("/admin/system-stats")
    public ResponseEntity<?> getSystemStats(Authentication authentication) {
        try {
            // Check if user is admin
            if (!isAdmin(authentication)) {
                return ResponseEntity.status(403).body("Admin access required");
            }
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalCoinsInSystem", coinService.getTotalCoinsInSystem());
            
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get system stats: " + e.getMessage());
        }
    }
    
    private Long getUserIdFromAuthentication(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof esprit.pfe.covoiturage_final.entities.User) {
            esprit.pfe.covoiturage_final.entities.User user = (esprit.pfe.covoiturage_final.entities.User) authentication.getPrincipal();
            System.out.println("DEBUG: CoinController.getUserIdFromAuthentication - User ID: " + user.getId() + ", Username: " + user.getUsername());
            return user.getId();
        }
        System.out.println("DEBUG: CoinController.getUserIdFromAuthentication - Authentication principal is not User type: " + (authentication != null ? authentication.getPrincipal().getClass().getName() : "null"));
        return 1L; // Fallback to admin user
    }
    
    private boolean isAdmin(Authentication authentication) {
        // This would need to be implemented based on your authentication system
        // For now, returning false - you'll need to check admin role
        return false; // TODO: Implement proper admin check
    }
}
