# World of Stars — Référence des unités terrestres

> Version 0.2 — Document de conception
> Complément au game_design.md et building_reference.md
> Statut : principes validés, **modèle de combat validé par simulation**, roster défini (stats = baseline à finaliser avec l'économie)

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

Les anciens noms issus de World of Stargate (léger, lourd, Malp, UAV, archéologue) sont abandonnés au profit de noms originaux dans l'univers World of Stars (voir section 9).

---

## 2. Catégories et rôles

### Combat

Trois archétypes, définis par la balance attaque/défense :

| Archétype  | Nom            | Profil                        | Rôle                        |
| ---------- | -------------- | ----------------------------- | --------------------------- |
| Offensif   | **Maraudeur**  | Attaque haute, défense faible | Raids, assauts rapides      |
| Défensif   | **Sentinelle** | Défense haute, attaque faible | Garnison, tenue de position |
| Polyvalent | **Régulier**   | Attaque/défense équilibrées   | Ligne de front, flexibilité |

Pas d'unité d'escorte dédiée au lancement : les combattants remplissent ce rôle en exploration. Les niveaux 7-10 du military_camp sont réservés à de futures unités (voir idée « unité officier » en section 10).

### Scientifique (exploration)

Génère des **points d'exploration** qui alimentent les **niveaux d'exploration** du joueur. Capacité de transport modérée. Possède une **attaque symbolique** (« arme de poing ») qui ne change rien à son statut : ce n'est pas une unité de combat, on ne l'envoie pas en assaut.

### Reconnaissance — double usage exploration/espionnage

| Profil            | Nom         | Domaine principal                 | Transport |
| ----------------- | ----------- | --------------------------------- | --------- |
| Recon-exploration | **Sonde**   | Exploration (bonus XP/ressources) | Élevé     |
| Recon-espionnage  | **Spectre** | Espionnage (furtivité élevée)     | Aucun     |

Les deux possèdent le trait **« aucune perte en exploration »** (PvE uniquement). Le coût/temps du Spectre est supérieur à celui de la Sonde, pour refléter sa spécialisation.

### Transport — **Mule**

- **Attaque : 0** — ne combat jamais, quel que soit le contexte.
- **Défense : faible mais non nulle** — peut encaisser, ne riposte pas.
- **Transport : très élevé** — la plus haute capacité de toutes les unités.

Une troupe composée uniquement de Mules ne peut **jamais gagner un combat**. Si la planète ciblée n'a **aucune unité en défense**, les Mules pillent les ressources non protégées par le bunker.

> **Conséquence du modèle de combat (voir §6) :** l'intelligence en combat est pondérée par l'attaque. Les unités à attaque nulle (Sonde, Spectre, Mule) **ne servent ni à attaquer ni à défendre** — elles n'influencent pas l'issue d'un combat et meurent sans riposter. On ne les emmène que pour l'exploration, l'espionnage, ou le pillage après une victoire. **L'UI doit avertir** le joueur qui voudrait les inclure dans un assaut.

---

## 3. Statistiques

Chaque unité possède les statistiques suivantes. Toutes sont modifiables par technologies.

| Stat             | Rôle                                                              |
| ---------------- | ----------------------------------------------------------------- |
| **Attaque**      | Contribue au budget de dégâts du camp par round (0 = ne combat pas) |
| **Défense**      | **Palier d'armure** : seuil de dégâts concentrés à dépasser pour détruire l'unité (pas de PV) |
| **Intelligence** | Ordre d'attaque (initiative) + efficacité du repli — **stat de combat uniquement** |
| **Transport**    | Ressources transportables, **par ressource** (métal, nourriture, thorium séparément) |
| **Exploration**  | Points d'exploration générés en mission                           |
| **Espionnage**   | Furtivité en mission d'espionnage (réduit le risque de détection) |

**Pas de PV.** La défense est un **palier** : un round détruit une unité seulement si les dégâts *concentrés* sur elle dépassent sa défense (voir l'algorithme en §6). Pas de dégâts partiels.

**Intelligence = stat de combat.** L'INT ne sert qu'à l'initiative et au repli, et n'est prise en compte que pour les unités qui combattent (pondération par l'attaque). La « compétence » d'un Spectre s'exprime par sa **furtivité (espionnage)**, pas par son INT — son INT en combat est négligeable et c'est voulu.

**Pas de vitesse** : les unités terrestres sont une charge utile (le temps de trajet dépend du porteur).

### Table de statistiques de combat — baseline v2 (validée par simulation, à finaliser avec l'économie)

| Unité        | ATQ | DEF | INT | Combattant |
| ------------ | --- | --- | --- | ---------- |
| Maraudeur    | 16  | 20  | 6   | oui        |
| Régulier     | 11  | 30  | 8   | oui        |
| Sentinelle   | 9   | 52  | 10  | oui        |
| Scientifique | 2   | 14  | 7   | marginal   |
| Sonde        | 0   | 12  | 4   | non        |
| Spectre      | 0   | 10  | 2   | non        |
| Mule         | 0   | 16  | 1   | non        |

**Principe de calibrage gravé :** `DEF_min > ATQ_max × 1,15`. Aucune unité ne meurt d'un seul tir — tuer exige de **concentrer** le feu de plusieurs unités, ce qui borne l'avantage du premier tir et étale le combat sur plusieurs rounds.

### Table logistique — transport / exploration / espionnage / traits

| Unité        | Transport | Explo        | Espion | Traits                          |
| ------------ | --------- | ------------ | ------ | ------------------------------- |
| Maraudeur    | 50        | 30 (fixe)\*  | 0      | —                               |
| Régulier     | 100       | 30 (fixe)\*  | 0      | —                               |
| Sentinelle   | 50        | 30 (fixe)\*  | 0      | —                               |
| Scientifique | 75        | 33 → croissant | 0    | XP ∝ risque (voir §7)           |
| Sonde        | 200       | 30           | 3      | Aucune perte en exploration     |
| Spectre      | 0         | 30           | 12     | Aucune perte en exploration     |
| Mule         | 300       | 0            | 0      | Ne combat jamais ; pillage seul |

\* Les 30 XP fixes des combattants/transports en exploration sont **annulés** en présence de Scientifiques (voir §7).

> **XP accordée à la destruction** (classement uniquement, sans effet mécanique) : à fixer **proportionnellement au coût de production** de l'unité, lors de la passe économie. Ordre de grandeur attendu : Mule < combattants < Scientifique < Sonde < Spectre.

---

## 4. Production des unités

### Lieu de production

Toutes les unités sont produites dans le **training_camp**, seul bâtiment capable de produire des unités terrestres.

### Réduction du temps de production

Monter le niveau du training_camp **réduit le temps de production** de toutes les unités. Formule exacte à définir.

### Files de production

Par défaut, **une seule file**. Des files parallèles sont débloquées par **technologie** (pas par le niveau du bâtiment).

### Déblocage des types d'unités

Les types d'unités sont débloqués par le **military_camp** selon son niveau, avec des **dépendances multiples** possibles (ex : Scientifique = military_camp + research_lab).

> **⚠ À revoir (passe économie/déblocage).** Le calendrier de déblocage et les coûts proposés précédemment ont été jugés **trop chers** (espionnage en particulier). Cette table sera reprise de zéro en cohérence avec l'économie réelle (production des mines, coût des bâtiments) et avec le modèle de combat validé. Ne pas figer avant cette passe.

### Coût de production

Chaque unité a un coût en **métal, nourriture, thorium** + un **temps de base** (réduit par le training_camp). **Pas d'énergie, pas d'entretien.** Valeurs à fixer en passe économie.

---

## 5. Mouvement

Les unités terrestres ne traversent jamais la carte seules. Deux modes :

### Portail quantique

- Durée fixe : **20 minutes** (indépendante de la distance).
- Nécessite un portail au départ **et** à destination (les planètes vides ont un portail implicite, exploration uniquement).
- **Contourne la couche orbitale** : dépose les troupes directement au sol.
- « Pas de portail = immunité aux attaques par portail » — le construire ouvre une vulnérabilité.
- **Iris** : défense débloquée en montant le portail quantique. **Design retenu** : l'Iris accorde un **bonus de défense (palier d'armure relevé)** aux unités en défense, **uniquement contre un assaut arrivé par portail**, croissant avec le niveau du portail. C'est la contrepartie défensive de la vulnérabilité ouverte par le portail. Valeurs à chiffrer avec l'arbre techno.

### Vaisseau (reporté)

- Durée proportionnelle à la distance ; doit franchir la couche orbitale.
- Un **vaisseau d'exploration unique** est disponible au lancement pour les joueurs sans portail.

---

## 6. Combat

> **Modèle validé : « Tir agrégé + paliers d'armure » (Modèle A), assignation par cible, sans PV.** Validé par simulation (voir §6.5). Référence de cohérence : `game_design.md` §6.

### 6.1 Modèle en couches

1. **Couche orbitale** (vaisseaux, reportée) : sautée si arrivée par portail. Porteur détruit = troupes embarquées perdues.
2. **Couche au sol** : unités débarquées vs unités stationnées. C'est ici qu'interviennent les stats terrestres.

### 6.2 Résolution d'un round

À chaque round, chaque camp tire une **salve**. Une salve fonctionne ainsi :

1. Chaque unité **combattante** (ATQ > 0) est assignée à **une** cible ennemie, tirée **au hasard** parmi les combattants adverses (pondéré par l'effectif). Les non-combattants (Mules en dernier) ne sont visés que s'il ne reste plus aucun combattant.
2. Pour chaque cible, on **somme** les dégâts des tireurs qui l'ont visée : `ATQ × jitter` par tireur, où **jitter ∈ [0,85 ; 1,15]** (variation aléatoire par tir).
3. Une cible est **détruite** si les dégâts concentrés sur elle **≥ sa DEF**. Sinon elle survit ; **aucun report** du reliquat.

La concentration aléatoire « gaspille » naturellement du feu (sur-tir sur certaines cibles, aucun sur d'autres) : c'est l'amortissement qui borne la létalité par round et fait durer le combat.

### 6.3 Initiative (qui tire en premier)

- L'**intelligence du camp** = **moyenne d'INT pondérée par l'attaque**, sur les **survivants combattants**, **recalculée à chaque round**.
- Le camp à l'INT la plus élevée **tire en premier** ; le second riposte avec ses survivants.
- **À INT égale** : les deux salves sont **simultanées** (calculées sur l'effectif de début de round, appliquées ensemble) — cela neutralise l'alpha-strike injuste dans le cas le plus sensible.

### 6.4 Repli (attaquant uniquement)

Le défenseur combat jusqu'au dernier. L'attaquant se replie automatiquement (v1) lorsque ses **pertes cumulées dépassent 55 %**.

Au repli, le défenseur tire une **volée d'adieu** dont la puissance dépend du **delta d'intelligence** `Δ = INT_att − INT_def` :

```
multiplicateur_volée = clamp(0,5 − Δ / 8 , 0 , 1,5)
```

- Δ positif (attaquant plus malin) → fuite propre, volée faible voire nulle.
- Δ ≈ 0 → demi-volée.
- Δ négatif (défenseur plus malin) → le défenseur « verrouille », volée renforcée, pertes lourdes.

**Statu quo** : si aucun camp ne progresse au-delà d'un plafond de rounds (mur infranchissable — ex. deux garnisons de Sentinelles), l'attaquant se retire (pas de pillage). Plafond à régler (≈ 40 rounds en simulation).

### 6.5 Algorithme (pseudocode Ruby)

```ruby
JITTER            = (0.85..1.15)
RETREAT_THRESHOLD = 0.55
RETREAT_K         = 8.0
STANDOFF_CAP      = 40   # à régler

def army_int(units)        # moyenne INT pondérée par l'ATQ, combattants seulement
  shooters = units.select { |u| u.atk > 0 }
  return 0.0 if shooters.empty?
  shooters.sum { |u| u.int * u.atk }.to_f / shooters.sum(&:atk)
end

def volley(attackers, defenders, mult = 1.0)   # renvoie les unités détruites
  shooters = attackers.select { |u| u.atk > 0 }
  return [] if shooters.empty? || defenders.empty?
  pool   = combat_targets(defenders)            # combattants ; sinon non-combattants ; Mules en dernier
  damage = Hash.new(0.0)
  shooters.each { |s| damage[pool.sample] += s.atk * rand(JITTER) * mult }
  damage.select { |target, d| d >= target.def }.keys
end

def resolve_round(att, defe)
  ia, idf = army_int(att), army_int(defe)
  if (ia - idf).abs < 1e-9                       # égalité -> simultané
    ka, kd = volley(att, defe), volley(defe, att)
    defe -= ka; att -= kd
  elsif ia > idf
    defe -= volley(att, defe)
    att  -= volley(defe, att) unless defe.empty?
  else
    att  -= volley(defe, att)
    defe -= volley(att, defe) unless att.empty?
  end
  [att, defe]
end
```

### 6.6 Bunker, pillage, rapport

- **Bunker** : mise à l'abri **consciente** avant le combat. 1 unité = 1 slot. Les unités abritées ne combattent pas et sont immunisées.
- **Pillage** : l'attaquant doit **tenir le sol** (gagner l'engagement) ; les transporteurs se remplissent des ressources non protégées par le bunker.
- **Rapport de combat** : généré pour les deux camps (pertes, butin, XP, survivants, round par round) + volet narratif IA.

### 6.7 Résultats de simulation (baseline v2)

| Scénario                                   | Résultat                                                            |
| ------------------------------------------ | ------------------------------------------------------------------- |
| Raid 100 Maraudeur vs 30/50/70 Régulier    | Victoire 100 % ; pertes attaquant **3,5 % / 11 % / 28 %**           |
| Miroir Régulier 100v100                    | Attaquant gagne **39 %** (avantage défenseur), ~10 rounds           |
| Perce-mur : Maraudeurs vs 100 Sentinelles  | Seuil de victoire vers **×1,5** d'effectif                          |
| Valeur du mur (attaquant fixe)             | +30 Sentinelles : pertes ATT 12 %→26 % ; +60 : assaut **repoussé** |
| Repli Δ positif / Δ négatif                | Δ+ : défenseur encaisse ; Δ− : défenseur intact                     |
| Spectre/Mule en combat                     | Inutiles (aucune influence, meurent sans riposte)                   |

**Conclusion** : mécaniques saines (multi-rounds, masse efficace, mur progressif, raids fluides, premier tir borné). Les **valeurs numériques** restent une baseline à régler finement lors de la passe économie (le « prix » d'une Sentinelle conditionne sa rentabilité défensive).

---

## 7. Exploration

_Résumé. Référence complète : `game_design.md` §7._

### Principe

Les planètes vides sont explorables (portail implicite). Une mission génère des **points d'exploration** et peut ramener des **ressources** (20 % de chance, 50–100 % de la capacité de transport).

### Durée

- Base **20 minutes** (portail) ; **+1 minute par unité**.

### Sécurité PvE

- Une équipe **ne peut jamais être totalement exterminée** ; 1 unité seule = aucune perte.
- Sonde et Spectre ne subissent **jamais de pertes** en exploration (trait intrinsèque).
- _Spécifique à l'exploration — ne s'applique pas au combat PvP._

### Scientifique — risque et XP

- 1 seul = 11 % de risque → 33 XP ; +1 % par Scientifique supplémentaire ; 90 = 100 % → 300 XP ; au-delà +3 XP/unité.
- **Formule** : `% risque × 3 = XP` ; pertes = % de risque ; variation ±5 %.
- En présence de Scientifiques, les 30 XP fixes des combattants/transports sont **annulés**.
- _Formule de réduction du risque par l'escorte (combattants) à recalculer autour de Maraudeur/Régulier/Sentinelle._

### Niveaux d'exploration

- Niveau 1 = 400 XP, ×1,2 par niveau ; gains ×1,0292 par niveau ; XP cumulée.

---

## 8. Espionnage

_Résumé. Référence complète : `game_design.md` §6._

Mission de **5 minutes**. Plus d'unités envoyées = plus d'informations mais plus de risque de détection ; la stat **espionnage** (furtivité) réduit ce risque.

| Pallier | Information                                                    |
| ------- | -------------------------------------------------------------- |
| 1       | Bâtiments                                                      |
| 2       | Unités terrestres                                              |
| 3       | Ressources                                                     |
| 4       | Technologies (nécessite techno espionnage ≥ cible)             |
| 5       | Vaisseaux en orbite (Spectre uniquement)                       |

~5 unités = compromis standard ; 10 niveaux de technologie d'espionnage.

> **Tension à résoudre en passe économie** : le Spectre est l'unité la plus chère et thorium-dépendante, ce qui rend l'espionnage de routine coûteux. Pistes : baisser nettement le coût du Spectre, ou faire porter les paliers 1–3 par la Sonde (furtivité rehaussée) et réserver le Spectre aux paliers 4–5.

---

## 9. Roster des unités

**Noms définitifs** (univers World of Stars) :

| Rôle              | Nom              | Catégorie       |
| ----------------- | ---------------- | --------------- |
| Combat offensif   | **Maraudeur**    | Combat          |
| Combat défensif   | **Sentinelle**   | Combat          |
| Combat polyvalent | **Régulier**     | Combat          |
| Scientifique      | **Scientifique** | Exploration     |
| Recon-exploration | **Sonde**        | Reconnaissance  |
| Recon-espionnage  | **Spectre**      | Reconnaissance  |
| Transport         | **Mule**         | Transport       |

Stats de combat et logistiques : voir **§3**. Coûts et déblocage : **passe économie** (voir §4 et §10).

---

## 10. Questions ouvertes

| Sujet                                         | État            | Note                                                                 |
| --------------------------------------------- | --------------- | -------------------------------------------------------------------- |
| Noms des unités                               | **Tranché**     | Maraudeur, Sentinelle, Régulier, Scientifique, Sonde, Spectre, Mule  |
| Modèle de combat                              | **Tranché**     | Modèle A (tir agrégé + paliers, assignation par cible, sans PV)      |
| Calcul de l'intelligence                      | **Tranché**     | Moyenne pondérée par l'ATQ, survivants, recalcul/round ; égalité → simultané |
| Repli (v1)                                    | **Tranché**     | Auto à 55 % de pertes ; volée d'adieu = f(delta INT)                 |
| Stats de combat (ATQ/DEF/INT)                 | Baseline validée| Shape validée par simulation ; valeurs à finaliser en passe économie |
| Coûts de production                           | À définir       | Passe économie                                                       |
| Calendrier de déblocage (military_camp)       | À refaire       | Jugé trop cher ; à reprendre avec l'économie                         |
| XP par unité détruite                         | À définir       | Proportionnel au coût de production                                  |
| Réduction du temps (training_camp)            | À définir       | Formule par niveau                                                   |
| Réduction du risque (escorte explo)           | À recalculer    | Autour de Maraudeur/Régulier/Sentinelle                              |
| Iris (portail)                                | Design retenu   | Bonus de DEF aux défenseurs vs assaut-portail, ∝ niveau portail ; à chiffrer |
| Technos de combat                             | Architecture posée | Modificateurs % sur ATQ/DEF/INT/repli ; pas modifiables (effet falaise) ; à chiffrer |
| Plafond de statu quo (rounds)                 | À régler        | ≈ 40 en simulation                                                   |
| Coût d'espionnage (Spectre)                   | À rééquilibrer  | Trop cher pour de la routine (voir §8)                               |
| Repli paramétrable par le joueur              | **Idée future** | Seuil de repli choisi avant l'envoi (v2+)                            |
| Unité officier (niv 7-10 military_camp)       | **Idée future** | Unité survivable dont l'INT mène le tempo de l'armée (modèle « initiative = INT max ») |
| Contenu détaillé du rapport de combat         | À définir       | Round par round + narratif IA                                        |
| Bombardement orbital                          | Reporté         | À définir avec les vaisseaux                                         |
| Bâtiments de défense statique                 | En réflexion    | Tourelles, structures fixes                                          |

---

_Document vivant v0.2 — à maintenir en parallèle de game_design.md et building_reference.md_
