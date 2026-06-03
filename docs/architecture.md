# World of Stars — Architecture & Points d'attention développement

> Document de référence technique — complément au game_design.md
> À consulter au démarrage de chaque feature majeure

---

## Stack retenue

| Composant         | Technologie                             | Rôle                                                   |
| ----------------- | --------------------------------------- | ------------------------------------------------------ |
| Backend           | Ruby on Rails 8                         | Logique métier, API, rendu serveur                     |
| Frontend socle    | Hotwire (Turbo + Stimulus)              | 80% de l'UI — pages, timers, flux serveur              |
| Build JS          | Vite (`vite_rails`)                     | Bundler moderne, support JSX/React/Pixi.js, hot reload |
| CSS               | Tailwind CSS                            | Utilitaires mobile-first, bien intégré Hotwire         |
| Frontend complexe | React (islands)                         | Carte galaxie, composants très interactifs             |
| Carte galaxie     | Pixi.js (WebGL)                         | Rendu performant, zoom/pan, flottes en mouvement       |
| Base de données   | PostgreSQL                              | Données de jeu, état des agents, mémoire des factions  |
| Jobs asynchrones  | Sidekiq                                 | Constructions, déplacements, combats, ticks IA         |
| Temps réel        | ActionCable + Turbo Streams             | Push serveur → client (ressources live, alertes radar) |
| Authentification  | `rails generate authentication`         | Auth maison Rails 8, code lisible et modifiable        |
| Tests             | RSpec + FactoryBot + WebMock            | Suite de tests complète, mocks des appels LLM          |
| IA produit        | API LLM                                 | Agents factions, narration, conseiller, support        |
| Observabilité LLM | Langfuse                                | Tracing de tous les appels LLM                         |
| Mobile            | Capacitor                               | Wrapping PWA → app stores (iOS + Android)              |
| Registry Docker   | GitHub Container Registry               | Gratuit, intégré GitHub Actions                        |
| Hébergement       | Infomaniak VPS Lite (4 vCPU / 8 GB RAM) | Linux brut, compatible Kamal, datacenter Suisse        |
| Déploiement       | Docker Compose (dev) + Kamal (prod)     | Déploiement Rails-natif sur VPS                        |
| Domaine           | worldofstars.fr                         | —                                                      |
| Traduction        | i18n                                    | Traduction des textes dans plusieurs langues           |

---

## Architecture frontend — le modèle "islands"

### Principe

Rails + Hotwire est le socle. React n'intervient que pour les composants qui en ont vraiment besoin. Les deux coexistent dans la même application Rails sans séparation API/frontend.

```
Rails (rendu serveur)
├── Turbo Frames      → navigation partielle, formulaires, panneau upgrade bâtiment
├── Turbo Streams     → push live (ressources, timers, file de construction, alertes)
├── Stimulus          → interactions légères, comportements JS ciblés
└── React islands     → composants interactifs autonomes
    ├── PlanetOrbitalView  → vue orbitale planète avec pins de bâtiments
    ├── Carte galaxie (Pixi.js)
    └── [Autres composants très interactifs si nécessaire]
```

### Intégration Rails ↔ React

- Via Vite (`vite_rails`, installé et configuré)
- Les islands React reçoivent leur état initial en props depuis Rails (ERB → JSON)
- Les mises à jour live passent par ActionCable ou fetch vers des endpoints JSON dédiés
- Pas besoin d'une API REST complète — juste des endpoints ciblés pour les islands

### i18n

