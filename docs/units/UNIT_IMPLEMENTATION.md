# World of Stars — Implémentation du système d'unités

> Document de synthèse (handoff)
> État au 12 juin 2026 : game design bouclé, trois resolvers du cœur de jeu implémentés et testés.
> Couvre les trois prompts d'implémentation des unités (registre/production, combat, exploration/espionnage).

---

## 0. Où on en est

- Le **game design est bouclé** pour le périmètre de lancement.
- Les **bâtiments** étaient déjà implémentés ; les **unités** le sont désormais (registre, persistance, production).
- Les **trois resolvers du cœur de jeu** sont implémentés et testés : combat, exploration, espionnage.
- Suite des specs : **414 → 452 → 494**, toutes vertes. Dernier commit du 3/3 : `a68a399`.
- Reste : l'**orchestration** (plomberie Rails) et quelques **sujets de design ouverts** (cf. §6).

---

## 1. Documents de référence (sources de vérité)

| Document | Version | Couvre |
| -------- | ------- | ------ |
| `game_design.md` | v1.0 | hub : vision, économie, progression, factions, **exploration (§7)**, **espionnage (§6)** |
| `combat_reference.md` | v1.1 | combat au sol (source de vérité unique) |
| `unit_reference.md` | v0.7 | roster, stats v2.1, coûts, production, calendrier de déblocage |
| `tech_reference.md` | v0.3 | arbre techno, pacing, coûts, bonus de combat |
| `building_reference.md` / `buildings.rb` | — | bâtiments (déjà implémentés ; pattern de registre à imiter) |

---

## 2. Décisions de design verrouillées (condensé)

