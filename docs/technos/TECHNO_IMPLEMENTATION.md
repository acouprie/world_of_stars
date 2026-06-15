# Système de recherche technologique — Implémentation

> Référence développeur — à lire en complément de `tech_reference.md` (game design) et `research_costs_v1.md` (tables de coûts).
> Implémenté le 2026-06-15. Branche des effets : **à faire séparément**.

---

## Schéma de base de données

### `planet_technologies`

| Colonne      | Type    | Notes                                 |
|--------------|---------|---------------------------------------|
| `planet_id`  | FK      | —                                     |
| `tech_key`   | string  | Clé symbolique ex. `"forage_cristallin"` |
| `level`      | integer | Niveau actuel, default 0              |
| `status`     | string  | `idle` / `researching`                |

Index unique sur `[planet_id, tech_key]`. Ligne créée à la première recherche (pas au démarrage).

### `research_queues`

| Colonne         | Type     | Notes                                   |
|-----------------|----------|-----------------------------------------|
| `planet_id`     | FK       | —                                       |
| `tech_key`      | string   | —                                       |
| `target_level`  | integer  | Niveau cible (level + 1 au moment du lancement) |
| `status`        | string   | `pending` / `completed` / `cancelled`   |
| `started_at`    | datetime | —                                       |
| `finishes_at`   | datetime | Calculé serveur : `now + cost[:time] / GameSpeed::MULTIPLIER` |
| `metal_cost`    | integer  | Coût snapshot au moment du lancement    |
| `food_cost`     | integer  | —                                       |
| `thorium_cost`  | integer  | —                                       |
| `sidekiq_job_id`| string   | Stocké après `perform_later`            |

Un seul `pending` par planète (validé en base + en service). Pas d'index unique — la contrainte est applicative.

### `users.exploration_xp`

Colonne `integer default 0` sur `users`. Incrémentée par le système d'exploration (branche séparée). Lue en lecture seule par le système de recherche via `user.exploration_level`.

---

## Couche modèle

### `Technologies` (module pure Ruby)

Fichier : `app/models/technologies.rb`

```
Technologies::REGISTRY          # hash figé — 9 technos initiales
Technologies::LEVEL_PREREQUISITES # checkpoints par niveau : { tech_key => { min_level => { prereq => value } } }

Technologies.for(tech_key)          # → hash de la techno, lève KeyError si inconnue
Technologies.cost_for(tech_key, n)  # → { metal:, food:, thorium:, time: } pour le niveau n
Technologies.max_level(tech_key)    # → integer
Technologies.prerequisites_met?(tech_key, target_level, planet, user)  # → bool
```

`prerequisites_met?` vérifie dans l'ordre :
1. Les clés de `requires` (research_lab, exploration, cross-tech) au niveau 1
2. Tous les checkpoints `LEVEL_PREREQUISITES` dont la clé ≤ `target_level`

Les associations `planet.buildings` et `planet.planet_technologies` doivent être chargées en mémoire avant l'appel (le module utilise `detect`, pas de requête SQL).

### `PlanetTechnology`

Analogie exacte avec `Building`. Pas de `slot_index`. Validations : `tech_key` ∈ `VALID_KEYS`, `status` ∈ `%w[idle researching]`, unicité `[planet_id, tech_key]`.

### `ResearchQueue`

Validations : un seul `pending` par planète (`only_one_pending_per_planet`), `finishes_at` présent. Scopes : `.pending`, `.completed`, `.cancelled`.

### `User#exploration_level`

```ruby
EXPLORATION_LEVEL_BASE_XP = 1000
EXPLORATION_LEVEL_FACTOR  = 1.2
# Niveau 0 : < 1000 XP
# Niveau 1 : 1000–1199
# Niveau 2 : 1200–1439
# …
```

Progression géométrique : chaque seuil = seuil précédent × 1.2.

---

## Couche service

### `Researches::StartService`

```
new(planet:, user:, tech_key:) → .call → Result(success?, error, queue)
```

Séquence sous `planet.with_lock` :

1. `Technologies.for(@tech_key)` — lève `KeyError` si clé invalide
2. Charge `planet.buildings`, `planet.planet_technologies`, `planet.calculate_resources!`
3. Vérifie : pas de pending, niveau max non atteint, prérequis satisfaits, ressources suffisantes
4. Déduit les ressources, crée la `PlanetTechnology` si absente, crée la `ResearchQueue`
5. Met `planet_technology.status = "researching"`
6. Schedule `CompleteResearchJob.set(wait_until: finishes_at).perform_later(queue.id)`
7. Stocke le `sidekiq_job_id` via `update_column`

### `Researches::CancelService`

```
new(planet) → .call → Result(success?, error)
```

Sous `planet.with_lock` : rembourse 100% des coûts (snapshot sur la queue), passe la queue en `cancelled`, remet la `PlanetTechnology` en `idle`. **Pas de suppression du job Sidekiq** — le job vérifie le statut avant d'agir.

---

## Job

### `CompleteResearchJob`

Idempotent par double-check :

```ruby
queue = ResearchQueue.find_by(id: id)
return unless queue&.pending?
queue.reload
return unless queue.pending?
# … upgrade
```

Dans une transaction : `queue → completed`, `planet_technology.level = target_level`, `planet_technology.status = idle`.

---

## Contrôleurs & routes

```ruby
# config/routes.rb — dans resources :planets
get    'research',       to: 'research#index',         as: :research
post   'research/queue', to: 'researches/queue#create', as: :research_queue
delete 'research/queue', to: 'researches/queue#destroy'
```

- `ResearchController#index` — construit `@techs_by_category` avec statuts `:available / :locked / :researching / :max` et affordability de chaque techno.
- `Researches::QueueController#create` — délègue à `StartService`, répond Turbo Stream + HTML.
- `Researches::QueueController#destroy` — délègue à `CancelService`, répond Turbo Stream + HTML.

---

## Invariants et pièges

**`calculate_resources!` plafonne les stocks à la capacité de stockage.** Sans entrepôt, la capacité est ~1 000. En test, initialiser les stocks dans cette limite ou créer les bâtiments de stockage nécessaires. Voir `spec/services/constructions/initiate_service_spec.rb` ligne 5 pour le pattern.

**Les coûts et `finishes_at` sont calculés côté serveur.** Jamais reçus du client.

**`GameSpeed::MULTIPLIER`** divise la durée (accélère le temps de recherche en dev), **multiplie** le calcul de ressources dans `calculate_resources!`.

**Les effets des technologies ne sont pas appliqués.** `Technologies::REGISTRY` définit les champs `effect:` pour la phase suivante (branche dédiée).

---

## Fichiers clés

```
app/models/technologies.rb
app/models/planet_technology.rb
app/models/research_queue.rb
app/models/user.rb                          # exploration_level, exploration_xp_for_level
app/models/planet.rb                        # has_many :planet_technologies, :research_queues
app/services/researches/start_service.rb
app/services/researches/cancel_service.rb
app/jobs/complete_research_job.rb
app/controllers/research_controller.rb
app/controllers/researches/queue_controller.rb
app/views/research/
app/helpers/research_helper.rb
spec/models/technologies_spec.rb
spec/models/user_spec.rb                    # describe "#exploration_level"
spec/services/researches/
spec/jobs/complete_research_job_spec.rb
spec/factories/planet_technologies.rb
spec/factories/research_queues.rb
db/migrate/20260615000001_add_exploration_xp_to_users.rb
db/migrate/20260615000002_create_planet_technologies.rb
db/migrate/20260615000003_create_research_queues.rb
```
