# World of Stars - Magnitude d'exploration & calendrier military_camp (passe économie, proposition v1)

> Complément de calibration - à fusionner après validation dans `game_design.md` §7
> (mécanismes d'exploration) et `unit_reference.md` §4 (calendrier de déblocage).
> Statut : **proposé, validé par Monte Carlo (200 000 missions par composition)**.

---

## 1. Exploration - ce qui ne change pas

Les **tables de paliers du GDD §7 sont conservées telles quelles** : elles satisfont déjà
l'équation de calibration (E[frac_pertes] = 5,58 %, k_butin implicite = 0,79).

| Tirage     | rien     | modeste        | bon            | extrême                   |
| ---------- | -------- | -------------- | -------------- | ------------------------- |
| Ressources | 20 % → 0 | 58 % → 1-6 %   | 18 % → 6-12 %  | 4 % → 12-25 %             |
| XP         | 18 % → 0 | 60 % → 0,3-0,8 | 18 % → 0,8-1,5 | 4 % → 1,5-3,0             |
| Pertes     | 55 % → 0 | 33 % → 2-10 %  | 10 % → 10-30 % | 2 % → 60-100 % (critique) |

Bases d'XP unitaires (validées avec la courbe ×1,7) : **Scientifique 60, Sonde 25,
Spectre 25, autres unités 10**. Échelle de coûts : **k = 5**.

## 2. Exploration - les mécanismes précisés (le travail de cette passe)

### Poids de risque par classe

Chaque classe d'unité porte un **poids de risque** `w` qui sert à la fois aux pertes
et au butin :

| Classe                          | w   | Lecture            |
| ------------------------------- | --- | ------------------ |
| Reconnaissance (Sonde, Spectre) | 0,6 | Meilleure survie   |
| Scientifique                    | 1,0 | Référence          |
| Combat (escorte)                | 1,1 | Encaisse les coups |
| Mule                            | 1,2 | Cible facile       |

### Pertes

```
pertes(classe) = f_tiré × (1 − 0,5 × part_escorte) × (1 − 0,02 × niv_carto) × w(classe) × effectif(classe)
```

- `part_escorte` = part des unités de combat dans l'effectif (en nombre). Une escorte
  à 50 % réduit les pertes du quart.
- **Le palier critique (2 %, 60-100 %) ignore TOUS les modificateurs** : poids, escorte,
  Cartographie. C'est le plancher du système : aucune composition n'est à l'abri d'un
  effacement, la terreur existentielle des 2 % est préservée. (Remplace le « plancher »
  flou de l'effet Cartographie.)

### Butin

```
butin = f_tiré × Σ [coût(u) × w(u)]  sur les unités NON-combat, plafonné par le transport
```

Deux choix structurants :

- **Pondéré par le risque** (« qui ne risque rien ne trouve rien ») : la base de butin
  d'une Sonde est 0,6 × son coût. Conséquence mathématique : le ratio butin/pertes est
  **indépendant de la composition** pour les équipes sans escorte. Sans cette pondération,
  les équipes de pure reconnaissance étaient nettes-positives (pompe à ressources, mesuré
  ratio 1,09 → 1,67 avec Carto 10).
- **Les unités de combat ne génèrent aucun butin** : l'escorte est une prime d'assurance
  (elle réduit les pertes, coûte quand elle meurt, ne rapporte rien). Pas de pompe à butin
  par sur-escorte.
- La Mule garde son archétype : base de butin ×1,2, risque ×1,2, zéro XP, zéro protection,
  le « run de butin » risqué.

### Cartographie stellaire - répartition définie

`+4 %/niv` ne s'applique **qu'à l'XP**. `-2 %/niv` sur les pertes (hors palier critique).
**Aucun bonus de butin** (sinon la techno re-crée la pompe à ressources qu'on vient de
fermer). Au niveau 10 : +40 % d'XP, -20 % de pertes ordinaires.

## 3. Validation Monte Carlo (k = 5, 200 000 missions/composition)

| Composition                         | Net/mission | Ratio butin/pertes | XP/mission |
| ----------------------------------- | ----------- | ------------------ | ---------- |
| 3 Sondes (bootstrap j1)             | -30         | 0,66               | 47         |
| 10 Sondes                           | -102        | 0,66               | 157        |
| 10 Mules (run de butin)             | -60         | 0,83               | 63         |
| 5 Sci + 2 Maraudeurs + 2 Sondes     | -104        | 0,63               | 232        |
| 5 Sci + 5 Sentinelles (blindé)      | -209        | 0,39               | 219        |
| 8 Sci + 4 Sent + 2 Sondes           | -231        | 0,53               | 358        |
| 8 Sci + 4 Sent + 2 Sondes, Carto 10 | -162        | 0,61               | 499        |
| 10 Sondes, Carto 10                 | -67         | 0,75               | 219        |

Lectures :

- **Toutes les compositions sont nettes-négatives** (cible « neutre à légèrement
  négative » respectée, aucune pompe à ressources, y compris en late avec Carto 10).
- **L'escorte lourde est la plus chère** (ratio 0,39-0,53) : c'est le prix de la sécurité,
  voulu. La reconnaissance pure est la plus proche du neutre (0,66-0,75).
- **Le coût absolu est dérisoire** : l'explorateur de référence (8 missions/jour, équipe
  standard) paie ~1 850 ressources/jour, soit ~1,5 % de son revenu au jour 15. L'exploration
  ne ruine personne ; le vrai régulateur est le temps de mission, pas le coût.
- XP/mission mesurés identiques aux valeurs utilisées pour calibrer la courbe ×1,7 et les
  checkpoints (`research_costs_v1.md`) : les deux documents sont cohérents.
- Effacement quasi-total : ~0,25 % des missions (palier critique tiré au-dessus de 95 %).

## 4. Calendrier military_camp (roster de départ acté)

Remplace l'ancien calendrier (`unit_reference.md` §4). La « fenêtre de vulnérabilité »
est abandonnée ; le kit complet arrive dans les premières heures de jeu.

| Camp | Déblocage                                      | Notes                                                                   |
| ---- | ---------------------------------------------- | ----------------------------------------------------------------------- |
| 1    | **Maraudeur + Sonde**                          | Offense + recon : raid et bootstrap exploration dès la première session |
| 2    | **Sentinelle + Mule**                          | Défense + transport : kit complet à quelques heures de jeu              |
| 3    | **Régulier** (avec Armement 1)                 | Premier déblocage croisé camp + techno                                  |
| 4    | Checkpoint technos militaires (niv 7+)         |                                                                         |
| 5    | **Spectre** (avec Renseignement 1)             | Arrive avec la feature espionnage                                       |
| 6    | À enrichir                                     | Candidats : capacité de garnison (reportée), bonus de formation         |
| 7    | Checkpoint technos militaires (niv 13+)        |                                                                         |
| 8    | **Officier** (futur, avec Guerre électronique) | Cohérent avec l'idée GDD « niv 7-10 »                                   |
| 9    | Checkpoint technos militaires (niv 17+)        |                                                                         |
| 10   | À enrichir                                     |                                                                         |

Hors calendrier camp :

- **Scientifique** : `research_lab` construit + Cartographie stellaire recherchée
  (aucun niveau de camp requis au-delà de l'existence du camp pour la production).
- **Vaisseau de colonie** : Colonisation 1. **Question ouverte** : exiger aussi un niveau
  de chantier spatial (`ship_factory`) ? Thématiquement logique, à trancher avec la
  branche vaisseaux.

## 5. Décisions de cette passe (à valider)

| #   | Décision                                                                                 | Statut  |
| --- | ---------------------------------------------------------------------------------------- | ------- |
| 1   | Tables de paliers du GDD conservées telles quelles                                       | Proposé |
| 2   | Poids de risque w (recon 0,6 / sci 1,0 / combat 1,1 / mule 1,2), communs pertes et butin | Proposé |
| 3   | Escorte : réduction des pertes = 0,5 × part d'unités de combat                           | Proposé |
| 4   | Palier critique ignore tous les modificateurs (c'est LE plancher du système)             | Proposé |
| 5   | Butin : base pondérée par w, unités de combat exclues, plafonné par le transport         | Proposé |
| 6   | Cartographie stellaire : +4 %/niv XP uniquement, -2 %/niv pertes, zéro bonus butin       | Proposé |
| 7   | Calendrier camp : 1 Mar+Sonde, 2 Sent+Mule, 3 Régulier, 5 Spectre, 8 Officier (futur)    | Proposé |
| 8   | Camp 6 et 10 sans contenu (« à enrichir »)                                               | Assumé  |
| 9   | Chantier spatial requis pour le Vaisseau de colonie ?                                    | Ouvert  |

### Retouches induites supplémentaires

- `game_design.md` §7 : « une seule mission à la fois » → **5 missions simultanées**
  (correction déjà identifiée) ; intégrer les mécanismes du §2 ci-dessus ; l'effet
  Cartographie y est décrit comme « XP & ressources » → devient XP seul.
- `tech_reference.md` §9 : ligne Cartographie stellaire à mettre à jour (répartition définie).
- `unit_reference.md` §4 : remplacer le calendrier ; §7 : ajouter poids de risque et
  mécanique d'escorte chiffrée.

---

_Proposition v1 - validée par `exploration_mc.py` (Monte Carlo, seed 42)._
