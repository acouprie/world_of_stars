# Résumé de session — Modèle de combat & roster des unités terrestres

> World of Stars — décisions actées dans cette conversation.
> Documents impactés : `unit_reference.md` (→ v0.2), `game_design.md` (→ v0.5).

---

## 1. Modèle de combat — **tranché**

**Modèle A : tir agrégé + paliers d'armure, assignation par cible, sans PV.**

Résolution d'un round, par salve :

1. Chaque unité combattante (ATQ > 0) est assignée à **une** cible ennemie tirée **au hasard**, pondérée par l'effectif des combattants. Les non-combattants (Mules en dernier) ne sont visés que s'il ne reste aucun combattant.
2. Pour chaque cible, on **additionne** les dégâts des tireurs qui l'ont visée : `ATQ × jitter` par tireur.
3. Cible détruite si dégâts concentrés **≥ sa DEF**. Sinon survit, **aucun report**.

La défense est un **palier d'armure** (pas de PV) : tuer exige de **concentrer** le feu. La répartition aléatoire gaspille du feu (sur-tir/sous-tir), ce qui **borne la létalité par round** et étale le combat.

- **Jitter** = variation aléatoire **par tir**, tirée dans **[0,85 ; 1,15]**. Appliqué par tir (et non globalement) : grosses armées = résultat resserré, escarmouches = plus imprévisibles.

---

## 2. Initiative (intelligence) — **tranché**

- INT du camp = **moyenne d'INT pondérée par l'attaque**, sur les **survivants combattants**, **recalculée à chaque round**.
- Le camp à l'INT la plus haute **tire en premier**.
- **À INT égale → salves simultanées** (calculées sur l'effectif de début de round) : neutralise l'alpha-strike injuste dans le cas le plus sensible.
- Conséquence assumée : l'INT est une **stat de combat uniquement**. Les unités à ATQ 0 (Sonde, Spectre, Mule) n'influencent pas l'initiative. La « compétence » du Spectre passe par sa **furtivité (espionnage)**, pas par son INT.

---

## 3. Repli (attaquant) — **tranché (v1)**

- **Automatique** : déclenché quand les pertes cumulées de l'attaquant dépassent **55 %**. Le défenseur combat jusqu'au dernier.
- **Volée d'adieu** du défenseur, puissance selon le delta `Δ = INT_att − INT_def` :
  `multiplicateur = clamp(0,5 − Δ/8, 0, 1,5)`
  (Δ+ → fuite propre ; Δ ≈ 0 → demi-volée ; Δ− → volée renforcée, pertes lourdes.)
- **Statu quo** : si aucun camp ne progresse au-delà d'un plafond (~40 rounds, à régler), l'attaquant se retire sans pillage.

---

## 4. Ciblage — **tranché**

- Assignation aléatoire **parmi les combattants d'abord**.
- Non-combattants visés en dernier ; **Mules en tout dernier** (queue de peloton).

---

## 5. Noms définitifs — **tranché**

| Rôle              | Nom              |
| ----------------- | ---------------- |
| Combat offensif   | **Maraudeur**    |
| Combat défensif   | **Sentinelle**   |
| Combat polyvalent | **Régulier**     |
| Scientifique      | **Scientifique** |
| Recon-exploration | **Sonde**        |
| Recon-espionnage  | **Spectre**      |
| Transport         | **Mule**         |

---

## 6. Stats de combat — **baseline v2 validée par simulation** (valeurs à finaliser en passe économie)

| Unité        | ATQ | DEF | INT | Combattant               |
| ------------ | --- | --- | --- | ------------------------ |
| Maraudeur    | 16  | 20  | 6   | oui                      |
| Régulier     | 11  | 30  | 8   | oui                      |
| Sentinelle   | 9   | 52  | 10  | oui                      |
| Scientifique | 2   | 14  | 7   | marginal (arme de poing) |
| Sonde        | 0   | 12  | 4   | non                      |
| Spectre      | 0   | 10  | 2   | non                      |
| Mule         | 0   | 16  | 1   | non                      |

**Principe de calibrage gravé : `DEF_min > ATQ_max × 1,15`** — aucune unité ne meurt d'un seul tir.

Logistique (transport / explo / espion) conservée de la proposition précédente ; voir `unit_reference.md` §3.

---

## 7. Résultats de simulation (3000–4000 itérations / scénario)

- **Raid** 100 Maraudeur vs 30/50/70 Régulier → victoire 100 %, pertes **3,5 % / 11 % / 28 %** (montée douce, pas de falaise).
- **Miroir Régulier** 100v100 → attaquant gagne **39 %** (avantage défenseur sain), ~10 rounds.
- **Perce-mur** : seuil de victoire vers **×1,5** d'effectif face à un mur de Sentinelles.
- **Valeur du mur** (attaquant fixe) : +30 Sentinelles → pertes ATT 12 %→26 % ; +60 → assaut **repoussé**.
- **Repli** : Δ+ le défenseur encaisse, Δ− le défenseur reste intact.
- **Non-combattants** (Spectre/Mule) : inutiles en combat, meurent sans riposter.

→ **Mécaniques validées.** Les valeurs numériques restent une baseline à régler finement avec l'économie.

---

## 8. Autres décisions de design

- **Iris** (portail) — _design retenu_ : bonus de **défense** aux unités en défense **contre un assaut par portail**, croissant avec le niveau du portail. Contrepartie défensive de la vulnérabilité ouverte par le portail. À chiffrer.
- **Technos de combat** — _architecture posée_ : modificateurs % sur ATQ / DEF / INT / repli, posés **par-dessus** le modèle. Effet « falaise » à surveiller (franchir un palier de DEF est binaire). À chiffrer avec l'arbre techno.
- **Scientifique** — reçoit une **attaque symbolique (ATQ 2)** sans devenir une unité de combat.
- **Pas d'unité d'escorte dédiée** au lancement.

---

## 9. Idées futures (notées dans le game design)

- **Unité officier** (niveaux 7-10 du military_camp) : unité survivable dont l'INT mènerait le tempo de l'armée (modèle « initiative = INT max »).
- **Seuil de repli paramétrable par le joueur** (choisi avant l'envoi) en v2+.

---

## 10. Reporté à la **passe économie / déblocage**

- **Coûts de production** des unités (métal/nourriture/thorium/temps).
- **Calendrier de déblocage** par le military_camp — l'ancienne proposition était **trop chère**, à reprendre de zéro.
- **XP accordée à la destruction** : proportionnelle au coût de production (valeurs à fixer).
- **Coût de l'espionnage** : le Spectre est trop cher pour de la routine → à rééquilibrer (ou faire porter les paliers 1-3 par la Sonde).
- **Réduction du temps** du training_camp (formule par niveau).
- **Réduction du risque d'exploration** par l'escorte (recalculer autour de Maraudeur/Régulier/Sentinelle).
- **Plafond de statu quo** (rounds) à régler.

---

_Prochaine étape logique : la passe économie (coûts + déblocage), qui permettra de figer définitivement les stats v2 et de juger la rentabilité réelle de chaque archétype._
