-- =====================================================
-- MIGRATION: Ajouter session_token à admin_users
-- Exécuter ce script dans Supabase SQL Editor
-- =====================================================

-- 1. Ajouter la colonne session_token si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_users' AND column_name = 'session_token'
    ) THEN
        ALTER TABLE admin_users ADD COLUMN session_token VARCHAR(255);
    END IF;
END $$;

-- 2. Créer l'index sur session_token
CREATE INDEX IF NOT EXISTS idx_admin_users_session_token ON admin_users(session_token);

-- 3. Mettre à jour la politique RLS pour permettre la lecture publique
-- (nécessaire pour vérifier si un utilisateur anonyme est admin)
DROP POLICY IF EXISTS "admin_users_select" ON admin_users;
CREATE POLICY "admin_users_select" ON admin_users
    FOR SELECT USING (true);

-- 4. Pour définir un admin existant avec un session_token spécifique:
-- UPDATE admin_users SET session_token = 'VOTRE_SESSION_TOKEN' WHERE email = 'louisskwiz@gmail.com';

SELECT 'Migration terminée. Ajoutez votre session_token à votre compte admin.' AS status;
