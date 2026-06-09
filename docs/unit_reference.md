# World of Stars — Référence des unités terrestres

> Version 0.4 — Document de conception
> Complément au `game_design.md`, `combat_reference.md` et `building_reference.md`
> Statut : principes validés · roster, stats v2.1, coûts, transport, durées **proposés et validés en coût-équivalent** (échelle absolue = curseur libre)
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

Les unités terrestres constituent l'armée du joueur. Elles sont la **charge utile** — elles ne se déplacent jamais seules et nécessitent un porteur (portail quantique ou vaisseau) pour agir sur une autre planète.

Chaque unité est définie par un coût de production (métal, nourriture, thorium, temps) et un ensemble de statistiques. **Aucun coût d'entretien** : le coût de production est unique. Les statistiques de base sont modifiables par les **technologies**.

Les combats peuvent opposer des **dizaines de milliers** d'unités de chaque côté. La résolution est donc conçue pour être **indépendante de l'effectif** (voir §6.5).

---

## 2. Catégories et rôles

### Combat — trois archétypes

| Archétype  | Nom            | Profil                         | Rôle                        |
| ---------- | -------------- | ------------------------------ | --------------------------- |
| Offensif   | **Maraudeur**  | Attaque haute, défense faible  | Raids, assauts rapides      |
| Défensif   | **Sentinelle** | Défense haute, attaque modérée | Garnison, tenue de position |
| Polyvalent | **Régulier**   | Attaque/défense équilibrées    | Ligne de front, flexibilité |

Pas d'unité d'escorte dédiée au lancement. Niveaux 7-10 du military_camp réservés à de futures unités (cf. idée « unité officier », §10).

### Scientifique (exploration)

Génère des **points d'exploration**. Transport modéré. **Attaque symbolique** (« arme de poing », ATQ 2) qui ne le transforme pas en unité de combat.

### Reconnaissance — Sonde (exploration) & Spectre (espionnage)

Toutes deux **sans pertes en exploration** (PvE). La Sonde transporte et explore ; le Spectre est furtif et espionne (transport nul).

### Transport — Mule

ATQ 0 (ne combat jamais), DEF faible, **transport très élevé**. Une troupe de Mules seules ne gagne jamais ; elle pille si la cible n'a aucun défenseur.

> **Conséquence du modèle (cf. §6) :** l'intelligence de combat est pondérée par l'attaque ; les unités à ATQ 0 (Sonde, Spectre, Mule) **n'influencent pas un combat** et meurent sans riposter. On ne les emmène qu'en exploration/espionnage, ou les Mules au pillage après victoire. **L'UI doit en avertir** le joueur.

---

## 3. Statistiques

| Stat             | Rôle                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------ |
| **Attaque**      | Contribue au budget de dégâts du camp (0 = ne combat pas)                            |
| **Défense**      | **Palier d'armure** : dégâts _concentrés_ à dépasser pour détruire (pas de PV)       |
| **Intelligence** | Initiative + efficacité du repli — **stat de combat uniquement**                     |
| **Transport**    | Ressources transportables, **par ressource** (métal, nourriture, thorium séparément) |
| **Exploration**  | Points d'exploration générés                                                         |
| **Espionnage**   | Furtivité en mission d'espionnage                                                    |

### Stats de combat — baseline v2.1 (validée par simulation)

| Unité        | ATQ | DEF | INT |
| ------------ | --- | --- | --- |
| Maraudeur    | 16  | 20  | 6   |
| Régulier     | 11  | 30  | 8   |
| Sentinelle   | 13  | 38  | 10  |
| Scientifique | 2   | 14  | 7   |
| Sonde        | 0   | 12  | 4   |
| Spectre      | 0   | 10  | 2   |
| Mule         | 0   | 16  | 1   |

> **v2.1 :** la Sentinelle passe de 9/52 à **13/38**. Sa DEF 52 créait un effet de seuil binaire (invincible si nombreuse, inerte sinon) et son ATQ 9 la rendait édentée — un « effet mur » indésirable et difficile à équilibrer en coût. Le profil 13/38 reste le plus blindé du roster, mais se comporte continûment.

