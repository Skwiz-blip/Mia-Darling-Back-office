// =====================================================
// MIA DARLING — Admin Back Office Config
// =====================================================

const SUPABASE_URL = 'https://yeawjdkyqjyjvpahlbmp.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllYXdqZGt5cWp5anZwYWhsYm1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NzQ2MzAsImV4cCI6MjA5MjI1MDYzMH0.DP3kRbQ0UH7moDkaF61y9wmlqupLXjClj6PSqROQNlA';

// Initialize Supabase client
let adminSupabase = null;
if (window.supabase && window.supabase.createClient) {
  adminSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// ── Auth Guard ─────────────────────────────────────
// Call this on every protected admin page
async function requireAdminAuth() {
  if (!adminSupabase) {
    window.location.href = 'admin-login.html';
    return null;
  }
  const { data: { session } } = await adminSupabase.auth.getSession();
  if (!session) {
    window.location.href = 'admin-login.html';
    return null;
  }
  // Verify admin role
  const { data: adminUser } = await adminSupabase
    .from('admin_users')
    .select('*')
    .eq('email', session.user.email)
    .eq('is_active', true)
    .single();

  if (!adminUser) {
    await adminSupabase.auth.signOut();
    window.location.href = 'admin-login.html';
    return null;
  }
  return { session, adminUser };
}

// ── Logout ─────────────────────────────────────────
async function adminLogout() {
  await adminSupabase.auth.signOut();
  localStorage.removeItem('mia_admin_email');
  localStorage.removeItem('mia_admin_id');
  window.location.href = 'admin-login.html';
}

// ── Helpers ────────────────────────────────────────
function timeAgo(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);
  if (seconds < 60) return "À l'instant";
  if (seconds < 3600) return `il y a ${Math.floor(seconds / 60)} min`;
  if (seconds < 86400) return `il y a ${Math.floor(seconds / 3600)}h`;
  if (seconds < 604800) return `il y a ${Math.floor(seconds / 86400)} j`;
  return new Date(dateString).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  });
}

function truncate(str, n) {
  return str && str.length > n ? str.slice(0, n) + '…' : str;
}

console.log('[Mia Admin] Config chargée ✓');
