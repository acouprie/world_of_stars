# World of Stars — Document de Game Design
> Version 0.3 — Document de référence projet
> Auteur : Antoine Couprie
> Statut : En cours — annexes à compléter

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

| Statut (`planet_type`) | Description |
|---|---|
| `player` | Assignée à un joueur à l'inscription ou colonisée/conquise |
| `ai_faction` | Appartenant aux factions l'Empire Varek, la Confédération Elyrans ou les Nexhianti |
| `empty` | Non assignée, colonisable et explorable |

Chaque planète possède également un **type visuel** (indépendant du statut de possession) qui détermine son apparence graphique :

| Type visuel | Apparence |
|---|---|
| `oceanic` | Monde aquatique, tons bleus profonds |
| `arid` | Surface désertique, tons ocre et sable |
| `volcanic` | Monde instable, tons rouge sombre et gris |
| `glacial` | Monde gelé, tons blanc et cyan |
| `forest` | Monde végétal, tons vert foncé et brun |

Le type visuel est dérivé de façon déterministe depuis l'identifiant de la planète (`id % 5`) — chaque planète a donc toujours le même skin, sans colonne supplémentaire en base.

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

| Ressource | Type | Production | Rôle |
|---|---|---|---|
| **Énergie** | Capacité installée | Centrales solaires, centrales à fission | Prérequis structurel pour les bâtiments |
| **Métal** | Stock | Mine de métaux | Construction, recherche, unités |
| **Nourriture** | Stock | Champs agricoles | Construction, recherche, unités |
| **Thorium** | Stock | Mine de thorium | Construction, recherche, unités |

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
| Bâtiment | Rôle |
|---|---|
| Centrale solaire | Production d'énergie de base |
| Centrale à fission nucléaire | Production d'énergie avancée (upgrade de la solaire) |

#### Production de ressources
| Bâtiment | Ressource produite |
|---|---|
| Champs agricoles | Nourriture |
| Mine de métaux | Métal |
| Mine de thorium | Thorium |

#### Stockage
| Bâtiment | Ressource stockée |
|---|---|
| Silo de nourriture | Nourriture |
| Entrepôt de métal | Métal |
| Entrepôt de thorium | Thorium |

#### Infrastructure & science
| Bâtiment | Rôle |
|---|---|
| Centre de commandement | Hub logistique central, prérequis pour de nombreuses constructions |
| Laboratoire | Recherche technologique, amélioration des capacités |
| Portail quantique | Téléportation inter-planétaire (déplacements et attaques) |
| Satellite radar | Détection des mouvements ennemis (voir ci-dessous) |

#### Infrastructure militaire
| Bâtiment | Rôle |
|---|---|
| Camp d'entraînement | Accès aux types de soldats selon le niveau |
| Camp militaire | Formation de soldats et de scientifiques |
| Usine spatiale | Construction de vaisseaux |
| Bunker | Protection des ressources et soldats (capacité limitée) |

### Satellite radar — niveaux de détection
| Niveau | Capacité |
|---|---|
| 1 | Détecte la présence d'une flotte en orbite |
| 2 | Révèle le pseudo du joueur propriétaire |
| 4 | Révèle la composition de la flotte en orbite |
| 5-7-9 | Détecte les flottes en approche selon une distance croissante |

### Portail quantique — contraintes
- Nécessite d'être construit sur la planète de départ **et** sur la planète de destination.
- **Ne pas construire de portail = immunité aux attaques par portail** (choix stratégique délibéré).
- Consomme de l'énergie de capacité comme tout bâtiment.
- *Note : un coût en ressources par utilisation (Thorium ?) est envisagé mais non tranché — voir questions ouvertes.*

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
- **Bunker** : protège ressources et soldats à hauteur de sa capacité.
- **Pas de portail** : immunité aux attaques par portail (choix stratégique).

---

## 6. Combat & espionnage

### Résolution des combats
- Les combats se résolvent **à l'arrivée de la flotte** attaquante sur la planète cible.
- L'ordre d'attaque est déterminé par l'**intelligence** des unités (moyenne pondérée de toutes les troupes engagées). Certaines technologies peuvent augmenter ou diminuer l'intelligence ennemie.
- Une attaque implique un aller **et** un retour pour les vaisseaux survivants.

### Résultats d'une attaque réussie
- Pillage d'une fraction des ressources non protégées par le bunker.
- Destruction partielle ou totale des défenses et unités non protégées.
- **Conquête** possible si les conditions sont remplies (planète non originelle, victoire totale).