**Principe gravé :** `DEF_min > ATQ_max × 1,15` — aucune unité ne meurt d'un seul tir ; tuer exige de **concentrer** le feu.

### Transport / exploration / espionnage

| Unité        | Transport | Explo          | Espion |
| ------------ | --------- | -------------- | ------ |
| Maraudeur    | 50        | 30 (fixe)\*    | 0      |
| Régulier     | 80        | 30 (fixe)\*    | 0      |
| Sentinelle   | 30        | 30 (fixe)\*    | 0      |
| Scientifique | 60        | 33 → croissant | 0      |
| Sonde        | 150       | 30             | 3      |
| Spectre      | 0         | 30             | 12     |
| Mule         | 350       | 0              | 0      |

\* 30 XP fixes en exploration, **annulés** en présence de Scientifiques (cf. §7). Transport « par ressource » : une Mule porte 350 métal **et** 350 nourriture **et** 350 thorium.

> **XP à la destruction** (classement, sans effet mécanique) : à fixer **proportionnellement au coût** de l'unité.

---

## 4. Production des unités

### Lieu & files

Toutes les unités sont produites au **training_camp** (seul producteur). Une file par défaut ; files parallèles débloquées par **technologie**. Déblocage des _types_ par le **military_camp** (cf. §10, calendrier à refaire).

### Coûts — baseline validée (coût-équivalent)

Principe : le coût des unités de combat **suit leur puissance** (ratios mesurés 1 : 1,15 : 1,5 pour Maraudeur : Régulier : Sentinelle) ; le **thorium gate les paliers** (petites quantités croissantes) ; l'**échelle absolue est un curseur libre `k`** (multiplier toute la table par `k` ajuste le rythme sans toucher l'équilibre).

| Unité        | Métal | Nourr. | Thorium | Total | ×Mar | Temps de base |
| ------------ | ----- | ------ | ------- | ----- | ---- | ------------- |
| Maraudeur    | 70    | 30     | 0       | 100   | 1,00 | 1 min 30      |
| Régulier     | 75    | 30     | 10      | 115   | 1,15 | 3 min 00      |
| Sentinelle   | 90    | 35     | 25      | 150   | 1,50 | 4 min 30      |
| Scientifique | 60    | 45     | 25      | 130   | 1,30 | 2 min 30      |
| Sonde        | 80    | 40     | 30      | 150   | 1,50 | 3 min 30      |
| Spectre      | 70    | 25     | 40      | 135   | 1,35 | 3 min 30      |
| Mule         | 70    | 40     | 0       | 110   | 1,10 | 2 min 00      |

Validation coût-équivalent (budget identique, victoire attaquant) — avantage défenseur cohérent, aucune domination :

```
ATT \ DEF     Maraudeur   Régulier   Sentinelle
Maraudeur        0%         12%         17%
Régulier        14%         40%         23%
Sentinelle      47%         70%         43%
```

