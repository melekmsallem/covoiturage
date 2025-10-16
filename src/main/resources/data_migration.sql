-- Comprehensive data migration for adding departure and arrival cities to voyages

-- Step 1: Add columns if they don't exist
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'voyages' 
     AND COLUMN_NAME = 'departure_ville_id') = 0,
    'ALTER TABLE voyages ADD COLUMN departure_ville_id BIGINT',
    'SELECT "Column departure_ville_id already exists" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'voyages' 
     AND COLUMN_NAME = 'arrival_ville_id') = 0,
    'ALTER TABLE voyages ADD COLUMN arrival_ville_id BIGINT',
    'SELECT "Column arrival_ville_id already exists" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 2: Create sample cities if they don't exist
INSERT IGNORE INTO villes (name, code_postal, pays, latitude, longitude) VALUES
('Tunis', '1000', 'Tunisia', 36.8065, 10.1815),
('Sfax', '3000', 'Tunisia', 34.7406, 10.7603),
('Sousse', '4000', 'Tunisia', 35.8256, 10.6411),
('Monastir', '5000', 'Tunisia', 35.7771, 10.8261),
('Bizerte', '7000', 'Tunisia', 37.2744, 9.8739),
('Gabes', '6000', 'Tunisia', 33.8886, 10.0982),
('Kairouan', '3100', 'Tunisia', 35.6781, 10.0963),
('Gafsa', '2100', 'Tunisia', 34.4258, 8.7842);

-- Step 3: Update existing voyages with city data
-- Assign different city combinations to existing voyages
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
WHERE v.departure_ville_id IS NULL OR v.arrival_ville_id IS NULL;

-- Step 4: Add foreign key constraints if they don't exist
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'voyages' 
     AND CONSTRAINT_NAME = 'fk_voyage_departure_ville') = 0,
    'ALTER TABLE voyages ADD CONSTRAINT fk_voyage_departure_ville FOREIGN KEY (departure_ville_id) REFERENCES villes(id)',
    'SELECT "Constraint fk_voyage_departure_ville already exists" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'voyages' 
     AND CONSTRAINT_NAME = 'fk_voyage_arrival_ville') = 0,
    'ALTER TABLE voyages ADD CONSTRAINT fk_voyage_arrival_ville FOREIGN KEY (arrival_ville_id) REFERENCES villes(id)',
    'SELECT "Constraint fk_voyage_arrival_ville already exists" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
































