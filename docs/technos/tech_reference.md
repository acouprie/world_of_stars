# World of Stars - Référence des technologies

> Version 1.1 - Document de conception
> Complément au `game_design.md`, `combat_reference.md`, `building_reference.md` et `unit_reference.md`
> Statut : structure, roster, réseau de dépendances, checkpoints et barème des effets **calibrés v1 (passe économie)**. Tables de coûts par niveau : voir Annexe D du `game_design.md`.

---

## Table des matières

1. [Principes généraux](#1-principes-généraux)
2. [Pacing - checkpoints de laboratoire](#2-pacing--checkpoints-de-laboratoire)
3. [Gating par exploration](#3-gating-par-exploration)
4. [Le réseau de dépendances](#4-le-réseau-de-dépendances)
5. [File de recherche](#5-file-de-recherche)
6. [Coût des technologies](#6-coût-des-technologies)
7. [Roster - périmètre initial](#7-roster---périmètre-initial)
8. [Roster - anticipé](#8-roster---anticipé)
9. [Barème des effets](#9-barème-des-effets)
10. [Déblocages d'unités et de bâtiments](#10-déblocages-dunités-et-de-bâtiments)
11. [Backlog d'enrichissement](#11-backlog-denrichissement)
12. [Correspondance World of Stargate](#12-correspondance-world-of-stargate)
13. [Structure de données](#13-structure-de-données)
14. [Questions ouvertes](#14-questions-ouvertes)

---

## 1. Principes généraux

Les technologies sont recherchées dans le **`research_lab`**. Chaque technologie est **indépendante** et possède **ses propres niveaux** : on améliore plusieurs fois la même technologie pour renforcer son effet.

**La profondeur du système vient du réseau de dépendances, pas de l'empilement de bonus numériques.** Cinq types de liens structurent l'arbre :

- **techno → bâtiment** (ex : Technologie Cristal débloque le Bunker)
- **bâtiment → techno** (ex : le `research_lab` et le `military_camp` jalonnent les niveaux de technos)
- **techno → techno** (ex : Raffinage du thorium exige Forage cristallin 5)
- **techno → unité** (ex : Armement débloque le Régulier)
- **exploration → techno** (chaque techno est jalonnée par des paliers d'exploration, cf. §3)

Règles structurantes :

- **Pas de doublons d'effet.** Le modèle de combat agrégé (pas de PV, puissance de feu cumulée) ne porte qu'un nombre limité de leviers distincts (ATQ, DEF, INT, plus quelques mécaniques spéciales). Chaque levier appartient à une seule technologie.
- **Bonus de combat globaux** : les technologies de combat s'appliquent à toutes les unités sans distinction de type. Les bonus ciblés par type sont dans le backlog (§11).
- **Pas d'orientation stratégique imposée** : tous les joueurs accèdent au même arbre. Les prérequis créent un ordre de progression naturel, pas des branches mutuellement exclusives.
- L'arbre est découpé en deux périmètres : **initial** (fonctionnalités existantes ou en cours) et **anticipé** (conçu maintenant, implémenté avec la fonctionnalité dont il dépend).

---

## 2. Pacing - checkpoints de laboratoire

> **L'ancienne table `LAB_CAP` (plafond uniforme par niveau de labo) est supprimée.**

Le plafonnement par le laboratoire est désormais **propre à chaque technologie**, sous forme de **checkpoints** :

- Un **palier de labo débloque le niveau 1** de la techno (clé `research_lab` dans `requires`).
- Ensuite, **2 ou 3 checkpoints de labo** conditionnent l'accès à certains niveaux supérieurs (pas un checkpoint par niveau). Format : `LEVEL_PREREQUISITES`, identique à `Buildings::LEVEL_PREREQUISITES`.
- Le « plafond » **émerge du checkpoint le plus haut** : les derniers niveaux d'une techno profonde exigent le labo 10.

Exemple (Armement, 18 niveaux) : labo 1 ouvre le niveau 1 ; les niveaux 7+, 13+ et 17+ exigent respectivement labo 4, 7 et 10.

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

**La courbe des paliers d'exploration requis doit rester sous la courbe d'XP naturelle d'un joueur qui explore régulièrement.** Un joueur actif (quelques missions par jour, jusqu'à **5 missions simultanées**) ne doit presque jamais buter sur le gate exploration ; un joueur qui ignore l'exploration doit être bloqué net. Le gate est un aiguillage (« explore pour chercher »), pas un péage qui ralentit tout le monde.

> Courbe d'exploration retenue : **paliers ×1,7/niveau** (niveau 1 = 1 000 XP cumulés). Voir `research_costs_v1.md` §3 pour la justification complète.

---

## 4. Le réseau de dépendances

Vue d'ensemble des liens (détail par techno aux §7-§8 et §10) :

```
exploration ──► research_lab (construction)
research_lab ──► toutes les technos (déblocage + checkpoints)
military_camp ──► technos militaires (checkpoints niv 4 / 7 / 9)

Technologie Cristal ──► Bunker (bâtiment, dès le niveau 1)
Conversion énergétique ──► Centrale nucléaire (bâtiment, niv 4)

Forage cristallin 5 ──► Raffinage du thorium

Armement ──► Régulier (unité)
Cartographie stellaire + research_lab ──► Scientifique (unité)
Renseignement ──► Spectre (unité)
Colonisation ──► Vaisseau de colonie (unité, + chantier spatial 10 placeholder)
```

**Convention d'implémentation** : un déblocage est toujours déclaré **côté consommateur** (le Bunker porte `requires: { technologie_cristal: 1 }` dans `Buildings::REGISTRY` ; le Régulier porte sa techno requise dans le registre des unités), comme les bâtiments déclarent leurs prérequis de `command_center`. `Technologies::REGISTRY` ne duplique pas ces liens : ce document en est la carte lisible.

---

## 5. File de recherche

- La recherche dispose de sa **propre file**, distincte de la file de construction des bâtiments et de la production d'unités.
- **Une seule recherche à la fois.** Les files de recherche parallèles sont dans le backlog (§11).
- Les anciennes technologies de files (`Ingénierie parallèle`, `Chaîne de production`) sont **sorties du périmètre** : risque de déséquilibre (burst, casse la priorisation forcée de la file unique, parallélisme déjà offert par la colonisation). Notées en backlog (§11).

---

## 6. Coût des technologies

Chaque niveau coûte des ressources (**métal, nourriture, thorium**) et un **temps de recherche** :

- **Coût géométrique** par niveau, **progression lente voulue** : facteur élevé et coûts de base supérieurs à un bâtiment de palier équivalent. Grimper l'arbre est un objectif de long terme.
- **Portée : compte entier** — une technologie s'applique à toutes les planètes du joueur. Les hauts niveaux ont un mauvais payback sur 1 planète mais rentrent dans la fenêtre cible (72-168 h) avec 2-3 planètes colonisées.
- **Pas de coût en énergie** pour la recherche.
- **Pas d'entretien** : le bonus est permanent une fois recherché.
- Les tables de coûts par niveau sont dans l'Annexe D du `game_design.md` (issues de `research_costs_v1.md`).

---

## 7. Roster - périmètre initial

9 technologies (Supraconductivité retirée — voir §11).

| Technologie                | Catégorie   | Effet                                           | Niv max | Déblocage (labo / explo) | Cross-dépendance    | Débloque              |
| -------------------------- | ----------- | ----------------------------------------------- | ------- | ------------------------ | ------------------- | --------------------- |
| **Forage cristallin**      | Production  | + production de métal                           | 18      | labo 1 / explo 1         | -                   | -                     |
| **Hydroponie**             | Production  | + production de nourriture                      | 18      | labo 1 / explo 1         | -                   | -                     |
| **Raffinage du thorium**   | Production  | + production de thorium                         | 15      | labo 2 / explo 2         | Forage cristallin 5 | -                     |
| **Conversion énergétique** | Énergie     | + production de la **centrale solaire**         | 10      | labo 1 / explo 1         | -                   | Centrale nucléaire    |
| **Armement**               | Militaire   | + attaque (toutes unités)                       | 18      | labo 1 / explo 1         | -                   | Régulier              |
| **Blindage tactique**      | Militaire   | + défense (toutes unités)                       | 18      | labo 1 / explo 1         | -                   | -                     |
| **Guerre électronique**    | Militaire   | + intelligence (toutes unités)                  | 15      | labo 2 / explo 2         | -                   | -                     |
| **Cartographie stellaire** | Exploration | + gains XP d'exploration et - pertes            | 10      | labo 1 / explo 1         | -                   | Scientifique (+ labo) |
| **Technologie Cristal**    | Déblocage   | Débloque le **Bunker** (gate pur, pas de bonus) | 1       | labo 1 / explo 1         | -                   | Bunker                |

> **Technologie Cristal** est une techno de **déblocage pur** : 1 niveau, aucun bonus numérique. Le Bunker est gaté **dès son niveau 1** (le gate porte sur la construction). C'est un choix early conscient : rechercher Cristal tôt pour s'abriter, ou accepter le risque de pillage.

> **Conversion énergétique** : bonus sur la **production de la centrale solaire uniquement** (+4 %/niv, 10 niveaux max). Au max : +276 ⚡ late (marge énergétique +126 → +402 avec solaire 13 + nucléaire 10). La contrainte énergétique est maintenue par design. Gate de la centrale nucléaire : **Conversion énergétique niveau 4**.

> **Bonus de combat - modèle acté.** Formule multiplicative `×(1 + r·niv)`, r = 0,04, delta-only. Voir `combat_reference.md` §9.

---

## 8. Roster - anticipé

Technologies conçues maintenant, implémentées avec la fonctionnalité dont elles dépendent.

| Technologie                 | Catégorie    | Effet                               | Niv max | Conditions       |
| --------------------------- | ------------ | ----------------------------------- | ------- | ---------------- |
| **Renseignement**           | Espionnage   | + niveau d'espionnage effectif      | 10      | labo 2 / explo 2 |
| **Colonisation**            | Colonisation | + 1 planète colonisable par niveau  | 2       | labo 4 / explo 2 |
| **Régénération cellulaire** | Breakthrough | % des pertes de combat ressuscitées | 5       | labo 7 / explo 8 |

> **Colonisation** : le Vaisseau de colonie exige Colonisation niv 1 + chantier spatial niveau 10 (placeholder ; niveau exact à caler avec la branche vaisseaux). La colonisation est le relais de progression late game (~jour 25-40).

> **Régénération cellulaire** : effet post-combat (appliqué après résolution, zéro impact sur l'algorithme de combat validé). Plafond bas obligatoire (~25 % cumulé). Portée de base : toutes les pertes, où que le combat ait eu lieu ; restriction « planètes propres uniquement » reste une option d'équilibrage (cf. §14).

---

## 9. Barème des effets

Valeurs calibrées v1 (passe économie), **sauf indication contraire**.

| Technologie                                | Modèle                    | Valeur par niveau                                                             | Au niveau max                    |
| ------------------------------------------ | ------------------------- | ----------------------------------------------------------------------------- | -------------------------------- |
| Forage cristallin / Hydroponie / Raffinage | Additif sur production    | **+6 %/niv**                                                                  | +108 % (niv 18) / +90 % (15)     |
| Conversion énergétique                     | Additif sur prod. solaire | **+4 %/niv**                                                                  | +40 % (niv 10) = +276 ⚡         |
| Armement / Blindage tactique               | `×(1 + 0,04·niv)` figé    | **r = 0,04**                                                                  | ×1,72 (niv 18)                   |
| Guerre électronique                        | `×(1 + 0,04·niv)` figé    | **r = 0,04**                                                                  | ×1,60 (niv 15)                   |
| Cartographie stellaire                     | Additif sur XP explo      | **+4 %/niv XP, -2 %/niv pertes** (hors palier critique), **zéro bonus butin** | +40 % XP / -20 % pertes (niv 10) |
| Renseignement                              | Palier entier             | **+1 niveau** espionnage effectif                                             | 10 (niv 10)                      |
| Régénération cellulaire                    | Additif sur pertes        | **+5 %/niv** ressuscités                                                      | ~25 % (niv 5, plafond bas)       |
| Technologie Cristal                        | Déblocage pur             | -                                                                             | -                                |

> Note : la contrainte énergétique late est **maintenue par design** — Conversion énergétique seule porte la marge de +126 à +402 ⚡ max, sans trivialiser le budget (Supraconductivité retirée pour cette raison).

---

## 10. Déblocages d'unités et de bâtiments

### Roster de départ (military_camp seul)

**Maraudeur, Sentinelle, Sonde, Mule** : offense + défense + recon + transport disponibles dès le début. Avec des factions IA agressives dès l'early game (Varek), priver le nouveau joueur de son unité défensive de base est une friction injustifiée. Le calendrier exact par niveau de `military_camp` est dans `unit_reference.md`.

### Unités avancées (military_camp + techno)

| Unité                   | Conditions                                                                 |
| ----------------------- | -------------------------------------------------------------------------- |
| **Régulier**            | military_camp (niveau à définir) + **Armement** recherché                  |
| **Scientifique**        | **research_lab** construit + **Cartographie stellaire** recherchée         |
| **Spectre**             | military_camp niv 5 + **Renseignement** niv 1 (avec la feature espionnage) |
| **Vaisseau de colonie** | **Colonisation** niv 1 + chantier spatial niv 10 (placeholder)             |

> Bootstrap complet : explorer à la **Sonde** (départ) → premiers points d'exploration → construire le **labo** → rechercher **Cartographie stellaire** → débloquer le **Scientifique** (moteur principal d'XP) → l'exploration s'accélère et ouvre le reste de l'arbre.

### Bâtiments gatés par techno

| Bâtiment               | Techno requise                                  |
| ---------------------- | ----------------------------------------------- |
| **Bunker**             | Technologie Cristal niv 1 (dès la construction) |
| **Centrale nucléaire** | Conversion énergétique niv 4                    |

### Checkpoints du military_camp (technos militaires)

Les niveaux **4, 7 et 9** du `military_camp` servent de checkpoints aux technos militaires (Armement, Blindage tactique, Guerre électronique), en plus des checkpoints de labo. C'est la valeur principale des niveaux de camp qui ne débloquent aucune unité.

---

## 11. Backlog d'enrichissement

Hors périmètre actuel. À réouvrir si le jeu en a besoin après les phases de test.

| Idée                                           | Note                                                                                                                                   |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Supraconductivité**                          | Retirée : doublon d'effet avec Conversion énergétique. Candidate à réintroduction si la contrainte énergétique late devient trop dure. |
| **Officier**                                   | Non planifiée. Débloquée par Guerre électronique (INT mène le tempo de l'armée). Rétrogradée de « future » à « non planifiée ».        |
| **military_camp niveaux 6, 8, 10**             | Niveaux sans déblocage ni checkpoint actuellement ; candidats à des bonus de garnison ou de formation.                                 |
| **Ingénierie parallèle**                       | +1 file de construction. Sortie du périmètre (burst, casse la priorisation forcée).                                                    |
| **Chaîne de production**                       | +1 file de production d'unités. Sortie du périmètre (même raison). Invention originale.                                                |
| **Étiquettes de paliers**                      | Noms originaux pour quelques niveaux jalons d'une techno (cosmétique, i18n). Pas en v1.                                                |
| **Vitesse de recherche**                       | Techno méta réduisant le temps de recherche.                                                                                           |
| **Capacité de stockage**                       | Techno augmentant le stockage (aujourd'hui 100 % bâtiment).                                                                            |
| **Files de recherche parallèles**              | Plusieurs recherches simultanées.                                                                                                      |
| **Bonus de combat ciblés par type**            | Spécialiser les bonus par type d'unité.                                                                                                |
| **Ligne Colonisation enrichie**                | Vitesse, coût réduit, bonus colonies.                                                                                                  |
| **Cooldown d'exploration par planète**         | Fréquence de lancement plafonnée.                                                                                                      |
| **Branche spatiale / vaisseaux**               | Propulsion, réacteurs, armement de vaisseau, hyperespace : attend la définition des vaisseaux.                                         |
| **Technologies exclusives Elyrans**            | Déblocage via diplomatie avec la Confédération Elyrans. Narratif pour l'instant.                                                       |
| **Régénération cellulaire — planètes propres** | Restreindre l'effet aux combats défensifs sur ses propres planètes reste une option d'équilibrage.                                     |

---

## 12. Correspondance World of Stargate

Référence d'inspiration uniquement. Les noms et valeurs WoSG (licence Stargate) sont **abandonnés** au profit de créations originales.

| Nom WoSG (inspiration)                                                   | Technologie World of Stars | Note                                                        |
| ------------------------------------------------------------------------ | -------------------------- | ----------------------------------------------------------- |
| Foreuse Kelownan                                                         | Forage cristallin          | Seule correspondance métal                                  |
| Technologie Cristal                                                      | Technologie Cristal        | Gate du Bunker (pas un bonus de métal)                      |
| Moissonneuse Aschens                                                     | Hydroponie                 |                                                             |
| Extracteur à Naquadah                                                    | Raffinage du thorium       |                                                             |
| -                                                                        | Conversion énergétique     | **Originale** (bonus production solaire)                    |
| P90 / Zat'n'ktel / Lance / Canon                                         | Armement                   | Technos d'arme consolidées en 1 (bonus global)              |
| Paquetage militaire / Tourelle d'attaque mobile                          | Blindage tactique          | Augmentent la défense                                       |
| Grenade à choc / Nish'ta / Manipulateur ADN                              | Guerre électronique        | Réduisent l'INT adverse → bonus d'INT (delta-only)          |
| Sarcophage                                                               | Régénération cellulaire    | Anticipé, breakthrough exploration                          |
| Espionnage                                                               | Renseignement              | 10 niveaux conservés                                        |
| Maîtrise de l'énergie / Technologie Naquadria                            | -                          | Technos de **vaisseaux**, mises de côté (branche vaisseaux) |
| Technologies spatiales (Ions, Plasma, réacteurs, hyperespace, antigrav…) | -                          | Reportées avec la branche vaisseaux                         |
| -                                                                        | (Supraconductivité)        | Retirée du roster — voir backlog §11                        |
| -                                                                        | (Chaîne de production)     | Sortie du périmètre — voir backlog §11                      |

---

## 13. Structure de données

> **Implémenté.** Source de vérité : `app/models/technologies.rb`. Voir `TECHNO_IMPLEMENTATION.md` pour les détails d'architecture (schéma BDD, services, job, routes).

Conventions identiques à `Buildings::REGISTRY` (`requires`, `LEVEL_PREREQUISITES`, helpers). **`LAB_CAP` est supprimée.** Les déblocages (bâtiments, unités) sont déclarés **côté consommateur** (cf. §4).

Chaque entrée `REGISTRY` comprend les champs `category`, `scope`, `max_level`, `requires`, `effect` **et un tableau `levels`** contenant la table de coûts `{ metal:, food:, thorium:, time: }` pour chaque niveau — tables complètes dans `research_costs_v1.md` et dans le code.

```ruby
module Technologies
  # Fields per entry:
  #   category    - :energy, :production, :military, :exploration,
  #                 :gate, :espionage, :colonization, :breakthrough
  #   scope       - :initial (build now) | :anticipated (build with its feature)
  #   max_level   - own ceiling (emergent cap = highest checkpoint in LEVEL_PREREQUISITES)
  #   requires    - level 1 unlock prerequisites
  #                 { research_lab:, exploration:, <other_tech>: }
  #   effect      - { type:, per_level: } — calibrated v1 (economy pass),
  #                 except combat (locked r = 0.04, see combat_reference §9)
  #   levels      - cost table array: [{ metal:, food:, thorium:, time: }, ...]
  #                 — full tables in research_costs_v1.md
  #
  # Unlocks (units, buildings) are declared on the consumer side:
  #   Buildings::REGISTRY  -> bunker requires technologie_cristal: 1
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
      category: :energy, scope: :initial, max_level: 10,
      requires: { research_lab: 1, exploration: 1 },
      # Bonus on solar_station production only (+4%/level).
      # Unlocks nuclear_plant construction at level 4 (declared in Buildings::REGISTRY).
      effect: { type: :solar_production_bonus, per_level: 0.04 }
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
      # +4%/level on exploration XP gained, -2%/level on losses (outside critical tier).
      # Zero bonus on loot.
      effect: { type: :exploration_xp_bonus, per_level: 0.04 }
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
  # Calibrated v1 (economy pass) - see game_design.md Annexe D.
  LEVEL_PREREQUISITES = {
    forage_cristallin: {
      7  => { research_lab: 4, exploration: 4 },
      13 => { research_lab: 7, exploration: 6 },
      17 => { research_lab: 10, exploration: 8 }
    },
    hydroponie: {
      7  => { research_lab: 4, exploration: 4 },
      13 => { research_lab: 7, exploration: 6 },
      17 => { research_lab: 10, exploration: 8 }
    },
    raffinage_thorium: {
      6  => { research_lab: 5, exploration: 4 },
      11 => { research_lab: 8, exploration: 6 }
    },
    conversion_energetique: {
      6  => { research_lab: 4, exploration: 3 }
    },
    armement: {
      7  => { research_lab: 4, military_camp: 4, exploration: 4 },
      13 => { research_lab: 7, military_camp: 7, exploration: 6 },
      17 => { research_lab: 10, military_camp: 9, exploration: 8 }
    },
    blindage_tactique: {
      7  => { research_lab: 4, military_camp: 4, exploration: 4 },
      13 => { research_lab: 7, military_camp: 7, exploration: 6 },
      17 => { research_lab: 10, military_camp: 9, exploration: 8 }
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

| Sujet                                        | État        | Note                                                                                                |
| -------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------- |
| Portée de Régénération cellulaire            | À trancher  | Base : toutes les pertes, partout. Option d'équilibrage : restreindre aux planètes propres (§11)    |
| Nom « Technologie Cristal »                  | À confirmer | Risque de confusion avec « Forage cristallin » ; alternative possible : « Structures cristallines » |
| Cross-dépendance Colonisation ← Cartographie | Proposé     | Lien thématique (cartographier avant de coloniser) ; à valider ou écarter                           |
| Coûts Colonisation / Régénération cellulaire | Provisoires | Validés provisoirement (50k/150k et base 60k) ; à confirmer lors de l'implémentation                |

---

_Document vivant v1.1 - à mettre à jour au fil du développement._
