-- Script SQL définitif pour corriger la colonne transaction_type
-- Ce script va corriger définitivement le problème de taille de colonne

-- 1. Vérifier la structure actuelle de la table
DESCRIBE coin_transactions;

-- 2. Modifier la colonne transaction_type pour accepter des valeurs plus longues
ALTER TABLE coin_transactions MODIFY COLUMN transaction_type VARCHAR(50);

-- 3. Vérifier que la modification a été appliquée
DESCRIBE coin_transactions;

-- 4. Vérifier les valeurs actuelles dans la table
SELECT DISTINCT transaction_type FROM coin_transactions;

-- 5. Si nécessaire, mettre à jour les valeurs existantes pour utiliser les noms courts
UPDATE coin_transactions 
SET transaction_type = 'ADMIN_ADJ' 
WHERE transaction_type = 'ADMIN_ADJUSTMENT';

UPDATE coin_transactions 
SET transaction_type = 'TRANSFER' 
WHERE transaction_type = 'TRANSFER_RECEIVED';

-- 6. Vérifier les valeurs après mise à jour
SELECT DISTINCT transaction_type FROM coin_transactions;










