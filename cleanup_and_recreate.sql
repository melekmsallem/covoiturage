-- Complete database cleanup and recreation script
-- This will delete all trips and create new ones with proper city IDs

-- Step 1: Delete all existing trips and related data
DELETE FROM point_gps;
DELETE FROM voyage_villes;
DELETE FROM voyage_options;
DELETE FROM reservations;
DELETE FROM avis;
DELETE FROM voyages;

-- Step 2: Reset auto increment
ALTER TABLE voyages AUTO_INCREMENT = 1;

-- Step 3: Insert new trips with proper city IDs
-- City IDs: 1=Tunis, 2=Sfax, 3=Sousse, 4=Kairouan, 5=Bizerte, 6=Gabès

INSERT INTO voyages (conducteur_id, departure_time, arrival_time, price_per_seat, max_seats, available_seats, description, status, created_at, updated_at, departure_ville_id, arrival_ville_id) VALUES
(1, '2024-09-19 08:00:00', '2024-09-19 10:30:00', 15.0, 4, 3, 'Comfortable ride from Tunis to Sfax', 'PLANNED', NOW(), NOW(), 1, 2),
(2, '2024-09-19 14:00:00', '2024-09-19 16:00:00', 12.0, 3, 2, 'Quick trip to Sousse', 'PLANNED', NOW(), NOW(), 1, 3),
(3, '2024-09-20 09:30:00', '2024-09-20 11:45:00', 18.0, 4, 4, 'Premium service to Kairouan', 'PLANNED', NOW(), NOW(), 1, 4),
(4, '2024-09-20 16:00:00', '2024-09-20 18:30:00', 20.0, 4, 1, 'Evening trip to Bizerte', 'PLANNED', NOW(), NOW(), 1, 5),
(5, '2024-09-21 07:00:00', '2024-09-21 09:15:00', 14.0, 3, 3, 'Early morning to Gabès', 'PLANNED', NOW(), NOW(), 1, 6),
(1, '2024-09-22 08:30:00', '2024-09-22 10:45:00', 16.0, 4, 2, 'Weekend trip to Sfax', 'PLANNED', NOW(), NOW(), 1, 2),
(2, '2024-09-22 15:00:00', '2024-09-22 17:15:00', 13.0, 3, 1, 'Afternoon ride to Sousse', 'PLANNED', NOW(), NOW(), 1, 3);

-- Step 4: Verify the data
SELECT 
    v.id,
    v.description,
    dv.name as departure_city,
    av.name as arrival_city,
    v.price_per_seat,
    v.max_seats,
    v.available_seats,
    v.status
FROM voyages v
LEFT JOIN villes dv ON v.departure_ville_id = dv.id
LEFT JOIN villes av ON v.arrival_ville_id = av.id
ORDER BY v.id;





