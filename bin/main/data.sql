-- Insert Tunisian cities with real GPS coordinates
INSERT INTO villes (name, code_postal, pays, latitude, longitude) VALUES
-- Major Tunisian Cities
('Tunis', '1000', 'Tunisia', 36.8065, 10.1815),
('Sfax', '3000', 'Tunisia', 34.7406, 10.7603),
('Sousse', '4000', 'Tunisia', 35.8256, 10.6411),
('Kairouan', '3100', 'Tunisia', 35.6711, 10.1008),
('Bizerte', '7000', 'Tunisia', 37.2744, 9.8739),
('Gabès', '6000', 'Tunisia', 33.8869, 10.0982),
('Ariana', '2080', 'Tunisia', 36.8625, 10.1956),
('Gafsa', '2100', 'Tunisia', 34.4258, 8.7842),
('Monastir', '5000', 'Tunisia', 35.7771, 10.8262),
('Ben Arous', '2013', 'Tunisia', 36.7531, 10.2189),
('Medenine', '4100', 'Tunisia', 33.3548, 10.5053),
('Nabeul', '8000', 'Tunisia', 36.4561, 10.7376),
('Tataouine', '3200', 'Tunisia', 32.9297, 10.4511),
('Kasserine', '1200', 'Tunisia', 35.1673, 8.8365),
('Sidi Bouzid', '9100', 'Tunisia', 35.0381, 9.4847),
('Kebili', '4200', 'Tunisia', 33.7050, 8.9656),
('Siliana', '6100', 'Tunisia', 36.0839, 9.3708),
('Beja', '9000', 'Tunisia', 36.7256, 9.1817),
('Jendouba', '8100', 'Tunisia', 36.5011, 8.7803),
('Mahdia', '5100', 'Tunisia', 35.5047, 11.0622),
('Zaghouan', '1100', 'Tunisia', 36.4028, 10.1428),
('Manouba', '2010', 'Tunisia', 36.8081, 10.0972),
('Tozeur', '2200', 'Tunisia', 33.9197, 8.1336),
('El Kef', '7100', 'Tunisia', 36.1822, 8.7147),
('Hammamet', '8050', 'Tunisia', 36.4000, 10.6167),
('Djerba', '4180', 'Tunisia', 33.8667, 10.8667),
('Tabarka', '8110', 'Tunisia', 36.9542, 8.7581),
('Korbous', '2015', 'Tunisia', 36.8331, 10.5833),
('Enfidha', '4030', 'Tunisia', 36.1333, 10.3833),
('Moknine', '5050', 'Tunisia', 35.6333, 10.9667),
('Mahres', '3012', 'Tunisia', 34.5333, 10.5000),
('Regueb', '9170', 'Tunisia', 34.8333, 9.7833),
('Zarzis', '4170', 'Tunisia', 33.5000, 11.1167),
('Nefta', '2240', 'Tunisia', 33.8667, 7.8833),
('Douz', '4260', 'Tunisia', 33.4667, 9.0167),
('Matmata', '6070', 'Tunisia', 33.5500, 9.9667),
('Chenini', '3270', 'Tunisia', 33.0167, 10.4333),
('Ksar Ghilane', '4260', 'Tunisia', 33.0000, 9.8333),
('Metlaoui', '2130', 'Tunisia', 34.3167, 8.4000),
('Redeyef', '2140', 'Tunisia', 34.3833, 8.1500),
('Menzel Bourguiba', '7050', 'Tunisia', 37.1500, 9.7833),
('Kélibia', '8090', 'Tunisia', 36.8500, 11.1000),
('Mateur', '7030', 'Tunisia', 37.0333, 9.6667),
('Béni Khalled', '8020', 'Tunisia', 36.6500, 10.6000),
('Soliman', '8025', 'Tunisia', 36.7000, 10.4667),
('Mornag', '2070', 'Tunisia', 36.6833, 10.2833),
('Rades', '2040', 'Tunisia', 36.7667, 10.2833),
('La Goulette', '2060', 'Tunisia', 36.8167, 10.3167),
('Carthage', '2016', 'Tunisia', 36.8500, 10.3167),
('Sidi Bou Said', '2026', 'Tunisia', 36.8667, 10.3333);