### Système d'XP combat
- Les joueurs gagnent de l'XP en détruisant des unités ennemies lors des combats.
- L'XP est associée **au joueur**, pas aux unités — elle sert uniquement au **classement** et n'a pas d'impact mécanique sur le gameplay.
- Le niveau 1 commence à 400 pts d'XP, chaque niveau suivant nécessite x1.2 pts supplémentaires.
- Les gains d'XP sont multipliés par 1.0292 à chaque passage de niveau.
- **L'XP se cumule** — l'excédent au passage de niveau n'est pas perdu.

#### Gains d'XP par unité détruite
| Unité détruite | XP gagnée |
|---|---|
| 1 unité légère | 0.3 XP |
| 1 unité lourde | 0.5 XP |
| 1 scientifique | 0.7 XP |
| 1 archéologue | 0.9 XP |
| 1 Malp (équivalent) | 2 XP |
| 1 UAV (équivalent) | 3 XP |

#### Multiplicateurs — victoire sans pertes
| Écart de force (attaquant / défenseur) | Multiplicateur XP |
|---|---|
| Plus de 20x | x1 (pas de bonus) |
| 15x à 20x | x3 |
| 10x à 15x | x5 |
| 5x à 10x | x10 |
| Moins de 5x | x15 |

### Espionnage
- Deux types d'unités d'espionnage : **Malp** (équivalent terrestre) et **UAV** (reconnaissance avancée).
- Une mission d'espionnage dure **5 minutes**.
- Plus on envoie d'unités, plus on obtient d'informations — mais plus le risque de se faire détecter est élevé.
- Si détecté, le joueur ciblé reçoit une notification dans sa messagerie.
- L'envoi de **5 unités** est généralement le bon compromis (bonne visibilité, risque de détection limité).

#### Niveaux de visibilité selon les unités envoyées
| Information révélée | Unité requise |
|---|---|
| Bâtiments | Malp |
| Unités terrestres | Malp |
| Ressources | Malp |
| Technologies | Malp (niveau technologie espionnage ≥ cible) |
| Vaisseaux en orbite | UAV uniquement |

- Formation d'un Malp ou UAV : **15 minutes**.
- 10 niveaux de technologie d'espionnage.

---

## 7. Exploration

### Principe
- Les planètes vides (non assignées) sont **explorables**.
- Une mission d'exploration envoie une équipe d'unités sur une planète vide.
- Résultats : **points de technologie** (XP exploration), **ressources** (aléatoire), **rapport de mission narratif** généré par IA.
- L'exploration se fait soit par vaisseau, soit par portail.

### Durée d'une expédition
- Durée de base : **20 minutes**
- **+1 minute par unité** ajoutée à l'équipe (une grande équipe = une expédition longue)

### Unités d'exploration et leurs rôles

| Unité | XP de base | Transport ressources | Particularités |
|---|---|---|---|
| Scientifique | 33 XP (seul) | 75 de chaque ressource | XP croissant avec le nombre, risque de pertes croissant |
| Archéologue | 31 XP (seul) | 75 de chaque ressource | Chance de ramener de l'or — mécanique à définir |
| Lourd | 30 XP fixe | 200 de chaque ressource | Réduit le risque de pertes des scientifiques/archéologues |
| Léger | 30 XP fixe | 100 de chaque ressource | Réduit le risque de pertes (moins efficace que lourd) |
| Malp | 30 XP fixe | 1000 de chaque ressource | Aucune perte possible |
| UAV | 30 XP fixe | Aucun transport | Aucune perte possible |

### Règles générales d'exploration
- **Chance de gagner des ressources : 20%** peu importe les unités envoyées. La quantité varie entre 50% et 100% de la capacité de transport de l'équipe.
- **Une équipe ne peut jamais être totalement exterminée** : si une seule unité est envoyée, aucune perte possible.
- La quantité de pertes est égale au pourcentage de risque calculé.
- Les XP gagnés ont une **variation de ±5%** (résultat non déterministe).
- En présence de Scientifiques ou d'Archéologues, les 30 XP des Lourds et Légers **ne sont pas comptabilisés** (annulés).
- L'XP des Scientifiques et Archéologues **s'additionne**.