### Combat (`combat_reference.md`)
- Tir agrégé + paliers d'armure, **sans PV**, résolution **par compteurs** (O(types)), ~10 rounds indépendants de la taille.
- Aléa : jitter par tir `[0,85 ; 1,15]` + **swing global `Normal(1 ; σ=0,25)`** par camp et par round (levier d'aléa principal).
- Initiative : INT pondérée par l'ATQ sur les unités **combat? uniquement**, recalculée chaque round ; à égalité, salves simultanées.
- Repli attaquant auto à **55 %** de pertes + **plafond de statu quo à 18 rounds** ; volée d'adieu `clamp(0,5 − Δ/8 ; 0 ; 1,5)`.
- Invariant `DEF_min > ATQ_max × 1,15` (stats de base).
- Bonus de techno : multiplicatif additif `×(1 + r·niveau)`, **r = 0,04**, delta-only.

### Exploration (`game_design.md` §7)
- **Trois tirages indépendants** par mission (XP, ressources, pertes), à paliers asymétriques.
- But premier : **points d'exploration → technologies** ; les ressources sont un bonus.
- Butin calé sur le **coût de l'équipe** (≈ 0,8 × coût des pertes), plafonné par le transport → neutre-à-négatif **quelle que soit la composition**.
- Toutes les unités risquent des pertes (recon = risque réduit), critique ~2 %, **pas de plancher PvE**.

### Espionnage (`game_design.md` §6)
- **Contest** : furtivité (Spectre 12, Sonde 3) + techno Renseignement de l'attaquant **contre** la techno Renseignement du défenseur.
- Trois sorties : détection, pertes si détecté, info par catégorie (profondeur gated par le nombre d'unités, complétude `q` dégradée, bruit).
- Reconnaissance uniquement ; le **Spectre** est le seul espion sérieux.

### Économie / progression
- **Tempo `k = 1`** (table de coûts telle quelle, armées en milliers).
- Sentinelle réalignée à **×1,60** (coût = puissance).
- **Technos lentes** (objectif long terme), gating par niveaux d'exploration.
- Calendrier `military_camp` : **Maraudeur + Sonde au 1**, Mule au 2, **Régulier au 3 + Armement**, **Sentinelle au 5 + Blindage tactique**, **Spectre au 6 + Guerre électronique**. **Scientifique via le `research_lab`** (lui-même gaté par un petit niveau d'exploration). Inversion **techno → unité** en place.
- **Point d'attention** : les niveaux `military_camp` **4** et **7-10** ne débloquent aucune unité.

---

## 3. Ce qui est implémenté

### Prompt 1/3 — Registre, persistance, production

**Registre (`app/models/units.rb`)** : module `Units`, calqué sur `Buildings::REGISTRY`. 7 types (Maraudeur, Régulier, Sentinelle, Scientifique, Sonde, Spectre, Mule) avec stats v2.1, coûts, durées de base, flag `combat?`, prérequis `requires` (niveau `military_camp` + technologie). Helpers : `find!`, `cost_for`, `combat?`, `training_time`, `unlocked?`.

**Persistance** : table `planet_units` (planet_id, unit_type, count) + index unique → **effectifs par type et par planète**, jamais d'objet par soldat. Modèle ActiveRecord d'abord `PlanetUnit`, **renommé `Unit`**.

**Production** :
- Producteur unique : `training_camp` ; table `training_queues` (1 file par défaut, parallèles via la techno Chaîne de production).
- `Trainings::InitiateService` : vérifie prérequis et coût, débite les ressources, met en file et planifie le job, à l'enqueue.
- `CompleteTrainingJob` (Sidekiq) : incrémente `planet_units`, broadcast Turbo.
- Durée = `base × 0,95^(training_camp_level − 1)`, coefficient en config.

**UI / câblage** : écran de production (`training_queues#index`) avec avertissement sur les unités non-combattantes, barre de progression, lien depuis la page planète ; contrôleur Turbo Stream, helpers, associations `planet.rb`, routes, i18n fr/en.

### Prompt 2/3 — Moteur de résolution de combat

**`Combats::Resolver`**, resolver **pur** (aucun accès base).

- **Entrées** : `attacker_force`, `defender_force` (compteurs par type), `context` (seed, technos, iris, assault_kind).
- **Sortie** : `Result` { `outcome`, `rounds_log`, `losses`, `xp`, `pillage_capacity` }.
- **Algorithme** (combat_reference §12) : stats effectives `base × (1 + 0,04 × tech)` + bonus DEF Iris si assaut par portail ; feu en **forme fermée** `p_kill = 1 − Φ((DEF/swing − mean)/sd)`, O(types), indépendant de la taille ; **swing `Normal(1 ; 0,25)`** par camp et par round (Box-Muller) ; `army_int` sur les unités **combat? uniquement** (Scientifique exclu malgré ATQ 2) ; ciblage combat → non-combat non-mule → mule ; repli 55 % + volée d'adieu ; plafond 18 rounds. Constantes en config (`sigma`, `jitter`, `round_cap`, `retreat_threshold`, `tech_rate`, `farewell_k`, `ej2`).
- **Bug corrigé** : l'anéantissement total de l'attaquant en un round franchissait le seuil de 55 % et déclenchait à tort `:attacker_retreat` ; le fix vérifie que les deux camps sont en vie avant le check de repli (plus juste que le pseudocode de référence).
- **38 specs** reproduisant les repères de simulation (§13) : rounds ~10 indépendants de la taille, bande pile-ou-face ~0,21, mur Sentinelle pénétrable à ×1,45, miroirs Maraudeur ~3 / Régulier ~10, plafond 18 rounds, delta-only des technos, courbe lisse en asymétrie, exclusion du Scientifique, déterminisme par seed.

### Prompt 3/3 — Exploration et espionnage

**`Explorations::Resolver`** (pur) : trois tirages indépendants à paliers (§7). XP porté par le Scientifique, ressources calées sur le **coût de l'équipe / 3 plafonnées par le transport** (≈ 0,8 × coût des pertes), pertes réduites par l'escorte et par la meilleure survie de la reconnaissance. Tout en config.

**`Espionnages::Resolver`** (pur) : contest furtivité vs Renseignement (§6). `p_det = D0 × n / furtivité × m_def / m_atq`, pertes si détecté, profondeur gated par le nombre d'unités / `ta ≥ td` / présence d'un Spectre, complétude `q` dégradée par rang, bruit gaussien sur les valeurs révélées.

**Branchement** : `Units.explore` et `Units.spy` remplacent les stubs et délèguent aux resolvers.

---

## 4. Conventions et faits clés (pour une session fraîche)

- Les **resolvers sont purs** (aucun accès base, déterministes par seed) ; c'est l'orchestration qui appliquera leurs résultats en base.
- Le flag **`combat?`** est `true` seulement pour Maraudeur / Régulier / Sentinelle. Le **Scientifique** (ATQ 2) est `combat? = false` : il ne tire pas et n'influence pas l'INT du camp.
- Persistance par **compteurs par type et par planète** (modèle `Unit`), jamais d'objet par soldat.
- Toutes les **constantes de gameplay** (σ, r, seuils, paliers, `k`) vivent en **config/registre**, jamais en dur dans la logique.
- **Invariant économique à préserver** : `E[butin exploration] ≤ E[coût des pertes]`, sinon l'exploration redevient une pompe à ressources et court-circuite les mines.
- Code, commentaires, noms, messages de commit : **anglais**.

---

## 5. Stubs / TODOs encore actifs

1. **`User#technology_level` → 0** (jusqu'au système de technologies). Conséquence : les unités tech-gatées (Régulier, Sentinelle, Spectre) sont **verrouillées** en l'état ; seuls Maraudeur, Sonde, Mule et Scientifique (via labo) sont produisibles.
2. **Prérequis `exploration_level` du `research_lab`** → TODO dans `Buildings::InitiateService` (c'est une stat **joueur**, pas un niveau de bâtiment).
3. **Vérifications légères suggérées, non confirmées** : test sur la table de multiplicateurs XP (§11, condition zéro-perte + paliers de ratio) et sur `pillage_capacity` côté combat ; test de propriété garantissant `E[butin] ≤ E[coût des pertes]` côté exploration.

---

## 6. Ce qui reste

### Orchestration (plomberie Rails, pas du design)
Déplacement de flotte et timing d'arrivée, application des résultats des resolvers en base (pertes, butin, XP, info d'espionnage), files de mission (une exploration ou un espionnage à la fois), rapports et notifications, et branchement du **débrief narratif IA** sur le rapport structuré. C'est ce qui rend le jeu réellement jouable.

### Sujets de design encore ouverts
- **Colonisation** : comment on acquiert de nouvelles planètes.
- **IA de faction** : Empire Varek, Confédération Elyrans, Nexhianti (le vrai différenciateur).
- **Valeur des niveaux `military_camp` 4 et 7-10**.
- **Couche orbitale / vaisseaux** (post-MVP ; le combat est portail-only au lancement).
- **Alliances** (v2).

---

_Document vivant. À maintenir en parallèle des documents de référence listés au §1._
