e 
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) DEFAULT 'admin',  -- 'admin' | 'super_admin'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    created_by UUID   
);

-- Index
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active) WHERE is_active = TRUE;
 
INSERT INTO admin_users (email, role, is_active)
VALUES ('louisskwiz@gmail.com', 'super_admin', true)
ON CONFLICT (email) DO NOTHING;


ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_users_select" ON admin_users
    FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_users_insert" ON admin_users
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

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