### Calcul du risque — Scientifiques
- 1 Scientifique seul = 11% de risque de pertes → 33 XP
- Chaque Scientifique supplémentaire = +1% de risque
- 90 Scientifiques = 100% de risque → 300 XP
- Au-delà de 100% : +3 XP par Scientifique supplémentaire
- **Formule XP** : `% de risque × 3 = XP`
- Les unités Lourdes/Légères réduisent le risque global selon leur proportion dans l'équipe

### Calcul du risque — Archéologues
- 1 Archéologue seul = 10% de risque → 31 XP
- Chaque Archéologue supplémentaire = +1% de risque
- **Formule XP** : `31 + (nombre_archéologues - 1) × 1.5`
- Même mécanique de réduction du risque avec Lourds/Légers que pour les Scientifiques

### Niveaux d'exploration
- L'XP d'exploration est associée **au joueur**, pas aux unités — elle sert au **classement** et n'a pas d'impact mécanique sur le gameplay.
- Niveau 1 : 400 XP requis
- Chaque niveau suivant : XP requis × 1.2
- Gains d'XP par exploration multipliés par 1.0292 à chaque passage de niveau
- **L'XP se cumule** — l'excédent au passage de niveau n'est pas perdu

### Points de technologie
- L'exploration de planètes vides génère des **points de technologie** utilisés pour progresser dans l'arbre technologique.
- Ces points débloquent de nouveaux bâtiments, unités, vaisseaux et améliorations de production.
- *L'arbre technologique complet est à définir — voir Annexes.*

---

## 8. Factions IA

### Vue d'ensemble

| Faction | Nom complet | Archétype | Comportement général | Diplomatie |
|---|---|---|---|---|
| **Varek** | L'Empire Varek | Agressive, expansionniste | Raids fréquents, cible les joueurs faibles | Hostile par défaut, hostilité croissante avec les points du joueur |
| **Elyrans** | La Confédération Elyrans | Neutre, technologiquement avancée | Jamais agressive sauf provocation | Neutre par défaut, réputation améliorable par le commerce |
| **Nexhianti** | Les Nexhianti | Menace globale, chaotique | Expansion par vagues, phases de rétractation | Aucune diplomatie possible |

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

| Niveau | Taille | Icône | Style |
|---|---|---|---|
| 1–2 | 28px | Outline (70% opacité) | Bordure fine |
| 3–4 | 32px | Pleine (100%) | Bordure normale |
| 5+ | 36px | Pleine + halo pulsé | Bordure accentuée + animation CSS |

Le halo de niveau 5+ est une animation `@keyframes` CSS sur le `box-shadow` — pas de librairie externe. La couleur d'icône varie selon la catégorie du bâtiment (énergie → or, militaire → rouge, orbital → cyan, etc.). Un bâtiment en cours d'amélioration affiche une barre de progression animée sous son pin.

