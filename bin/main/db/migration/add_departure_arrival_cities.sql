-- Step 1: Add departure and arrival city columns to voyages table (nullable initially)
ALTER TABLE voyages 
ADD COLUMN departure_ville_id BIGINT,
ADD COLUMN arrival_ville_id BIGINT;

-- Step 2: Create some sample cities if they don't exist
INSERT IGNORE INTO villes (name, code_postal, pays, latitude, longitude) VALUES
('Tunis', '1000', 'Tunisia', 36.8065, 10.1815),
('Sfax', '3000', 'Tunisia', 34.7406, 10.7603),
('Sousse', '4000', 'Tunisia', 35.8256, 10.6411),
('Monastir', '5000', 'Tunisia', 35.7771, 10.8261),
('Bizerte', '7000', 'Tunisia', 37.2744, 9.8739);

-- Step 3: Update existing voyages with sample data
-- Get the first two cities and assign them to existing voyages
UPDATE voyages 
SET departure_ville_id = (SELECT id FROM villes WHERE name = 'Tunis' LIMIT 1),
    arrival_ville_id = (SELECT id FROM villes WHERE name = 'Sfax' LIMIT 1)
WHERE departure_ville_id IS NULL OR arrival_ville_id IS NULL;

-- Step 4: Add foreign key constraints after data is populated
ALTER TABLE voyages 
ADD CONSTRAINT fk_voyage_departure_ville 
FOREIGN KEY (departure_ville_id) REFERENCES villes(id);

ALTER TABLE voyages 
ADD CONSTRAINT fk_voyage_arrival_ville 
FOREIGN KEY (arrival_ville_id) REFERENCES villes(id);