Utilisation de la gem i18n de Rails pour les textes statiques. Les islands React reçoivent les traductions nécessaires en props (ex: labels, messages d'erreur). Pas de solution de traduction JS dédiée — on reste dans le modèle "Rails rend tout".
L'application est disponible en français et en anglais dès le lancement, avec possibilité d'ajouter d'autres langues plus tard.

### Vite — pourquoi pas importmap

Rails 8 propose deux approches pour le JavaScript. Importmap charge les modules directement depuis le navigateur sans build, ce qui est parfait pour du Stimulus léger. Vite est un bundler moderne qui compile le code avant de l'envoyer au client.

Pour ce projet, Vite est nécessaire dès le début parce que Pixi.js et React nécessitent npm et JSX — deux choses qu'importmap ne supporte pas nativement. Avantages concrets : hot reload en développement (le navigateur se met à jour à chaque sauvegarde sans recharger la page), accès complet à l'écosystème npm, et support TypeScript si souhaité.

Le fichier `vite.config.ts` est le point d'entrée pour tous les assets JS/CSS. Tailwind s'intègre directement dans ce pipeline. `vite_rails` est déjà installé et configuré dans ce projet.

### Points d'attention — vue orbitale planète (`PlanetOrbitalView`)

**Composant React island** (`app/javascript/components/PlanetOrbitalView.jsx`) monté via partial ERB.

- La planète est rendue en **SVG inline** — 5 variantes visuelles (`oceanic`, `arid`, `volcanic`, `glacial`, `forest`) dérivées de `planet.id % 5` côté serveur. Pas de colonne en base, pas de PNG externe.
- Les pins sont en `position: absolute` sur le conteneur planète, coordonnées en pourcentages depuis `position_x`/`position_y` (float 0.0–1.0, stockés en base sur `buildings`).
- **12 emplacements fixes** définis dans le helper Rails (`SLOT_POSITIONS`), dont 1 orbital pour le satellite radar (positionné sur l'anneau en dehors de la planète).
- Le composant React **ne gère pas le panneau d'upgrade** — il délègue via callback `onBuildingSelect(building_id)`, le parent ERB affiche le détail via Turbo Frame.
- **Pointer Events obligatoires** (pas MouseEvents) pour la compatibilité tactile mobile.
- Utiliser exclusivement les **variables CSS du projet** pour les couleurs — ne jamais hardcoder de hex dans le composant (voir Annexe E du GDD).
- Apparence des pins selon le niveau : 28px outline (nv 1–2), 32px plein (nv 3–4), 36px + `@keyframes pulse-halo` sur `box-shadow` (nv 5+).
- Vue liste en toggle (groupée par catégorie) pour mobile et préférence joueur — même données, rendu différent.

### Points d'attention — carte galaxie (Pixi.js)

- Pixi.js est un renderer WebGL : penser en sprites/textures, pas en DOM
- Prévoir la gestion mémoire : détruire les sprites des planètes/flottes hors champ
- Le zoom/pan doit être fluide même avec 500+ planètes → utiliser les conteneurs Pixi, pas de re-render React
- Les flottes en mouvement = interpolation position côté client entre deux états serveur (ne pas dépendre du serveur pour chaque frame)
- État synchronisé via ActionCable (canal dédié carte) : le serveur pousse les events, le client interpole

---

## Mobile — Capacitor

### Ce que c'est

Capacitor (Ionic) transforme une PWA en application native iOS/Android. La codebase reste une seule app web ; Capacitor ajoute une couche native légère qui permet :

- Distribution via App Store et Google Play
- Accès aux APIs natives (notifications push, etc.)
- Une WebView optimisée (WKWebView sur iOS, pas la WebView système)

### Points d'attention

- **Concevoir mobile-first dès le début** — rétrofitter une UI desktop en mobile est coûteux
- Les interactions tactiles (tap, swipe, pinch-to-zoom sur la carte) doivent être testées tôt
- Pixi.js fonctionne bien dans Capacitor mais tester sur vrai device rapidement (émulateur insuffisant pour WebGL)
- Les notifications push nécessitent un setup Capacitor spécifique (plugin `@capacitor/push-notifications`) — à anticiper pour les alertes radar/attaques
- ActionCable/WebSocket : tester le comportement en arrière-plan sur iOS (l'OS peut couper les connexions)

---

## Mobile-first — intégration dans le workflow de développement

### La posture à adopter

Une seule codebase Rails. L'app mobile _est_ l'app web. Le schéma complet :

```
App Rails (PWA)
├── Fonctionne dans un navigateur desktop
├── Fonctionne dans un navigateur mobile (responsive)
└── Wrappée par Capacitor → distributable sur App Store / Google Play
```

**PWA = Progressive Web App** : ton app Rails normale à laquelle on ajoute deux fichiers — un `manifest.json` (nom, icône, couleur de thème) et un service worker (cache offline partiel). Ça permet au navigateur mobile de proposer "Ajouter à l'écran d'accueil", et l'app s'ouvre alors sans barre d'URL, comme une vraie application. Rails 8 génère ces fichiers automatiquement via `rails new` avec les options par défaut.

### CSS : écrire mobile-first dès le premier composant

```css
/* ✅ Mobile-first : la base s'applique au mobile */
.galaxy-controls {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

/* Le desktop est un override explicite */
@media (min-width: 768px) {
  .galaxy-controls {
    flex-direction: row;
  }
}

/* ❌ Desktop-first : à éviter — le mobile devient un patch */
.galaxy-controls {
  display: flex;
  flex-direction: row;
}
@media (max-width: 768px) {
  .galaxy-controls {
    flex-direction: column;
  }
}
```

Garder un onglet Chrome DevTools en mode iPhone 14 (375px) ouvert en permanence pendant le développement — pas en fin de sprint.

### Règles UI tactiles à respecter systématiquement

- Zones cliquables minimum **44×44px** (recommandation Apple/Google) — un bouton trop petit sur desktop est un enfer sur mobile
- Aucun comportement **hover-only** — tout ce qui réagit au hover doit aussi réagir au tap
- Pas de double-tap accidentel sur les actions Turbo — configurer un debounce dans les Stimulus controllers
- Formulaires : les `<input type="number">` ouvrent le bon clavier numérique sur mobile, utiliser les bons types HTML

### La carte galaxie (Pixi.js) — gestion des deux modes d'interaction

C'est le composant le plus complexe à adapter. À coder en utilisant les **Pointer Events** (pas les MouseEvents), qui unifient click et touch :

```javascript
// ✅ Pointer Events — fonctionnent sur desktop ET mobile
app.stage.on("pointerdown", onSelectPlanet);
app.stage.on("pointermove", onDragMap);

// ❌ MouseEvents — ignorés sur mobile
app.stage.on("click", onSelectPlanet);
```

Deux comportements à implémenter explicitement :

| Action                   | Desktop              | Mobile              |
| ------------------------ | -------------------- | ------------------- |
| Sélectionner une planète | Click                | Tap                 |
| Déplacer la vue          | Drag (clic maintenu) | Swipe (un doigt)    |
| Zoomer                   | Scroll molette       | Pinch (deux doigts) |

Le pinch-to-zoom ne vient pas automatiquement — il faut l'implémenter via une librairie gesture (ex: `hammerjs`) ou à la main avec les `pointermove` events.

### Notifications push — à anticiper tôt

Les alertes d'attaque et les fins de construction sont des features d'engagement critiques sur mobile. Elles nécessitent le plugin Capacitor dédié, mais aussi un **setup côté serveur** (service de push Apple/Google). À ne pas traiter comme un ajout tardif.

```bash
npm install @capacitor/push-notifications
```

Côté Rails, prévoir un modèle `DeviceToken` dès le début pour stocker les tokens push des joueurs.

### Workflow de test mobile

- **Quotidien** : Chrome DevTools device mode (375px, 768px)
- **Hebdomadaire** : test sur un vrai device Android (les simulateurs sont insuffisants pour WebGL/Pixi)
- **Avant chaque release** : test Capacitor complet sur iOS et Android
- **Règle de PR** : toute PR touchant l'UI doit avoir été testée sur viewport 375px avant merge

### Contraintes de build iOS

Pour soumettre sur l'App Store, il faut obligatoirement :

- Un compte Apple Developer (99$/an)
- Xcode sur macOS pour compiler le build iOS

Si tu développes sous Linux ou Windows, anticiper l'accès à un Mac ou un service de build cloud (Codemagic est bien intégré avec Capacitor).

---

## Authentification — `rails generate authentication`

Rails 8 intègre un générateur d'authentification natif qui produit directement dans ton app le code minimal nécessaire — quelques centaines de lignes lisibles dans tes propres fichiers, que tu peux modifier librement.

```bash
rails generate authentication
# Génère :
# app/models/user.rb (avec has_secure_password)
# app/models/session.rb
# app/controllers/sessions_controller.rb
# app/controllers/passwords_controller.rb
# app/mailers/passwords_mailer.rb
# db/migrate/..._create_users.rb
# db/migrate/..._create_sessions.rb
```

### Différence avec Devise

Devise est une gem externe de ~10 000 lignes qui gère tout mais reste une boîte noire. Le générateur Rails 8 produit du code que tu possèdes et comprends entièrement.

**Ce que `rails generate authentication` inclut** : connexion/déconnexion, sessions sécurisées, réinitialisation de mot de passe par email, `has_secure_password` (bcrypt).

**Ce qui n'est pas inclus** et à implémenter si nécessaire :

- Confirmation email à l'inscription
- OAuth (Google, Discord, etc.) — ajouter la gem `omniauth` le moment venu
- Rate limiting sur les tentatives de connexion — ajouter `rack-attack`

Pour le lancement de World of Stars, aucun de ces points n'est bloquant.

---

## Tests — RSpec, FactoryBot, WebMock

### Pourquoi RSpec plutôt que Minitest

RSpec offre un DSL plus expressif, un meilleur écosystème de matchers, et un meilleur support dans Claude Code pour la génération de tests complexes. Sur un projet avec des formules d'équilibrage et des agents IA, la lisibilité des tests compte.

### Setup initial

```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'webmock'           # mock HTTP en général
  gem 'vcr'               # enregistre/rejoue les appels HTTP réels
end

group :test do
  gem 'shoulda-matchers'  # matchers supplémentaires pour les modèles
  gem 'faker'             # données de test réalistes
end
```

```bash
rails generate rspec:install
```

### Mocker les appels LLM

**WebMock** bloque tous les appels HTTP externes dans les tests par défaut. C'est le garde-fou : aucun test ne peut appeler l'API LLM (et donc coûter de l'argent ou dépendre du réseau).

```ruby
# spec/support/anthropic_helpers.rb
module AnthropicHelpers
  def stub_anthropic_response(content:)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          content: [{ type: "text", text: content }],
          usage: { input_tokens: 100, output_tokens: 50 }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end

# Utilisation dans les tests
RSpec.describe ExplorationReport, type: :service do
  include AnthropicHelpers

  it "génère un rapport narratif" do
    stub_anthropic_response(content: "Les explorateurs ont découvert...")
    report = ExplorationReport.new(mission).generate
    expect(report).to include("explorateurs")
  end
end
```

**VCR** (optionnel, pour les tests d'intégration) : enregistre un vrai appel Anthropic une fois, puis le rejoue dans les tests suivants. Utile pour tester les prompts des agents sans les mocker manuellement.

### Ce qu'on teste en priorité

Les formules d'équilibrage sont les candidates idéales pour les tests unitaires — elles sont déterministes, critiques pour le gameplay, et faciles à tester :

```ruby
RSpec.describe CombatResolver, type: :service do
  it "applique le multiplicateur x15 pour un écart inférieur à 5x" do
    attacker = build(:fleet, strength: 400)
    defender = build(:fleet, strength: 100)  # ratio 4x < 5x
    result = CombatResolver.new(attacker, defender).resolve
    expect(result.xp_multiplier).to eq(15)
  end
end
```

### Règle fondamentale

**Aucun appel HTTP réel dans les tests.** WebMock lève une exception si un appel non stubbé est tenté. Cette règle s'applique aussi aux appels vers des APIs tierces futures.

---

## Gestion du temps — points d'attention critiques

### Le modèle `last_updated_at` (ressources)

```ruby
# Calcul à la volée — élégant mais attention aux cas limites
resources += production_rate * (Time.current - last_updated_at)
```

- **Race condition** : deux workers Sidekiq touchant la même planète simultanément peuvent corrompre l'état
- Solution : transactions PostgreSQL + `SELECT ... FOR UPDATE` (lock pessimiste) sur la planète avant toute écriture
- À implémenter dès le début — rajouter des locks après coup est douloureux
- Tester systématiquement les scénarios concurrents : flotte qui arrive + construction qui finit + raid IA au même moment

### Jobs Sidekiq — bonnes pratiques

- Rendre tous les jobs **idempotents** : si un job s'exécute deux fois (retry après crash), l'état final doit être identique
- Stocker l'heure d'arrivée prévue en base, pas seulement dans la queue Sidekiq — permet de reconstruire l'état si la queue est perdue
- Les jobs de combat/conquête doivent vérifier que l'état n'a pas changé entre la création du job et son exécution (ex : la planète a changé de propriétaire entre-temps)

---

## IA dans le produit

### Niveau 1 — Narration (MVP, faible complexité)

**Rapports d'exploration**

- Prompt : contexte de la planète (type, coordonnées, unités envoyées) + résultat mécanique (ressources trouvées, pertes) → Claude génère un rapport narratif
- Garder le prompt court, le contexte minimal, la sortie bornée (max 200 tokens)
- Cacher le résultat (Redis) pour éviter de régénérer si le joueur relit son rapport

**Rapports de combat**

- Même logique : résultat mécanique calculé d'abord, narration générée ensuite
- La narration n'influence jamais le résultat — calculer avant d'appeler le LLM

**Messages des factions**

- Déclarations de guerre Varek, propositions commerciales Elyrans, alertes Nexhianti
- Utiliser un `system prompt` par faction avec sa personnalité définie
- Prévoir une bibliothèque de quelques messages fallback si l'API est indisponible

### Niveau 2 — Conseiller impérial (feature à fort impact vitrine)

Agent contextuel accessible depuis l'interface, capable de :

- Analyser l'état réel de la planète du joueur (bâtiments, ressources, voisins)
- Suggérer les prochaines actions prioritaires
- Répondre aux questions sur les règles (RAG sur le GDD)

```ruby
class ImperialAdvisor
  def advise(player)
    context = build_context(player) # état complet en JSON
    anthropic_client.messages.create(
      model: "claude-sonnet-4-20250514",
      system: ADVISOR_SYSTEM_PROMPT,
      messages: [{ role: "user", content: context }],
      max_tokens: 500
    )
  end
end
```

**Points d'attention** : rate limiting par joueur (1 appel/minute max), ne jamais exposer l'état des autres joueurs dans le contexte.

### Niveau 3 — Agents de factions (phase 2)

#### Architecture recommandée

```ruby
class FactionAgent
  def tick(faction_state)
    response = anthropic_client.messages.create(
      model: "claude-sonnet-4-20250514",
      system: faction_system_prompt,
      tools: available_actions,        # liste des actions possibles
      messages: build_messages(faction_state)
    )
    execute_tool_use(response)
    persist_memory(response)           # stocker la décision en base
  end
end
```

#### Ordre de migration recommandé

1. **Les nexhianti** en premier — comportement chaotique, pas de diplomatie, les erreurs sont des features
2. **Les Varek** ensuite — logique d'agression scriptable, bon test de la cohérence décisionnelle
3. **Les Elyrans** en dernier — la diplomatie et la réputation nécessitent un agent plus nuancé

#### Mémoire des agents (modèle PostgreSQL)

```ruby
# À créer dès le début, pas en retard
create_table :faction_memories do |t|
  t.string :faction        # varek, elyrans, nexhianti
  t.string :memory_type    # objective, last_decision, target_priority
  t.jsonb  :content
  t.timestamps
end
```

---

## Observabilité LLM — Langfuse

### Pourquoi dès le début

Sans traçage, débugger un comportement de faction bizarre revient à inspecter des logs bruts. Langfuse donne :

- Historique de chaque appel (prompt, réponse, tokens, coût, latence)
- Évaluation des décisions agents sur le temps
- Détection des dérives de comportement

### Intégration Rails

```ruby
# Wrapper autour de chaque appel Anthropic
class TrackedAnthropicClient
  def messages_create(params, trace_name:)
    trace = Langfuse.trace(name: trace_name)
    generation = trace.generation(input: params)

    response = anthropic_client.messages.create(params)

    generation.end(output: response, usage: response.usage)
    response
  end
end
```

---

## Gestion des coûts API Anthropic

### Matrice modèles → usages

| Usage                                      | Modèle recommandé        | Raison                              |
| ------------------------------------------ | ------------------------ | ----------------------------------- |
| Décisions simples des factions (scriptées) | claude-haiku-4-5         | Rapide, < 1¢ par décision           |
| Narration exploration/combat               | claude-haiku-4-5         | Créativité suffisante, volume élevé |
| Agents ReAct des factions                  | claude-sonnet-4-20250514 | Raisonnement complexe               |
| Conseiller impérial                        | claude-sonnet-4-20250514 | Qualité attendue par le joueur      |
| Support joueurs (RAG)                      | claude-haiku-4-5         | Questions/réponses factuelles       |

### Garde-fous à implémenter dès le début

- **Rate limiting par joueur** : 1 appel conseiller/minute, 1 rapport d'exploration narratif généré une seule fois (jamais reégénéré)
- **Cache Redis** : mettre en cache les rapports narratifs générés (clé = hash des paramètres mécaniques)
- **Décisions de faction throttlées** : une décision Varek toutes les N minutes, pas à chaque tick Sidekiq
- **Budget mensuel hardcodé** : couper les features LLM non critiques si le budget est dépassé (variable d'environnement)
- **Timeout sur les appels** : ne jamais laisser un appel LLM bloquer un job Sidekiq indéfiniment

---

## Evals — mesurer la qualité des agents

Point crucial pour la montée en compétence et la fiabilité du jeu.

### Principe

Créer une suite de scénarios de test pour chaque agent de faction :

```ruby
# Exemple d'eval pour les Varek
VAREK_EVAL_SCENARIOS = [
  {
    description: "Joueur faible voisin, Varek à 80% capacité",
    game_state: { ... },
    expected_behavior: "attaque ou pillage",
    forbidden_behavior: "proposition commerciale"
  },
  {
    description: "Joueur dominant, Varek en dessous du seuil minimum",
    game_state: { ... },
    expected_behavior: "consolidation, pas d'attaque",
  }
]
```

### Ce qu'on mesure

- **Cohérence de personnalité** : les Varek agressent-ils bien les faibles et évitent-ils les puissants ?
- **Respect des règles** : les agents ne proposent jamais d'actions impossibles ?
- **Stabilité** : le comportement est-il reproductible sur 10 appels avec le même contexte ?

---

## Angles morts — checklist par feature

### À vérifier à chaque nouvelle feature

- [ ] Un test unitaire existe pour chaque formule ou règle métier
- [ ] Les appels Anthropic sont stubbés avec WebMock dans les specs concernées
- [ ] Les factories FactoryBot couvrent les nouveaux modèles

### À vérifier à chaque feature impliquant la vue orbitale

- [ ] Les couleurs utilisent les variables CSS du projet (pas de hex hardcodé)
- [ ] Pointer Events utilisés (pas MouseEvents)
- [ ] Zones cliquables ≥ 44×44px
- [ ] Testé en vue liste (toggle) et sur viewport 375px

### À vérifier à chaque feature impliquant des ressources

- [ ] Lock pessimiste PostgreSQL sur la planète avant toute écriture
- [ ] Job Sidekiq idempotent (safe en cas de double exécution)
- [ ] L'état prévu (heure d'arrivée, fin de construction) est persisté en base

### À vérifier à chaque feature impliquant un appel LLM

- [ ] Rate limiting en place
- [ ] Résultat mécanique calculé avant l'appel LLM (la narration ne change jamais le gameplay)
- [ ] Appel tracé dans Langfuse
- [ ] Fallback si l'API est indisponible (message générique, pas de crash)
- [ ] Modèle choisi est le moins cher qui convient

### À vérifier à chaque feature avec état de faction

- [ ] La décision est persistée dans `faction_memories`
- [ ] Le comportement a un scénario d'eval associé
- [ ] Le throttling est respecté (pas d'appel à chaque tick)

### À vérifier pour les features mobile

- [ ] UI testée sur viewport 375px
- [ ] Interactions tactiles testées sur vrai device
- [ ] Comportement WebSocket testé en arrière-plan iOS

---

## Déploiement — Kamal sur Infomaniak VPS Lite

Kamal est l'outil de déploiement officiel de l'écosystème Rails (créé par Basecamp). Il orchestre Docker sur VPS sans la complexité de Kubernetes. Kamal est exceptionnellement compatible avec les environnements Linux VPS — il installe Docker lui-même sur le serveur au premier déploiement, aucune configuration préalable requise.

### Pourquoi VPS Lite et pas Jelastic

Jelastic est un PaaS qui gère l'infrastructure à ta place. C'est incompatible avec Kamal qui a besoin d'un Linux brut avec accès root pour orchestrer Docker. Le VPS Lite donne cet accès root complet.

Configuration recommandée : **4 vCPU / 8 GB RAM / 160 GB NVMe** (~20€/mois). En dessous de 4 GB RAM, les déploiements Docker risquent des OOM kills (Rails + PostgreSQL + Redis + Sidekiq, tout tourne en parallèle).

### Configuration Kamal

### Configuration Kamal

```yaml
# config/deploy.yml
service: world-of-stars
image: ghcr.io/ton-username/world-of-stars # GitHub Container Registry

servers:
  web:
    - IP_DU_VPS_INFOMANIAK
  job:
    hosts:
      - IP_DU_VPS_INFOMANIAK
    cmd: bundle exec sidekiq

proxy:
  ssl: true
  host: worldofstars.fr
  app_port: 3000

registry:
  server: ghcr.io
  username: ton-username-github
  password:
    - KAMAL_REGISTRY_PASSWORD

accessories:
  db:
    image: postgres:16
    host: IP_DU_VPS_INFOMANIAK
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
  redis:
    image: redis:7
    host: IP_DU_VPS_INFOMANIAK
    port: 6379
    directories:
      - data:/data
```

**Points d'attention** :

- Séparer les containers web et Sidekiq dès le début (scalabilité)
- Prévoir un container dédié pour les agents IA si les microservices Python arrivent en phase 2
- ActionCable nécessite un adapter Redis (déjà dans la stack)

---

## Utilisation de l'IA dans le développement

### Claude Code — usage recommandé

- Génération des migrations et modèles à partir du GDD (excellent point de départ)
- Tests unitaires des formules d'équilibrage (combat, exploration, XP) — générer 100 scénarios de test
- Refactoring des agents après chaque itération
- Revue des prompts avant mise en production

### Génération de contenu de jeu

- **Noms de planètes** : batch generation avec contraintes (sonorité par faction, longueur)
- **Descriptions de missions** : générer une bibliothèque offline, stocker en base — pas de génération live pour le contenu statique
- **Événements Nexhianti** : les messages globaux d'alerte peuvent être générés à l'avance et stockés

### Documentation technique

- Générer les commentaires de code complexe (formules d'équilibrage, logique agents)
- Maintenir le GDD à jour : après chaque sprint, demander à Claude de synthétiser les décisions prises et de mettre à jour les questions ouvertes

---

_Document vivant — à mettre à jour en parallèle du game_design.md_
| Backend | Ruby on Rails 8 | Logique métier, API, rendu serveur |
| Frontend socle | Hotwire (Turbo + Stimulus) | 80% de l'UI — pages, timers, flux serveur |
| Frontend complexe | React (islands) | Carte galaxie, composants très interactifs |
| Carte galaxie | Pixi.js (WebGL) | Rendu performant, zoom/pan, flottes en mouvement |
| Base de données | PostgreSQL | Données de jeu, état des agents, mémoire des factions |
| Jobs asynchrones | Sidekiq | Constructions, déplacements, combats, ticks IA |
| Temps réel | ActionCable + Turbo Streams | Push serveur → client (ressources live, alertes radar) |
| IA produit | API Anthropic | Agents factions, narration, conseiller, support |
| Observabilité LLM | Langfuse | Tracing de tous les appels Anthropic |
| Mobile | Capacitor | Wrapping PWA → app stores (iOS + Android) |
| Déploiement | Docker Compose (dev) + Kamal (prod) | Déploiement Rails-natif sur VPS |

---

_Document vivant — à mettre à jour en parallèle du game_design.md_
