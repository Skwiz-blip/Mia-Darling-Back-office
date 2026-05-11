-- =====================================================
-- MIGRATION: Rendre les groupes accessibles aux utilisateurs anonymes
-- Exécuter ce script dans Supabase SQL Editor
-- =====================================================

-- 1. Mettre à jour la politique RLS sur la table groups
-- Permet aux utilisateurs anonymes de voir les groupes actifs
DROP POLICY IF EXISTS "groups_select" ON groups;
CREATE POLICY "groups_select" ON groups
    FOR SELECT USING (status = 'active' OR auth.role() = 'authenticated');

-- 2. Mettre à jour la politique RLS sur la table group_members
-- Permet aux utilisateurs anonymes de voir les membres et rejoindre les groupes
DROP POLICY IF EXISTS "group_members_select" ON group_members;
CREATE POLICY "group_members_select" ON group_members
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "group_members_insert" ON group_members;
CREATE POLICY "group_members_insert" ON group_members
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "group_members_delete" ON group_members;
CREATE POLICY "group_members_delete" ON group_members
    FOR DELETE USING (true);

-- 3. Mettre à jour la politique RLS sur la table group_messages
-- Permet aux utilisateurs anonymes de voir et envoyer des messages
DROP POLICY IF EXISTS "group_messages_select" ON group_messages;
CREATE POLICY "group_messages_select" ON group_messages
    FOR SELECT USING (status = 'visible');

DROP POLICY IF EXISTS "group_messages_insert" ON group_messages;
CREATE POLICY "group_messages_insert" ON group_messages
    FOR INSERT WITH CHECK (true);

-- Message de confirmation
SELECT 'Politiques RLS mises à jour avec succès ! Les groupes sont maintenant accessibles aux utilisateurs anonymes.' AS result;
