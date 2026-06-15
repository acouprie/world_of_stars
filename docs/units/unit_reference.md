# World of Stars - Référence des unités terrestres

> Version 0.8 - Document de conception
> Complément au `game_design.md`, `combat_reference.md` et `building_reference.md`
> Statut : principes validés · roster, stats v2.1, **coûts (échelle k=5 validée)**, transport, durées **validés** ; **calendrier de déblocage v2 (passe économie)** ; mécanismes d'exploration chiffrés
> **La mécanique de combat a été déplacée dans `combat_reference.md` (source de vérité). Le §6 ci-dessous n'en garde que le volet « unités ».**

---

## Table des matières

1. [Principes généraux](#1-principes-généraux)
2. [Catégories et rôles](#2-catégories-et-rôles)
3. [Statistiques](#3-statistiques)
4. [Production des unités](#4-production-des-unités)
5. [Mouvement et Iris](#5-mouvement-et-iris)
6. [Combat](#6-combat)
7. [Exploration](#7-exploration)
8. [Espionnage](#8-espionnage)
9. [Roster des unités](#9-roster-des-unités)
10. [Questions ouvertes](#10-questions-ouvertes)

---

## 1. Principes généraux

Les unités terrestres constituent l'armée du joueur. Elles sont la **charge utile** : elles ne se déplacent jamais seules et nécessitent un porteur (portail quantique ou vaisseau) pour agir sur une autre planète.

Chaque unité est définie par un coût de production (métal, nourriture, thorium, temps) et un ensemble de statistiques. **Aucun coût d'entretien** : le coût de production est unique. Les statistiques de base sont modifiables par les **technologies**.

Les combats peuvent opposer des **milliers** d'unités de chaque côté (à k=5, les armées se comptent en centaines puis en milliers). La résolution est conçue pour être **indépendante de l'effectif** (voir §6).

---

## 2. Catégories et rôles

### Combat - trois archétypes

| Archétype  | Nom            | Profil                         | Rôle                        |
| ---------- | -------------- | ------------------------------ | --------------------------- |
| Offensif   | **Maraudeur**  | Attaque haute, défense faible  | Raids, assauts rapides      |
| Défensif   | **Sentinelle** | Défense haute, attaque modérée | Garnison, tenue de position |
| Polyvalent | **Régulier**   | Attaque/défense équilibrées    | Ligne de front, flexibilité |

Pas d'unité d'escorte dédiée au lancement. Les niveaux de military_camp sans déblocage d'unité (6, 8, 10) sont notés au backlog d'enrichissement (cf. `game_design.md`).

### Scientifique (exploration)

Génère des **points d'exploration**. Transport modéré. **Attaque symbolique** (« arme de poing », ATQ 2) qui ne le transforme pas en unité de combat.

### Reconnaissance - Sonde (exploration) & Spectre (espionnage)

En exploration, leur **risque de pertes est réduit** (poids de risque 0,6, pas d'immunité, cf. §7). La Sonde transporte et explore ; le Spectre est furtif et espionne (transport nul).

### Transport - Mule

ATQ 0 (ne combat jamais), DEF faible, **transport très élevé**. Une troupe de Mules seules ne gagne jamais ; elle pille si la cible n'a aucun défenseur. En exploration : poids de risque 1,2, base de butin élevée, zéro XP - l'archétype du « run de butin » risqué.

> **Conséquence du modèle (cf. §6) :** l'intelligence de combat est pondérée par l'attaque ; les unités à ATQ 0 (Sonde, Spectre, Mule) **n'influencent pas un combat** et meurent sans riposter. On ne les emmène qu'en exploration/espionnage, ou les Mules au pillage après victoire. **L'UI doit en avertir** le joueur.

---

## 3. Statistiques

| Stat             | Rôle                                                                                  |
| ---------------- | ------------------------------------------------------------------------------------- |
| **Attaque**      | Contribue au budget de dégâts du camp (0 = ne combat pas)                             |
| **Défense**      | **Palier d'armure** : dégâts _concentrés_ à dépasser pour détruire (pas de PV)        |
| **Intelligence** | Initiative + efficacité du repli - **stat de combat uniquement**                      |
| **Transport**    | Ressources transportables, **par ressource** (métal, nourriture, thorium séparément)  |
| **Exploration**  | Contribution à la base d'XP d'exploration de l'équipe                                 |
| **Espionnage**   | Furtivité en mission d'espionnage                                                     |

### Stats de combat - baseline v2.1 (validée par simulation)

| Unité        | ATQ | DEF | INT |
| ------------ | --- | --- | --- |
| Maraudeur    | 16  | 20  | 6   |
| Régulier     | 11  | 30  | 8   |
| Sentinelle   | 13  | 38  | 10  |
| Scientifique | 2   | 14  | 7   |
| Sonde        | 0   | 12  | 4   |
| Spectre      | 0   | 10  | 2   |
| Mule         | 0   | 16  | 1   |

> **v2.1 :** la Sentinelle passe de 9/52 à **13/38**. Sa DEF 52 créait un effet de seuil binaire (invincible si nombreuse, inerte sinon) et son ATQ 9 la rendait édentée - un « effet mur » indésirable et difficile à équilibrer en coût. Le profil 13/38 reste le plus blindé du roster, mais se comporte continûment.

**Principe gravé :** `DEF_min > ATQ_max × 1,15` - aucune unité ne meurt d'un seul tir ; tuer exige de **concentrer** le feu.

### Transport / exploration / espionnage

| Unité        | Transport | Base d'XP explo | Espion |
| ------------ | --------- | --------------- | ------ |
| Maraudeur    | 50        | 10              | 0      |
| Régulier     | 80        | 10              | 0      |
| Sentinelle   | 30        | 10              | 0      |
| Scientifique | 60        | **60**          | 0      |
| Sonde        | 150       | 25              | 3      |
| Spectre      | 0         | 25              | 12     |
| Mule         | 350       | 0               | 0      |

\* La colonne « Base d'XP explo » est la **contribution à la base d'XP** de l'équipe (valeurs calibrées à la passe économie, cohérentes avec la courbe de niveaux ×1,7) : les **Scientifiques** en sont le moteur principal, la reconnaissance apporte une part secondaire, les combattants une part mineure, les Mules rien. Le gain d'XP réel d'une mission est un **tirage** autour de cette base (cf. §7 et `game_design.md` §7). Transport « par ressource » : une Mule porte 350 métal **et** 350 nourriture **et** 350 thorium.

> **XP à la destruction** (classement, sans effet mécanique) : proportionnelle au **coût** de l'unité (suit donc automatiquement l'échelle k=5).

---

## 4. Production des unités

### Lieu & files

Toutes les unités sont produites au **training_camp** (seul producteur). **Une seule file de production.** Les files parallèles (ex-techno « Chaîne de production ») sont **sorties du périmètre** : backlog d'enrichissement (cf. `game_design.md`). Déblocage des _types_ par le **military_camp** (calendrier ci-dessous).

### Coûts - échelle k=5 validée

Principe : le coût des unités de combat **suit leur puissance** (ratio de puissance mesuré par simulation **1 : 1,15 : 1,6** pour Maraudeur : Régulier : Sentinelle, cf. `combat_reference.md` §13 ; la table respecte ce ratio, Sentinelle alignée à ×1,60) ; le **thorium gate les paliers**. L'échelle absolue **k = 5** est validée par double ancre World of Stargate : soldat lourd 850 ressources ↔ Sentinelle 800 (k=5,3), scientifique 600 ↔ Scientifique 650 (k=4,6). La table relative (k=1) reste la référence d'équilibre ; les valeurs ci-dessous sont la table ×5 effective.

| Unité        | Métal | Nourr. | Thorium | Total | ×Mar | Temps de base |
| ------------ | ----- | ------ | ------- | ----- | ---- | ------------- |
| Maraudeur    | 350   | 150    | 0       | 500   | 1,00 | 7 min 30      |
| Régulier     | 375   | 150    | 50      | 575   | 1,15 | 10 min 00     |
| Sentinelle   | 475   | 175    | 150     | 800   | 1,60 | 12 min 30     |
| Scientifique | 300   | 225    | 125     | 650   | 1,30 | 12 min 30     |
| Sonde        | 400   | 200    | 150     | 750   | 1,50 | 12 min 30     |
| Spectre      | 350   | 125    | 200     | 675   | 1,35 | 15 min 00     |
| Mule         | 350   | 200    | 0       | 550   | 1,10 | 12 min 30     |

Les temps de base sont inchangés et dans la gamme de l'original WoSG (soldat lourd 15 min, scientifique 12 min 30).

Validation coût-équivalent (budget identique, victoire attaquant) - avantage défenseur cohérent, aucune domination (invariante par k) :

```
ATT \ DEF     Maraudeur   Régulier   Sentinelle
Maraudeur        0%         12%         17%
Régulier        14%         40%         23%
Sentinelle      47%         70%         43%
```

Repères économiques à k=5 (ancres de la passe économie : CC 5 ≈ j10-14, CC 10 ≈ j50-60) : un raid de 30 Maraudeurs = 15 000 ressources ≈ 5-7 h de production vers le jour 5 ; une garnison de 100 Sentinelles = 80 000 (investissement d'ère CC 7) ; un scan de 5 Spectres = 1 000 thorium ≈ 1,5-3,7 h de thorium en mid-game : l'espionnage de routine reste abordable.

### Déblocage des types (military_camp + technologie)

Une unité est débloquée par **deux conditions cumulées** : le **niveau de military_camp** requis, **et** (pour les unités avancées) la **recherche de la technologie associée** (c'est la recherche de la techno qui ouvre l'unité, pas l'inverse). Le `military_camp` requiert `command_center 2` ; sa courbe est géométrique (×2/niveau).

| military_camp | Unité débloquée            | Techno requise en plus                                |
| ------------- | -------------------------- | ------------------------------------------------------ |
| 1             | **Maraudeur**, **Sonde**   | - (premier raid + exploration à la Sonde)              |
| 2             | **Sentinelle**, **Mule**   | - (kit complet : offense + défense + recon + transport) |
| 3             | **Régulier**               | **Armement** (recherchée)                              |
| 4             | _(aucune unité)_           | checkpoint des technos militaires                      |
| 5             | **Spectre**                | **Renseignement** (recherchée, avec la feature espionnage) |
| 6             | _(aucune unité)_           | à enrichir (backlog)                                   |
| 7             | _(aucune unité)_           | checkpoint des technos militaires                      |
| 8             | _(aucune unité)_           | à enrichir (backlog)                                   |
| 9             | _(aucune unité)_           | checkpoint des technos militaires                      |
| 10            | _(aucune unité)_           | à enrichir (backlog)                                   |

**Le Scientifique n'est pas débloqué ici** : il exige le **`research_lab`** construit (lui-même conditionné à un petit niveau d'exploration, cf. `game_design.md` §7) **et la technologie Cartographie stellaire recherchée**. Le bootstrap voulu : explorer d'abord à la **Sonde** (dispo dès military_camp 1) → premiers points d'exploration → construire le labo → rechercher **Cartographie stellaire** → débloquer le **Scientifique** (moteur principal d'XP d'exploration).

**Le kit complet arrive dès le camp 2.** L'ancienne « fenêtre de vulnérabilité » (offensif avant défensif) est **abandonnée** : avec des factions IA agressives dès l'early game (Varek), priver le nouveau joueur de son unité défensive de base était une friction sans contrepartie. La Sentinelle et la Mule ne dépendent d'**aucune technologie**.

> Les niveaux **4, 7 et 9** servent de **checkpoints aux technologies militaires** (Armement, Blindage tactique, Guerre électronique - cf. `tech_reference.md`). Les niveaux **6, 8 et 10** sont au backlog d'enrichissement (candidats : capacité de garnison, bonus de formation).

### Réduction du temps par le training_camp

`temps = temps_base × 0,95^(niveau − 1)` (-5 %/niveau, composé). Le `training_camp` plafonne à **10 niveaux** : au niveau 10 (max), le temps est ÷1,4 (~30 % plus rapide). Coefficient ajustable.

---

## 5. Mouvement et Iris

Les unités ne traversent jamais la carte seules. Deux modes :

### Portail quantique

- Durée fixe **20 min** (indépendante de la distance). Envoi en attaque/exploration **dès le niveau 3** du portail ; on peut **subir** une attaque par portail dès qu'on en possède un.
- **Contourne la couche orbitale** : dépose les troupes au sol.
- « Pas de portail = immunité aux attaques par portail ».

### Iris - protection du portail

Activable/désactivable consciemment (comme le bunker). Quand l'Iris est **active**, elle accorde un **bonus de défense** à toutes les unités en défense **contre un assaut arrivé par portail** (relève leurs paliers d'armure). Contrepartie : **+10 min** sur la durée des attaques et expéditions **sortantes** par portail tant qu'elle est active.

| Niveau Iris | Structure      | Bonus défense |
| ----------- | -------------- | ------------- |
| 1           | Titane         | **+10 %**     |
| 2           | Titane-tritium | **+15 %**     |
| 3           | Tritium        | **+20 %**     |

Les niveaux d'Iris se débloquent en montant le portail quantique.

### Vaisseau (reporté)

Durée proportionnelle à la distance ; franchit la couche orbitale. Un **vaisseau d'exploration unique** est disponible au lancement.

---

## 6. Combat

> **La mécanique de combat complète vit dans [`combat_reference.md`](combat_reference.md)** (source de vérité unique : modèle, aléa, initiative, repli, plafond de rounds, technos de combat, algorithme par compteurs, validation). Cette section ne garde que ce qui touche directement les unités.

### Ce que les unités apportent au combat

- **ATQ** alimente le budget de feu agrégé du camp (0 = ne combat pas).
- **DEF** est un **palier d'armure** : il faut concentrer des dégâts ≥ DEF pour détruire l'unité (pas de PV).
- **INT** sert à l'initiative et au repli (stat de combat uniquement) ; les unités **non-combattantes** (`combat? = false` : Mule, Sonde, Spectre, **et le Scientifique** malgré son ATQ 2) ne tirent pas et n'influencent pas l'INT du camp.
- Les stats de combat de référence (baseline v2.1) sont au **§3**. L'invariant `DEF_min > ATQ_max × 1,15` s'applique aux unités de ligne (Maraudeur, Régulier, Sentinelle) ; les supports (Mule, Sonde, Spectre) en sont exclus - mourir vite fait partie de leur identité.
- **Ancre de coûts** : Maraudeur : Régulier : Sentinelle ≈ **1 : 1,15 : 1,6**, exploitée par la table k=5 du §4.

## 7. Exploration

_Modèle complet (source de vérité) : `game_design.md` §7 et `exploration_magnitude_v1.md`. Ici, seul le volet « unités »._

L'exploration tire **trois résultats indépendants** par mission - points d'exploration, ressources, pertes - chacun le plus souvent modeste, parfois nul, rarement extrême. **But premier : les points d'exploration** (niveaux du joueur, seuils ×1,7, qui gatent les technologies) ; les ressources sont un bonus net-négatif en moyenne. Mission : **20 min + 1 min/unité**, **jusqu'à 5 missions simultanées**.

### Poids de risque et rôles

Chaque classe porte un **poids de risque `w`**, commun aux pertes et à la base de butin (« qui ne risque rien ne trouve rien ») :

| Unité                                 | w    | Apport en exploration                                                              |
| ------------------------------------- | ---- | ----------------------------------------------------------------------------------- |
| **Scientifique**                      | 1,0  | Moteur principal d'XP (base 60) ; transport modéré (60)                            |
| **Sonde**                             | 0,6  | Transport élevé (150), risque réduit ; XP secondaire (base 25)                      |
| **Spectre**                           | 0,6  | Aucun transport, risque réduit ; XP secondaire (base 25) ; surtout un espion        |
| **Maraudeur / Régulier / Sentinelle** | 1,1  | **Escorte** : réduisent les pertes de l'équipe (`× (1 − 0,5 × part de combattants)`), ne génèrent **aucun butin** ; XP mineure (base 10) |
| **Mule**                              | 1,2  | Transport maximal (350), base de butin ×1,2, **zéro XP, zéro protection** : run de butin risqué |

- **Pertes** : `f_tiré × (1 − 0,5 × part_escorte) × (1 − 0,02 × niv_Cartographie) × w(classe)` par classe.
- **Butin** : `f_tiré × Σ coût(u) × w(u)` sur les unités **non-combat**, plafonné par le transport total.
- **Palier critique (2 %, 60-100 % de pertes) : ignore tous les modificateurs** (poids, escorte, Cartographie). Aucune composition n'est à l'abri d'un effacement.
- Cartographie stellaire : **+4 %/niv sur l'XP uniquement**, -2 %/niv sur les pertes ordinaires, aucun bonus de butin.

> **Changements actés (remplacent l'ancien modèle linéaire) :** plus de plancher PvE (« jamais exterminé », « 1 unité = aucune perte »), plus d'immunité de la reconnaissance, plus de formule `% risque × 3 = XP`. XP, ressources et pertes sont trois tirages **séparés**. Validation Monte Carlo (k=5) : toutes les compositions sont nettes-négatives (ratios butin/pertes 0,39-0,83), aucune pompe à ressources, coût d'exploration ≈ 1-2 % du revenu journalier de l'explorateur actif.

---

## 8. Espionnage

_Modèle complet (source de vérité) : `game_design.md` §6. Ici, seul le volet « unités »._

Mission **5 min**, réalisable uniquement par la reconnaissance. Le **Spectre** (furtivité 12) est le seul espion sérieux ; la **Sonde** (furtivité 3) est marginale : envoyée espionner, elle est détectée environ 3 fois sur 4 et décimée. Le coût du Spectre est volontairement contenu (cf. §4) pour rendre l'espionnage de routine viable. C'est un **contest** : furtivité de l'équipe et techno Renseignement de l'attaquant contre techno Renseignement du défenseur. Trois sorties par mission : détection, pertes d'unités (si détecté), et information par catégorie (bâtiments, unités, ressources, technologies, vaisseaux), possiblement lacunaire.

### Comportement (simulation, constantes de travail)

| Scénario                    | p_dét | perdues/détection | information révélée                                                                     |
| --------------------------- | ----- | ----------------- | --------------------------------------------------------------------------------------- |
| 1 Spectre, technos égales   | 4 %   | 0                 | bâtiments 14 % seulement                                                                |
| 5 Spectres, technos égales  | 19 %  | ~1                | tout, mais lacunaire (bât. 70 %, unités 60 %, ress. 50 %, technos 40 %, vaisseaux 30 %) |
| 10 Spectres, technos égales | 38 %  | ~2                | quasi complet (bât. 100 %, unités 90 %...)                                              |
| 5 Sondes, technos égales    | 75 %  | ~4                | même profondeur, mais détecté 3 fois sur 4 et décimé                                    |
| 5 Spectres, ta 10 vs td 0   | 9 %   | ~1                | complet et discret                                                                      |
| 5 Spectres, ta 0 vs td 10   | 38 %  | ~2                | dégradé (bât. 35 %, unités 25 %, ress. 15 %), technos bloquées, vaisseaux 0             |

---

## 9. Roster des unités

| Rôle              | Nom              | Catégorie      |
| ----------------- | ---------------- | -------------- |
| Combat offensif   | **Maraudeur**    | Combat         |
| Combat défensif   | **Sentinelle**   | Combat         |
| Combat polyvalent | **Régulier**     | Combat         |
| Scientifique      | **Scientifique** | Exploration    |
| Recon-exploration | **Sonde**        | Reconnaissance |
| Recon-espionnage  | **Spectre**      | Reconnaissance |
| Transport         | **Mule**         | Transport      |

---

## 10. Questions ouvertes

| Sujet                                     | État                  | Note                                                                                       |
| ----------------------------------------- | --------------------- | ------------------------------------------------------------------------------------------ |
| Noms des unités                           | **Tranché**           | -                                                                                          |
| Modèle de combat                          | **Tranché**           | Modèle A, résolution par compteurs (indépendante de l'effectif)                            |
| Aléa                                      | **Tranché**           | Jitter par tir [0,85;1,15] + swing global Normal(1; 0,25)/round                            |
| Initiative / repli (v1)                   | **Tranché**           | INT pondérée par l'ATQ ; repli auto 55 % ; volée d'adieu = f(Δ)                            |
| Stats de combat (v2.1)                    | **Validé**            | Sentinelle 13/38 ; baseline validée, fine-tuning possible avec le jeu                      |
| Coûts de production                       | **Validé (k=5)**      | Double ancre WoSG (soldat lourd 850 ↔ Sentinelle 800 ; scientifique 600 ↔ 650)            |
| Transport                                 | **Proposé**           | Par ressource ; à équilibrer vs capacité du bunker                                         |
| Durées de formation                       | **Validé**            | Base WoSG-compatible + réduction `0,95^(niveau−1)` du training_camp                        |
| Iris                                      | **Tranché**           | +10 / +15 / +20 % DEF (niv 1/2/3) vs assaut portail ; +10 min sortant                      |
| Calendrier de déblocage (military_camp)   | **Tranché (v2)**      | Kit complet au camp 2 ; Régulier 3+Armement ; Spectre 5+Renseignement ; Scientifique labo+Cartographie |
| Valeur des niveaux military_camp          | **Tranché**           | 4/7/9 = checkpoints technos militaires ; 6/8/10 = backlog d'enrichissement                 |
| XP par unité détruite                     | À définir             | ∝ coût de production (suit k=5)                                                            |
| Modèle d'exploration                      | **Tranché**           | 3 tirages indépendants + poids de risque + escorte + critique sans modificateurs (§7)      |
| Technos de combat                         | **Acté**              | Multiplicatif additif `×(1+r·niv)`, delta-only, **r = 0,04** (`combat_reference.md` §9)    |
| Repli paramétrable par le joueur          | **Idée future**       | Seuil choisi avant l'envoi (v2+)                                                           |
| Unité officier                            | **Non planifiée**     | Backlog ; Guerre électronique ne débloque plus rien                                        |
| Bombardement orbital / défenses statiques | Reporté / réflexion   | Avec les vaisseaux                                                                         |

---

_Document vivant v0.8 - à maintenir avec `game_design.md`, `combat_reference.md`, `building_reference.md` et les documents de calibration de la passe économie (`research_costs_v1.md`, `exploration_magnitude_v1.md`)._
