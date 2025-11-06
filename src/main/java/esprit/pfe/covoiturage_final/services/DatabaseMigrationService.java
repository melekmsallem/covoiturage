package esprit.pfe.covoiturage_final.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class DatabaseMigrationService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Transactional
    public void migrateVoyageCities() {
        try {
            System.out.println("Starting database migration for voyage cities...");
            
            // Check if columns already exist
            String checkColumnsQuery = """
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'voyages' 
                AND COLUMN_NAME IN ('departure_ville_id', 'arrival_ville_id')
                """;
            
            Integer columnCount = jdbcTemplate.queryForObject(checkColumnsQuery, Integer.class);
            
            if (columnCount == null || columnCount < 2) {
                System.out.println("Adding departure and arrival city columns...");
                
                // Add columns
                jdbcTemplate.execute("ALTER TABLE voyages ADD COLUMN departure_ville_id BIGINT");
                jdbcTemplate.execute("ALTER TABLE voyages ADD COLUMN arrival_ville_id BIGINT");
                
                System.out.println("Columns added successfully!");
            } else {
                System.out.println("Columns already exist, skipping...");
            }
            
            // Create sample cities
            System.out.println("Creating sample cities...");
            String insertCitiesQuery = """
                INSERT IGNORE INTO villes (name, code_postal, pays, latitude, longitude) VALUES
                ('Tunis', '1000', 'Tunisia', 36.8065, 10.1815),
                ('Sfax', '3000', 'Tunisia', 34.7406, 10.7603),
                ('Sousse', '4000', 'Tunisia', 35.8256, 10.6411),
                ('Monastir', '5000', 'Tunisia', 35.7771, 10.8261),
                ('Bizerte', '7000', 'Tunisia', 37.2744, 9.8739),
                ('Gabes', '6000', 'Tunisia', 33.8886, 10.0982),
                ('Kairouan', '3100', 'Tunisia', 35.6781, 10.0963),
                ('Gafsa', '2100', 'Tunisia', 34.4258, 8.7842)
                """;
            
            jdbcTemplate.execute(insertCitiesQuery);
            System.out.println("Sample cities created!");
            
            // Update existing voyages with city data
            System.out.println("Updating existing voyages with city data...");
            String updateVoyagesQuery = """
                UPDATE voyages v
                SET 
                    departure_ville_id = (
                        SELECT id FROM villes 
                        WHERE name IN ('Tunis', 'Sousse', 'Monastir', 'Bizerte') 
                        ORDER BY RAND() 
                        LIMIT 1
                    ),
                    arrival_ville_id = (
                        SELECT id FROM villes 
                        WHERE name IN ('Sfax', 'Gabes', 'Kairouan', 'Gafsa') 
                        ORDER BY RAND() 
                        LIMIT 1
                    )
                WHERE v.departure_ville_id IS NULL OR v.arrival_ville_id IS NULL
                """;
            
            int updatedRows = jdbcTemplate.update(updateVoyagesQuery);
            System.out.println("Updated " + updatedRows + " voyages with city data!");
            
            // Add foreign key constraints
            System.out.println("Adding foreign key constraints...");
            try {
                jdbcTemplate.execute("ALTER TABLE voyages ADD CONSTRAINT fk_voyage_departure_ville FOREIGN KEY (departure_ville_id) REFERENCES villes(id)");
                jdbcTemplate.execute("ALTER TABLE voyages ADD CONSTRAINT fk_voyage_arrival_ville FOREIGN KEY (arrival_ville_id) REFERENCES villes(id)");
                System.out.println("Foreign key constraints added successfully!");
            } catch (Exception e) {
                System.out.println("Foreign key constraints may already exist: " + e.getMessage());
            }
            
            System.out.println("Database migration completed successfully!");
            
        } catch (Exception e) {
            System.err.println("Error during database migration: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Database migration failed", e);
        }
    }
    
    public void checkMigrationStatus() {
        try {
            // Check if columns exist
            String checkColumnsQuery = """
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'voyages' 
                AND COLUMN_NAME IN ('departure_ville_id', 'arrival_ville_id')
                """;
            
            Integer columnCount = jdbcTemplate.queryForObject(checkColumnsQuery, Integer.class);
            System.out.println("Columns found: " + columnCount);
            
            // Check voyages with city data
            String checkVoyagesQuery = """
                SELECT COUNT(*) as count 
                FROM voyages 
                WHERE departure_ville_id IS NOT NULL AND arrival_ville_id IS NOT NULL
                """;
            
            Integer voyageCount = jdbcTemplate.queryForObject(checkVoyagesQuery, Integer.class);
            System.out.println("Voyages with city data: " + voyageCount);
            
            // Check cities
            String checkCitiesQuery = "SELECT COUNT(*) FROM villes";
            Integer cityCount = jdbcTemplate.queryForObject(checkCitiesQuery, Integer.class);
            System.out.println("Total cities: " + cityCount);
            
        } catch (Exception e) {
            System.err.println("Error checking migration status: " + e.getMessage());
        }
    }
}

































































