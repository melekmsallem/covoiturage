-- Fix existing voyage records to have proper departure and arrival city IDs
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 2 WHERE id = 1; -- Tunis to Sfax
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 3 WHERE id = 2; -- Tunis to Sousse  
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 4 WHERE id = 3; -- Tunis to Kairouan
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 5 WHERE id = 4; -- Tunis to Bizerte
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 6 WHERE id = 5; -- Tunis to Gabès
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 2 WHERE id = 6; -- Tunis to Sfax (meh's trip)
UPDATE voyages SET departure_ville_id = 1, arrival_ville_id = 3 WHERE id = 7; -- Tunis to Sousse (meh's trip)





