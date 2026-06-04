# World of Stars — Référence des unités terrestres

> Version 0.1 — Document de conception
> Complément au game_design.md et building_reference.md
> Statut : principes validés, roster en cours de définition

---

## Table des matières

1. [Principes généraux](#1-principes-généraux)
2. [Catégories et rôles](#2-catégories-et-rôles)
3. [Statistiques](#3-statistiques)
4. [Production des unités](#4-production-des-unités)
5. [Mouvement](#5-mouvement)
6. [Combat](#6-combat)
7. [Exploration](#7-exploration)
8. [Espionnage](#8-espionnage)
9. [Roster des unités](#9-roster-des-unités)
10. [Questions ouvertes](#10-questions-ouvertes)

---

## 1. Principes généraux

Les unités terrestres constituent l'armée du joueur. Elles sont la **charge utile** — elles ne se déplacent jamais seules et nécessitent un porteur (portail quantique ou vaisseau) pour agir sur une autre planète.

Chaque unité est définie par un coût de production (métal, nourriture, thorium, temps) et un ensemble de statistiques. **Aucune unité n'a de coût d'entretien** : le coût de production est unique. Les statistiques de base sont modifiables par les **technologies** (bonus d'attaque, de défense, d'intelligence, etc.).

Les anciens noms issus de World of Stargate (léger, lourd, Malp, UAV, archéologue) sont abandonnés au profit de noms originaux dans l'univers World of Stars. Le roster définitif est en cours de définition (voir section 9).

---

## 2. Catégories et rôles

### Combat

Trois archétypes minimum, définis par la balance attaque/défense :

| Archétype  | Profil                        | Rôle                        |
| ---------- | ----------------------------- | --------------------------- |
| Offensif   | Attaque haute, défense faible | Raids, assauts rapides      |
| Défensif   | Défense haute, attaque faible | Garnison, tenue de position |
| Polyvalent | Attaque/défense équilibrées   | Ligne de front, flexibilité |

_D'autres variantes mid-range peuvent être ajoutées si le gameplay le justifie._

### Scientifique (exploration)

Génère des **points d'exploration** qui alimentent les **niveaux d'exploration** du joueur. Ces niveaux peuvent être un prérequis pour certaines technologies. Capacité de transport modérée.

En exploration, plus on en envoie, plus on gagne d'XP — mais plus le risque de pertes augmente (formule détaillée en section 7).

### Reconnaissance — double usage exploration/espionnage

Deux unités à profil asymétrique :

| Profil            | Domaine principal                 | Domaine secondaire  | Transport |
| ----------------- | --------------------------------- | ------------------- | --------- |
| Recon-exploration | Exploration (bonus XP/ressources) | Espionnage limité   | Élevé     |
| Recon-espionnage  | Espionnage (furtivité élevée)     | Exploration limitée | Aucun     |

Les deux possèdent le trait **« aucune perte en exploration »** (PvE uniquement). En combat PvP, elles sont vulnérables comme n'importe quelle unité.

Le coût et/ou le temps de production de l'unité orientée espionnage est **plus élevé** que celle orientée exploration, pour refléter la spécialisation.

### Transport

Unité dédiée au convoi de ressources. Profil :

- **Attaque : 0** — ne combat jamais, quel que soit le contexte.
- **Défense : faible mais non nulle** — peut encaisser un coup mais ne riposte pas.
- **Transport : très élevé** — la plus haute capacité de transport de toutes les unités.

**Règle de combat** : une troupe composée uniquement de transports ne peut **jamais gagner un combat**, même contre une seule unité combattante. Cependant, si la planète ciblée n'a **aucune unité en défense**, les transports peuvent piller les ressources non protégées par le bunker.

**Usages** : don de ressources à un allié ; rapatriement du butin après un raid victorieux (escortés par des combattants).

### Escorte (à confirmer)

Les unités combattantes remplissent déjà un rôle d'escorte en exploration (réduction du risque de pertes des scientifiques). La question d'une unité **d'escorte dédiée** reste ouverte — elle pourrait offrir une réduction du risque supérieure aux combattants standards sans leurs stats d'attaque, créant un choix supplémentaire dans la composition d'équipe.

---

## 3. Statistiques

Chaque unité possède les statistiques suivantes. Toutes sont modifiables par technologies.

| Stat             | Rôle                                                              | Notes                                                |
| ---------------- | ----------------------------------------------------------------- | ---------------------------------------------------- |
| **Attaque**      | Dégâts infligés par round                                         | 0 pour les transports                                |
| **Défense**      | Seuil d'encaissement (pas de PV, destruction binaire)             | Un coup > défense = unité détruite                   |
| **Intelligence** | Ordre d'attaque en combat + efficacité du repli (attaquant)       | Moyenne pondérée de toutes les troupes engagées      |
| **Transport**    | Ressources transportables (par unité, pour chaque ressource)      | Sert au pillage, don, et exploration                 |
| **Exploration**  | Points d'exploration générés en mission                           | 0 pour la plupart des unités hors scientifique/recon |
| **Espionnage**   | Furtivité en mission d'espionnage (réduit le risque de détection) | Élevé pour la recon-espionnage                       |

**Pas de PV** : la défense est le seuil d'encaissement. Si un coup dépasse la défense, l'unité est détruite. Pas de dégâts partiels ni de points de vie résiduels.

**Pas de vitesse** : les unités terrestres sont une charge utile. Le temps de déplacement dépend du porteur (portail = fixe 20 min, vaisseau = distance). Les unités terrestres n'ont pas de stat de vitesse individuelle.

---

## 4. Production des unités

### Lieu de production

Toutes les unités sont produites dans le **training_camp**. C'est le seul bâtiment capable de produire des unités terrestres.

### Réduction du temps de production

Monter le niveau du training_camp **réduit le temps de production** de toutes les unités. La formule exacte de réduction par niveau est à définir.

### Files de production

Par défaut, **une seule file de production** (une unité à la fois). Des files parallèles supplémentaires sont débloquées par **technologie** (pas par le niveau du bâtiment). Cela sépare le choix stratégique « produire plus vite » (training_camp) de « produire en parallèle » (technologie).

### Déblocage des types d'unités

Les types d'unités sont débloqués par le **military_camp** selon son niveau. Certaines unités ont des **dépendances multiples** :

| Exemple              | Prérequis                                              |
| -------------------- | ------------------------------------------------------ |
| Unité combat basique | military_camp niv 1                                    |
| Scientifique         | military_camp niv X **+** research_lab niv Y           |
| Recon-espionnage     | military_camp niv X (+ éventuellement une technologie) |

_Le calendrier exact de déblocage sera défini avec le roster (section 9)._

### Coût de production

Chaque unité a un coût en **métal, nourriture, thorium** et un **temps de base** de production (réduit par le niveau du training_camp). **Pas de coût en énergie** pour la production d'unités. **Pas d'entretien** : le coût est payé une fois, l'unité existe ensuite sans drain.

---

## 5. Mouvement

Les unités terrestres ne traversent jamais la carte seules. Deux modes de transport :

### Portail quantique

- Durée fixe : **20 minutes** (indépendamment de la distance).
- Nécessite un portail sur la planète de départ **et** sur la planète de destination.
- Les planètes vides sont considérées comme ayant un **portail implicite** (exploration uniquement).
- **Contourne la couche orbitale** : un assaut par portail dépose les troupes directement au sol, sans affronter les vaisseaux en orbite.
- « Pas de portail = immunité aux attaques par portail » — construire un portail est un choix stratégique qui ouvre une vulnérabilité.
- **Iris** : mécanisme de défense débloqué par l'amélioration du portail quantique — bonus à la défense contre les assauts par portail. Comportement exact à définir.

### Vaisseau (reporté)

- Durée proportionnelle à la distance euclidienne entre les planètes.
- Nécessite un vaisseau capable de transporter des troupes.
- Doit franchir la **couche orbitale** avant le débarquement au sol.
- Un **vaisseau d'exploration unique** est disponible dès le lancement pour les joueurs sans portail (lent, faible capacité, peu de points d'exploration).
- Le roster complet de vaisseaux sera défini séparément.

---

## 6. Combat

_Résumé des règles de combat. Référence complète dans le `game_design.md`, section 6._

### Modèle en couches

1. **Couche orbitale** (vaisseaux, reportée) : sautée si arrivée par portail. Si le porteur est détruit, les troupes embarquées sont perdues.
2. **Couche au sol** : unités débarquées vs unités stationnées. C'est cette couche qui utilise les stats des unités terrestres.

### Résolution par rounds

- Les unités frappent dans l'**ordre d'intelligence** (moyenne pondérée du camp).
- Chaque coup est comparé à la **défense** de l'unité ciblée : si le coup dépasse la défense, l'unité est détruite.
- **Pas de plancher de pertes** : un attaquant écrasé peut être totalement anéanti.

### Repli (attaquant uniquement)

Le défenseur combat jusqu'au dernier. Seul l'attaquant peut se replier.

L'efficacité du repli dépend du **delta d'intelligence** : `intelligence_attaquant − intelligence_défenseur`.

- Delta positif → repli précoce, pertes minimisées.
- Delta nul → repli moyen.
- Delta négatif → le défenseur verrouille le champ de bataille, l'attaquant se replie difficilement, pertes lourdes.

_Les technologies modifiant l'intelligence affectent ce delta._

### Bunker

Mise à l'abri **consciente** d'unités par le joueur avant le combat. 1 unité = 1 slot, quel que soit le type. Les unités abritées ne combattent pas et sont immunisées.

### Pillage

L'attaquant doit **tenir le sol** (gagner l'engagement terrestre) pour piller. Les transporteurs se remplissent de ressources non protégées par le bunker.

### Rapport de combat

Un rapport est généré pour **l'attaquant et le défenseur**, incluant au minimum les pertes des deux camps, le butin, l'XP gagnée, les survivants, et un volet narratif généré par IA.

### XP de combat

- Associée au joueur (classement uniquement).
- Niveau 1 = 400 XP, chaque niveau × 1.2 pts requis.
- Gains × 1.0292 à chaque passage de niveau.
- **L'XP se cumule** (l'excédent n'est pas perdu).
- Multiplicateurs selon l'écart de force : >20× → ×1, 15–20× → ×3, 10–15× → ×5, 5–10× → ×10, <5× → ×15.

---

## 7. Exploration

_Résumé des règles d'exploration. Référence complète dans le `game_design.md`, section 7._

### Principe

Les planètes vides sont explorables. Une mission envoie une équipe d'unités qui génère des **points d'exploration** et peut ramener des **ressources** (20 % de chance, 50–100 % de la capacité de transport). Les niveaux d'exploration peuvent être prérequis de certaines technologies.

### Durée

- Base : **20 minutes** (par portail).
- **+1 minute par unité** ajoutée à l'équipe.

### Règle de sécurité PvE

- Une équipe **ne peut jamais être totalement exterminée**.
- 1 unité envoyée seule = aucune perte possible.
- Les unités de type reconnaissance ne subissent **jamais de pertes** en exploration (trait intrinsèque).
- _Cette règle est spécifique à l'exploration et ne s'applique **pas** au combat PvP._

### Scientifique — calcul du risque et de l'XP

- 1 seul = 11 % de risque → 33 XP.
- Chaque supplémentaire = +1 % de risque.
- 90 scientifiques = 100 % de risque → 300 XP.
- Au-delà de 100 % : +3 XP par scientifique supplémentaire.
- **Formule** : `% de risque × 3 = XP`.
- La quantité de pertes = le pourcentage de risque.
- XP avec une **variation de ±5 %** (non déterministe).

### Rôle de l'escorte

Les unités combattantes envoyées en exploration **réduisent le risque** de pertes des scientifiques proportionnellement à leur nombre dans l'équipe. En présence de scientifiques, les 30 XP fixes des combattants et transports **ne sont pas comptabilisés** (annulés).

_La formule de réduction du risque par l'escorte est à recalculer autour des unités offensives/défensives (qui remplacent les anciens lourds/légers)._

### Niveaux d'exploration

- Associés au joueur (peuvent être prérequis pour des technologies).
- Niveau 1 = 400 XP, chaque niveau × 1.2 pts requis.
- Gains × 1.0292 à chaque passage de niveau.
- **L'XP se cumule** (l'excédent n'est pas perdu).

---

## 8. Espionnage

_Résumé des règles d'espionnage. Référence complète dans le `game_design.md`, section 6._

### Principe

Une mission d'espionnage envoie des unités de reconnaissance sur une planète ennemie pour récolter des informations. Durée : **5 minutes**.

### Informations révélées (ordre progressif)

| Pallier | Information                                                    |
| ------- | -------------------------------------------------------------- |
| 1       | Bâtiments                                                      |
| 2       | Unités terrestres                                              |
| 3       | Ressources                                                     |
| 4       | Technologies (nécessite niveau techno espionnage ≥ cible)      |
| 5       | Vaisseaux en orbite (uniquement avec l'unité recon-espionnage) |

### Quantité vs furtivité

- **Plus d'unités envoyées** = plus d'informations révélées, mais **plus de risque de détection**.
- La stat d'**espionnage** (furtivité) de chaque unité **réduit** le risque de détection.
- Si détecté, le défenseur reçoit une notification : « Joueur X vous a espionné ».
- ~5 unités = compromis standard (bonne visibilité, risque de détection limité).
- 10 niveaux de technologie d'espionnage.

_Formule exacte de détection et de révélation à définir lors de l'implémentation._

---

## 9. Roster des unités

_**En cours de définition.**_

Le roster détaillera pour chaque unité :

| Champ               | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| Nom                 | Nom original dans l'univers World of Stars                        |
| Catégorie           | Combat / Scientifique / Reconnaissance / Transport                |
| Prérequis           | military_camp niv X (+ éventuellement autre bâtiment/technologie) |
| Coût                | Métal, Nourriture, Thorium                                        |
| Temps de production | Durée de base (avant réduction du training_camp)                  |
| Attaque             | Valeur de base                                                    |
| Défense             | Valeur de base (seuil d'encaissement)                             |
| Intelligence        | Valeur de base                                                    |
| Transport           | Capacité par unité (pour chaque ressource)                        |
| Exploration         | Points d'exploration générés                                      |
| Espionnage          | Furtivité                                                         |
| XP accordée         | XP gagnée par l'adversaire à la destruction de cette unité        |
| Traits spéciaux     | Ex : « aucune perte en exploration », « ne combat jamais »        |

### Unités prévues (noms provisoires, à définir)

| Rôle                  | Description courte                                              |
| --------------------- | --------------------------------------------------------------- |
| Combat offensif       | Attaque haute, défense faible, raids                            |
| Combat défensif       | Défense haute, attaque faible, garnison                         |
| Combat polyvalent     | Équilibré, ligne de front                                       |
| Scientifique          | Points d'exploration, transport modéré                          |
| Recon-exploration     | Exploration bonus, transport élevé, aucune perte en exploration |
| Recon-espionnage      | Espionnage bonus, aucun transport, aucune perte en exploration  |
| Transport             | 0 attaque, défense faible, transport très élevé                 |
| Escorte (à confirmer) | Réduction du risque d'exploration, stats de combat modérées     |

---

## 10. Questions ouvertes

| Sujet                                         | État         | Note                                                                    |
| --------------------------------------------- | ------------ | ----------------------------------------------------------------------- |
| Noms définitifs des unités                    | À définir    | Noms originaux dans l'univers World of Stars                            |
| Calendrier de déblocage (military_camp)       | À définir    | Quelle unité à quel niveau du military_camp                             |
| Statistiques détaillées                       | À définir    | Valeurs de base attaque/défense/intelligence/transport/explo/espionnage |
| Coûts de production                           | À définir    | Métal, nourriture, thorium, temps de base                               |
| XP par unité détruite                         | À définir    | Remplace la table existante (léger 0.3, lourd 0.5...)                   |
| Formule de réduction du temps (training_camp) | À définir    | −X% par niveau ? Courbe de réduction ?                                  |
| Formule de réduction du risque (escorte)      | À recalculer | Adapter la table lourd/léger aux unités offensives/défensives           |
| Unité d'escorte dédiée                        | À trancher   | Nécessaire ou les combattants suffisent-ils ?                           |
| Iris                                          | À définir    | Bonus défense portail, débloqué par le portail quantique                |
| Contenu du rapport de combat                  | À définir    | Pertes, butin, XP, survivants, narratif IA                              |
| Formule de repli (delta intelligence)         | À définir    | Seuil de déclenchement et % de survivants                               |
| Seuil d'encaissement (défense)                | À préciser   | Comment se calcule le « coup » vs la « défense » exactement             |
| Bombardement orbital                          | Reporté      | Dégâts purs sans butin ? À définir avec les vaisseaux                   |
| Bâtiments de défense statique                 | En réflexion | Tourelles, structures défensives fixes                                  |

---

_Document vivant v0.1 — à maintenir en parallèle de game_design.md et building_reference.md_
