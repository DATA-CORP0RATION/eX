# ExploreCI 🇨🇮

Application de découverte touristique de la Côte d'Ivoire : un backend **Django
REST Framework** et une application mobile **Flutter**, pensés ensemble pour
permettre à un voyageur de trouver des lieux, suivre un calendrier
d'événements, échanger avec une communauté de voyageurs et progresser via un
système de défis et de badges.

Le dépôt est un **monorepo** organisé en deux projets indépendants :

```
explore_ci/
├── explore_ci_backend/   # API Django + DRF (source de vérité des données)
└── explore_ci_mobile/    # Application Flutter (client officiel de l'API)
```

---

## Aperçu fonctionnel

| Module | Ce qu'il permet |
| --- | --- |
| **Auth** | Inscription / connexion par email, JWT (access + refresh) |
| **Tourisme** | Catalogue de lieux touristiques (~50 lieux réels de Côte d'Ivoire), catégories, régions, carte, recherche et filtres |
| **Interactions** | Favoris et avis (note 1-5 + commentaire, un seul avis par utilisateur et par lieu) |
| **Événements** | Calendrier de festivals, concerts, fêtes culturelles, sport, foires ; participation des utilisateurs |
| **Communauté** | Publications de voyageurs (récits, conseils, photos), likes, commentaires |
| **Gamification** | Check-in de visites, défis (par catégorie de lieu ou type d'événement), badges, statistiques de profil |

Toutes les entités métier héritent d'un modèle de base commun : **clé
primaire UUID**, horodatage `created_at` / `updated_at`, et **suppression
douce** (`is_deleted` / `deleted_at`) plutôt qu'une suppression en base.

---

## Backend — `explore_ci_backend/`

Django 5 + Django REST Framework, authentification par JWT
(`djangorestframework-simplejwt`), base SQLite par défaut (PostgreSQL en
production via `DATABASE_URL`).

### Apps Django

| App | Rôle |
| --- | --- |
| `core` | Modèle abstrait de base (UUID, soft delete, timestamps) |
| `accounts` | Utilisateur custom (email/mot de passe) + JWT |
| `tourism` | Catégories, régions, lieux touristiques + script de seed (~50 lieux) |
| `interactions` | Favoris et avis sur les lieux |
| `events` | Calendrier d'événements + participations |
| `community` | Publications, photos, likes, commentaires |
| `gamification` | Visites, défis, badges, statistiques de profil |

### Installation

```bash
cd explore_ci_backend
python3 -m venv .venv
source .venv/bin/activate        # .venv\Scripts\activate sous Windows
pip install -r requirements.txt

cp .env.example .env             # optionnel, SQLite fonctionne sans .env

python manage.py migrate
python manage.py seed_places      # catégories, régions et lieux touristiques
python manage.py seed_challenges  # badges et défis de démo
python manage.py createsuperuser  # accès à /admin/
python manage.py runserver
```

### Principaux endpoints (préfixe `/api/`)

| Zone | Exemples |
| --- | --- |
| `auth/` | `register/`, `login/`, `token/refresh/`, `me/` |
| `tourism/` | `categories/`, `regions/`, `places/`, `places/<id>/` (filtres `?category=`, `?region=`, `?search=`) |
| `tourism/` | `favorites/`, `places/<id>/favorite/`, `places/<id>/reviews/`, `places/<id>/reviews/me/` |
| `events/` | `events/`, `events/mine/`, `events/<id>/`, `events/<id>/participate/` |
| `community/` | `community/posts/`, `community/posts/<id>/`, `community/posts/<id>/like/`, `community/posts/<id>/comments/` |
| `gamification/` | `challenges/`, `badges/`, `badges/mine/`, `visits/mine/`, `places/<id>/visit/`, `profile/` |
| — | `admin/` (Django Admin natif sur toutes les entités) |

Détails complets, exemples `curl` et règles métier : voir
[`explore_ci_backend/README.md`](explore_ci_backend/README.md).

### Déploiement

Fichiers fournis pour Render / Railway / Heroku : `Procfile`, `build.sh`,
`runtime.txt`, `whitenoise` pour les fichiers statiques, CORS configuré via
`django-cors-headers`.

---

## Mobile — `explore_ci_mobile/`

Application Flutter consommant l'API ci-dessus.

### Stack

| Besoin | Package |
| --- | --- |
| Réseau | `http` |
| Carte interactive | `flutter_map` + `latlong2` (OpenStreetMap, pas de clé API) |
| Géolocalisation | `geolocator` |
| Stockage sécurisé des tokens | `flutter_secure_storage` |
| Gestion d'état | `provider` |

### Structure

```
lib/
├── config/       # URL de base de l'API et endpoints (api_config.dart)
├── models/       # Category, Region, Place, Event, Post, Review, User, Favorite...
├── services/     # Appels HTTP par domaine (auth, tourism, events, community, gamification, interactions)
└── screens/      # Écrans : auth, home, carte, liste des lieux, favoris,
                  # événements, communauté, gamification (défis/badges), profil
```

### Installation

```bash
cd explore_ci_mobile
flutter pub get
flutter run
```

Avant de lancer l'app, adapter `lib/config/api_config.dart` :

| Contexte | `baseUrl` à utiliser |
| --- | --- |
| Émulateur Android | `http://10.0.2.2:8000/api` |
| Simulateur iOS / Flutter Web | `http://127.0.0.1:8000/api` |
| Appareil physique | `http://<IP locale de la machine>:8000/api` |
| Production | URL du backend déployé (Render/Railway/Heroku) |

---

## Démarrage rapide (backend + mobile en local)

```bash
# 1. Backend
cd explore_ci_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_places
python manage.py seed_challenges
python manage.py runserver

# 2. Mobile (dans un autre terminal)
cd ../explore_ci_mobile
flutter pub get
flutter run
```

---

## Règles métier verrouillées

- Clés primaires en **UUID** sur toutes les entités.
- **Suppression douce** (`is_active` / `is_deleted`) au lieu d'un `DELETE` SQL.
- **Un avis par utilisateur et par lieu** (contrainte unique `user` + `place`).
- **Un badge débloqué une seule fois** par utilisateur (contrainte unique `user` + `badge`).
- Favoris, participations aux événements, likes et visites : toggle idempotent, un seul enregistrement par couple utilisateur/objet.

---

## Licence

Projet DATACORP. / prototype — usage interne.
