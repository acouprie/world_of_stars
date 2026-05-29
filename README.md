# World of Stars

Jeu de stratégie spatial asynchrone par navigateur. Univers, noms et graphismes originaux — mécaniques inspirées librement d'OGame et World of Stargate.

**Deux objectifs :** vitrine technique Ruby on Rails + terrain d'expérimentation pour les agents IA.

---

## Le jeu

Chaque joueur commence avec une planète dans une galaxie partagée. Il construit des bâtiments, produit des ressources, forme des armées, explore des planètes vides et attaque ses voisins. La galaxie ne se vide pas au lancement : trois factions contrôlées par des agents IA peuplent la carte dès le premier joueur inscrit.

### Factions IA

| Faction | Archétype | Comportement |
|---|---|---|
| **L'Empire Varek** | Agressif, expansionniste | Raids réguliers, cible les joueurs isolés et les plus faibles |
| **La Confédération Elyrans** | Neutre, technologiquement avancée | N'attaque jamais en premier — réputation améliorable par le commerce |
| **Les Nexhari** | Menace globale, chaotique | Vagues d'expansion cycliques, aucune diplomatie possible |

Les décisions des factions sont prises par des agents LLM, avec un fallback scripté pour les comportements de base.

### Ressources

- **Énergie** — capacité installée (centrales), prérequis structurel pour construire
- **Métal, Nourriture, Thorium** — stocks produits en continu, calculés à la volée (`taux × (now - last_updated_at)`)

---

## Stack technique

| Composant | Technologie |
|---|---|
| Backend | Ruby on Rails 8.1 (Ruby 3.4) |
| Frontend socle | Hotwire — Turbo + Stimulus |
| Build JS | Vite (`vite_rails`) |
| CSS | Tailwind CSS v4 |
| Carte galaxie | React island + Pixi.js (WebGL) |
| Base de données | PostgreSQL 16 |
| Jobs asynchrones | Sidekiq 7 |
| Temps réel | ActionCable + Redis |
| Authentification | `rails generate authentication` (Rails 8 natif) |
| Tests | RSpec + FactoryBot + WebMock + VCR |
| IA produit | API LLM |
| Observabilité LLM | Langfuse |
| Mobile | PWA Rails 8 natif → Capacitor (iOS/Android) |
| Déploiement | Kamal → Infomaniak VPS Lite |
| Domaine | [worldofstars.fr](https://worldofstars.fr) |

---

## Démarrage en développement

### Prérequis

- Docker + Docker Compose

### Installation

```bash
# 1. Cloner et copier la config d'environnement
git clone <repo>
cd world_of_stars
cp .env.example .env
# Remplir RAILS_MASTER_KEY (valeur dans config/master.key)

# 2. Builder les images
docker compose build

# 3. Créer et migrer la base de données
docker compose run --rm web bin/rails db:create db:migrate

# 4. Démarrer tous les services
docker compose up
```

L'application est accessible sur [http://localhost:3000](http://localhost:3000).
Le Vite dev server (HMR) tourne sur le port 3036.
L'interface Sidekiq est accessible sur [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq) en développement.

### Services démarrés par Docker Compose

| Service | Rôle | Port |
|---|---|---|
| `web` | Rails server | 3000 |
| `vite` | Vite dev server (HMR) | 3036 |
| `sidekiq` | Workers background | — |
| `db` | PostgreSQL 16 | 5432 |
| `redis` | Redis 7 | 6379 |

### Sans Docker (développement local)

```bash
bundle install
npm install
bin/dev  # démarre Rails + Vite + Sidekiq via Foreman
```

---

## Tests

```bash
# Dans Docker
docker compose run --rm web bundle exec rspec

# En local
bundle exec rspec
```

Tous les appels HTTP externes sont bloqués par WebMock — aucun appel accidentel à l'API LLM pendant les tests.

---

## Structure du projet

```
app/
├── frontend/
│   ├── entrypoints/        # Points d'entrée Vite (JS + CSS)
│   ├── islands/
│   │   └── GalaxyMap/      # Carte galaxie — React + Pixi.js (WebGL)
│   └── controllers/        # Stimulus controllers
├── models/
│   ├── user.rb             # has_secure_password
│   ├── session.rb          # Auth sessions
│   └── current.rb          # CurrentAttributes (Current.user)
├── controllers/
│   └── concerns/
│       └── authentication.rb  # Concern inclus dans ApplicationController
├── channels/
│   └── application_cable/
│       └── connection.rb   # Auth WebSocket via cookie de session
├── jobs/                   # Jobs Sidekiq (constructions, déplacements, IA)
└── services/               # Service objects (logique métier)

config/
├── sidekiq.yml             # 5 queues : critical > default > ai_factions > narration > low
├── deploy.yml              # Configuration Kamal
└── vite.json               # Configuration vite_rails

db/migrate/
├── ..._create_users.rb
└── ..._create_sessions.rb
```

---

## Queues Sidekiq

Les jobs sont répartis par priorité pour que les événements critiques (combat, arrivée de flotte) ne soient jamais retardés par la génération de texte IA.

| Queue | Priorité | Exemples |
|---|---|---|
| `critical` | 10 | Résolution de combat, arrivée de flotte |
| `default` | 5 | Fin de construction, colonisation |
| `ai_factions` | 3 | Ticks de décision Varek/Elyrans/Nexhari |
| `narration` | 2 | Génération narrative LLM (non-bloquant) |
| `low` | 1 | Stats, nettoyage |

---

## Déploiement

Le déploiement utilise [Kamal](https://kamal-deploy.org/) vers un VPS Infomaniak Lite (4 vCPU / 8 GB RAM) avec SSL automatique via Let's Encrypt.

```bash
# Première fois — installe Docker sur le VPS et déploie
cp .kamal/secrets.example .kamal/secrets
# Remplir .kamal/secrets avec les vraies valeurs
kamal setup

# Déploiements suivants
kamal deploy
```

`.kamal/secrets` n'est jamais commité. Voir `.kamal/secrets.example` pour la liste des variables nécessaires.

---

## Documentation

- [`docs/game_design.md`](docs/game_design.md) — Game design complet : ressources, bâtiments, combat, exploration, factions IA, alliances
- [`docs/architecture.md`](docs/architecture.md) — Décisions techniques, points d'attention critiques (race conditions, WebMock, agents IA), checklist par feature