Sanity économie (mines niv ~6) : un scan de 5 Spectres ≈ **0,7 h de thorium** (contre ~6,5 h dans l'ancienne proposition jugée trop chère). L'espionnage de routine est abordable.

### Réduction du temps par le training_camp

`temps = temps_base × 0,95^(niveau − 1)` (−5 %/niveau, composé). Au niv 10 : ÷1,4 (~30 % plus rapide) ; au niv 20 : ÷2,6. Coefficient ajustable.

---

## 5. Mouvement et Iris

Les unités ne traversent jamais la carte seules. Deux modes :

### Portail quantique

- Durée fixe **20 min** (indépendante de la distance). Envoi en attaque/exploration **dès le niveau 3** du portail ; on peut **subir** une attaque par portail dès qu'on en possède un.
- **Contourne la couche orbitale** : dépose les troupes au sol.
- « Pas de portail = immunité aux attaques par portail ».

### Iris — protection du portail

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

> **La mécanique de combat complète vit désormais dans [`combat_reference.md`](combat_reference.md)** (source de vérité unique : modèle, aléa, initiative, repli, plafond de rounds, technos de combat, algorithme par compteurs, validation). Cette section ne garde que ce qui touche directement les unités.

### Ce que les unités apportent au combat

- **ATQ** alimente le budget de feu agrégé du camp (0 = ne combat pas).
- **DEF** est un **palier d'armure** : il faut concentrer des dégâts ≥ DEF pour détruire l'unité (pas de PV).
- **INT** sert à l'initiative et au repli (stat de combat uniquement) ; les unités à ATQ nulle (Mule, Sonde, Spectre) n'influencent pas l'INT du camp.
- Les stats de combat de référence (baseline v2.1) sont au **§3**. L'invariant `DEF_min > ATQ_max × 1,15` s'applique aux unités de ligne (Maraudeur, Régulier, Sentinelle) ; les supports (Mule, Sonde, Spectre) en sont exclus — mourir vite fait partie de leur identité.
- **Ancre de coûts** issue de la validation : Maraudeur : Régulier : Sentinelle ≈ **1 : 1,15 : 1,6** (à exploiter à la passe économie).

## 7. Exploration

_Résumé. Référence : `game_design.md` §7._

Planètes vides explorables (portail implicite). Mission : **20 min + 1 min/unité** ; **plancher PvE** (jamais exterminé) ; Sonde/Spectre sans pertes. Scientifique : `% risque × 3 = XP`, 1 seul = 11 % → 33 XP, 90 = 100 % → 300 XP, puis +3 XP/unité ; annule les 30 XP fixes des autres unités. Niveaux d'exploration : niv 1 = 400 XP, ×1,2/niveau, XP cumulée.

---

## 8. Espionnage

_Résumé. Référence : `game_design.md` §6._

Mission **5 min**. Plus d'unités = plus d'info mais plus de risque ; la **furtivité (espionnage)** réduit la détection. Paliers : 1 bâtiments, 2 unités, 3 ressources, 4 technologies (techno espionnage ≥ cible), 5 vaisseaux (Spectre uniquement). ~5 unités = compromis standard ; 10 niveaux de techno. Coût du Spectre revu à la baisse (cf. §4) pour rendre l'espionnage de routine viable.

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

| Sujet                                     | État                | Note                                                                  |
| ----------------------------------------- | ------------------- | --------------------------------------------------------------------- |
| Noms des unités                           | **Tranché**         | —                                                                     |
| Modèle de combat                          | **Tranché**         | Modèle A, résolution par compteurs (indépendante de l'effectif)       |
| Aléa                                      | **Tranché**         | Jitter par tir [0,85;1,15] + swing global Normal(1; 0,25)/round       |
| Initiative / repli (v1)                   | **Tranché**         | INT pondérée par l'ATQ ; repli auto 55 % ; volée d'adieu = f(Δ)       |
| Stats de combat (v2.1)                    | **Validé**          | Sentinelle 13/38 ; baseline validée, fine-tuning possible avec le jeu |
| Coûts de production                       | **Proposé/validé**  | Coût-équivalent OK ; échelle absolue = curseur `k`                    |
| Transport                                 | **Proposé**         | Par ressource ; à équilibrer vs capacité du bunker                    |
| Durées de formation                       | **Proposé**         | Base + réduction `0,95^(niveau−1)` du training_camp                   |
| Iris                                      | **Tranché**         | +10 / +15 / +20 % DEF (niv 1/2/3) vs assaut portail ; +10 min sortant |
| Calendrier de déblocage (military_camp)   | **À refaire**       | Prochain chantier ; cohérence avec l'économie                         |
| XP par unité détruite                     | À définir           | ∝ coût de production                                                  |
| Technos de combat                         | Architecture posée  | Modificateurs % sur ATQ/DEF/INT/repli ; à chiffrer                    |
| Repli paramétrable par le joueur          | **Idée future**     | Seuil choisi avant l'envoi (v2+)                                      |
| Unité officier (niv 7-10 military_camp)   | **Idée future**     | INT mène le tempo (modèle « initiative = INT max »)                   |
| Bombardement orbital / défenses statiques | Reporté / réflexion | Avec les vaisseaux                                                    |

---

_Document vivant v0.3 — à maintenir avec game_design.md et building_reference.md_
