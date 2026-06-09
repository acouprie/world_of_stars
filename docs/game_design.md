# World of Stars — Document de Game Design

> Version 0.7 — Document de référence projet
> Auteur : Antoine Couprie
> Statut : En cours — annexes à compléter

> **Structure de la documentation.** Ce GDD est le **hub** : vision, univers, économie, progression, factions, alliances, UI, architecture. Les systèmes les plus détaillés vivent dans des documents de référence dédiés, sources de vérité de leur domaine :
> - [`combat_reference.md`](combat_reference.md) — système de combat au sol (modèle, aléa, repli, technos de combat, algorithme, validation)
> - [`unit_reference.md`](unit_reference.md) — roster, stats, production, exploration & espionnage des unités
> - [`tech_reference.md`](tech_reference.md) — arbre technologique, pacing, coûts
> - [`building_reference.md`](building_reference.md) — bâtiments, coûts par niveau, prérequis
>
> Combat, exploration et espionnage **ne sont plus dupliqués** dans le GDD : il en donne un résumé et renvoie au document de référence.

---

## Table des matières

1. [Vision & contexte](#1-vision--contexte)
2. [Univers & carte](#2-univers--carte)
3. [Ressources & économie](#3-ressources--économie)
4. [Bâtiments](#4-bâtiments)
5. [Progression & planètes](#5-progression--planètes)
6. [Combat & espionnage](#6-combat--espionnage)
7. [Exploration](#7-exploration)
8. [Factions IA](#8-factions-ia)
9. [Alliances & diplomatie](#9-alliances--diplomatie)
10. [Interface — Page planète](#10-interface--page-planète)
11. [Architecture technique & agents IA](#11-architecture-technique--agents-ia)
12. [Questions ouvertes & équilibrage futur](#12-questions-ouvertes--équilibrage-futur)
13. [Annexes](#13-annexes)

---

## 1. Vision & contexte

### Le projet

World of Stars est un jeu de stratégie spatial par navigateur, asynchrone, inspiré de World of Stargate et Ogame. L'univers, les noms et les graphismes sont originaux — aucune licence existante n'est reproduite. Les mécaniques de base s'inspirent librement des jeux cités.

### Objectifs du projet

- **Vitrine technique** pour l'activité freelance de l'auteur (Ruby on Rails, intégration IA)
- **Terrain d'expérimentation** pour la formation aux agents IA (au-delà de la simple intégration d'API)
- Un projet construit avec plaisir avant tout

### Différenciation clé

L'absence de factions IA dans les jeux du genre crée un vide au lancement : pas de cibles, pas d'activité. World of Stars introduit trois factions contrôlées par des agents IA avec des personnalités distinctes, rendant le jeu jouable dès le premier joueur inscrit.

---

## 2. Univers & carte

### Structure de l'univers

- **Une galaxie = un serveur de jeu.** Si plusieurs serveurs coexistent à terme, chacun constitue une galaxie indépendante.
- La galaxie est générée à l'initialisation : un maillage fixe de planètes réparties sur une carte 2D avec des coordonnées **(x, y)**.
- La carte est visualisable en **vue galaxie** : chaque joueur voit sa planète et toutes les autres, et peut naviguer sur la carte.

### Planètes

Trois **statuts de possession** coexistent sur la carte :

| Statut (`planet_type`) | Description                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------- |
| `player`               | Assignée à un joueur à l'inscription ou colonisée/conquise                         |
| `ai_faction`           | Appartenant aux factions l'Empire Varek, la Confédération Elyrans ou les Nexhianti |
| `empty`                | Non assignée, colonisable et explorable                                            |

Chaque planète possède également un **biome** (propriété `biome`, stockée en base, indépendante du statut de possession) qui détermine son apparence graphique et influence sa production de ressources.

| Biome         | Apparence                                                            |
| ------------- | -------------------------------------------------------------------- |
| `oceanic`     | Monde aquatique, tons bleus profonds                                 |
| `arid`        | Surface désertique, tons ocre et sable                               |
| `volcanic`    | Monde instable, tons rouge sombre et gris                            |
| `glacial`     | Monde gelé, tons blanc et cyan                                       |
| `forest`      | Monde végétal, tons vert foncé et brun                               |
| `temperate`   | Mélange eau/terre/nuages, tons bleu clair, vert doux et beige        |
| `tundra`      | Sol nu gris-brun, sans calottes, pergélisol apparent                 |
| `crystalline` | Formations géométriques translucides, tons violet pâle et cyan       |
| `fungal`      | Formes organiques arrondies, tons mauve et orange chaud              |
| `toxic`       | Nuages denses jaune-vert, surface brunâtre corrosive                 |
| `irradiated`  | Surface fracturée, lueur vert néon, cratères lumineux                |
| `barren`      | Roche nue cratérisée, gris bleuté très sombre, quasi sans atmosphère |

Le biome est assigné à la génération de la galaxie de façon déterministe (`(coord_x + coord_y) % 12`), garantissant une distribution régulière sur la carte.

### Bonus de production par biome

Le biome d'une planète applique un **bonus dégressif** sur la production des ressources correspondantes, incitant le joueur à coloniser des planètes de biomes variés.

**Formule :** `taux_final = base + k × √base`

Le bonus est proportionnel à la racine carrée de la production de base — fort en proportion sur les niveaux 1 à 5 des bâtiments de production (early game), il devient négligeable en late game sans jamais être nul.

| Biome         | Métal (k) | Nourriture (k) | Thorium (k) | Profil                  |
| ------------- | --------- | -------------- | ----------- | ----------------------- |
| `oceanic`     | 1.5       | 1.5            | —           | Métal + nourriture      |
| `arid`        | 3.0       | —              | —           | Métal pur               |
| `volcanic`    | —         | —              | 3.0         | Thorium pur             |
| `glacial`     | 1.0       | —              | 2.0         | Thorium dominant        |
| `forest`      | —         | 3.0            | —           | Nourriture pure         |
| `temperate`   | 1.0       | 1.0            | 1.0         | Tri-ressource équilibré |
| `tundra`      | 2.0       | 1.0            | —           | Métal dominant          |
| `crystalline` | 1.0       | —              | 2.0         | Thorium dominant        |
| `fungal`      | —         | 2.0            | 1.0         | Nourriture dominant     |
| `toxic`       | —         | 1.5            | 1.5         | Nourriture + thorium    |
| `irradiated`  | —         | 1.0            | 2.0         | Thorium dominant        |
| `barren`      | 2.0       | —              | 1.0         | Métal dominant          |

Le k total par biome est identique (3.0), garantissant l'équilibre entre biomes quelle que soit la ressource visée. `temperate` est le seul biome tri-ressource — polyvalent mais sans excellence sur aucun axe.

### Capacité maximale du serveur

- Le nombre de planètes est **fixé à l'initialisation** du serveur.
- Un nombre maximum de joueurs est défini en conséquence, en réservant :
  - Les planètes des factions IA (Varek et Elyrans ont des planètes fixes)
  - Un stock minimal de planètes vides pour l'exploration et l'expansion des Nexhianti
  - Le calcul prend en compte le maximum de 3 planètes par joueur

### Déplacements

- **Par vaisseau** : durée calculée en fonction de la distance euclidienne entre les coordonnées (x, y) des deux planètes. Implique un aller et un retour.
- **Par portail quantique** : durée fixe, indépendante de la distance. Nécessite un Portail Quantique construit sur la planète de départ **et** sur la planète de destination.

---

## 3. Ressources & économie

### Les quatre ressources

| Ressource      | Type               | Production                              | Rôle                                    |
| -------------- | ------------------ | --------------------------------------- | --------------------------------------- |
| **Énergie**    | Capacité installée | Centrales solaires, centrales à fission | Prérequis structurel pour les bâtiments |
| **Métal**      | Stock              | Mine de métaux                          | Construction, recherche, unités         |
| **Nourriture** | Stock              | Champs agricoles                        | Construction, recherche, unités         |
| **Thorium**    | Stock              | Mine de thorium                         | Construction, recherche, unités         |

### Énergie — fonctionnement détaillé

L'énergie n'est **pas un stock consommable** : c'est une **capacité installée permanente**.

- Les centrales produisent X unités d'énergie disponibles en continu.
- Chaque bâtiment construit consomme une fraction de cette capacité.
- **Si la capacité installée est insuffisante, il est impossible de construire ou d'améliorer un bâtiment.** Il faut d'abord augmenter la production d'énergie.
- L'énergie ne s'accumule pas et ne se dépense pas — elle représente une infrastructure, pas un carburant.

### Production des ressources (Métal, Nourriture, Thorium)

- Production **continue**, calculée à la volée au moment où le joueur consulte ses ressources.
- Formule : `ressources += taux_production * (now - last_updated_at)`
- Pas de job récurrent pour la production — calcul instantané côté serveur.

### Stockage

- Chaque ressource dispose d'un bâtiment de stockage dédié.
- La capacité de stockage est limitée par le niveau du bâtiment correspondant.
- Les ressources produites au-delà de la capacité de stockage sont perdues.

### Protection des ressources

- Le **Bunker** permet de mettre en sécurité une fraction des ressources et des soldats.
- Capacité du bunker limitée (ressources et soldats indépendants), augmente par niveau de bâtiment.
- Les ressources hors bunker sont pillables lors d'une attaque.

---

## 4. Bâtiments

### Catégories de bâtiments

#### Production énergétique

| Bâtiment                     | Rôle                                                 |
| ---------------------------- | ---------------------------------------------------- |
| Centrale solaire             | Production d'énergie de base                         |
| Centrale à fission nucléaire | Production d'énergie avancée (upgrade de la solaire) |

#### Production de ressources

| Bâtiment         | Ressource produite |
| ---------------- | ------------------ |
| Champs agricoles | Nourriture         |
| Mine de métaux   | Métal              |
| Mine de thorium  | Thorium            |

#### Stockage

| Bâtiment            | Ressource stockée |
| ------------------- | ----------------- |
| Silo de nourriture  | Nourriture        |
| Entrepôt de métal   | Métal             |
| Entrepôt de thorium | Thorium           |

#### Infrastructure & science

| Bâtiment               | Rôle                                                               |
| ---------------------- | ------------------------------------------------------------------ |
| Centre de commandement | Hub logistique central, prérequis pour de nombreuses constructions |
| Laboratoire            | Recherche technologique, amélioration des capacités                |
| Portail quantique      | Téléportation inter-planétaire (déplacements et attaques)          |
| Satellite radar        | Détection des mouvements ennemis (voir ci-dessous)                 |

#### Infrastructure militaire

| Bâtiment            | Rôle                                                         |
| ------------------- | ------------------------------------------------------------ |
| Camp d'entraînement | Production des unités terrestres (niveau ↑ = temps ↓)        |
| Camp militaire      | Débloque les types d'unités selon son niveau                 |
| Usine spatiale      | Construction de vaisseaux                                    |
| Bunker              | Mise à l'abri consciente d'unités + protection de ressources |

### Satellite radar — niveaux de détection

| Niveau | Capacité                                                      |
| ------ | ------------------------------------------------------------- |
| 1      | Détecte la présence d'une flotte en orbite                    |
| 2      | Révèle le pseudo du joueur propriétaire                       |
| 4      | Révèle la composition de la flotte en orbite                  |
| 5-7-9  | Détecte les flottes en approche selon une distance croissante |

### Portail quantique — contraintes

- Nécessite d'être construit sur la planète de départ **et** sur la planète de destination.
- **Ne pas construire de portail = immunité aux attaques par portail** (choix stratégique délibéré).
- Les planètes vides sont considérées comme ayant un **portail implicite** (exploration uniquement).
- Consomme de l'énergie de capacité comme tout bâtiment.
- **Iris** : mécanisme de défense débloqué par l'amélioration du portail quantique. Bonus à la défense des assauts entrants par portail — comportement et équilibrage exact à définir (voir questions ouvertes).
- _Note : un coût en ressources par utilisation (Thorium ?) est envisagé mais non tranché — voir questions ouvertes._

---

## 5. Progression & planètes

### Planète d'origine

- Chaque joueur commence avec **une seule planète**.
- La planète d'origine est **inattaquable pour la conquête** — elle ne peut jamais changer de propriétaire. Elle peut en revanche être attaquée (pillage de ressources, destruction d'unités hors bunker).
- Le joueur ne peut donc jamais être entièrement éliminé.

### Expansion — colonisation

- Un joueur peut coloniser des planètes vides via un **vaisseau de colonisation**.
- La colonisation est débloquée par la recherche technologique.
- **Maximum de 3 planètes par joueur** (planète d'origine incluse), plafonné par le niveau technologique.
- Ce maximum pourra être réévalué lors des phases d'équilibrage.

### Expansion — conquête

- Une planète colonisée (non originelle) peut être **conquise définitivement** par un autre joueur ou une faction IA.
- La conquête transfère la propriété de la planète avec tous ses bâtiments.
- Les planètes IA (Varek, Elyrans, Nexhianti) sont conquérables selon les mêmes règles, avec des spécificités par faction (voir section 8).

### Protection contre les abus

- **Range de points** : un joueur ne peut pas attaquer un joueur dont les points sont trop inférieurs aux siens. Cela protège les nouveaux joueurs sans les rendre intouchables indéfiniment.
- **Planète d'origine** : ne peut pas être conquise en toutes circonstances.
- **Bunker** : mise à l'abri consciente d'unités (immunisées au combat) et protection d'une fraction des ressources. 1 unité = 1 slot, quel que soit le type.
- **Pas de portail** : immunité aux attaques par portail (choix stratégique).

---

## 6. Combat & espionnage

> **La mécanique de combat complète a été sortie dans son propre document : [`combat_reference.md`](combat_reference.md).** Ce fichier est la **source de vérité unique** du combat (modèle, aléa, repli, technos, algorithme, validation). Le résumé ci-dessous donne l'essentiel ; tout détail ou toute évolution se fait dans `combat_reference.md`.

### Résumé du combat (détail dans `combat_reference.md`)

- **Couches** : orbitale (vaisseaux, reportée — sautée si arrivée par portail) puis **au sol** (unités terrestres). C'est la couche au sol qui est entièrement spécifiée.
- **Modèle acté** : **tir agrégé + paliers d'armure, sans PV**. On oppose la **puissance de feu agrégée d'un camp** (Σ ATQ) aux **paliers de défense** des cibles ; tuer exige de **concentrer** le feu. Résolution **par compteurs de type** (forme fermée, `O(types)`), **indépendante de la taille** des armées (~10 rounds, qu'on oppose 100 ou 100 000 unités).
- **Aléa** : jitter par tir `[0,85 ; 1,15]` (texture) + **swing global par round `Normal(1 ; σ=0,25)`** (acté — principale incertitude à grande échelle). Game feel cible : **prédictif ~80 %, bande pile-ou-face ~20 % de ratio de force**.
- **Initiative** : INT du camp = moyenne pondérée par l'ATQ, recalculée chaque round ; à égalité, salves simultanées.
- **Repli (attaquant seul)** : automatique au-delà de **55 %** de pertes, avec **volée d'adieu** modulée par le delta d'INT `clamp(0,5 − Δ/8 ; 0 ; 1,5)`. **Plafond de statu quo à 18 rounds** → retrait de l'attaquant (jamais d'impasse).
- **Invariant** : `DEF_min > ATQ_max × 1,15` (stats de base) → aucune unité de ligne one-shottable. La défense a un avantage **réel mais pénétrable** (cracker un mur de Sentinelles ≈ ×1,45 de force).
- **Technos de combat** : bonus **multiplicatif à accumulation additive**, lisse — **seul le delta** entre les camps compte (modèle acté ; valeurs à calibrer).
- **Bunker / pillage / conquête / rapport / XP** : cf. `combat_reference.md` (XP = classement uniquement, table de multiplicateurs « victoire sans pertes » volontairement inversée pour récompenser le combat serré).

### Espionnage

Deux types d'unités de reconnaissance aux profils distincts : l'une orientée exploration (remplace l'ancien « Malp »), l'autre orientée espionnage (remplace l'ancien « UAV »). Voir `unit_reference.md` pour les noms définitifs.

- Une mission d'espionnage dure **5 minutes**.
- **Quantité d'unités vs furtivité** : plus on envoie d'unités, plus on obtient d'informations (bâtiments → unités → ressources → technologies → vaisseaux en orbite). Mais plus on en envoie, plus le **risque de détection** augmente. Si détecté, le joueur ciblé reçoit une notification dans sa messagerie.
- La stat d'**espionnage** des unités limite le risque de détection — une unité avec un espionnage élevé est plus discrète.
- L'envoi de **5 unités** est généralement un bon compromis (bonne visibilité, risque de détection limité).
- Les vaisseaux en orbite ne sont visibles que par l'unité de type espionnage (pas par l'unité type exploration).
- L'espionnage des **technologies** ennemies nécessite un niveau de technologie d'espionnage ≥ celui de la cible.
- 10 niveaux de technologie d'espionnage.

_Formule exacte de détection et de révélation d'information à définir lors de l'implémentation._

---

## 7. Exploration

### Principe

- Les planètes vides (non assignées) sont **explorables**.
- Les planètes vides sont considérées comme ayant un **portail implicite** permettant l'exploration par portail.
- Une mission d'exploration envoie une équipe d'unités sur une planète vide.
- Résultats : **points d'exploration** (alimentent les niveaux d'exploration), **ressources** (aléatoire), **rapport de mission narratif** généré par IA.
- L'exploration est **beaucoup plus rapide par portail**. Pour ne pas bloquer les joueurs sans portail, un **vaisseau d'exploration unique** est disponible dès le lancement (stratégie plus lente mais plus sûre, peu de points d'exploration).

### Durée d'une expédition

- Durée de base : **20 minutes** (par portail)
- **+1 minute par unité** ajoutée à l'équipe (une grande équipe = une expédition longue)

### Unités d'exploration et leurs rôles

_Les noms définitifs des unités seront définis dans `unit_reference.md`. Le tableau ci-dessous décrit les rôles fonctionnels._

| Rôle                 | XP de base   | Transport ressources | Particularités                                          |
| -------------------- | ------------ | -------------------- | ------------------------------------------------------- |
| Scientifique         | 33 XP (seul) | Modéré               | XP croissant avec le nombre, risque de pertes croissant |
| Recon-exploration    | 30 XP fixe   | Élevé                | Aucune perte en exploration, bonus exploration          |
| Recon-espionnage     | 30 XP fixe   | Aucun transport      | Aucune perte en exploration, bonus espionnage           |
| Combattant (escorte) | 30 XP fixe   | Variable             | Réduit le risque de pertes des scientifiques            |
| Transport            | —            | Très élevé           | Capacité de transport maximale                          |

### Règles générales d'exploration

- **Chance de gagner des ressources : 20%** peu importe les unités envoyées. La quantité varie entre 50% et 100% de la capacité de transport de l'équipe.
- **Règle de sécurité PvE** : une équipe d'exploration **ne peut jamais être totalement exterminée**. Si une seule unité est envoyée, aucune perte possible. Les unités de type reconnaissance ne subissent **jamais de pertes** en exploration (trait intrinsèque). _Cette règle est spécifique à l'exploration et ne s'applique pas au combat PvP._
- La quantité de pertes est égale au pourcentage de risque calculé.
- Les XP gagnés ont une **variation de ±5%** (résultat non déterministe).
- En présence de Scientifiques, les 30 XP des combattants et transports **ne sont pas comptabilisés** (annulés).

### Calcul du risque — Scientifiques

- 1 Scientifique seul = 11% de risque de pertes → 33 XP
- Chaque Scientifique supplémentaire = +1% de risque
- 90 Scientifiques = 100% de risque → 300 XP
- Au-delà de 100% : +3 XP par Scientifique supplémentaire
- **Formule XP** : `% de risque × 3 = XP`
- Les unités combattantes d'escorte réduisent le risque global selon leur proportion dans l'équipe

### Niveaux d'exploration

- L'XP d'exploration est associée **au joueur**, pas aux unités.
- Les niveaux d'exploration peuvent servir de **prérequis pour certaines technologies**.
- Niveau 1 : 400 XP requis
- Chaque niveau suivant : XP requis × 1.2
- Gains d'XP par exploration multipliés par 1.0292 à chaque passage de niveau
- **L'XP se cumule** — l'excédent au passage de niveau n'est pas perdu

### Points d'exploration et technologies

- L'exploration de planètes vides génère des **points d'exploration** qui alimentent les **niveaux d'exploration** du joueur.
- Les niveaux d'exploration peuvent être un **prérequis** pour la recherche de certaines technologies.
- Les niveaux d'exploration servent de **prérequis aux technologies du palier avancé** (Cœur de thorium, Colonisation, et la future Régénération cellulaire) — voir `tech_reference.md`.

---

## 8. Factions IA

### Vue d'ensemble

| Faction       | Nom complet              | Archétype                         | Comportement général                         | Diplomatie                                                         |
| ------------- | ------------------------ | --------------------------------- | -------------------------------------------- | ------------------------------------------------------------------ |
| **Varek**     | L'Empire Varek           | Agressive, expansionniste         | Raids fréquents, cible les joueurs faibles   | Hostile par défaut, hostilité croissante avec les points du joueur |
| **Elyrans**   | La Confédération Elyrans | Neutre, technologiquement avancée | Jamais agressive sauf provocation            | Neutre par défaut, réputation améliorable par le commerce          |
| **Nexhianti** | Les Nexhianti            | Menace globale, chaotique         | Expansion par vagues, phases de rétractation | Aucune diplomatie possible                                         |

---

### L'Empire Varek

**Identité** : empire conquérant, hiérarchique, expansionniste. Ciblent les joueurs isolés et les empires faibles pour accumuler des ressources et des planètes.

**Présence sur la carte** : planètes physiques fixes sur la carte, conquérables par les joueurs. Après conquête, l'Empire Varek **reconstitue ses forces sur ses planètes restantes** et recrute la planète perdue comme cible prioritaire de reconquête — le nombre de planètes total sur la carte reste fixe.

**Mécanisme de survie** : un seuil minimum de planètes Varek est garanti — si ce seuil est atteint, les planètes Varek deviennent temporairement inattaquables le temps que la faction se reconstitue. Cela évite l'anéantissement total par un joueur dominant.

**Comportement** :

- Raids réguliers sur les joueurs dont les points sont dans leur range
- Priorité aux cibles isolées (joueurs sans alliance)
- Tentatives de conquête de planètes vides ou faiblement défendues
- Peuvent attaquer les planètes d'origine mais ne peuvent pas les conquérir (même règle que pour les joueurs)

**Diplomatie** :

- Hostilité de base élevée
- L'hostilité augmente proportionnellement aux points du joueur ciblé — un joueur dominant devient leur cible prioritaire
- Effet équilibreur naturel : les Varek mettent la pression sur les plus puissants, donnant aux plus faibles le temps de progresser

---

### La Confédération Elyrans

**Identité** : civilisation ancienne, technologiquement supérieure, philosophiquement pacifiste. Observent, commercent, partagent leur savoir avec ceux qui le méritent.

**Présence sur la carte** : planètes très fortement défendues, quasi-inexpugnables. La conquête est techniquement possible mais extrêmement coûteuse — réservée aux alliances les plus puissantes. Même mécanisme de survie que les Varek : seuil minimum de planètes garanti.

**Comportement** :

- N'attaquent jamais en premier
- Ripostent si attaqués (défense disproportionnée)
- Proposent des échanges commerciaux et technologiques aux joueurs avec une réputation suffisante

**Diplomatie — système de réputation** :

- Chaque joueur possède une **jauge de réputation individuelle** avec les Elyrans
- Le commerce augmente la réputation → accès à des technologies exclusives, prix préférentiels, protection diplomatique partielle
- Attaquer un allié des Elyrans fait chuter la réputation
- Un modificateur alliance s'applique : les actions de l'alliance du joueur l'affectent légèrement (à la hausse ou à la baisse)
- La réputation est **individuelle**, pas héritée à l'inscription dans une alliance

---

### Les Nexhianti

**Identité** : entité collective, sans diplomatie, sans territoire permanent. S'étendent, consomment, se rétractent. Leur logique est écologique, pas politique. Aucune structure, aucun nom propre — juste les Nexhianti.

**Présence sur la carte** : pas de planètes fixes. Colonisent dynamiquement des planètes vides ou faiblement défendues lors de leurs phases d'expansion. Repartent de planètes vides lors des événements de reconstitution.

**Comportement — phases cycliques** :

1. **Phase d'expansion** : colonisent agressivement des planètes vides, attaquent les planètes isolées. Déclenchée par un seuil (ex : nombre de planètes joueurs actifs, temps écoulé depuis la dernière vague).
2. **Phase de consolidation** : renforcent les planètes colonisées, moins d'attaques actives.
3. **Événement global** : si les Nexhianti atteignent un seuil de planètes contrôlées, un événement global est déclenché — alerte tous les joueurs et force la coopération inter-alliances pour les repousser.
4. **Phase de rétractation** : après une défaite collective ou l'événement global résolu, les Nexhianti perdent leurs planètes et se reconstituent à partir de planètes vides.

**Diplomatie** : aucune. Réputation sans effet. Aucun échange possible.

---

### Architecture IA des factions

**Phase 1 — Comportements scriptés + LLM (MVP)**

- Les règles de décision (qui attaquer, quand, avec quoi) sont codées en Ruby (scripts).
- Le LLM intervient pour :
  - Choisir parmi les actions disponibles selon le contexte (état des ressources, carte, joueurs voisins)
  - Générer les messages narratifs des factions (déclarations de guerre, propositions commerciales, alertes Nexhianti)
  - Donner de la variété et de la personnalité aux décisions sans les rendre imprévisibles au point de casser l'équilibrage

**Phase 2 — Agents ReAct autonomes (évolution)**

- Migration faction par faction vers des agents plus autonomes.
- Candidat naturel pour la première migration : **les Nexhianti** (comportement chaotique, imprévisible par design, pas de diplomatie à gérer).
- Les agents perçoivent l'état du jeu, raisonnent et planifient de façon autonome.

---

## 9. Alliances & diplomatie

### Structure des alliances

- Une **alliance** est un regroupement de joueurs avec une identité commune — équivalent des alliances dans Ogame.
- Chaque joueur peut créer ou rejoindre une alliance, ou rester **solo** (pleinement viable mais sans les avantages du collectif).
- Le **type** de l'alliance fait partie de son nom et est choisi librement par ses membres : Empire, Alliance, Confédération, République, Collectif, etc.
- Les trois factions IA sont des entités permanentes de la carte avec leurs propres identités : l'Empire Varek, la Confédération Elyrans, les Nexhianti.

### Relations entre alliances

Les alliances humaines peuvent définir des statuts diplomatiques entre elles :

- Non-agression
- Alliance
- Guerre déclarée

> **Note** : ces statuts sont pour l'instant **informatifs uniquement**, sans impact mécanique sur le gameplay. Des effets concrets (partage de vision radar, attaques coordonnées, etc.) pourront être ajoutés en v2.

### Réputation avec les factions IA

- La réputation est **individuelle** — elle ne se transfère pas en rejoignant ou quittant une alliance.
- Un **modificateur alliance** s'applique à la marge : les actions collectives de l'alliance affectent légèrement la réputation de chaque membre (à définir lors de l'équilibrage).

---

## 10. Interface — Page planète

La page planète est la page principale du jeu. Le joueur y revient en permanence pour gérer ses bâtiments, surveiller ses ressources et préparer ses flottes.

### Structure générale

La page se compose de quatre zones :

- **Barre de navigation** (en haut) : accès aux sections Planète, Galaxie, Flottes, Diplomatie, Classement
- **Barre de ressources** (permanente) : Énergie (capacité installée/max + jauge), Métal, Nourriture, Thorium — valeurs calculées à la volée, taux de production affiché
- **En-tête planète** : nom, coordonnées `[x : y]`, badge "Origine" si `is_home`, actions rapides (Envoyer flotte, Espionner, Coloniser)
- **Zone centrale** : vue orbitale ou liste des bâtiments (toggle)
- **Panneau latéral droit** : détail du bâtiment sélectionné (upgrade), file de construction, résumé des flottes, alertes

### Vue orbitale (défaut desktop)

La planète est représentée en SVG inline, centrée dans la zone d'affichage sur un fond étoilé. Un anneau orbital en pointillés entoure la planète pour matérialiser l'espace orbital.

**Emplacements de bâtiments** : 12 emplacements fixes répartis sur la planète, dont 1 orbital (satellite radar, positionné sur l'anneau hors de la planète). Tous les emplacements sont visibles dès le début — libres ou occupés.

**Placement libre** : le joueur choisit sur quel emplacement construire chaque bâtiment. Une fois posé, le bâtiment ne bouge plus. Clic sur un emplacement libre → dropdown de sélection parmi les bâtiments disponibles non encore construits.

**Pins de bâtiments** : chaque bâtiment construit est représenté par un pin cliquable. L'apparence du pin évolue avec le niveau :

| Niveau | Taille | Icône                 | Style                             |
| ------ | ------ | --------------------- | --------------------------------- |
| 1–2    | 28px   | Outline (70% opacité) | Bordure fine                      |
| 3–4    | 32px   | Pleine (100%)         | Bordure normale                   |
| 5+     | 36px   | Pleine + halo pulsé   | Bordure accentuée + animation CSS |

Le halo de niveau 5+ est une animation `@keyframes` CSS sur le `box-shadow` — pas de librairie externe. La couleur d'icône varie selon la catégorie du bâtiment (énergie → or, militaire → rouge, orbital → cyan, etc.). Un bâtiment en cours d'amélioration affiche une barre de progression animée sous son pin.

**Clic sur un pin** → sélection du bâtiment, affichage du détail dans le panneau droit (coûts de l'upgrade suivant, ressources disponibles/manquantes colorées, durée estimée, bouton lancer).

### Vue liste (mobile et préférence joueur)

Toggle en haut de la zone centrale. Bâtiments groupés par catégorie (Énergie, Production, Infrastructure, Militaire, Stockage). Même interaction clic → panneau droit. Vue liste par défaut sur mobile, vue orbitale par défaut sur desktop. Le choix est mémorisé côté client.

### File de construction

Un seul bâtiment peut être en construction à la fois (un slot, extensible via recherche technologique). La file est visible dans le panneau droit avec le temps restant et la barre de progression (timer live via Turbo Streams).

---

## 11. Architecture technique & agents IA

### Stack technique

_Stack confirmée et en cours d'implémentation._

| Composant         | Technologie                                     |
| ----------------- | ----------------------------------------------- |
| Backend           | Ruby on Rails 8                                 |
| Frontend socle    | Hotwire (Turbo + Stimulus)                      |
| Build JS          | Vite (`vite_rails`)                             |
| CSS               | Tailwind CSS                                    |
| Frontend complexe | React (islands)                                 |
| Carte galaxie     | Pixi.js (WebGL)                                 |
| Base de données   | PostgreSQL                                      |
| Jobs asynchrones  | Sidekiq                                         |
| Temps réel        | ActionCable + Turbo Streams                     |
| Authentification  | `rails generate authentication` (Rails 8 natif) |
| IA en jeu         | API Anthropic                                   |
| Observabilité LLM | Langfuse                                        |
| Mobile            | Capacitor (PWA → App Store / Google Play)       |
| Déploiement       | Docker Compose (dev) + Kamal (prod)             |
| Hébergement       | Infomaniak VPS Lite — worldofstars.fr           |

### Gestion du temps de jeu

- **Production de ressources** : continue, calculée à la volée (`last_updated_at`)
- **Construction / amélioration de bâtiments** : durée absolue, job Sidekiq schedulé à la fin
- **Déplacements de flottes** : durée = f(distance), job Sidekiq schedulé à l'arrivée
- **Résolution des combats** : à l'arrivée de la flotte (même job)
- **Déplacements par portail** : durée fixe, même mécanique Sidekiq
- **Comportements des factions IA** : jobs Sidekiq récurrents, appels LLM ponctuels lors des prises de décision

### Utilisation de l'IA dans le développement

L'IA est utilisée comme outil de développement à tous les niveaux, au-delà des agents en jeu :

- **Claude Code** : développement assisté, génération de code, refactoring
- **Revue de code** : analyse et suggestions via Claude
- **Tests automatisés** : génération de cas de test, notamment pour les formules d'équilibrage (combat, exploration)
- **Génération de contenu** : noms de planètes, descriptions de missions d'exploration, événements narratifs Nexhianti
- **Support joueurs** : agent capable de répondre aux questions sur les règles du jeu
- **Équilibrage assisté** : analyse des données de jeu et suggestions d'ajustements de paramètres
- **SEO / marketing** : génération de contenu, optimisation
- **Documentation** : génération et maintenance des docs techniques

---

## 12. Questions ouvertes & équilibrage futur

Ces points sont intentionnellement non tranchés dans cette version du document. Ils seront résolus lors des phases de développement et de test.

| Sujet                                           | État             | Note                                                                                                                             |
| ----------------------------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------- | --- |
| Coût d'utilisation du Portail quantique         | À définir        | Coût fixe ou variable en Thorium ? Favorise les décisions stratégiques                                                           |
| Iris — bonus de défense portail                 | Design retenu    | Bonus de défense aux unités en défense contre un assaut **par portail**, croissant avec le niveau du portail. Valeurs à chiffrer |     |
| Nombre maximum de planètes                      | Base : 3         | À réévaluer lors des tests d'équilibrage                                                                                         |
| Capacité du bunker                              | À équilibrer     | Doit protéger sans éliminer tout le risque                                                                                       |
| Modificateur alliance sur la réputation Elyrans | À définir        | Principe acté, valeurs à équilibrer                                                                                              |
| Seuil minimum de planètes Varek/Elyrans         | À définir        | Garantit la survie des factions, valeur à fixer selon la taille du serveur                                                       |
| Seuils de déclenchement des vagues Nexhianti    | À définir        | Basé sur nombre de planètes contrôlées ou temps                                                                                  |
| Fenêtre de vulnérabilité                        | **Supprimée**    | Remplacée par le système bunker                                                                                                  |
| Archéologue et or                               | **Reporté**      | Mécanique retirée du scope actuel, à reconsidérer en v2                                                                          |
| Bombardement orbital                            | À définir        | Flottes sans troupes au sol : dégâts purs sans butin ? À définir avec les vaisseaux                                              |
| Bâtiments de défense statique                   | En réflexion     | Toute la défense passe par les unités pour l'instant ; tourelles/structures possibles plus tard                                  |
| Capacité de garnison (military_camp)            | Reporté          | Limiter le nombre d'unités stationnées par planète selon le niveau du camp                                                       |
| Unité d'escorte dédiée                          | **Écartée (v1)** | Les combattants remplissent ce rôle ; pas d'escorte dédiée au lancement                                                          |
| Modèle de combat au sol                         | **Tranché**      | Tir agrégé + paliers d'armure, sans PV — validé par simulation. Source de vérité : `combat_reference.md`              |
| Seuil de repli paramétrable par le joueur       | **Idée future**  | En v1 le seuil est automatique (55 %) ; le rendre choisi avant l'envoi en v2+                                                    |
| Unité officier (niv 7-10 military_camp)         | **Idée future**  | Unité survivable dont l'intelligence mènerait le tempo de l'armée (initiative = INT max)                                         |
| Contenu exact du rapport de combat              | À définir        | Pertes, butin, XP, survivants + volet narratif IA                                                                                |
| Formule exacte de l'espionnage                  | À implémenter    | Stat furtivité + quantité → détection/révélation                                                                                 |
| Formule exacte du repli (delta intelligence)    | **Tranché (v1)** | Auto à 55 % de pertes + plafond de statu quo à 18 rounds ; volée d'adieu = `clamp(0,5 − Δ/8, 0, 1,5)` (cf. `combat_reference.md`)                                                                |
| Monétisation                                    | À définir en v2  | Hors scope pour le développement initial                                                                                         |
| Arbre technologique complet                     | **Structuré**    | Structure et roster validés — voir `tech_reference.md`. Reste : valeurs d'équilibrage                                            |
| Liste complète des vaisseaux                    | À construire     | Voir Annexes                                                                                                                     |
| Roster complet des unités terrestres            | **En cours**     | Voir `unit_reference.md`                                                                                                         |
| Mécaniques d'alliance avancées                  | À définir en v2  | Partage radar, attaques coordonnées, etc.                                                                                        |

---

## 13. Annexes

### Annexe A — Arbre technologique

_Structure validée — voir `tech_reference.md` pour le document de référence complet (roster, prérequis, structure de données)._

**Principes :** arbre **hybride** de technologies **à niveaux** (on améliore plusieurs fois la même techno). Chaque technologie a son propre niveau maximum. Bonus de combat **globaux** (toutes unités) pour l'instant. **Pas d'orientation stratégique imposée** : tous les joueurs accèdent au même arbre, les prérequis créent un ordre de progression naturel.

**Pacing :** le niveau du `research_lab` **plafonne le niveau maximum de chaque technologie**, comme le `command_center` plafonne les bâtiments. `niveau_utile = min(plafond_labo, niveau_max_techno)`.

**Prérequis (3 leviers superposés) :**

- **Niveau de laboratoire** — plafond global.
- **Cross-dépendances** — une techno peut exiger un niveau minimum d'une autre techno.
- **Exploration** — appliqué directement sur certaines technologies « breakthrough ». L'exploration (découverte scientifique) est la **porte d'entrée du palier avancé** ; le palier initial reste accessible sans explorer.

**File de recherche :** propre au `research_lab`, distincte des files de construction et de production. Une recherche à la fois.

Les technologies servent à :

- Augmenter la production de ressources (métal, nourriture, thorium) et l'énergie
- Réduire la consommation énergétique des bâtiments
- Améliorer les capacités de combat (attaque, défense, intelligence — bonus globaux)
- Ajouter des files de construction et de production d'unités
- Améliorer les gains et la sécurité de l'exploration
- _(Anticipé)_ Débloquer la colonisation de planètes supplémentaires (jusqu'à 3 max)
- _(Anticipé)_ Améliorer les capacités d'espionnage

**Périmètre initial** (11 technos) : Conversion énergétique, Supraconductivité, Forage cristallin, Hydroponie, Raffinage du thorium, Armement, Blindage tactique, Guerre électronique, Ingénierie parallèle, Chaîne de production, Cartographie stellaire.

**Anticipé** (conçu, implémenté avec la fonctionnalité) : Cœur de thorium (exploration), Renseignement (espionnage), Colonisation (colonisation + vaisseau).

**Évolutions futures notées** : Régénération cellulaire (résurrection d'unités post-combat), vitesse de recherche, capacité de stockage, files de recherche parallèles, bonus de combat ciblés par type, branche spatiale/vaisseaux, technologies exclusives via diplomatie Elyrans.

### Annexe B — Vaisseaux

_À construire._

Types connus à ce stade : chasseurs, vaisseaux mères, transporteurs, bombardiers, vaisseau de colonisation.

### Annexe C — Unités terrestres

_En cours de définition — voir `unit_reference.md` pour le document de référence complet._

**Roster défini** : **Maraudeur** (offensif), **Sentinelle** (défensif), **Régulier** (polyvalent), **Scientifique** (exploration), **Sonde** (recon-exploration), **Spectre** (recon-espionnage), **Mule** (transport). Les anciens noms « léger / lourd / Malp / UAV / archéologue » sont abandonnés. Stats et logistique : voir `unit_reference.md`. Modèle de combat : voir `combat_reference.md`.

**Principes de production** : toutes les unités sont produites dans le `training_camp` (niveau ↑ = temps ↓). Les types d'unités sont débloqués par le `military_camp`, avec des dépendances multiples possibles (ex : scientifique = military_camp + research_lab). Files de production parallèles supplémentaires débloquées par technologie. Coût en métal/nourriture/thorium + temps. Pas d'entretien (coût unique).

**Stats** : Attaque, Défense, Intelligence, Transport, Exploration, Espionnage. Pas de PV (défense = palier d'armure ; tuer exige de concentrer le feu — cf. `combat_reference.md`). Pas de vitesse (unités terrestres = charge utile). Toutes les stats sont modifiables par technologies.

### Annexe D — Équilibrage des ressources

_À construire lors des phases de test._

Inclura : coûts de construction par niveau de bâtiment, coûts de recherche technologique, coûts de production des unités et vaisseaux, taux de production des mines et champs selon le niveau.

### Annexe E — Palette de couleurs & identité visuelle

Direction artistique : sci-fi sombre et immersif. Interface sobre avec des accents colorés porteurs de sens (faction, statut, catégorie).

```css
:root {
  /* Fonds */
  --color-space-bg: #0d0e12; /* fond principal — espace */
  --color-space-bg-2: #14151c; /* fond secondaire */
  --color-surface: #1c1d27; /* cartes, panneaux */
  --color-border: #2a2b38; /* bordures */

  /* Typographie */
  --color-text: #e8e4d8; /* texte principal */
  --color-text-muted: #a09e96; /* texte secondaire */
  --color-text-subtle: #5e5d58; /* texte discret, emplacements vides */

  /* Interface */
  --color-primary: #c8a96e; /* or/ambre — accent principal, énergie */
  --color-secondary: #4e8faf; /* bleu-gris — infrastructure, secondaire */
  --color-quantum: #2ec4a0; /* cyan-vert — portail quantique, orbital */

  /* Catégories de bâtiments */
  --color-energy: #e9d454; /* or — énergie */
  --color-production: #4e8faf; /* bleu-gris — production */
  --color-storage: #a09e96; /* gris — stockage */
  --color-infra: #8b7fcc; /* violet — infrastructure */
  --color-orbital: #2ec4a0; /* cyan — orbital */
  --color-military: #e8622a; /* orange-rouge — militaire */

  /* Factions */
  --color-varek: #e8622a; /* orange-rouge */
  --color-varek-dark: #a83d16;
  --color-varek-bg: #1a0e0a;
  --color-alert: #cc0000;
  --color-warning: #ee8800;
  --color-elyrans: #5bc4d4; /* bleu clair */
  --color-elyrans-dark: #2e91a4;
  --color-elyrans-bg: #080f18;
  --color-nexhianti: #b87fe8; /* violet */
  --color-nexhianti-dark: #8448c2;
  --color-nexhianti-bg: #0e0914;
}
```

**Codage couleur des catégories de bâtiments (pins vue orbitale) :**

| Catégorie                 | Token                | Valeur    |
| ------------------------- | -------------------- | --------- |
| Énergie                   | `--color-energy`     | `#e9d454` |
| Production                | `--color-production` | `#4e8faf` |
| Stockage                  | `--color-storage`    | `#a09e96` |
| Infrastructure            | `--color-infra`      | `#8b7fcc` |
| Orbital (satellite radar) | `--color-orbital`    | `#2ec4a0` |
| Militaire                 | `--color-military`   | `#e8622a` |

---

_Document vivant — à mettre à jour au fil du développement._
