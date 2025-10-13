-- Clean up duplicate trips
-- Delete all trips with ID > 7 (keep only the original 7 trips)

-- First, delete related records
DELETE FROM point_gps WHERE voyage_id > 7;
DELETE FROM voyage_villes WHERE voyage_id > 7;
DELETE FROM voyage_options WHERE voyage_id > 7;
DELETE FROM reservations WHERE voyage_id > 7;

-- Then delete the trips
DELETE FROM voyages WHERE id > 7;

-- Reset auto increment to start from 8
ALTER TABLE voyages AUTO_INCREMENT = 8;





