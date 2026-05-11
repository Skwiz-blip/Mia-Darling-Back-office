# Mia Darling — Back Office Admin

Tableau de bord d'administration pour la plateforme **Mia Darling**.  
Projet séparé, déployable indépendamment.

## Structure

```
MiaDarlia-Admin/
├── admin-login.html        # Page de connexion (email + mot de passe)
├── admin-dashboard.html    # Dashboard principal (toutes les sections)
├── js/
│   └── admin-config.js     # Config Supabase + helpers partagés
├── database/
│   └── admin-schema.sql    # Tables SQL à créer dans Supabase
└── README.md
```

## Sections du back office

| Section | Description |
|---|---|
| 📊 **Tableau de bord** | Statistiques globales, posts récents, tags populaires |
| 📝 **Témoignages** | Liste, recherche, filtres, masquer/supprimer/restaurer |
| 💬 **Commentaires** | Modération, suppression |
| 👤 **Sessions** | Voir toutes les sessions anonymes, bannir |
| 🚫 **Bannis** | Gérer les utilisateurs bannis, débannir |
| 🏷️ **Tags & Humeurs** | Ajouter/désactiver tags et moods |
| 🛡️ **Administrateurs** | Gérer les accès admin |

## Installation

### Étape 1 — Créer les tables admin dans Supabase

1. Allez dans **Supabase > SQL Editor**
2. Exécutez le fichier `database/admin-schema.sql`

### Étape 2 — Créer le compte admin

1. Dans Supabase, allez dans **Authentication > Users**
2. Cliquez **Add User** et créez un compte avec votre email
3. Dans le SQL Editor, mettez à jour l'email dans `admin-schema.sql` :
   ```sql
   INSERT INTO admin_users (email, role, is_active)
   VALUES ('votre-email@exemple.com', 'super_admin', true);
   ```

### Étape 3 — Vérifier la config

Ouvrez `js/admin-config.js` — la config Supabase est déjà remplie avec les clés du projet principal.

### Étape 4 — Déployer

Déployez sur n'importe quel hébergeur statique, idéalement sous un sous-domaine séparé :
- `admin.miadarling.com` (recommandé)
- ou un dossier protégé sur votre hébergeur

### Étape 5 — Se connecter

Ouvrez `admin-login.html`, entrez votre email + mot de passe.  
Vous serez redirigé automatiquement vers le dashboard.

## Sécurité

- L'authentification repose sur **Supabase Auth** (JWT)
- Chaque requête vérifie que l'email est dans la table `admin_users` avec `is_active = true`
- La déconnexion invalide la session côté Supabase
- RLS activé sur `admin_users`

## Accès depuis le site principal

Pour lier depuis `welcome.html` du projet principal, ajoutez un lien discret :

```html
<!-- Lien discret en bas de welcome.html -->
<a href="https://admin.miadarling.com/admin-login.html" 
   style="opacity: 0.15; font-size: 0.7rem; color: inherit; text-decoration: none;">
  ⬡
</a>
```

## Technologies

- HTML/CSS/JS vanilla (aucune dépendance frontend)
- Supabase JS SDK v2
- Google Fonts (Great Vibes + DM Sans)
