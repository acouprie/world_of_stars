# World of Stars - Implémentation du système d'unités

> Document de synthèse (handoff)
> État au 12 juin 2026 : game design bouclé **+ passe d'équilibrage économique terminée**, trois resolvers du cœur de jeu implémentés et testés.
> Couvre les trois prompts d'implémentation des unités (registre/production, combat, exploration/espionnage).
> ⚠️ **Le §3 décrit ce qui est implémenté ; le §3bis liste les divergences avec la passe économie, à corriger** (prompt dédié : `prompt_correction_implement_units.md`).

---

## 0. Où on en est

- Le **game design est bouclé** pour le périmètre de lancement, **passe économie comprise** (tempo, k=5, coûts de recherche, magnitude d'exploration, calendrier de déblocage v2).
- Les **bâtiments** étaient déjà implémentés ; les **unités** le sont désormais (registre, persistance, production).
- Les **trois resolvers du cœur de jeu** sont implémentés et testés : combat, exploration, espionnage.
- Suite des specs : **414 → 452 → 494**, toutes vertes. Dernier commit du 3/3 : `a68a399`.
- Reste : la **correction d'alignement passe économie** (§3bis), l'**orchestration** (plomberie Rails) et quelques **sujets de design ouverts** (cf. §6).

---

## 1. Documents de référence (sources de vérité)

| Document | Version | Couvre |
| -------- | ------- | ------ |
| `game_design.md` | v1.0+ | hub : vision, économie, progression, factions, **exploration (§7)**, **espionnage (§6)** |
| `combat_reference.md` | v1.1 | combat au sol (source de vérité unique) - **inchangé par la passe économie** |
| `unit_reference.md` | **v0.8** | roster, stats v2.1, **coûts k=5**, production, **calendrier de déblocage v2** |
| `tech_reference.md` | v1.0 → v1.1 (fusion en cours) | arbre techno, checkpoints, coûts |
| `research_costs_v1.md` | v1 | tables de coûts de recherche, checkpoints chiffrés, courbe d'exploration ×1,7 |
| `exploration_magnitude_v1.md` | v1 | mécanismes d'exploration chiffrés (poids, escorte, butin, critique) |
| `building_reference.md` / `buildings.rb` | - | bâtiments (déjà implémentés ; pattern de registre à imiter) |

---

## 2. Décisions de design verrouillées (condensé, à jour de la passe économie)

### Combat (`combat_reference.md`) - inchangé
- Tir agrégé + paliers d'armure, **sans PV**, résolution **par compteurs** (O(types)), ~10 rounds indépendants de la taille.
- Aléa : jitter par tir `[0,85 ; 1,15]` + **swing global `Normal(1 ; σ=0,25)`** par camp et par round (levier d'aléa principal).
- Initiative : INT pondérée par l'ATQ sur les unités **combat? uniquement**, recalculée chaque round ; à égalité, salves simultanées.
- Repli attaquant auto à **55 %** de pertes + **plafond de statu quo à 18 rounds** ; volée d'adieu `clamp(0,5 − Δ/8 ; 0 ; 1,5)`.
- Invariant `DEF_min > ATQ_max × 1,15` (stats de base).
- Bonus de techno : multiplicatif additif `×(1 + r·niveau)`, **r = 0,04**, delta-only.

### Exploration (`game_design.md` §7 + `exploration_magnitude_v1.md`)
- **Trois tirages indépendants** par mission (XP, ressources, pertes), à paliers asymétriques (tables inchangées).
- But premier : **points d'exploration → technologies** (niveaux du joueur : seuils **400 × 1,7^(n−1)**, gains ×1,0292/niveau) ; les ressources sont un bonus net-négatif.
- **Poids de risque par classe** (recon 0,6 / sci 1,0 / combat 1,1 / mule 1,2), communs aux pertes et à la base de butin.
- **Pertes** : `f × (1 − 0,5 × part_escorte) × (1 − 0,02 × niv_Carto) × w(classe)` ; **palier critique (2 %) = ignore tous les modificateurs**.
- **Butin** : `f × Σ coût(u) × w(u)` sur les **unités non-combat uniquement**, plafonné par le transport. Les combattants ne génèrent aucun butin.
- Bases d'XP : Scientifique 60, Sonde 25, Spectre 25, combattants 10, **Mule 0**.
- **Jusqu'à 5 missions d'exploration simultanées** ; durée 20 min + 1 min/unité.
- Cartographie stellaire : +4 %/niv **XP uniquement**, -2 %/niv pertes ordinaires, pas de bonus de butin.

### Espionnage (`game_design.md` §6) - inchangé
- **Contest** : furtivité (Spectre 12, Sonde 3) + techno Renseignement de l'attaquant **contre** la techno Renseignement du défenseur.
- Trois sorties : détection, pertes si détecté, info par catégorie (profondeur gated par le nombre d'unités, complétude `q` dégradée, bruit).
- Reconnaissance uniquement ; le **Spectre** est le seul espion sérieux.

### Économie / progression (passe économie validée)
- **Échelle k = 5** (double ancre WoSG) : Maraudeur 500, Régulier 575, Sentinelle 800, Scientifique 650, Sonde 750, Spectre 675, Mule 550. Armées en centaines puis milliers (le modèle de combat est indépendant de l'effectif).
- Tempo ancré : CC 5 ≈ jour 10-14, CC 10 ≈ jour 50-60. Technos = portée **compte entier** (toutes les planètes).
- Calendrier `military_camp` v2 : **Maraudeur + Sonde au 1**, **Sentinelle + Mule au 2 (sans techno - fenêtre de vulnérabilité abandonnée)**, **Régulier au 3 + Armement**, **Spectre au 5 + Renseignement**, niveaux **4/7/9 = checkpoints des technos militaires**, **6/8/10 = backlog**. **Scientifique = `research_lab` + Cartographie stellaire**.
- Une seule file de production d'unités ; la techno « Chaîne de production » est **sortie du périmètre** (backlog).
- Unité Officier : **non planifiée** (Guerre électronique ne débloque plus rien).

---

## 3. Ce qui est implémenté

### Prompt 1/3 - Registre, persistance, production

**Registre (`app/models/units.rb`)** : module `Units`, calqué sur `Buildings::REGISTRY`. 7 types (Maraudeur, Régulier, Sentinelle, Scientifique, Sonde, Spectre, Mule) avec stats v2.1, coûts, durées de base, flag `combat?`, prérequis `requires` (niveau `military_camp` + technologie). Helpers : `find!`, `cost_for`, `combat?`, `training_time`, `unlocked?`.

**Persistance** : table `planet_units` (planet_id, unit_type, count) + index unique → **effectifs par type et par planète**, jamais d'objet par soldat. Modèle ActiveRecord d'abord `PlanetUnit`, **renommé `Unit`**.

**Production** :
- Producteur unique : `training_camp` ; table `training_queues`.
- `Trainings::InitiateService` : vérifie prérequis et coût, débite les ressources, met en file et planifie le job, à l'enqueue.
- `CompleteTrainingJob` (Sidekiq) : incrémente `planet_units`, broadcast Turbo.
- Durée = `base × 0,95^(training_camp_level − 1)`, coefficient en config.

**UI / câblage** : écran de production (`training_queues#index`) avec avertissement sur les unités non-combattantes, barre de progression, lien depuis la page planète ; contrôleur Turbo Stream, helpers, associations `planet.rb`, routes, i18n fr/en.

### Prompt 2/3 - Moteur de résolution de combat

**`Combats::Resolver`**, resolver **pur** (aucun accès base). **Conforme au design final, aucune correction requise.**

- **Entrées** : `attacker_force`, `defender_force` (compteurs par type), `context` (seed, technos, iris, assault_kind).
- **Sortie** : `Result` { `outcome`, `rounds_log`, `losses`, `xp`, `pillage_capacity` }.
- **Algorithme** (combat_reference §12) : stats effectives `base × (1 + 0,04 × tech)` + bonus DEF Iris si assaut par portail ; feu en **forme fermée** `p_kill = 1 − Φ((DEF/swing − mean)/sd)`, O(types), indépendant de la taille ; **swing `Normal(1 ; 0,25)`** par camp et par round (Box-Muller) ; `army_int` sur les unités **combat? uniquement** (Scientifique exclu malgré ATQ 2) ; ciblage combat → non-combat non-mule → mule ; repli 55 % + volée d'adieu ; plafond 18 rounds. Constantes en config (`sigma`, `jitter`, `round_cap`, `retreat_threshold`, `tech_rate`, `farewell_k`, `ej2`).
- **Bug corrigé** : l'anéantissement total de l'attaquant en un round franchissait le seuil de 55 % et déclenchait à tort `:attacker_retreat` ; le fix vérifie que les deux camps sont en vie avant le check de repli (plus juste que le pseudocode de référence).
- **38 specs** reproduisant les repères de simulation (§13) : rounds ~10 indépendants de la taille, bande pile-ou-face ~0,21, mur Sentinelle pénétrable à ×1,45, miroirs Maraudeur ~3 / Régulier ~10, plafond 18 rounds, delta-only des technos, courbe lisse en asymétrie, exclusion du Scientifique, déterminisme par seed.

### Prompt 3/3 - Exploration et espionnage

**`Explorations::Resolver`** (pur) : trois tirages indépendants à paliers (§7). XP porté par le Scientifique, ressources calées sur le **coût de l'équipe / 3 plafonnées par le transport** (≈ 0,8 × coût des pertes), pertes réduites par l'escorte et par la meilleure survie de la reconnaissance. Tout en config. **→ Mécanismes à aligner sur `exploration_magnitude_v1.md` (cf. §3bis).**

**`Espionnages::Resolver`** (pur) : contest furtivité vs Renseignement (§6). `p_det = D0 × n / furtivité × m_def / m_atq`, pertes si détecté, profondeur gated par le nombre d'unités / `ta ≥ td` / présence d'un Spectre, complétude `q` dégradée par rang, bruit gaussien sur les valeurs révélées. **Conforme.**

**Branchement** : `Units.explore` et `Units.spy` remplacent les stubs et délèguent aux resolvers.

---

## 3bis. Divergences avec la passe économie - corrections à appliquer

Implémenté sur la base des docs pré-passe économie. Prompt de correction : `prompt_correction_implement_units.md`.

| # | Sujet | Implémenté | Attendu |
| - | ----- | ---------- | ------- |
| 1 | Échelle de coûts | k = 1 (Maraudeur 100...) | **k = 5** (Maraudeur 500...) |
| 2 | Sentinelle | camp 5 + Blindage tactique | **camp 2, sans techno** |
| 3 | Mule | camp 2 | camp 2 (inchangé) |
| 4 | Spectre | camp 6 + Guerre électronique | **camp 5 + Renseignement** |
| 5 | Scientifique | research_lab seul | **research_lab + Cartographie stellaire** |
| 6 | Files de production | parallèles via « Chaîne de production » | **file unique** (Chaîne de production = backlog) |
| 7 | Mécanismes d'exploration | coût/3 plafonné transport, escorte/recon qualitatifs | **poids w, escorte 0,5×part, critique sans modificateurs, butin non-combat pondéré, bases d'XP 60/25/25/10/0** |
| 8 | Niveaux d'exploration joueur | (orchestration) | seuils **×1,7**, à déclarer en constantes |
| 9 | Missions simultanées | (orchestration : « une à la fois ») | **5 explorations simultanées** |

---

## 4. Conventions et faits clés (pour une session fraîche)

- Les **resolvers sont purs** (aucun accès base, déterministes par seed) ; c'est l'orchestration qui appliquera leurs résultats en base.
- Le flag **`combat?`** est `true` seulement pour Maraudeur / Régulier / Sentinelle. Le **Scientifique** (ATQ 2) est `combat? = false` : il ne tire pas et n'influence pas l'INT du camp.
- Persistance par **compteurs par type et par planète** (modèle `Unit`), jamais d'objet par soldat.
- Toutes les **constantes de gameplay** (σ, r, seuils, paliers, `k`, poids d'exploration) vivent en **config/registre**, jamais en dur dans la logique.
- **Invariant économique à préserver** : `E[butin exploration] ≤ E[coût des pertes]` pour toute composition (mesuré 0,39-0,83 à k=5), sinon l'exploration redevient une pompe à ressources et court-circuite les mines.
- Code, commentaires, noms, messages de commit : **anglais**.

---

## 5. Stubs / TODOs encore actifs

1. **`User#technology_level` → 0** (jusqu'au système de technologies). Conséquence **après correction du calendrier** : Régulier (Armement), Spectre (Renseignement) et Scientifique (Cartographie stellaire) sont **verrouillés** en l'état ; Maraudeur, Sonde, **Sentinelle et Mule** sont produisibles dès les camps 1-2.
2. **Prérequis `exploration_level` du `research_lab`** → TODO dans `Buildings::InitiateService` (c'est une stat **joueur**, pas un niveau de bâtiment).
3. **Vérifications légères suggérées, non confirmées** : test sur la table de multiplicateurs XP (§11, condition zéro-perte + paliers de ratio) et sur `pillage_capacity` côté combat ; test de propriété garantissant `E[butin] ≤ E[coût des pertes]` côté exploration (à rejouer avec les poids w).

---

## 6. Ce qui reste

### Correction d'alignement (prioritaire, avant l'orchestration)
Appliquer `prompt_correction_implement_units.md` (§3bis).

### Orchestration (plomberie Rails, pas du design)
Déplacement de flotte et timing d'arrivée, application des résultats des resolvers en base (pertes, butin, XP, info d'espionnage), files de mission (**jusqu'à 5 explorations simultanées** ; concurrence des missions d'espionnage : non tranchée), rapports et notifications, et branchement du **débrief narratif IA** sur le rapport structuré. C'est ce qui rend le jeu réellement jouable. Exigences de sécurité au câblage : `docs/audit_11062026.md` §6 (ownership, anti-rejeu, non-fuite des rapports).

### Sujets de design encore ouverts
- **Système de technologies** : prochain chantier d'implémentation (registre, recherche, checkpoints) ; débloque Régulier, Spectre, Scientifique et les gates de bâtiments (Bunker, nucléaire).
- **Colonisation** : comment on acquiert de nouvelles planètes (design : Colonisation 1 + chantier spatial 10, placeholder).
- **IA de faction** : Empire Varek, Confédération Elyrans, Nexhianti (le vrai différenciateur).
- **Couche orbitale / vaisseaux** (post-MVP ; le combat est portail-only au lancement).
- **Alliances** (v2).
- Backlog d'enrichissement (camps 6/8/10, files parallèles, Officier...) : voir `game_design.md`.

---

_Document vivant. À maintenir en parallèle des documents de référence listés au §1._
