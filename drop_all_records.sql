-- SQL commands to drop all records from all tables
-- WARNING: This will delete ALL data from your database!

-- Delete all records from all tables (in correct order to avoid foreign key constraints)

-- Delete from child tables first
DELETE FROM point_gps;
DELETE FROM voyage_villes;
DELETE FROM voyage_options;
DELETE FROM reservations;
DELETE FROM avis;
DELETE FROM paiements;
DELETE FROM notifications;

-- Delete from main tables
DELETE FROM voyages;
DELETE FROM users;
DELETE FROM villes;
DELETE FROM options;

-- Reset auto-increment counters
ALTER TABLE voyages AUTO_INCREMENT = 1;
ALTER TABLE users AUTO_INCREMENT = 1;
ALTER TABLE villes AUTO_INCREMENT = 1;
ALTER TABLE options AUTO_INCREMENT = 1;
ALTER TABLE reservations AUTO_INCREMENT = 1;
ALTER TABLE avis AUTO_INCREMENT = 1;
ALTER TABLE paiements AUTO_INCREMENT = 1;
ALTER TABLE notifications AUTO_INCREMENT = 1;
ALTER TABLE point_gps AUTO_INCREMENT = 1;

-- Verify tables are empty
SELECT 'voyages' as table_name, COUNT(*) as record_count FROM voyages
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'villes', COUNT(*) FROM villes
UNION ALL
SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'avis', COUNT(*) FROM avis
UNION ALL
SELECT 'paiements', COUNT(*) FROM paiements
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL
SELECT 'point_gps', COUNT(*) FROM point_gps;





