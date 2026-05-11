CREATE TABLE IF NOT EXISTS admin_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    session_token VARCHAR(255),
    role VARCHAR(50) DEFAULT 'admin',  -- 'admin' | 'super_admin'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    created_by UUID   
);

-- Index
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_session_token ON admin_users(session_token);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active) WHERE is_active = TRUE;
 
INSERT INTO admin_users (email, role, is_active)
VALUES ('louisskwiz@gmail.com', 'super_admin', true)
ON CONFLICT (email) DO NOTHING;


ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Permettre la lecture publique pour vérifier si un user est admin via session_token
DROP POLICY IF EXISTS "admin_users_select" ON admin_users;
CREATE POLICY "admin_users_select" ON admin_users
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "admin_users_insert" ON admin_users;
CREATE POLICY "admin_users_insert" ON admin_users
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "admin_users_update" ON admin_users;
CREATE POLICY "admin_users_update" ON admin_users
    FOR UPDATE
    USING (auth.role() = 'authenticated');


-- =====================================================
-- 3. Ajout du statut "hidden" pour les posts
-- (si pas déjà fait dans votre schema)
-- =====================================================

-- Vérifier que le status 'hidden' est supporté
-- Si votre colonne status a une contrainte CHECK, ajoutez 'hidden' :
-- ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_status_check;
-- ALTER TABLE posts ADD CONSTRAINT posts_status_check
--   CHECK (status IN ('draft', 'published', 'deleted', 'hidden'));

CREATE OR REPLACE VIEW admin_posts_view AS
SELECT
    p.id,
    p.content,
    p.session_token,
    p.status,
    p.views_count,
    p.reactions_count,
    p.comments_count,
    p.created_at,
    p.is_edited,
    s.anonymous_name
FROM posts p
LEFT JOIN anonymous_sessions s ON p.session_token = s.session_token;


-- =====================================================
-- 4. Groupes de discussion
-- =====================================================

CREATE TABLE IF NOT EXISTS groups (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by_admin UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active',  -- 'active' | 'closed' | 'hidden'
    members_count INTEGER DEFAULT 0,
    messages_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
 
DROP VIEW IF EXISTS admin_groups_view;

DO $$
BEGIN
    -- Drop session_token column if it exists (old schema)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'groups' AND column_name = 'session_token') THEN
        ALTER TABLE groups DROP COLUMN session_token;
    END IF;
    -- Add created_by_admin if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'groups' AND column_name = 'created_by_admin') THEN
        ALTER TABLE groups ADD COLUMN created_by_admin UUID REFERENCES admin_users(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_groups_status ON groups(status);
CREATE INDEX IF NOT EXISTS idx_groups_created_by ON groups(created_by_admin);

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs anonymes de voir les groupes actifs
DROP POLICY IF EXISTS "groups_select" ON groups;
CREATE POLICY "groups_select" ON groups
    FOR SELECT USING (status = 'active' OR auth.role() = 'authenticated');

DROP POLICY IF EXISTS "groups_insert" ON groups;
CREATE POLICY "groups_insert" ON groups
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "groups_update" ON groups;
CREATE POLICY "groups_update" ON groups
    FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "groups_delete" ON groups;
CREATE POLICY "groups_delete" ON groups
    FOR DELETE USING (auth.role() = 'authenticated');


-- =====================================================
-- 4b. Membres des groupes (accès utilisateurs)
-- =====================================================

CREATE TABLE IF NOT EXISTS group_members (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, session_token)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_session_token ON group_members(session_token);

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Permettre aux utilisateurs anonymes de voir les membres des groupes
DROP POLICY IF EXISTS "group_members_select" ON group_members;
CREATE POLICY "group_members_select" ON group_members
    FOR SELECT USING (true);

-- Permettre aux utilisateurs anonymes de rejoindre un groupe
DROP POLICY IF EXISTS "group_members_insert" ON group_members;
CREATE POLICY "group_members_insert" ON group_members
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "group_members_delete" ON group_members;
CREATE POLICY "group_members_delete" ON group_members
    FOR DELETE USING (true);


-- =====================================================
-- 5. Messages de groupe
-- =====================================================

CREATE TABLE IF NOT EXISTS group_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    is_admin_reply BOOLEAN DEFAULT FALSE,
    admin_email VARCHAR(255),
    status VARCHAR(20) DEFAULT 'visible',  -- 'visible' | 'deleted'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_messages_group_id ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_session_token ON group_messages(session_token);

ALTER TABLE group_messages ENABLE ROW LEVEL SECURITY;

-- Permettre aux utilisateurs anonymes de voir les messages des groupes
DROP POLICY IF EXISTS "group_messages_select" ON group_messages;
CREATE POLICY "group_messages_select" ON group_messages
    FOR SELECT USING (status = 'visible');

-- Permettre aux utilisateurs anonymes d'envoyer des messages
DROP POLICY IF EXISTS "group_messages_insert" ON group_messages;
CREATE POLICY "group_messages_insert" ON group_messages
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "group_messages_update" ON group_messages;
CREATE POLICY "group_messages_update" ON group_messages
    FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "group_messages_delete" ON group_messages;
CREATE POLICY "group_messages_delete" ON group_messages
    FOR DELETE USING (auth.role() = 'authenticated');


-- =====================================================
-- 6. Vue admin pour les groupes
-- =====================================================

CREATE OR REPLACE VIEW admin_groups_view AS
SELECT
    g.id,
    g.name,
    g.description,
    g.status,
    g.members_count,
    g.messages_count,
    g.created_at,
    g.updated_at,
    a.email AS creator_email,
    a.role AS creator_role
FROM groups g
LEFT JOIN admin_users a ON g.created_by_admin = a.id;