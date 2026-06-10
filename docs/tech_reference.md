# World of Stars — Référence des technologies

> Version 0.3 — Document de conception
> Complément au `game_design.md`, `combat_reference.md`, `building_reference.md` et `unit_reference.md`
> Statut : structure validée, valeurs d'équilibrage à définir

---

## Table des matières

1. [Principes généraux](#1-principes-généraux)
2. [Pacing — le laboratoire plafonne les niveaux](#2-pacing--le-laboratoire-plafonne-les-niveaux)
3. [Prérequis](#3-prérequis)
4. [File de recherche](#4-file-de-recherche)
5. [Coût des technologies](#5-coût-des-technologies)
6. [Roster — périmètre initial](#6-roster--périmètre-initial)
7. [Roster — anticipé](#7-roster--anticipé)
8. [Évolutions futures](#8-évolutions-futures)
9. [Correspondance World of Stargate](#9-correspondance-world-of-stargate)
10. [Structure de données](#10-structure-de-données)
11. [Questions ouvertes](#11-questions-ouvertes)

---

## 1. Principes généraux

Les technologies sont recherchées dans le **`research_lab`**. Elles forment un **arbre hybride** : chaque technologie a un nombre de niveaux propre, et améliorer une technologie plusieurs fois renforce son effet.

- **Technologies à niveaux** : on améliore plusieurs fois la même technologie pour augmenter son effet (comme les bâtiments, pas un déblocage unique).
- **Chaque technologie a son propre niveau maximum.**
- **Bonus de combat globaux** : pour l'instant, les technologies de combat s'appliquent à **toutes les unités** sans distinction de type. Les bonus ciblés par type sont une évolution future (voir section 8).
- **Pas d'orientation stratégique imposée** : tous les joueurs accèdent au même arbre. Les prérequis créent un **ordre de progression naturel**, pas des branches mutuellement exclusives.
- L'arbre est volontairement découpé en deux paliers : un **périmètre initial** (fonctionnalités existantes ou en cours) et un palier **anticipé** (conçu maintenant, implémenté avec la fonctionnalité dont il dépend).

---

## 2. Pacing — le laboratoire plafonne les niveaux

Le mécanisme de pacing reprend le pattern du **Centre de Commandement** : de la même façon que le `command_center` plafonne le niveau maximum des bâtiments, le **niveau du `research_lab` plafonne le niveau maximum atteignable par chaque technologie.**

Monter le laboratoire = débloquer la **profondeur** de recherche. Le niveau utile d'une technologie est :

```
niveau_max_utile = min(plafond_labo, niveau_max_techno)
```

### Plafond de niveau de technologie par niveau de laboratoire

| `research_lab` niv | Plafond de niveau techno |
| ------------------ | ------------------------ |
| 1                  | 2                        |
| 2                  | 4                        |
| 3                  | 6                        |
| 4                  | 8                        |
| 5                  | 10                       |
| 6                  | 12                       |
| 7                  | 14                       |
| 8                  | 15                       |
| 9                  | 17                       |
| 10                 | 18                       |

> Rappel : le `research_lab` est lui-même plafonné par le `command_center` (labo niv 1 à CC niv 2, labo niv 10 à CC niv 9 — voir `building_reference.md`). La progression de recherche est donc indirectement cadencée par le Centre de Commandement.
>
> **Amorçage** : construire le `research_lab` exige un **petit niveau d'exploration** (cf. `game_design.md` §7). On explore donc d'abord à la **Sonde**, et les premiers points d'exploration ouvrent la recherche. Le labo débloque aussi l'unité **Scientifique** (moteur principal d'XP d'exploration).

---

## 3. Prérequis

Trois leviers de prérequis se superposent :

1. **Niveau de laboratoire** (cf. section 2) — le plafond global, commun à toutes les technologies.
2. **Cross-dépendances** — certaines technologies exigent un niveau minimum d'une **autre technologie**. C'est la composante « hybride » de l'arbre (ex : `Raffinage du thorium` exige `Forage cristallin` niv 5).
3. **Prérequis d'exploration** — appliqué **directement sur les technologies concernées** (et non sur le laboratoire). Le niveau d'exploration du joueur sert de porte d'entrée au palier avancé.

### Exploration = porte d'entrée du palier avancé

Narrativement, l'exploration est de la **découverte scientifique** : explorer des planètes vides ramène des données qui font avancer la recherche. Mécaniquement, les technologies « breakthrough » (énergie exotique, résurrection d'unités, colonisation) exigent un niveau d'exploration minimum.

Cela crée une **boucle vertueuse** :

```
explorer → gagner des niveaux d'exploration → débloquer la recherche avancée
       ↑                                                    │
       └──────────  Cartographie stellaire boost  ←─────────┘
```

Le palier initial reste accessible **sans explorer** : l'exploration ouvre le second palier, elle n'est pas un péage sur l'ensemble de l'arbre.

---

## 4. File de recherche

- La recherche dispose de sa **propre file**, distincte de la file de construction des bâtiments et de la file de production des unités.
- **Une seule recherche à la fois** par défaut.
- L'ajout de files de recherche parallèles n'est **pas** dans le périmètre initial (évolution future possible — voir section 8).

| File          | Bâtiment        | Extension                                      |
| ------------- | --------------- | ---------------------------------------------- |
| Construction  | `command_center`/planète | `Ingénierie parallèle` (techno)        |
| Production    | `training_camp` | `Chaîne de production` (techno)                |
| Recherche     | `research_lab`  | — (file unique pour l'instant)                 |

---

## 5. Coût des technologies

Chaque niveau d'une technologie coûte des ressources (**métal, nourriture, thorium**) et un **temps de recherche**. Modèle :

- **Coût géométrique** par niveau (comme les bâtiments). **Progression lente voulue** : facteur de progression élevé et coûts de base supérieurs à un bâtiment de palier équivalent, pour que grimper l'arbre soit un objectif de long terme. Les paliers avancés sont en plus **gatés par les niveaux d'exploration**.
- **Pas de coût en énergie** pour la recherche.
- **Pas d'entretien** : le bonus est permanent une fois recherché.
- Les **tables de coûts par niveau** seront établies en phase d'équilibrage (Annexe D du `game_design.md`), une fois la structure validée.

---

## 6. Roster — périmètre initial

Technologies dont les fonctionnalités support existent ou sont en cours de construction. Effets exprimés en intentions ; valeurs numériques à équilibrer.

| Technologie             | Catégorie   | Effet                                                        | Niv max | Cross-dépendance          |
| ----------------------- | ----------- | ------------------------------------------------------------ | ------- | ------------------------- |
| **Conversion énergétique** | Énergie     | + production des centrales                                   | 15      | —                         |
| **Supraconductivité**      | Énergie     | − consommation énergétique des bâtiments                     | 13      | Conversion énergétique 3  |
| **Forage cristallin**      | Production  | + production de métal                                        | 18      | —                         |
| **Hydroponie**             | Production  | + production de nourriture                                   | 18      | —                         |
| **Raffinage du thorium**   | Production  | + production de thorium                                      | 15      | Forage cristallin 5       |
| **Armement**               | Militaire   | + attaque (toutes unités)                                    | 18      | —                         |
| **Blindage tactique**      | Militaire   | + défense (toutes unités)                                    | 18      | —                         |
| **Guerre électronique**    | Militaire   | + intelligence (toutes unités)                               | 15      | —                         |
| **Ingénierie parallèle**   | Logistique  | + 1 file de construction par niveau                          | 3       | —                         |
| **Chaîne de production**   | Logistique  | + 1 file de production d'unités par niveau                   | 4       | —                         |
| **Cartographie stellaire** | Exploration | + gains XP & ressources d'exploration, − risque de pertes    | 10      | —                         |

> **Bonus de combat — modèle acté.** Armement, Blindage tactique et Guerre électronique appliquent un bonus **multiplicatif à accumulation additive** sur la stat : `stat_eff = stat_base × (1 + r·niveau)`. En agrégé, l'effet est **lisse** (pas de falaise) et **seul le delta de techno entre les camps compte** — monter la même techno des deux côtés ne change rien. Le couple `(r, niveau_max)` est borné pour garder le combat **≥ ~3 rounds au differentiel maximal** (sinon l'initiative décide tout en un round). Détail et validation : `combat_reference.md` §9. **Valeur figée : `r = 0,04`** (vérifié : au delta de techno maximal, le combat reste ≥ ~3 rounds). De plus, **ces trois technos débloquent des unités** (en complément du niveau de `military_camp`) : **Armement → Régulier**, **Blindage tactique → Sentinelle**, **Guerre électronique → Spectre** (cf. `unit_reference.md` §4).

---

## 7. Roster — anticipé

Technologies **conçues maintenant** mais implémentées quand la fonctionnalité dont elles dépendent est prête. Présence d'un prérequis d'exploration ou de fonctionnalité.

| Technologie         | Catégorie     | Effet                                                                 | Niv max | Prérequis spécial                                  | Dépend de        |
| ------------------- | ------------- | --------------------------------------------------------------------- | ------- | -------------------------------------------------- | ---------------- |
| **Cœur de thorium** | Énergie       | + production d'énergie majeure (palier avancé)                        | 10      | Exploration niv 3 + Conversion énergétique 5       | Exploration      |
| **Renseignement**   | Espionnage    | + furtivité / niveau d'espionnage (limite la détection, révèle plus)  | 10      | —                                                  | Feature espionnage |
| **Colonisation**    | Colonisation  | Niv 1 = débloque le vaisseau de colonisation + 2ᵉ planète · Niv 2 = 3ᵉ planète | 2 | Niv 1 : Exploration niv 2 · Niv 2 : Exploration niv 4 | Feature colonisation + vaisseau |

> **Colonisation** : version simple volontairement (2 niveaux = 2 planètes supplémentaires). Une ligne de recherche plus riche (vitesse de colonisation, coût réduit, bonus sur les nouvelles planètes) est une évolution future.

---

## 8. Évolutions futures

Notées pour anticipation, **hors périmètre actuel** :

| Idée                                    | Note                                                                                       |
| --------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Régénération cellulaire**             | Récupère/ressuscite une fraction des unités détruites après un combat (façon « sarcophage »). Exploration-gated. Touche le combat (en construction) — reporté. |
| **Vitesse de recherche**                | Technologie méta réduisant le temps de recherche. Idée notée, non implémentée.             |
| **Capacité de stockage**                | Technologie augmentant la capacité de stockage (aujourd'hui 100 % bâtiment). Idée notée.   |
| **Files de recherche parallèles**       | Permettre plusieurs recherches simultanées. Hors scope.                                    |
| **Bonus de combat ciblés par type**     | Aujourd'hui les bonus de combat sont globaux ; les spécialiser par type d'unité plus tard. |
| **Branche spatiale / vaisseaux**        | Toute la famille « technologies spatiales » (propulsion, réacteurs, armement de vaisseau, hyperespace) attend la définition des vaisseaux. |
| **Technologies exclusives Elyrans**     | Débloquer certaines technologies via une action diplomatique avec la Confédération Elyrans. Purement narratif pour l'instant. |

---

## 9. Correspondance World of Stargate

Référence d'inspiration. Les noms World of Stargate (licence Stargate) sont **abandonnés** au profit de noms originaux. Les valeurs de niveaux WoSG ne sont pas reprises.

| Nom WoSG (inspiration)                       | Technologie World of Stars   | Note                                              |
| -------------------------------------------- | ---------------------------- | ------------------------------------------------- |
| Maîtrise de l'énergie                        | Conversion énergétique       |                                                   |
| —                                            | Supraconductivité            | Nouvelle (réduction de consommation)              |
| Technologie Naquadria                        | Cœur de thorium              | Énergie exotique → thorium                         |
| Technologie Cristal + Foreuse Kelownan       | Forage cristallin            | Consolidées                                       |
| Moissonneuse Aschens                         | Hydroponie                   |                                                   |
| Extracteur à Naquadah                        | Raffinage du thorium         |                                                   |
| P90 / Zat'n'ktel / Lance / Grenade / Canon   | Armement                     | 5 technos d'arme consolidées en 1 (bonus globaux) |
| Tourelle d'attaque mobile                    | Blindage tactique            |                                                   |
| Nish'ta / Manipulateur ADN                   | Guerre électronique          | → bonus d'intelligence                            |
| Sarcophage                                   | Régénération cellulaire      | Évolution future                                  |
| Paquetage militaire                          | Chaîne de production         | → files de production d'unités                    |
| Espionnage                                   | Renseignement                | 10 niveaux conservés                              |
| Technologies spatiales (Ions, Plasma, réacteurs, hyperespace, antigrav…) | — | Reportées avec la branche vaisseaux               |

---

## 10. Structure de données

Structure cible calquée sur `Buildings::REGISTRY` (mêmes conventions : `requires`, plafonds par seuils, helpers). Le commentaire de `buildings.rb` prévoit déjà l'ajout de clés technologiques dans les prérequis.

```ruby
module Technologies
  # Per-level lookup tables — canonical source of truth for technology effects and costs.
  #
  # Fields per entry:
  #   category    — :energy, :production, :military, :logistics,
  #                 :exploration, :espionage, :colonization
  #   scope       — :initial (build now) | :anticipated (build with its feature)
  #   max_level   — own ceiling (capped further by research_lab via LAB_CAP)
  #   requires    — unlock prerequisites at level 1
  #                 { research_lab:, exploration:, <other_tech>: }
  #   effect      — { type:, per_level: }  (per_level values = PLACEHOLDERS, to balance)
  #   levels      — cost table { metal:, food:, thorium:, time: } — TBD (balancing)
  REGISTRY = {
    # ─── Périmètre initial ──────────────────────────────────────────────────
    conversion_energetique: {
      category: :energy, scope: :initial, max_level: 15,
      requires: { research_lab: 1 },
      effect: { type: :energy_production_bonus, per_level: 0.03 } # +3%/niv (placeholder)
    },
    supraconductivite: {
      category: :energy, scope: :initial, max_level: 13,
      requires: { research_lab: 1, conversion_energetique: 3 },
      effect: { type: :energy_consumption_reduction, per_level: 0.02 }
    },
    forage_cristallin: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1 },
      effect: { type: :metal_production_bonus, per_level: 0.03 }
    },
    hydroponie: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1 },
      effect: { type: :food_production_bonus, per_level: 0.03 }
    },
    raffinage_thorium: {
      category: :production, scope: :initial, max_level: 15,
      requires: { research_lab: 1, forage_cristallin: 5 },
      effect: { type: :thorium_production_bonus, per_level: 0.03 }
    },
    armement: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1 },
      effect: { type: :unit_attack_bonus, per_level: 0.04 } # ×(1+0.04·niv) ATQ — r figé (combat_reference §9) ; unlocks Régulier
    },
    blindage_tactique: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1 },
      effect: { type: :unit_defense_bonus, per_level: 0.04 } # ×(1+0.04·niv) DEF — r figé ; unlocks Sentinelle
    },
    guerre_electronique: {
      category: :military, scope: :initial, max_level: 15,
      requires: { research_lab: 1 },
      effect: { type: :unit_intelligence_bonus, per_level: 0.04 } # ×(1+0.04·niv) INT — r figé ; unlocks Spectre
    },
    ingenierie_parallele: {
      category: :logistics, scope: :initial, max_level: 3,
      requires: { research_lab: 1 },
      effect: { type: :construction_queue_slots, per_level: 1 }
    },
    chaine_de_production: {
      category: :logistics, scope: :initial, max_level: 4,
      requires: { research_lab: 1 },
      effect: { type: :unit_production_queue_slots, per_level: 1 }
    },
    cartographie_stellaire: {
      category: :exploration, scope: :initial, max_level: 10,
      requires: { research_lab: 1 },
      effect: { type: :exploration_gain_bonus, per_level: 0.04 }
    },

    # ─── Anticipé ───────────────────────────────────────────────────────────
    coeur_de_thorium: {
      category: :energy, scope: :anticipated, max_level: 10,
      requires: { research_lab: 5, exploration: 3, conversion_energetique: 5 },
      effect: { type: :energy_production_bonus, per_level: 0.06 }
    },
    renseignement: {
      category: :espionage, scope: :anticipated, max_level: 10,
      requires: { research_lab: 1 },
      effect: { type: :espionage_level, per_level: 1 }
    },
    colonisation: {
      category: :colonization, scope: :anticipated, max_level: 2,
      requires: { research_lab: 1 },
      effect: { type: :max_planets, per_level: 1 } # +1 colonisable planet per level
    }
  }.freeze

  # Global research_lab ceiling: lab level → max reachable technology level.
  # Usable level = [LAB_CAP[lab_level], REGISTRY[tech][:max_level]].min
  LAB_CAP = { 1 => 2, 2 => 4, 3 => 6, 4 => 8, 5 => 10,
              6 => 12, 7 => 14, 8 => 15, 9 => 17, 10 => 18 }.freeze

  # Level-dependent prerequisites for technologies whose gates change per level.
  # Threshold format identical to Buildings::LEVEL_PREREQUISITES:
  #   { tech_key => { min_tech_level => { prereq_type => min_level } } }
  LEVEL_PREREQUISITES = {
    colonisation: { 1 => { exploration: 2 }, 2 => { exploration: 4 } }
  }.freeze
end
```

> Les `per_level` et les tables de coûts sont des **placeholders**. La calibration intervient en phase d'équilibrage, après validation des stats d'unités pour les technologies de combat.

---

## 11. Questions ouvertes

| Sujet                                          | État          | Note                                                                          |
| ---------------------------------------------- | ------------- | ----------------------------------------------------------------------------- |
| Valeurs `per_level` des bonus                  | À équilibrer  | Additif vs multiplicatif, % par niveau                                        |
| Bonus de combat (Armement/Blindage/G. élec.)   | **Figé**        | Multiplicatif additif `×(1+r·niv)`, **r = 0,04**, delta-only (`combat_reference.md` §9). Ces technos débloquent aussi des unités |
| Tables de coûts de recherche                   | À construire  | Coût géométrique métal/nourriture/thorium + temps (Annexe D)                  |
| Effet exact de Cartographie stellaire          | À définir     | Répartition entre + XP, + chance de ressources, − risque de pertes            |
| Seuils d'exploration de Colonisation           | À équilibrer  | Niv 2 / niv 4 proposés, à ajuster                                             |
| Bornes du plafond labo (`LAB_CAP`)             | À valider     | Progression 2→18 proposée                                                     |

---

_Document vivant — à mettre à jour au fil du développement._
