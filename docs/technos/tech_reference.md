# World of Stars - Référence des technologies

> Version 1.0 - Document de conception (refonte)
> Complément au `game_design.md`, `combat_reference.md`, `building_reference.md` et `unit_reference.md`
> Statut : structure, roster, réseau de dépendances et modèle de gating **validés**. Valeurs numériques (paliers labo/exploration, `per_level`, coûts) = placeholders, à caler en passe d'équilibrage.

---

## Table des matières

1. [Principes généraux](#1-principes-généraux)
2. [Pacing - checkpoints de laboratoire](#2-pacing--checkpoints-de-laboratoire)
3. [Gating par exploration](#3-gating-par-exploration)
4. [Le réseau de dépendances](#4-le-réseau-de-dépendances)
5. [File de recherche](#5-file-de-recherche)
6. [Coût des technologies](#6-coût-des-technologies)
7. [Roster - périmètre initial](#7-roster--périmètre-initial)
8. [Roster - anticipé](#8-roster--anticipé)
9. [Barème des effets](#9-barème-des-effets)
10. [Déblocages d'unités et de bâtiments](#10-déblocages-dunités-et-de-bâtiments)
11. [Évolutions futures](#11-évolutions-futures)
12. [Correspondance World of Stargate](#12-correspondance-world-of-stargate)
13. [Structure de données](#13-structure-de-données)
14. [Questions ouvertes](#14-questions-ouvertes)

---

## 1. Principes généraux

Les technologies sont recherchées dans le **`research_lab`**. Chaque technologie est **indépendante** et possède **ses propres niveaux** : on améliore plusieurs fois la même technologie pour renforcer son effet.

**La profondeur du système vient du réseau de dépendances, pas de l'empilement de bonus numériques.** Cinq types de liens structurent l'arbre :

- **techno → bâtiment** (ex : Technologie Cristal débloque le Bunker)
- **bâtiment → techno** (ex : le `research_lab` et le `military_camp` jalonnent les niveaux de technos)
- **techno → techno** (ex : Supraconductivité exige Conversion énergétique 3)
- **techno → unité** (ex : Armement débloque le Régulier)
- **exploration → techno** (chaque techno est jalonnée par des paliers d'exploration, cf. §3)

Règles structurantes :

- **Pas de doublons d'effet.** Le modèle de combat agrégé (pas de PV, puissance de feu cumulée) ne porte qu'un nombre limité de leviers distincts (ATQ, DEF, INT, plus quelques mécaniques spéciales). Chaque levier appartient à une seule technologie.
- **Bonus de combat globaux** : les technologies de combat s'appliquent à toutes les unités sans distinction de type. Les bonus ciblés par type sont une évolution future (§11).
- **Pas d'orientation stratégique imposée** : tous les joueurs accèdent au même arbre. Les prérequis créent un ordre de progression naturel, pas des branches mutuellement exclusives.
- L'arbre est découpé en deux périmètres : **initial** (fonctionnalités existantes ou en cours) et **anticipé** (conçu maintenant, implémenté avec la fonctionnalité dont il dépend).

---

## 2. Pacing - checkpoints de laboratoire

> **L'ancienne table `LAB_CAP` (plafond uniforme par niveau de labo) est supprimée.**

Le plafonnement par le laboratoire est désormais **propre à chaque technologie**, sous forme de **checkpoints** :

- Un **palier de labo débloque le niveau 1** de la techno (clé `research_lab` dans `requires`).
- Ensuite, **2 ou 3 checkpoints de labo** conditionnent l'accès à certains niveaux supérieurs (pas un checkpoint par niveau). Format : `LEVEL_PREREQUISITES`, identique à `Buildings::LEVEL_PREREQUISITES`.
- Le « plafond » **émerge du checkpoint le plus haut** : les derniers niveaux d'une techno profonde exigent le labo 10.

Exemple (Armement, 18 niveaux) : labo 1 ouvre le niveau 1 ; les niveaux 7+, 13+ et 17+ exigent respectivement labo 4, 7 et 10 (valeurs placeholders).

> Rappel : le `research_lab` est lui-même plafonné par le `command_center` (labo 1 à CC 2, labo 10 à CC 9, voir `building_reference.md`), et sa **construction exige un petit niveau d'exploration** (`game_design.md` §7). La progression de recherche est donc cadencée par trois rythmes superposés : Centre de Commandement, laboratoire, exploration.

---

## 3. Gating par exploration

L'exploration est le **deuxième axe de gate, quasi universel**. Narrativement : explorer des planètes ramène de la technologie ; la recherche avance avec les données rapportées.

- **Chaque technologie exige un niveau d'exploration pour son niveau 1** (clé `exploration` dans `requires`), et des **paliers d'exploration croissants** à ses checkpoints (`LEVEL_PREREQUISITES`).
- Les **bases** entrent à exploration ~1 ; les niveaux **breakthrough** (hauts niveaux des technos profondes, Régénération cellulaire) culminent à exploration ~8-10.
- **Boucle vertueuse** : Cartographie stellaire entre tôt (exploration 1) et augmente les gains d'exploration, ce qui ouvre le reste de l'arbre.

```
explorer → gagner des niveaux d'exploration → franchir les paliers de recherche
       ↑                                                    │
       └──────────  Cartographie stellaire boost  ←─────────┘
```

### Règle de calibration (gravée)

**La courbe des paliers d'exploration requis doit rester sous la courbe d'XP naturelle d'un joueur qui explore régulièrement.** Un joueur actif (quelques missions par jour, jusqu'à **5 missions simultanées**) ne doit presque jamais buter sur le gate exploration ; un joueur qui ignore l'exploration doit être bloqué net. Le gate est un aiguillage (« explore pour chercher »), pas un péage qui ralentit tout le monde. Les valeurs exactes des paliers sont des **placeholders relatifs**, à caler avec la passe de magnitude d'exploration.

---

## 4. Le réseau de dépendances

Vue d'ensemble des liens (détail par techno aux §7-§8 et §10) :

```
exploration ──► research_lab (construction)
research_lab ──► toutes les technos (déblocage + checkpoints)
military_camp ──► technos militaires (checkpoints niv 4 / 7 / 9)

Technologie Cristal ──► Bunker (bâtiment, dès le niveau 1)
Conversion énergétique ──► Centrale nucléaire (bâtiment)

Forage cristallin 5 ──► Raffinage du thorium
Conversion énergétique 3 ──► Supraconductivité

Armement ──► Régulier (unité)
Cartographie stellaire + research_lab ──► Scientifique (unité)
Renseignement ──► Spectre (unité)
Colonisation ──► Vaisseau de colonie (unité)
Guerre électronique ──► Officier (unité future)
```

**Convention d'implémentation** : un déblocage est toujours déclaré **côté consommateur** (le Bunker porte `requires: { technologie_cristal: 1 }` dans `Buildings::REGISTRY` ; le Régulier porte sa techno requise dans le registre des unités), comme les bâtiments déclarent leurs prérequis de `command_center`. `Technologies::REGISTRY` ne duplique pas ces liens : ce document en est la carte lisible.

---

## 5. File de recherche

- La recherche dispose de sa **propre file**, distincte de la file de construction des bâtiments et de la production d'unités.
- **Une seule recherche à la fois.** Les files de recherche parallèles sont hors périmètre (évolution future, §11).
- Les anciennes technologies de files (`Ingénierie parallèle`, `Chaîne de production`) sont **sorties du périmètre** : risque de déséquilibre (burst, casse la priorisation forcée de la file unique, parallélisme déjà offert par la colonisation). Notées en idées futures (§11).

---

## 6. Coût des technologies

Chaque niveau coûte des ressources (**métal, nourriture, thorium**) et un **temps de recherche** :

- **Coût géométrique** par niveau, **progression lente voulue** : facteur élevé et coûts de base supérieurs à un bâtiment de palier équivalent. Grimper l'arbre est un objectif de long terme.
- **Pas de coût en énergie** pour la recherche.
- **Pas d'entretien** : le bonus est permanent une fois recherché.
- Les **tables de coûts par niveau** seront établies en phase d'équilibrage (Annexe D du `game_design.md`).

---

## 7. Roster - périmètre initial

10 technologies. Effets exprimés en intentions ; valeurs au §9 (placeholders sauf combat).

| Technologie                | Catégorie   | Effet                                           | Niv max | Déblocage (labo / explo) | Cross-dépendance         | Débloque              |
| -------------------------- | ----------- | ----------------------------------------------- | ------- | ------------------------ | ------------------------ | --------------------- |
| **Forage cristallin**      | Production  | + production de métal                           | 18      | labo 1 / explo 1         | -                        | -                     |
| **Hydroponie**             | Production  | + production de nourriture                      | 18      | labo 1 / explo 1         | -                        | -                     |
| **Raffinage du thorium**   | Production  | + production de thorium                         | 15      | labo 2 / explo 2         | Forage cristallin 5      | -                     |
| **Conversion énergétique** | Énergie     | + production d'énergie des centrales            | 15      | labo 1 / explo 1         | -                        | Centrale nucléaire    |
| **Supraconductivité**      | Énergie     | - consommation énergétique des bâtiments        | 13      | labo 3 / explo 3         | Conversion énergétique 3 | -                     |
| **Armement**               | Militaire   | + attaque (toutes unités)                       | 18      | labo 1 / explo 1         | -                        | Régulier              |
| **Blindage tactique**      | Militaire   | + défense (toutes unités)                       | 18      | labo 1 / explo 1         | -                        | -                     |
| **Guerre électronique**    | Militaire   | + intelligence (toutes unités)                  | 15      | labo 2 / explo 2         | -                        | (Officier, futur)     |
| **Cartographie stellaire** | Exploration | + gains XP & ressources d'exploration, - pertes | 10      | labo 1 / explo 1         | -                        | Scientifique (+ labo) |
| **Technologie Cristal**    | Déblocage   | Débloque le **Bunker** (gate pur, pas de bonus) | 1       | labo 1 / explo 1         | -                        | Bunker                |

> **Technologie Cristal** est une techno de **déblocage pur** : 1 niveau, aucun bonus numérique. Le Bunker est gaté **dès son niveau 1** (le gate porte sur la construction, pas sur les niveaux : pas de mur invisible après coup). C'est un choix early conscient : rechercher Cristal tôt pour s'abriter, ou accepter le risque de pillage.

> **Bonus de combat - modèle acté.** Armement, Blindage tactique et Guerre électronique appliquent un bonus **multiplicatif à accumulation additive** : `stat_eff = stat_base × (1 + r·niveau)`. Effet lisse, et **seul le delta de techno entre les camps compte**. **Valeur figée : `r = 0,04`** (au delta maximal, le combat reste ≥ ~3 rounds). Détail et validation : `combat_reference.md` §9.

> **Centrale nucléaire** : gatée par Conversion énergétique (niveau requis placeholder : **4**). Le niveau exact se cale sur le moment où la centrale solaire devient trop chère par ⚡ marginal (crossover solaire/nucléaire, vers CC 5) : le gate ne doit pas retarder un joueur qui touche normalement à l'arbre techno. À valider en passe économie.

---

## 8. Roster - anticipé

Technologies **conçues maintenant**, implémentées quand leur fonctionnalité est prête.

| Technologie                 | Catégorie    | Effet                                                         | Niv max | Déblocage (labo / explo) | Débloque            | Dépend de            |
| --------------------------- | ------------ | ------------------------------------------------------------- | ------- | ------------------------ | ------------------- | -------------------- |
| **Renseignement**           | Espionnage   | +1 palier d'espionnage par niveau (contest `ta`/`td`)         | 10      | labo 2 / explo 2         | **Spectre**         | Feature espionnage   |
| **Colonisation**            | Colonisation | Niv 1 = vaisseau de colonie + 2ᵉ planète · Niv 2 = 3ᵉ planète | 2       | labo 4 / explo 2         | Vaisseau de colonie | Feature colonisation |
| **Régénération cellulaire** | Breakthrough | Ressuscite une fraction des pertes après combat               | 5       | labo 7 / explo 8         | -                   | Combat implémenté    |

> **Renseignement** débloque le **Spectre** (auparavant lié à Guerre électronique) : l'unité d'espionnage arrive avec la techno d'espionnage, cohérence thématique. Aucun prérequis de bâtiment radar (les deux systèmes ne se recouvrent pas : radar = flottes entrantes, Renseignement = espionnage sortant et contre-espionnage).

> **Colonisation** : version simple volontairement (2 niveaux = 2 planètes supplémentaires, max 3 planètes). Une ligne plus riche (vitesse, coût réduit, bonus colonies) est une évolution future.

> **Régénération cellulaire** : effet **post-combat** (pourcentage appliqué après résolution), zéro impact sur l'algorithme de combat validé. C'est la **carotte discrète du haut de l'axe exploration** (explo 8-10). Plafond bas obligatoire (~25 % cumulé). Base : s'applique à toutes les pertes, où que le combat ait eu lieu ; une restriction « planètes propres uniquement » reste une option d'équilibrage (cf. §14).

---

## 9. Barème des effets

Placeholders à valider en passe d'équilibrage, **sauf le combat (figé)**.

| Technologie                                | Modèle                  | Valeur par niveau                                      | Au niveau max                |
| ------------------------------------------ | ----------------------- | ------------------------------------------------------ | ---------------------------- |
| Forage cristallin / Hydroponie / Raffinage | Additif sur production  | **+6 %/niv**                                           | +108 % (niv 18) / +90 % (15) |
| Conversion énergétique                     | Additif sur production  | **+6 %/niv**                                           | +90 % (niv 15)               |
| Supraconductivité                          | Additif sur conso       | **-2 %/niv**                                           | -26 % (niv 13)               |
| Armement / Blindage tactique               | `×(1 + 0,04·niv)` figé  | **r = 0,04**                                           | ×1,72 (niv 18)               |
| Guerre électronique                        | `×(1 + 0,04·niv)` figé  | **r = 0,04**                                           | ×1,60 (niv 15)               |
| Cartographie stellaire                     | Additif sur gains explo | **+4 %/niv** XP & ressources, - pertes (avec plancher) | +40 % (niv 10)               |
| Renseignement                              | Palier entier           | **+1 niveau** `ta`/`td`                                | 10 (niv 10)                  |
| Régénération cellulaire                    | Additif sur pertes      | **+5 %/niv** ressuscités                               | ~25 % (niv 5, plafond bas)   |
| Technologie Cristal                        | Déblocage pur           | -                                                      | -                            |

> **Point de vigilance (passe économie)** : Conversion énergétique (+90 %) cumulée à Supraconductivité (-26 %) risque de rendre la contrainte énergétique triviale en late game, alors que le budget tout-max est déjà soluble par les bâtiments seuls (2 solaires + 1 nucléaire, marge +817 ⚡). Les `per_level` énergétiques devront être calés pour que l'énergie reste une contrainte vivante.
>
> **Répartition exacte de Cartographie stellaire** (part +XP vs +ressources vs -pertes, valeur du plancher) : à définir à la passe magnitude d'exploration.

---

## 10. Déblocages d'unités et de bâtiments

### Roster de départ (military_camp seul)

**Maraudeur, Sentinelle, Sonde, Mule** : offense + défense + recon + transport disponibles dès le début. L'ancienne « fenêtre de vulnérabilité » (offensif avant défensif) est **abandonnée** : avec des factions IA agressives dès l'early game (Varek), priver le nouveau joueur de son unité défensive de base est une friction qui coûte des joueurs. Le calendrier exact par niveau de `military_camp` est **à refaire** dans `unit_reference.md`.

### Unités avancées (military_camp + techno)

| Unité                   | Conditions                                                               |
| ----------------------- | ------------------------------------------------------------------------ |
| **Régulier**            | military_camp (niveau à définir) + **Armement** recherché                |
| **Scientifique**        | **research_lab** construit + **Cartographie stellaire** recherchée       |
| **Spectre**             | military_camp + **Renseignement** recherché (avec la feature espionnage) |
| **Vaisseau de colonie** | **Colonisation** niv 1 (avec la feature colonisation)                    |
| **Officier** (futur)    | **Guerre électronique** (niveau à définir)                               |

> Bootstrap complet : explorer à la **Sonde** (départ) → premiers points d'exploration → construire le **labo** → rechercher **Cartographie stellaire** → débloquer le **Scientifique** (moteur principal d'XP) → l'exploration s'accélère et ouvre le reste de l'arbre.

### Bâtiments gatés par techno

| Bâtiment               | Techno requise                                  |
| ---------------------- | ----------------------------------------------- |
| **Bunker**             | Technologie Cristal niv 1 (dès la construction) |
| **Centrale nucléaire** | Conversion énergétique niv 4 (placeholder)      |

### Checkpoints du military_camp (technos militaires)

Conservé du design précédent : les niveaux **4, 7 et 9** du `military_camp` servent de **checkpoints aux technos militaires** (Armement, Blindage tactique, Guerre électronique), en plus des checkpoints de labo. C'est la valeur des niveaux de camp qui ne débloquent aucune unité.

---

## 11. Évolutions futures

Hors périmètre actuel, notées pour anticipation :

| Idée                                | Note                                                                                           |
| ----------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Ingénierie parallèle**            | +1 file de construction. Sortie du périmètre (burst, casse la priorisation forcée).            |
| **Chaîne de production**            | +1 file de production d'unités. Sortie du périmètre (même raison). Invention originale.        |
| **Unité Officier**                  | Débloquée par Guerre électronique ; INT mène le tempo de l'armée.                              |
| **Étiquettes de paliers**           | Noms originaux pour quelques niveaux jalons d'une techno (cosmétique, i18n). Pas en v1.        |
| **Vitesse de recherche**            | Techno méta réduisant le temps de recherche.                                                   |
| **Capacité de stockage**            | Techno augmentant le stockage (aujourd'hui 100 % bâtiment).                                    |
| **Files de recherche parallèles**   | Plusieurs recherches simultanées.                                                              |
| **Bonus de combat ciblés par type** | Spécialiser les bonus par type d'unité.                                                        |
| **Branche spatiale / vaisseaux**    | Propulsion, réacteurs, armement de vaisseau, hyperespace : attend la définition des vaisseaux. |
| **Technologies exclusives Elyrans** | Déblocage via diplomatie avec la Confédération Elyrans. Narratif pour l'instant.               |

---

## 12. Correspondance World of Stargate

Référence d'inspiration uniquement. Les noms et valeurs WoSG (licence Stargate) sont **abandonnés** au profit de créations originales.

| Nom WoSG (inspiration)                                                   | Technologie World of Stars | Note                                                        |
| ------------------------------------------------------------------------ | -------------------------- | ----------------------------------------------------------- |
| Foreuse Kelownan                                                         | Forage cristallin          | Seule correspondance métal                                  |
| Technologie Cristal                                                      | Technologie Cristal        | Gate du Bunker (pas un bonus de métal)                      |
| Moissonneuse Aschens                                                     | Hydroponie                 |                                                             |
| Extracteur à Naquadah                                                    | Raffinage du thorium       |                                                             |
| -                                                                        | Conversion énergétique     | **Originale** (Maîtrise de l'énergie = techno de vaisseau)  |
| -                                                                        | Supraconductivité          | **Originale** (réduction de consommation)                   |
| P90 / Zat'n'ktel / Lance / Canon                                         | Armement                   | Technos d'arme consolidées en 1 (bonus global)              |
| Paquetage militaire / Tourelle d'attaque mobile                          | Blindage tactique          | Augmentent la défense                                       |
| Grenade à choc / Nish'ta / Manipulateur ADN                              | Guerre électronique        | Réduisent l'INT adverse → bonus d'INT (delta-only)          |
| Sarcophage                                                               | Régénération cellulaire    | Anticipé, breakthrough exploration                          |
| Espionnage                                                               | Renseignement              | 10 niveaux conservés                                        |
| Maîtrise de l'énergie / Technologie Naquadria                            | -                          | Technos de **vaisseaux**, mises de côté (branche vaisseaux) |
| Technologies spatiales (Ions, Plasma, réacteurs, hyperespace, antigrav…) | -                          | Reportées avec la branche vaisseaux                         |
| -                                                                        | (Chaîne de production)     | Invention originale, sortie du périmètre                    |

---

## 13. Structure de données

Conventions identiques à `Buildings::REGISTRY` (`requires`, `LEVEL_PREREQUISITES`, helpers). **`LAB_CAP` est supprimée.** Les déblocages (bâtiments, unités) sont déclarés **côté consommateur** (cf. §4).

```ruby
module Technologies
  # Per-level lookup tables - canonical source of truth for technology effects.
  #
  # Fields per entry:
  #   category    - :energy, :production, :military, :exploration,
  #                 :gate, :espionage, :colonization, :breakthrough
  #   scope       - :initial (build now) | :anticipated (build with its feature)
  #   max_level   - own ceiling (emergent cap = highest checkpoint in LEVEL_PREREQUISITES)
  #   requires    - level 1 unlock prerequisites
  #                 { research_lab:, exploration:, <other_tech>: }
  #   effect      - { type:, per_level: } (PLACEHOLDERS except combat, locked r = 0.04)
  #   levels      - cost table { metal:, food:, thorium:, time: } - TBD (balancing pass)
  #
  # Unlocks (units, buildings) are declared on the consumer side:
  #   Buildings::REGISTRY  -> bunker requires technologie_cristal: 1,
  #                           nuclear_plant requires conversion_energetique: 4
  #   Units registry       -> regulier requires armement: 1, etc.
  REGISTRY = {
    # ─── Initial scope ──────────────────────────────────────────────────────
    forage_cristallin: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :metal_production_bonus, per_level: 0.06 }
    },
    hydroponie: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :food_production_bonus, per_level: 0.06 }
    },
    raffinage_thorium: {
      category: :production, scope: :initial, max_level: 15,
      requires: { research_lab: 2, exploration: 2, forage_cristallin: 5 },
      effect: { type: :thorium_production_bonus, per_level: 0.06 }
    },
    conversion_energetique: {
      category: :energy, scope: :initial, max_level: 15,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :energy_production_bonus, per_level: 0.06 }
    },
    supraconductivite: {
      category: :energy, scope: :initial, max_level: 13,
      requires: { research_lab: 3, exploration: 3, conversion_energetique: 3 },
      effect: { type: :energy_consumption_reduction, per_level: 0.02 }
    },
    armement: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :unit_attack_bonus, per_level: 0.04 } # locked (combat_reference §9)
    },
    blindage_tactique: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :unit_defense_bonus, per_level: 0.04 } # locked
    },
    guerre_electronique: {
      category: :military, scope: :initial, max_level: 15,
      requires: { research_lab: 2, exploration: 2 },
      effect: { type: :unit_intelligence_bonus, per_level: 0.04 } # locked
    },
    cartographie_stellaire: {
      category: :exploration, scope: :initial, max_level: 10,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :exploration_gain_bonus, per_level: 0.04 }
    },
    technologie_cristal: {
      category: :gate, scope: :initial, max_level: 1,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :building_unlock, per_level: nil } # pure gate, no numeric bonus
    },

    # ─── Anticipated ────────────────────────────────────────────────────────
    renseignement: {
      category: :espionage, scope: :anticipated, max_level: 10,
      requires: { research_lab: 2, exploration: 2 },
      effect: { type: :espionage_level, per_level: 1 }
    },
    colonisation: {
      category: :colonization, scope: :anticipated, max_level: 2,
      requires: { research_lab: 4, exploration: 2 },
      effect: { type: :max_planets, per_level: 1 }
    },
    regeneration_cellulaire: {
      category: :breakthrough, scope: :anticipated, max_level: 5,
      requires: { research_lab: 7, exploration: 8 },
      effect: { type: :combat_loss_resurrection, per_level: 0.05 } # hard low cap (~25%)
    }
  }.freeze

  # Lab / exploration / military_camp checkpoints per technology.
  # Threshold format identical to Buildings::LEVEL_PREREQUISITES:
  #   { tech_key => { min_tech_level => { prereq_type => min_level } } }
  # The emergent ceiling of each tech is its highest checkpoint.
  # ALL VALUES ARE PLACEHOLDERS (economy / exploration magnitude pass).
  LEVEL_PREREQUISITES = {
    forage_cristallin: {
      7  => { research_lab: 4,  exploration: 3 },
      13 => { research_lab: 7,  exploration: 5 },
      17 => { research_lab: 10, exploration: 7 }
    },
    hydroponie: {
      7  => { research_lab: 4,  exploration: 3 },
      13 => { research_lab: 7,  exploration: 5 },
      17 => { research_lab: 10, exploration: 7 }
    },
    raffinage_thorium: {
      6  => { research_lab: 5, exploration: 4 },
      11 => { research_lab: 8, exploration: 6 }
    },
    conversion_energetique: {
      6  => { research_lab: 4, exploration: 3 },
      11 => { research_lab: 8, exploration: 6 }
    },
    supraconductivite: {
      6  => { research_lab: 6, exploration: 5 },
      10 => { research_lab: 9, exploration: 7 }
    },
    armement: {
      7  => { research_lab: 4,  military_camp: 4, exploration: 3 },
      13 => { research_lab: 7,  military_camp: 7, exploration: 5 },
      17 => { research_lab: 10, military_camp: 9, exploration: 7 }
    },
    blindage_tactique: {
      7  => { research_lab: 4,  military_camp: 4, exploration: 3 },
      13 => { research_lab: 7,  military_camp: 7, exploration: 5 },
      17 => { research_lab: 10, military_camp: 9, exploration: 7 }
    },
    guerre_electronique: {
      6  => { research_lab: 5, military_camp: 4, exploration: 4 },
      11 => { research_lab: 8, military_camp: 7, exploration: 6 }
    },
    cartographie_stellaire: {
      4 => { research_lab: 3, exploration: 2 },
      8 => { research_lab: 6, exploration: 4 }
    },
    renseignement: {
      4 => { research_lab: 4, exploration: 3 },
      8 => { research_lab: 7, exploration: 5 }
    },
    colonisation: {
      2 => { exploration: 4 }
    },
    regeneration_cellulaire: {
      3 => { exploration: 9 },
      5 => { exploration: 10 }
    }
  }.freeze
end
```

---

## 14. Questions ouvertes

| Sujet                                              | État         | Note                                                                                                |
| -------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------- |
| Valeurs `per_level` (hors combat)                  | À équilibrer | +6 % éco, -2 % supra, +4 % carto, +5 % régén = placeholders                                         |
| Bonus de combat                                    | **Figé**     | `×(1 + r·niv)`, **r = 0,04**, delta-only (`combat_reference.md` §9)                                 |
| Paliers labo / exploration / camp des checkpoints  | À équilibrer | Tous placeholders ; respecter la règle de calibration du §3                                         |
| Tables de coûts de recherche                       | À construire | Coût géométrique métal/nourriture/thorium + temps (Annexe D)                                        |
| Niveau de Conversion énergétique pour la nucléaire | À équilibrer | Placeholder 4 ; caler sur le crossover de coût solaire/nucléaire (vers CC 5)                        |
| Répartition de l'effet Cartographie stellaire      | À définir    | Part +XP vs +ressources vs -pertes, valeur du plancher (passe magnitude exploration)                |
| Portée de Régénération cellulaire                  | À trancher   | Base : toutes les pertes, partout. Option d'équilibrage : restreindre aux planètes propres          |
| Nom « Technologie Cristal »                        | À confirmer  | Risque de confusion avec « Forage cristallin » ; alternative possible : « Structures cristallines » |
| Cross-dépendance Colonisation ← Cartographie       | Proposé      | Lien thématique (cartographier avant de coloniser) ; à valider ou écarter                           |
| Contrainte énergétique en late game                | À surveiller | Conversion + Supra cumulées risquent de trivialiser l'énergie (cf. §9)                              |
| Calendrier military_camp (roster de départ)        | À refaire    | Maraudeur, Sentinelle, Sonde, Mule au départ ; niveaux exacts dans `unit_reference.md`              |

---

_Document vivant v1.0 - à mettre à jour au fil du développement._
