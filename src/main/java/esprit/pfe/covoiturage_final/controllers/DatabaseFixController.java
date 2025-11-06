package esprit.pfe.covoiturage_final.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DatabaseFixController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostMapping("/fix-transaction-type-final")
    public ResponseEntity<Map<String, Object>> fixTransactionTypeColumnFinal() {
        try {
            // 1. Modifier la colonne transaction_type pour accepter des valeurs plus longues
            jdbcTemplate.execute("ALTER TABLE coin_transactions MODIFY COLUMN transaction_type VARCHAR(50)");
            
            // 2. Mettre à jour les valeurs existantes pour utiliser les noms courts
            jdbcTemplate.update("UPDATE coin_transactions SET transaction_type = 'ADMIN_ADJ' WHERE transaction_type = 'ADMIN_ADJUSTMENT'");
            jdbcTemplate.update("UPDATE coin_transactions SET transaction_type = 'TRANSFER' WHERE transaction_type = 'TRANSFER_RECEIVED'");
            
            // 3. Vérifier les valeurs après mise à jour
            var result = jdbcTemplate.queryForList("SELECT DISTINCT transaction_type FROM coin_transactions");
            
            return ResponseEntity.ok(Map.of(
                "success", true, 
                "message", "Transaction type column fixed definitively",
                "currentValues", result
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("success", false, "message", "Failed to fix transaction type column: " + e.getMessage()));
        }
    }
}
