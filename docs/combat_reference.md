# World of Stars — Référence du combat

> Version 1.0 — Document de conception
> Complément au `game_design.md`, `unit_reference.md`, `tech_reference.md`, `building_reference.md`
> Statut : **modèle validé par simulation Monte-Carlo · décisions de game feel actées (juin 2026)**

Ce document est la **source de vérité unique** pour le système de combat au sol. Les autres documents renvoient ici ; ils ne dupliquent plus la mécanique de combat.

---

## Table des matières

1. [Décisions actées (récapitulatif)](#1-décisions-actées-récapitulatif)
2. [Couches de combat](#2-couches-de-combat)
3. [Modèle : tir agrégé + paliers d'armure](#3-modèle--tir-agrégé--paliers-darmure)
4. [Résolution d'un round](#4-résolution-dun-round)
5. [Aléa — jitter & swing global](#5-aléa--jitter--swing-global)
6. [Initiative](#6-initiative)
7. [Repli & plafond de statu quo](#7-repli--plafond-de-statu-quo)
8. [Invariant anti-one-shot](#8-invariant-anti-one-shot)
9. [Technologies de combat](#9-technologies-de-combat)
10. [Bunker, pillage, conquête, rapport](#10-bunker-pillage-conquête-rapport)
11. [XP de combat](#11-xp-de-combat)
12. [Algorithme par compteurs (pseudocode Ruby)](#12-algorithme-par-compteurs-pseudocode-ruby)
13. [Validation par simulation](#13-validation-par-simulation)
14. [Questions ouvertes](#14-questions-ouvertes)

---

## 1. Décisions actées (récapitulatif)

| # | Décision | Valeur actée |
| - | -------- | ------------ |
| 1 | Modèle de résolution | **Tir agrégé + paliers d'armure (« Modèle A »), sans PV**, par compteurs de type (forme fermée, `O(types)`) |
| 2 | Rythme du combat | ~10 rounds en pratique, quelle que soit la taille des armées |
| 3 | Aléa principal | **Swing global par camp et par round, `Normal(1 ; σ=0,25)`**, borné > 0 |
| 4 | Aléa de texture | Jitter par tir `∈ [0,85 ; 1,15]` (s'évapore sur la masse) |
| 5 | Initiative | INT du camp = **moyenne d'INT pondérée par l'ATQ** des combattants survivants, **recalculée chaque round** ; à égalité → **salves simultanées** |
| 6 | Repli (perte) | **Automatique** au-delà de **55 %** de pertes cumulées de l'attaquant, avec volée d'adieu du défenseur |
| 7 | Repli (statu quo) | **Plafond de 18 rounds** : si atteint, l'attaquant se retire (avec volée d'adieu) — filet de sécurité, ne se déclenche que ~1–6 % du temps |
| 8 | Formule de volée d'adieu | `multiplicateur = clamp(0,5 − Δ/8 ; 0 ; 1,5)` avec `Δ = INT_att − INT_def` |
| 9 | Répartition du feu | **Proportionnelle / cible aléatoire** (combattants d'abord, non-combattants ensuite, **Mules en dernier**) — focus-fire reporté |
| 10 | Échelle ATQ/DEF | **Deux chiffres** (lisible ; en agrégé c'est le ratio qui compte) |
| 11 | Fragilité des unités de ligne | **Contrainte universelle** : aucune unité de combat one-shottable (`DEF_min > ATQ_max × 1,15`) — glass cannon reporté en variante future |
| 12 | Technos de combat | **Bonus multiplicatif à accumulation additive** sur la stat (`stat_eff = stat_base × (1 + r·niveau)`) ; lisse, seul le **delta** compte. Valeurs `r` / plafonds à calibrer (cf. §9) |

> **Game feel cible (acté) :** combat **prédictif à ~80 %**, avec une zone « pile ou face » s'étalant sur **~20 % de ratio de force**. Mesuré : à σ=0,25, la bande 25 %→75 % de victoire = 0,21 de ratio ; la bande 20 %→80 % = 0,25. La défense a un **avantage réel mais pénétrable** (cracker un mur de Sentinelles coûte ~×1,45 de force).

---

## 2. Couches de combat

Les combats se résolvent **à l'arrivée** des forces attaquantes sur la planète cible.

1. **Couche orbitale** _(reportée — définie avec les vaisseaux)_ : flotte attaquante vs flotte + défenses orbitales du défenseur. **Sautée si l'assaut arrive par portail quantique** (le portail téléporte au sol et contourne l'orbite). Si le porteur est détruit ici, les troupes embarquées sont perdues avec lui.
2. **Couche au sol** : les unités terrestres débarquées affrontent les unités stationnées en défense. **C'est l'objet de ce document.**

**Asymétrie portail / vaisseau** : le portail contourne l'orbite mais exige un portail des deux côtés (le construire = accepter cette vulnérabilité ; ne pas en construire = immunité aux assauts par portail). L'assaut par vaisseau atteint n'importe quelle planète mais doit franchir l'orbite. L'**Iris** (débloqué par le portail) confère un bonus de DEF aux défenseurs contre un assaut par portail (cf. `unit_reference.md`).

---

## 3. Modèle : tir agrégé + paliers d'armure

Le combat **n'oppose jamais une unité à une unité** (ce qui créerait un comparateur booléen attaque > défense, donc un effet falaise où +1 en stat bascule tout). Il oppose la **puissance de feu agrégée d'un camp** aux **paliers d'armure (DEF)** des unités cibles.

- **ATQ** contribue au **budget de dégâts** du camp ; une unité à faible ATQ n'est jamais inutile, elle ajoute sa part au total.
- **DEF** est un **palier d'armure** : il faut **concentrer** des dégâts ≥ DEF sur une même cible pour la détruire. **Pas de points de vie**, pas de dégâts reportés d'un round à l'autre.
- Chaque round **recalcule les morts à partir des effectifs survivants** — aucun état de santé par unité n'est conservé.

Conséquence : attaque et défense vivent sur une **échelle continue commune**, les pertes s'accumulent en douceur sur plusieurs rounds, et un bonus de +1 en armement devient une **courbe lisse**, pas un interrupteur.

---

## 4. Résolution d'un round

Conceptuellement, chaque camp tire une **salve** :

1. Chaque unité combattante (ATQ > 0) vise une **cible ennemie tirée au hasard**, pondérée par l'effectif des combattants ; les **non-combattants** ne sont visés qu'ensuite, et les **Mules en tout dernier**.
2. Les dégâts des tireurs visant une **même cible s'additionnent** (`ATQ × jitter × swing`).
3. Une cible meurt si ces dégâts **concentrés ≥ sa DEF**. Pas de report du surplus.

La répartition aléatoire « gaspille » du feu (plusieurs tireurs peuvent sur-tuer une cible), ce qui **borne la létalité par round** et **étale le combat** — c'est ce qui garantit ~10 rounds plutôt qu'un wipe au premier tir.

En pratique, on **ne simule jamais les unités individuellement** : la résolution se fait **par compteurs de type** en forme fermée (cf. §12), pour un coût **indépendant de la taille des armées**.

---

## 5. Aléa — jitter & swing global

Deux sources d'aléa, à deux échelles :

- **Jitter par tir** `∈ [0,85 ; 1,15]` — texture des petites escarmouches. **S'évapore sur la masse** (loi des grands nombres) : négligeable à grande échelle.
- **Swing global par round** — un multiplicateur tiré **une fois par camp et par round**, `swing ~ Normal(1 ; 0,25)`, borné > 0, appliqué à **toute la salve** du camp. **C'est la principale source d'incertitude à grande échelle** : corrélé sur toute la salve, il ne se moyenne pas. Il lisse les courbes de victoire et adoucit l'effet falaise résiduel.

> **σ = 0,25 est acté.** C'est la valeur qui produit le game feel cible (bande pile-ou-face ~20 %, prédictif ~80 %). Monter à 0,30–0,35 élargit la bande à ~25–32 % (plus d'upsets, plus de frustration). Descendre vers 0 rend le combat quasi-déterministe (bande ~7 %).
>
> **Attention implémentation :** le swing global **doit** figurer dans le moteur **et** dans la suite de validation. Une simulation sans swing sous-estime fortement l'incertitude et l'impasse des murs (cf. §13).

---

## 6. Initiative

- **INT du camp** = moyenne d'INT **pondérée par l'ATQ**, calculée sur les **seuls combattants survivants**, **recalculée à chaque round**. Les unités à ATQ nulle (Mule, Sonde, Spectre) **n'influencent pas** l'INT du camp.
- Le camp à l'INT la plus élevée **tire en premier** ; ses pertes infligées retirent des unités **avant** la riposte.
- **À INT égale**, les deux salves sont **simultanées** (calculées sur l'effectif de début de round).
- L'INT est une **stat de combat uniquement** (initiative + efficacité du repli, cf. §7). Les technologies modifiant l'INT (bonus à soi / malus à l'ennemi) déplacent le delta et donc l'avantage d'initiative et le repli.

---

## 7. Repli & plafond de statu quo

Seul l'**attaquant** peut se replier ; le défenseur combat jusqu'au dernier.

**Repli sur pertes (automatique, v1).** Déclenché quand les pertes cumulées de l'attaquant dépassent **55 %** de son effectif initial. Le défenseur tire alors une **volée d'adieu** dont la puissance dépend du delta d'intelligence :

```
Δ = INT_attaquant − INT_défenseur
multiplicateur_volée_adieu = clamp(0,5 − Δ/8 ; 0 ; 1,5)
```

- **Δ positif** (attaquant plus malin) → décrochage propre, pertes minimisées.
- **Δ ≈ 0** → repli moyen, pertes significatives.
- **Δ négatif** (défenseur plus malin) → le défenseur « verrouille » le champ de bataille, pertes lourdes à la retraite.

Ce mécanisme donne à l'INT du défenseur un rôle concret même s'il ne se replie jamais.

**Plafond de statu quo (acté).** Si un combat atteint **18 rounds** sans résolution (cas typique d'un mur quasi-infranchissable), l'**attaquant se retire** avec une volée d'adieu du défenseur — il ne reste **jamais** dans une impasse de dizaines de rounds. Avec le swing à σ=0,25, ce plafond ne se déclenche que **~1–6 %** du temps : c'est un filet de sécurité, pas un chemin courant (les combats normaux tournent à ~10 rounds).

> Le repli **manuel** (l'attaquant choisit son seuil, ou décide de forcer/décrocher tôt) est un levier de profondeur **reporté** à une version ultérieure.

---

## 8. Invariant anti-one-shot

Règle gravée sur les **stats de base** des unités de combat (de ligne) :

```
DEF_min > ATQ_max × 1,15
```

Elle garantit qu'**aucune unité de ligne ne meurt d'un seul tir** : tuer exige toujours de **concentrer** le feu de plusieurs unités. C'est ce qui :

- supprime l'effet falaise (pas de bascule on/off),
- borne l'avantage d'initiative (le premier tireur ne wipe pas),
- maintient le nombre de rounds à peu près constant (~10) quelle que soit la taille.

Les **unités support** (Mule, Sonde, Spectre) sont **volontairement exclues** de cette contrainte : mourir vite fait partie de leur identité.

> L'invariant porte sur les **stats de base**. L'asymétrie de technologie peut, en pratique, pousser l'ATQ effective au-delà d'une DEF non-upgradée ; le modèle agrégé **absorbe cette asymétrie en douceur** (cf. §9) sans réintroduire de one-shot ni de discontinuité.

---

## 9. Technologies de combat

Les trois technologies militaires (cf. `tech_reference.md`) appliquent un **bonus global à toutes les unités** :

| Techno | Effet |
| ------ | ----- |
| Armement | + ATQ (toutes unités) |
| Blindage tactique | + DEF (toutes unités) |
| Guerre électronique | + INT (toutes unités) |

**Modèle de bonus acté : multiplicatif à accumulation additive.**

```
stat_eff = stat_base × (1 + r · niveau_techno)
```

Propriétés vérifiées par simulation (cf. §13) :

- **Pas de falaise.** En agrégé, le bonus produit une **courbe de victoire lisse**, jamais un interrupteur — la pathologie du modèle binaire ne revient pas.
- **Seul le delta compte.** Quand les deux camps montent la même techno, le résultat **ne bouge pas** : c'est le **différentiel** de techno qui crée l'avantage, pas le niveau absolu. Propriété idéale pour un jeu de progression (tout le monde qui monte ensemble préserve l'équilibre).
- **Décisif mais graduel.** Un differentiel de techno tue plus vite et **comprime le nombre de rounds** ; il n'y a pas de saut.

**Garde-fou de calibration (le seul vrai contrainte) :** borner le couple `(r, niveau_max)` pour que, **au delta de techno maximal réaliste**, le combat reste **≥ ~3 rounds** — sinon l'initiative décide tout en un seul round et la structure de combat dégénère.

> **Valeurs proposées (à calibrer) :** `r ≈ 0,04–0,05` avec un plafond de niveau tel que le delta maximal plafonne le multiplicateur autour de **×1,6 à ×1,9**. Ces valeurs débloquent les `per_level` laissés à `nil` dans `tech_reference.md`. La calibration finale se fera par simulation, en même temps que la passe économie.

---

## 10. Bunker, pillage, conquête, rapport

- **Bunker** — mise à l'abri **consciente** d'unités **avant** la bataille (le joueur choisit quoi protéger). 1 unité = 1 slot, quel que soit le type. Les unités abritées ne combattent pas et sont **immunisées**. Le bunker protège aussi une fraction des ressources (cf. `building_reference.md`). Préférer être pillé plutôt que perdre des troupes est un choix valide.
- **Pillage** — l'attaquant doit **tenir le sol** (gagner l'engagement terrestre) pour piller. Pas de butin sur une simple victoire orbitale. Les transporteurs se remplissent des ressources **non protégées** par le bunker.
- **Conquête** _(reportée)_ — exige **zéro défense restante** sur la planète. La planète d'origine n'est jamais conquérable.
- **Rapport de combat** — généré **pour les deux camps**, **round par round en effectifs de type** (compact même à 100 000 unités) : pertes, butin, survivants, XP, + un **volet narratif généré par IA**.

---

## 11. XP de combat

- Gagnée en détruisant des unités ennemies. Associée **au joueur**, pas aux unités — **classement uniquement, aucun impact mécanique**.
- Niveau 1 = **400 XP** ; chaque niveau suivant ×1,2 ; gains ×1,0292 par passage de niveau ; **XP cumulée** (l'excédent n'est pas perdu).
- **XP par unité détruite** : proportionnelle au **coût de production** de l'unité (valeurs fixées à la passe économie).

**Multiplicateurs — victoire sans pertes** (récompense le combat serré, décourage le farm des faibles) :

| Écart de force (att / déf) | Multiplicateur XP |
| -------------------------- | ----------------- |
| > 20×                      | ×1 (aucun bonus)  |
| 15× à 20×                  | ×3                |
| 10× à 15×                  | ×5                |
| 5× à 10×                   | ×10               |
| < 5×                       | ×15               |

> Cette table est **volontairement inversée** par rapport à l'intuition : on récompense la victoire **risquée** (faible écart) et on neutralise l'écrasement des faibles (fort écart). Ce n'est pas un bug.

---

## 12. Algorithme par compteurs (pseudocode Ruby)

On ne simule **jamais** les unités individuellement. L'état d'un camp est un dictionnaire `{type => effectif}`. La probabilité de mort d'un type est calculée en **forme fermée** (approximation normale de la somme de Poisson composée), validée à quelques % près contre une simulation par unité, pour un coût de **`O(types)`** par round (~7 types × ~10 rounds ≪ 1 ms en Ruby, quelle que soit la taille).

```ruby
SIGMA = 0.25       # écart-type du swing global (ACTÉ)
EJ2   = 1.0075     # E[jitter^2] pour jitter ~ U[0.85, 1.15]
CAP   = 18         # plafond de statu quo (rounds) — ACTÉ

def army_int(counts)               # moyenne INT pondérée par l'ATQ
  num = den = 0.0
  counts.each { |t, c| next unless c > 0 && t.atk > 0
                       num += t.int * t.atk * c; den += t.atk * c }
  den > 0 ? num / den : 0.0
end

def fire(att, defe, swing, mult = 1.0)
  shots = sum1 = sum2 = 0.0
  att.each { |t, c| next unless c > 0 && t.atk > 0 && t.combat?
                    shots += c; sum1 += c * t.atk; sum2 += c * t.atk**2 }
  return defe if shots.zero?
  elig = eligible_targets(defe)    # combattants ; sinon non-combattants ; Mules en dernier
  n = elig.sum { |t| defe[t] }
  return defe if n.zero?
  mean = (sum1 / n) * mult
  sd   = Math.sqrt(sum2 * EJ2 / n) * mult
  elig.each do |t|
    p_kill = 1.0 - normal_cdf((t.def / [swing, 0.05].max - mean) / sd)
    defe[t] = [0, defe[t] - (defe[t] * p_kill).round].max
  end
  defe
end

def resolve_round(att, defe)
  ia, idf = army_int(att), army_int(defe)
  sA, sD  = sample_swing, sample_swing          # Normal(1, SIGMA), borné > 0
  if (ia - idf).abs < 1e-9                        # égalité -> simultané
    nd = fire(att, defe.dup, sA)
    na = fire(defe, att.dup, sD)
    [na, nd]
  elsif ia > idf
    defe = fire(att, defe, sA)
    att  = fire(defe, att, sD) if alive?(defe)
    [att, defe]
  else
    att  = fire(defe, att, sD)
    defe = fire(att, defe, sA) if alive?(att)
    [att, defe]
  end
end

# Boucle : resolve_round jusqu'à ce qu'un camp soit vide, OU pertes_attaquant > 55 %
# (volée d'adieu), OU round > CAP (retrait attaquant + volée d'adieu).
```

`normal_cdf(x) = 0.5 * (1 + Math.erf(x / Math.sqrt(2)))`

---

## 13. Validation par simulation

Le modèle a été validé par un faisceau Monte-Carlo (suite `combat_balance_suite.py`). Sept propriétés indépendantes confirmées : **terminaison** (pas de wipe au premier tir, pas de boucle infinie), **monotonie** (plus de force = plus de victoires, sans inversion), **archétypes distincts**, **valeur défensive progressive**, **repli orienté par le delta d'INT**, **robustesse** (perturbation ±15 % d'une stat → déplacement doux du seuil, sans chaos), **absence de stratégie dégénérée**.

> **Deux corrections à apporter à la suite de validation** (le rapport historique tournait sans elles, ce qui sous-estimait l'incertitude) :
> 1. **Intégrer le swing global σ=0,25** (la suite ne tournait qu'avec le jitter par tir). Sans lui : bande contestée ~7 %, miroir Sentinelle figé à ~41 rounds. Avec lui : bande ~20 %, miroir Sentinelle résolu en ~12 rounds.
> 2. **Utiliser les stats v2.1** (Sentinelle 13/38, pas l'ancienne 9/52) et le **plafond de 18 rounds**.
>
> Le rapport doit être rejoué sur cette base pour refléter le modèle réellement acté.

**Repères mesurés (stats v2.1, σ=0,25, cap=18) :**

| Scénario | Résultat |
| -------- | -------- |
| Bande pile-ou-face Maraudeur→Régulier | ~0,21 de ratio (25 %→75 %) |
| Mur Sentinelle : ratio pour 50 % de victoire | Maraudeur ×1,45 · Régulier ×1,44 · Sentinelle ×1,03 |
| Miroir Sentinelle 100v100 | ~12 rounds, se résout (plus d'impasse) |
| Miroir Régulier 100v100 | ~10 rounds, léger avantage défenseur |
| Miroir Maraudeur 100v100 | ~3 rounds (glass cannon, brutal) |
| Armement asymétrique (attaquant seul, ×1→×2) | victoire 73 %→100 %, rounds 5,2→3,2 — **courbe lisse** |
| Technos symétriques (les deux camps) | victoire stable ~72–75 % — **seul le delta compte** |

**Ancre de coûts pour la passe économie** (puissance de combat relative à effectif égal) : **Maraudeur : Régulier : Sentinelle ≈ 1 : 1,15 : 1,6**. La finalisation des stats appartient à la passe économie, qui rejoue ces tests en raisonnant **coût-équivalent** plutôt qu'à effectif égal.

---

## 14. Questions ouvertes

| Sujet | État | Note |
| ----- | ---- | ---- |
| Couche orbitale (vaisseaux) | Reporté | ~40 % du système de combat ; au lancement, le combat réel passe **par portail**. Périmètre MVP à confirmer. |
| Valeurs `r` / plafonds des technos de combat | À calibrer | Modèle acté (§9) ; chiffres avec la passe économie |
| Repli manuel | Reporté | Levier de profondeur futur (seuil choisi, forcer/décrocher) |
| Focus-fire | Reporté | Répartition v1 = proportionnelle ; focus-fire récompenserait la composition |
| Bombardement orbital | Reporté | Flottes sans troupes : dégâts purs sans butin ? À définir avec les vaisseaux |
| Défense statique (tourelles) | En réflexion | Toute la défense passe par les unités pour l'instant |
| Coût d'utilisation du portail | À définir | Conditionne l'équilibre attaque/défense |
| Iris — valeurs exactes | Partiellement acté | +10/+15/+20 % DEF contre assaut par portail (cf. `unit_reference.md`) ; interaction fine à valider |

---

_Document vivant — source de vérité du combat. À maintenir en parallèle de `game_design.md`, `unit_reference.md` et `tech_reference.md`._
