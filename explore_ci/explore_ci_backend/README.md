# ExploreCI — Backend (VVP délai serré, 10 jours / 3 développeurs)

Backend Django + DRF du « Core MVP » défini dans la spécification VVP :
Auth (JWT), Tourisme (lieux/catégories/régions/carte), Avis & Favoris simplifiés.
Back-office natif via Django Admin. Aucune gamification, événement, communauté
avancée ou notification (hors périmètre, voir section 2 de la spec).

## État d'avancement

- ✅ Semaine 1 — Dev A : apps `accounts` (JWT) et `tourism` (lieux touristiques),
  script de génération des ~50 lieux (`seed_places`).
- ✅ Semaine 1 — Dev C (partie backend) : endpoints `Review` et `Favorite`
  simplifiés (app `interactions`).
- ✅ Semaine 2 — Dev A : configuration de déploiement (Render / Railway / Heroku),
  fichiers `Procfile`, `build.sh`, `runtime.txt`, CORS et fichiers statiques (whitenoise).

## Lancer le projet en local

```bash
python3 -m venv .venv
source .venv/bin/activate        # ou .venv\Scripts\activate sous Windows
pip install -r requirements.txt

cp .env.example .env             # optionnel, SQLite fonctionne sans .env

python manage.py migrate
python manage.py seed_places     # injecte catégories, régions et ~50 lieux touristiques
python manage.py createsuperuser # pour accéder à /admin/
python manage.py runserver
```

Le projet utilise **SQLite par défaut**. Pour passer sur PostgreSQL, définir
`DATABASE_URL` dans `.env` (exemple fourni dans `.env.example`).

## Endpoints disponibles

### Auth (`/api/auth/`)

| Méthode | URL | Description |
| --- | --- | --- |
| POST | `/api/auth/register/` | Inscription (email, password, first_name, last_name) |
| POST | `/api/auth/login/` | Connexion → retourne `access` + `refresh` (JWT) |
| POST | `/api/auth/token/refresh/` | Rafraîchir le token d'accès |
| GET | `/api/auth/me/` | Utilisateur connecté (`Authorization: Bearer <access>`) |

### Tourisme (`/api/tourism/`) — lecture publique, pas d'auth requise

| Méthode | URL | Description |
| --- | --- | --- |
| GET | `/api/tourism/categories/` | Liste des catégories |
| GET | `/api/tourism/regions/` | Liste des régions |
| GET | `/api/tourism/places/` | Liste des lieux (paginée, 20/page) |
| GET | `/api/tourism/places/?category=<slug>` | Filtre par catégorie |
| GET | `/api/tourism/places/?region=<slug>` | Filtre par région |
| GET | `/api/tourism/places/?search=<texte>` | Recherche par nom |
| GET | `/api/tourism/places/<id>/` | Fiche détaillée d'un lieu |

### Favoris & Avis (`/api/tourism/`) — authentification requise pour écrire

| Méthode | URL | Description |
| --- | --- | --- |
| GET | `/api/tourism/favorites/` | Mes favoris |
| POST | `/api/tourism/places/<id>/favorite/` | Ajoute/retire le lieu des favoris (toggle) |
| GET | `/api/tourism/places/<id>/reviews/` | Avis d'un lieu (public) |
| POST | `/api/tourism/places/<id>/reviews/` | Déposer un avis (note 1-5 + commentaire) — un seul par utilisateur/lieu |
| GET/PATCH/DELETE | `/api/tourism/places/<id>/reviews/me/` | Consulter / modifier / supprimer son propre avis |

### Admin

| — | `/admin/` | Django Admin natif (Category, Region, Place, User, Favorite, Review) |

## Exemple rapide

```bash
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"motdepasse123"}'

curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"motdepasse123"}'

curl http://127.0.0.1:8000/api/tourism/places/?region=grand-bassam

curl -X POST http://127.0.0.1:8000/api/tourism/places/<id>/favorite/ \
  -H "Authorization: Bearer <access>"
```

## Structure

```
explore_ci/
├── core/           # BaseModel abstrait (UUID PK + soft delete + timestamps)
├── accounts/       # User custom (email/password) + auth JWT
├── tourism/        # Category, Region, Place + endpoints carte/liste/filtres + seed_places
├── interactions/   # Favorite (toggle) + Review (note/commentaire, 1 par lieu/utilisateur)
└── explore_ci/     # settings, urls, wsgi
```

## Déploiement (Semaine 2)

Le projet est prêt pour **Render**, **Railway** ou **Heroku** :

- `Procfile` : commande `release` (migrate automatique) + commande `web` (gunicorn)
- `build.sh` : script de build alternatif pour Render (`pip install` + `collectstatic` + `migrate`)
- `runtime.txt` : version Python (utilisé par Heroku)
- Fichiers statiques servis directement par **whitenoise** (pas de service séparé nécessaire)
- CORS activé (`django-cors-headers`) — autorisé partout en dev, à restreindre en prod via
  `CORS_ALLOWED_ORIGINS` dans les variables d'environnement

### Étapes génériques (Render / Railway)

1. Créer le service web, connecter le repo Git.
2. Build Command : `./build.sh` (Render) ou automatique via `Procfile` (Railway/Heroku).
3. Start Command : `gunicorn explore_ci.wsgi --log-file - --bind 0.0.0.0:$PORT`.
4. Variables d'environnement à définir : `SECRET_KEY`, `DEBUG=False`, `ALLOWED_HOSTS`,
   `DATABASE_URL` (PostgreSQL fourni par la plateforme).
5. Après le premier déploiement : `python manage.py seed_places` (une fois, via le shell
   de la plateforme) pour peupler les lieux touristiques.

⚠️ Comme rappelé en section 6 de la spec : initier cette configuration dès le début de la
semaine 1 (même avec un projet vide) pour détecter tôt les problèmes d'environnement.

## Données de démonstration

`python manage.py seed_places` injecte 9 catégories, 14 régions et 50 lieux touristiques
ivoiriens réels (Basilique de Yamoussoukro, Grand-Bassam classé UNESCO, Parc National de
Taï, Cascade de Man, villages sénoufo de Korhogo, etc.). Les coordonnées GPS sont des
approximations raisonnables suffisantes pour la démo carte de la VVP — à affiner avant une
mise en production réelle. Option `--flush` pour repartir de zéro.