-- Reset options and insert selected set (no fees)
DELETE FROM options;
INSERT INTO options (name, description, price, category, icon_name, is_active, sort_order) VALUES
('Air Conditioning', 'Climate control for comfort', 0.0, 'COMFORT', 'ac_unit', true, 1),
('Heating', 'Warm air heating system', 0.0, 'COMFORT', 'thermostat', true, 2),
('Bluetooth Audio', 'Wireless music streaming', 0.0, 'ENTERTAINMENT', 'bluetooth_audio', true, 3),
('WiFi Hotspot', 'Free internet connection', 0.0, 'ENTERTAINMENT', 'wifi_hotspot', true, 4),
('Smoking Allowed', 'Designated smoking breaks', 0.0, 'OTHER', 'smoking_rooms', true, 5),
('Pet Friendly', 'Pets allowed in the vehicle', 0.0, 'PETS', 'pets', true, 6),
('Extra Luggage Space', 'Additional storage capacity', 0.0, 'LUGGAGE', 'luggage', true, 7),
('Food & Drinks', 'Snacks and beverages provided', 0.0, 'FOOD', 'restaurant', true, 8);

-- Insert sample users (drivers)
INSERT INTO users (username, email, password, first_name, last_name, phone_number, role, user_type, is_active, is_verified, license_number, vehicle_model, vehicle_color, vehicle_plate, max_passengers, rating, total_trips) VALUES
('driver1', 'driver1@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Ahmed', 'Ben Ali', '+21612345678', 'CONDUCTEUR', 'CONDUCTEUR', true, true, 'LIC123456', 'Toyota Corolla', 'White', '123TUN456', 4, 4.5, 25),
('driver2', 'driver2@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Fatma', 'Trabelsi', '+21687654321', 'CONDUCTEUR', 'CONDUCTEUR', true, true, 'LIC789012', 'Renault Clio', 'Blue', '789TUN012', 3, 4.2, 18),
('driver3', 'driver3@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Mohamed', 'Khelil', '+21655555555', 'CONDUCTEUR', 'CONDUCTEUR', true, true, 'LIC345678', 'Peugeot 208', 'Red', '345TUN678', 4, 4.8, 32),
('meh', 'meh@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Mehdi', 'Ben Salem', '+21698765432', 'CONDUCTEUR', 'CONDUCTEUR', true, true, 'LIC999999', 'Hyundai i20', 'Black', '999TUN999', 4, 4.7, 15),
-- Add a passenger user for testing bookings
('passenger1', 'passenger1@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Sara', 'Ben Ammar', '+21611111111', 'PASSAGER', 'PASSAGER', true, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
-- Add admin user
('admin', 'admin@covoiturage.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'Admin', 'User', '+21600000000', 'ADMIN', 'ADMIN', true, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Insert sample trips with departure and arrival city IDs
INSERT INTO voyages (conducteur_id, departure_time, arrival_time, price_per_seat, max_seats, available_seats, description, status, created_at, updated_at, departure_ville_id, arrival_ville_id) VALUES
(1, '2024-09-19 08:00:00', '2024-09-19 10:30:00', 15.0, 4, 3, 'Comfortable ride from Tunis to Sfax', 'PLANNED', NOW(), NOW(), 1, 2),
(2, '2024-09-19 14:00:00', '2024-09-19 16:00:00', 12.0, 3, 2, 'Quick trip to Sousse', 'PLANNED', NOW(), NOW(), 1, 3),
(3, '2024-09-20 09:30:00', '2024-09-20 11:45:00', 18.0, 4, 4, 'Premium service to Kairouan', 'PLANNED', NOW(), NOW(), 1, 4),
(1, '2024-09-20 16:00:00', '2024-09-20 18:30:00', 20.0, 4, 1, 'Evening trip to Bizerte', 'PLANNED', NOW(), NOW(), 1, 5),
(2, '2024-09-21 07:00:00', '2024-09-21 09:15:00', 14.0, 3, 3, 'Early morning to Gabès', 'PLANNED', NOW(), NOW(), 1, 6),
-- Trips for user 'meh' (ID 4)
(4, '2024-09-22 10:00:00', '2024-09-22 12:30:00', 16.0, 4, 4, 'Morning trip from Tunis to Sfax', 'PLANNED', NOW(), NOW(), 1, 2),
(4, '2024-09-22 15:00:00', '2024-09-22 17:00:00', 13.0, 4, 4, 'Afternoon trip to Sousse', 'PLANNED', NOW(), NOW(), 1, 3);

-- Link trips with cities (departure and arrival)
INSERT INTO voyage_villes (voyage_id, ville_id) VALUES
-- Trip 1: Tunis to Sfax
(1, 1), (1, 2),
-- Trip 2: Tunis to Sousse  
(2, 1), (2, 3),
-- Trip 3: Tunis to Kairouan
(3, 1), (3, 4),
-- Trip 4: Tunis to Bizerte
(4, 1), (4, 5),
-- Trip 5: Tunis to Gabès
(5, 1), (5, 6),
-- Trip 6: Tunis to Sfax (meh's trip)
(6, 1), (6, 2),
-- Trip 7: Tunis to Sousse (meh's trip)
(7, 1), (7, 3);

-- Add GPS points for departure and arrival
INSERT INTO point_gps (voyage_id, latitude, longitude, address, point_type) VALUES
-- Trip 1: Tunis to Sfax
(1, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(1, 34.7406, 10.7603, 'Sfax, Tunisia', 'END'),
-- Trip 2: Tunis to Sousse
(2, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(2, 35.8256, 10.6411, 'Sousse, Tunisia', 'END'),
-- Trip 3: Tunis to Kairouan
(3, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(3, 35.6711, 10.1008, 'Kairouan, Tunisia', 'END'),
-- Trip 4: Tunis to Bizerte
(4, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(4, 37.2744, 9.8739, 'Bizerte, Tunisia', 'END'),
-- Trip 5: Tunis to Gabès
(5, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(5, 33.8869, 10.0982, 'Gabès, Tunisia', 'END'),
-- Trip 6: Tunis to Sfax (meh's trip)
(6, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(6, 34.7406, 10.7603, 'Sfax, Tunisia', 'END'),
-- Trip 7: Tunis to Sousse (meh's trip)
(7, 36.8065, 10.1815, 'Tunis, Tunisia', 'START'),
(7, 35.8256, 10.6411, 'Sousse, Tunisia', 'END');

-- Link trips with options (voyage_options)
INSERT INTO voyage_options (voyage_id, option_id) VALUES
-- Trip 1: Tunis to Sfax - Premium options
(1, 1), -- Air Conditioning
(1, 2), -- Heating
(1, 3), -- Bluetooth Audio
(1, 4), -- WiFi Hotspot
(1, 6), -- Pet Friendly
-- Trip 2: Tunis to Sousse - Basic options
(2, 1), -- Air Conditioning
(2, 3), -- Bluetooth Audio
(2, 7), -- Extra Luggage Space
-- Trip 3: Tunis to Kairouan - Comfort options
(3, 1), -- Air Conditioning
(3, 2), -- Heating
(3, 4), -- WiFi Hotspot
(3, 8), -- Food & Drinks
-- Trip 4: Tunis to Bizerte - All options
(4, 1), -- Air Conditioning
(4, 2), -- Heating
(4, 3), -- Bluetooth Audio
(4, 4), -- WiFi Hotspot
(4, 5), -- Smoking Allowed
(4, 6), -- Pet Friendly
(4, 7), -- Extra Luggage Space
(4, 8), -- Food & Drinks
-- Trip 5: Tunis to Gabès - Pet friendly
(5, 1), -- Air Conditioning
(5, 6), -- Pet Friendly
(5, 7), -- Extra Luggage Space
-- Trip 6: Tunis to Sfax (meh's trip) - Premium options
(6, 1), -- Air Conditioning
(6, 2), -- Heating
(6, 3), -- Bluetooth Audio
(6, 4), -- WiFi Hotspot
(6, 6), -- Pet Friendly
-- Trip 7: Tunis to Sousse (meh's trip) - Basic options
(7, 1), -- Air Conditioning
(7, 3), -- Bluetooth Audio
(7, 7); -- Extra Luggage Space

-- Insert sample bookings for testing
INSERT INTO reservations (voyage_id, passager_id, number_of_seats, total_price, status, notes, reservation_date) VALUES
-- Bookings for meh's trips (user ID 5 is passenger1)
(6, 5, 2, 32.0, 'PENDING', 'Need space for luggage', NOW()),
(7, 5, 1, 13.0, 'PENDING', 'First time using the service', NOW());