**Clic sur un pin** → sélection du bâtiment, affichage du détail dans le panneau droit (coûts de l'upgrade suivant, ressources disponibles/manquantes colorées, durée estimée, bouton lancer).

### Vue liste (mobile et préférence joueur)

Toggle en haut de la zone centrale. Bâtiments groupés par catégorie (Énergie, Production, Infrastructure, Militaire, Stockage). Même interaction clic → panneau droit. Vue liste par défaut sur mobile, vue orbitale par défaut sur desktop. Le choix est mémorisé côté client.

### File de construction

Un seul bâtiment peut être en construction à la fois (un slot, extensible via recherche technologique). La file est visible dans le panneau droit avec le temps restant et la barre de progression (timer live via Turbo Streams).

---

## 11. Architecture technique & agents IA

### Stack technique
*Stack confirmée et en cours d'implémentation.*

| Composant | Technologie |
|---|---|
| Backend | Ruby on Rails 8 |
| Frontend socle | Hotwire (Turbo + Stimulus) |
| Build JS | Vite (`vite_rails`) |
| CSS | Tailwind CSS |
| Frontend complexe | React (islands) |
| Carte galaxie | Pixi.js (WebGL) |
| Base de données | PostgreSQL |
| Jobs asynchrones | Sidekiq |
| Temps réel | ActionCable + Turbo Streams |
| Authentification | `rails generate authentication` (Rails 8 natif) |
| IA en jeu | API Anthropic |
| Observabilité LLM | Langfuse |
| Mobile | Capacitor (PWA → App Store / Google Play) |
| Déploiement | Docker Compose (dev) + Kamal (prod) |
| Hébergement | Infomaniak VPS Lite — worldofstars.fr |

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

| Sujet | État | Note |
|---|---|---|
| Coût d'utilisation du Portail quantique | À définir | Coût fixe ou variable en Thorium ? Favorise les décisions stratégiques |
| Nombre maximum de planètes | Base : 3 | À réévaluer lors des tests d'équilibrage |
| Capacité du bunker | À équilibrer | Doit protéger sans éliminer tout le risque |
| Modificateur alliance sur la réputation Elyrans | À définir | Principe acté, valeurs à équilibrer |
| Seuil minimum de planètes Varek/Elyrans | À définir | Garantit la survie des factions, valeur à fixer selon la taille du serveur |
| Seuils de déclenchement des vagues Nexhianti | À définir | Basé sur nombre de planètes contrôlées ou temps |
| Fenêtre de vulnérabilité | **Supprimée** | Remplacée par le système bunker |
| Rôle de l'or et des archéologues | À creuser | Mécanique intéressante, à définir en v2 |
| Monétisation | À définir en v2 | Hors scope pour le développement initial |
| Arbre technologique complet | À construire | Voir Annexes |
| Liste complète des vaisseaux | À construire | Voir Annexes |
| Mécaniques d'alliance avancées | À définir en v2 | Partage radar, attaques coordonnées, etc. |

---

## 13. Annexes

### Annexe A — Arbre technologique
*À construire.*

Les technologies servent à :
- Débloquer des bâtiments, unités et vaisseaux
- Augmenter la production de ressources
- Améliorer les capacités de combat (attaque, défense, intelligence)
- Améliorer les chances de succès et les gains d'exploration
- Débloquer la colonisation de planètes supplémentaires (jusqu'à 3 max)
- Améliorer les capacités d'espionnage

### Annexe B — Vaisseaux
*À construire.*

Types connus à ce stade : chasseurs, vaisseaux mères, transporteurs, bombardiers, vaisseau de colonisation.

### Annexe C — Unités terrestres
*À construire.*

Types connus à ce stade : unités légères, unités lourdes, scientifiques, archéologues, Malp (équivalent), UAV (équivalent).

### Annexe D — Équilibrage des ressources
*À construire lors des phases de test.*

Inclura : coûts de construction par niveau de bâtiment, coûts de recherche technologique, coûts de production des unités et vaisseaux, taux de production des mines et champs selon le niveau.

### Annexe E — Palette de couleurs & identité visuelle

Direction artistique : sci-fi sombre et immersif. Interface sobre avec des accents colorés porteurs de sens (faction, statut, catégorie).

```css
:root {
  /* Fonds */
  --color-space-bg: #0d0e12;     /* fond principal — espace */
  --color-space-bg-2: #14151c;   /* fond secondaire */
  --color-surface: #1c1d27;      /* cartes, panneaux */
  --color-border: #2a2b38;       /* bordures */

  /* Typographie */
  --color-text: #e8e4d8;         /* texte principal */
  --color-text-muted: #a09e96;   /* texte secondaire */
  --color-text-subtle: #5e5d58;  /* texte discret, emplacements vides */

  /* Interface */
  --color-primary: #c8a96e;      /* or/ambre — accent principal, énergie */
  --color-secondary: #4e8faf;    /* bleu-gris — infrastructure, secondaire */
  --color-quantum: #2ec4a0;      /* cyan-vert — portail quantique, orbital */

  /* Factions */
  --color-varek: #e8622a;        /* orange-rouge */
  --color-varek-dark: #a83d16;
  --color-varek-bg: #1a0e0a;
  --color-elyrans: #5bc4d4;      /* bleu clair */
  --color-elyrans-dark: #2e91a4;
  --color-elyrans-bg: #080f18;
  --color-nexhianti: #b87fe8;    /* violet */
  --color-nexhianti-dark: #8448c2;
  --color-nexhianti-bg: #0e0914;
}
```

**Codage couleur des catégories de bâtiments (pins vue orbitale) :**

| Catégorie | Couleur |
|---|---|
| Énergie | `--color-primary` (or) |
| Production | `--color-secondary` (bleu-gris) |
| Infrastructure | `--color-secondary` |
| Militaire | `--color-varek` (orange-rouge) |
| Stockage | `--color-text-muted` (gris) |
| Orbital (satellite radar) | `--color-quantum` (cyan) |

---

*Document vivant — à mettre à jour au fil du développement.*