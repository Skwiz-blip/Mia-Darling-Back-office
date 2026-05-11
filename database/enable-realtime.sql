-- =====================================================
-- ACTIVATION SUPABASE REALTIME POUR GROUP_MESSAGES
-- Exécuter ce script dans Supabase SQL Editor
-- =====================================================

-- 1. Activer l'extension postgres (si pas déjà fait)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Vérifier que Realtime est activé pour la table group_messages
-- Dans Supabase Dashboard: Database > Replication > group_messages > Enable

-- Alternative via SQL (peut nécessiter des droits admin):
ALTER PUBLICATION supabase_realtime ADD TABLE group_messages;

-- 3. Activer Realtime pour les autres tables liées
ALTER PUBLICATION supabase_realtime ADD TABLE groups;
ALTER PUBLICATION supabase_realtime ADD TABLE group_members;

-- 4. Vérification
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- Message de confirmation
SELECT 'Realtime activé pour les tables groups, group_members, group_messages' AS status;
