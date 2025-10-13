-- Populate database with correct data
-- This script will create users, cities, and trips with proper relationships

-- Insert cities first
INSERT INTO villes (id, name, code_postal, pays, latitude, longitude) VALUES
(1, 'Tunis', '1000', 'Tunisia', 36.8065, 10.1815),
(2, 'Sfax', '3000', 'Tunisia', 34.7406, 10.7603),
(3, 'Sousse', '4000', 'Tunisia', 35.8256, 10.6411),
(4, 'Kairouan', '3100', 'Tunisia', 35.6711, 10.1006),
(5, 'Bizerte', '7000', 'Tunisia', 37.2744, 9.8739),
(6, 'Gabès', '6000', 'Tunisia', 33.8869, 10.0982);

-- Insert users
INSERT INTO users (id, username, email, first_name, last_name, password, role, user_type, is_active, is_verified, created_at, updated_at) VALUES
(1, 'adem', 'adem@example.com', 'adem', 'adem', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK', 'DRIVER', 'DRIVER', true, true, NOW(), NOW()),
(2, 'ali', 'ali@example.com', 'ali', 'ali', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK', 'DRIVER', 'DRIVER', true, true, NOW(), NOW()),
(3, 'malek', 'malek@example.com', 'malek', 'msallem', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK', 'DRIVER', 'DRIVER', true, true, NOW(), NOW()),
(4, 'testuser', 'test@example.com', 'Test', 'User', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK', 'DRIVER', 'DRIVER', true, true, NOW(), NOW()),
(5, 'admin', 'admin@example.com', 'Admin', 'User', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKyVhUx0U8pQv7/3XJdKjKjKjKjK', 'ADMIN', 'ADMIN', true, true, NOW(), NOW());

-- Insert trips with proper city IDs
INSERT INTO voyages (id, conducteur_id, departure_time, arrival_time, price_per_seat, max_seats, available_seats, description, status, created_at, updated_at, departure_ville_id, arrival_ville_id) VALUES
(1, 1, '2024-09-19 08:00:00', '2024-09-19 10:30:00', 15.0, 4, 3, 'Comfortable ride from Tunis to Sfax', 'PLANNED', NOW(), NOW(), 1, 2),
(2, 2, '2024-09-19 14:00:00', '2024-09-19 16:00:00', 12.0, 3, 2, 'Quick trip to Sousse', 'PLANNED', NOW(), NOW(), 1, 3),
(3, 3, '2024-09-20 09:30:00', '2024-09-20 11:45:00', 18.0, 4, 4, 'Premium service to Kairouan', 'PLANNED', NOW(), NOW(), 1, 4),
(4, 1, '2024-09-20 16:00:00', '2024-09-20 18:30:00', 20.0, 4, 1, 'Evening trip to Bizerte', 'PLANNED', NOW(), NOW(), 1, 5),
(5, 2, '2024-09-21 07:00:00', '2024-09-21 09:15:00', 14.0, 3, 3, 'Early morning to Gabès', 'PLANNED', NOW(), NOW(), 1, 6);

-- Reset auto-increment counters
ALTER TABLE voyages AUTO_INCREMENT = 6;
ALTER TABLE users AUTO_INCREMENT = 6;
ALTER TABLE villes AUTO_INCREMENT = 7;





