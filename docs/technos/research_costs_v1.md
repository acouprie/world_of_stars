# World of Stars - Coûts de recherche & checkpoints (passe économie, proposition v1)

> Complément de calibration au `tech_reference.md` v1.0 - à fusionner après validation
> dans `tech_reference.md` (checkpoints, §13) et l'Annexe D du `game_design.md` (tables de coûts).
> Statut : **proposé, validé par simulation**, en attente de validation conversationnelle.

---

## 1. Ancres de calibration (validées en conversation)

| Ancre                                                       | Valeur                                                                                      |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Mid-game (CC 5)                                             | jour 10-14                                                                                  |
| Late game (CC 10)                                           | jour 50-60                                                                                  |
| Payback cible des technos économiques                       | 72-168 h (bande mid-game, sur 1 planète)                                                    |
| Portée des technologies                                     | **Compte entier** (toutes les planètes du joueur)                                           |
| Curseur k unités                                            | **k = 5**                                                                                   |
| Part du revenu allouée à la recherche (joueur de référence) | ~30 %                                                                                       |
| Budget énergie late                                         | Contrainte maintenue (Conversion solaire-only +4 %/niv max 10, Supraconductivité supprimée) |

Justification du « coût supérieur aux bâtiments » : une techno s'applique à **toutes les planètes**.
Les hauts niveaux ont un payback mauvais sur 1 planète mais rentrent dans la fenêtre 72-168 h
avec 2-3 planètes colonisées (Forage 18 : ~176 h sur 3 mines de métal niv 20).

## 2. Modèle de coût et de temps

```
coût(n)  = base × f^(n-1)      (total ressources, réparti métal/nourriture/thorium)
temps(n) = t_base × g^(n-1)    (g > f : la « montée lente » vient du temps, pas du coût)
```

- Le **coût** suit la fenêtre de payback (f = 1,40-1,45 ; plus doux que les bâtiments).
- Le **temps** est plus raide (g = 1,55-1,70) : les derniers niveaux des technos phares
  prennent plusieurs jours de file (Forage 18 = 9j 13h), c'est l'horloge du long terme.
- File de recherche unique : maxer tout l'arbre représente ~130-140 jours de file cumulée,
  l'endgame multi-mois voulu.
- Pas de coût en énergie, pas d'entretien. Arrondis : 3 chiffres significatifs.

| Famille             | base           | f    | t_base | g    | Technos                                                                             |
| ------------------- | -------------- | ---- | ------ | ---- | ----------------------------------------------------------------------------------- |
| Phare 18 niveaux    | 1 600          | 1,40 | 8 min  | 1,55 | Forage cristallin, Hydroponie, Armement, Blindage tactique                          |
| Profonde 15 niveaux | 2 400          | 1,40 | 10 min | 1,55 | Raffinage du thorium, Guerre électronique                                           |
| Support 10 niveaux  | 800-1 800      | 1,45 | 6 min  | 1,60 | Conversion énergétique (800), Cartographie stellaire (1 000), Renseignement (1 800) |
| Gate                | 2 000 (unique) | -    | 30 min | -    | Technologie Cristal                                                                 |
| Palier              | manuel         | -    | manuel | -    | Colonisation (50k / 150k)                                                           |
| Breakthrough        | 60 000         | 1,60 | 12 h   | 1,70 | Régénération cellulaire                                                             |

## 3. Courbe d'exploration - changement requis

**La courbe documentée (`game_design.md` §7 : niv 1 = 400 XP, ×1,2/niveau) est incompatible
avec le design des checkpoints** : la production d'XP d'une équipe croît bien plus vite (Sondes →
pile de Scientifiques, ~×10) que les seuils (×1,2^9 ≈ ×5,2). Simulation : explo 10 tombe au
**jour 10**, ce qui viderait l'axe exploration de toute progression.

**Proposition : seuils ×1,7/niveau** (niv 1 = 400 inchangé, amorçage préservé). Bases d'XP
unitaires : Scientifique 60, Sonde 25, contribution fixe des autres unités 10. Multiplicateur
de gains ×1,0292 par niveau conservé.

| Facteur            | explo 1 | explo 3 | explo 5 | explo 7 | explo 8 | explo 10 |
| ------------------ | ------- | ------- | ------- | ------- | ------- | -------- |
| ×1,2 (actuel)      | j1,4    | j4,3    | j5,7    | j7,5    | j8,2    | **j10**  |
| **×1,7 (proposé)** | j1,4    | j5,0    | j9,0    | j16,6   | j22,2   | **j41**  |

(Joueur explorateur de référence : 6 missions/jour au départ avec des Sondes, montée à 8-10/jour
avec 4-8 Scientifiques escortés ; hypothèse à confirmer.)

Seuils résultants (XP par niveau) : 400, 680, 1 156, 1 965, 3 341, 5 680, 9 656, 16 415,
27 906, 47 440. Cumul explo 10 ≈ 114 000 XP.

## 4. Checkpoints chiffrés (labo / exploration / camp militaire)

Format `Niv ≥ X : prérequis`. Le déblocage (niveau 1) est la première ligne.

| Technologie             | Niv 1                     | Checkpoint 2                | Checkpoint 3                 | Checkpoint 4                  |
| ----------------------- | ------------------------- | --------------------------- | ---------------------------- | ----------------------------- |
| Forage cristallin       | labo 1, explo 1           | 7 : labo 4, explo 4         | 13 : labo 7, explo 6         | 17 : labo 10, explo 8         |
| Hydroponie              | labo 1, explo 1           | 7 : labo 4, explo 4         | 13 : labo 7, explo 6         | 17 : labo 10, explo 8         |
| Raffinage du thorium    | labo 2, explo 2, Forage 5 | 6 : labo 5, explo 4         | 11 : labo 8, explo 6         | -                             |
| Conversion énergétique  | labo 1, explo 1           | 6 : labo 4, explo 3         | -                            | -                             |
| Armement                | labo 1, explo 1           | 7 : labo 4, camp 4, explo 4 | 13 : labo 7, camp 7, explo 6 | 17 : labo 10, camp 9, explo 8 |
| Blindage tactique       | labo 1, explo 1           | 7 : labo 4, camp 4, explo 4 | 13 : labo 7, camp 7, explo 6 | 17 : labo 10, camp 9, explo 8 |
| Guerre électronique     | labo 2, explo 2           | 6 : labo 5, camp 4, explo 4 | 11 : labo 8, camp 7, explo 6 | -                             |
| Cartographie stellaire  | labo 1, explo 1           | 4 : labo 3, explo 2         | 8 : labo 6, explo 4          | -                             |
| Technologie Cristal     | labo 1, explo 1           | -                           | -                            | -                             |
| Renseignement           | labo 2, explo 2           | 4 : labo 4, explo 3         | 8 : labo 7, explo 5          | -                             |
| Colonisation            | labo 4, explo 2           | 2 : explo 4                 | -                            | -                             |
| Régénération cellulaire | labo 7, explo 8           | 3 : explo 9                 | 5 : explo 10                 | -                             |

## 5. Validation par simulation

Simulateur intégré (revenu réaliste ancré sur le tempo, file de recherche unique,
politique de recherche type, exploration simulée) :

**Joueur de référence (30 % du revenu en recherche, explorateur actif) :**

- Conversion 4 au **j3,3** (la fenêtre du gate nucléaire avant CC 5 est large)
- Technologie Cristal au j3,6 ; Forage 5 au j5,7 ; Colonisation 1 au j17,6
- Régénération cellulaire 1 au j29 ; Forage 18 au j60 ; Armement 18 au j84
- Le gate exploration **ne le bloque jamais** ; le labo le retient 3 fois, de 1 à 2 jours
  (règle de calibration du §3 de `tech_reference.md` respectée)

**Rusher recherche (60 % du revenu) :** retenu 6 fois par les checkpoints (0,2 à 4,6 jours,
labo et camp militaire). Les gates ont des dents sans être des murs.

**Non-explorateur :** intégralement bloqué (cohérent : le labo lui-même exige explo).

## 6. Hypothèses à confirmer

1. **Courbe d'exploration ×1,7** (remplace ×1,2 dans `game_design.md` §7) et bases d'XP
   unitaires (Scientifique 60, Sonde 25, autres 10).
2. **Joueur explorateur de référence** : 6-10 missions/jour. Si la cible est plus casual
   (3-4/jour), passer le facteur à ×1,5-1,6.
3. Coûts de Colonisation (50k / 150k) et de Régénération cellulaire (base 60k) posés
   par jugement, sans ancre formelle.
4. Part recherche 30 % du revenu : convention de calibration, pas une règle de jeu.

---

## 7. Tables complètes par technologie

### Forage cristallin

`coût(n) = 1600 × 1.4^(n-1)` réparti 50/30/20 (M/N/T) · `temps(n) = 8 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 800     | 480        | 320     | 1 600   | 8m      |
| 2   | 1 125   | 670        | 450     | 2 250   | 12m     |
| 3   | 1 575   | 940        | 625     | 3 125   | 19m     |
| 4   | 2 200   | 1 325      | 880     | 4 400   | 30m     |
| 5   | 3 075   | 1 850      | 1 225   | 6 150   | 46m     |
| 6   | 4 300   | 2 575      | 1 725   | 8 600   | 1h 12m  |
| 7   | 6 025   | 3 625      | 2 400   | 12 000  | 1h 51m  |
| 8   | 8 425   | 5 050      | 3 375   | 16 900  | 2h 52m  |
| 9   | 11 800  | 7 075      | 4 725   | 23 600  | 4h 27m  |
| 10  | 16 500  | 9 925      | 6 600   | 33 100  | 6h 53m  |
| 11  | 23 100  | 13 900     | 9 250   | 46 300  | 10h 40m |
| 12  | 32 400  | 19 400     | 13 000  | 64 800  | 16h 33m |
| 13  | 45 400  | 27 200     | 18 100  | 90 700  | 1j 01h  |
| 14  | 63 500  | 38 100     | 25 400  | 127 000 | 1j 15h  |
| 15  | 88 900  | 53 300     | 35 600  | 178 000 | 2j 13h  |
| 16  | 124 500 | 74 700     | 49 800  | 249 000 | 3j 23h  |
| 17  | 174 000 | 104 500    | 69 700  | 348 500 | 6j 04h  |
| 18  | 244 000 | 146 500    | 97 600  | 488 000 | 9j 13h  |

_Cumul : 1 703 500 ressources · 26j 22h de recherche._

### Hydroponie

`coût(n) = 1600 × 1.4^(n-1)` réparti 50/30/20 (M/N/T) · `temps(n) = 8 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 800     | 480        | 320     | 1 600   | 8m      |
| 2   | 1 125   | 670        | 450     | 2 250   | 12m     |
| 3   | 1 575   | 940        | 625     | 3 125   | 19m     |
| 4   | 2 200   | 1 325      | 880     | 4 400   | 30m     |
| 5   | 3 075   | 1 850      | 1 225   | 6 150   | 46m     |
| 6   | 4 300   | 2 575      | 1 725   | 8 600   | 1h 12m  |
| 7   | 6 025   | 3 625      | 2 400   | 12 000  | 1h 51m  |
| 8   | 8 425   | 5 050      | 3 375   | 16 900  | 2h 52m  |
| 9   | 11 800  | 7 075      | 4 725   | 23 600  | 4h 27m  |
| 10  | 16 500  | 9 925      | 6 600   | 33 100  | 6h 53m  |
| 11  | 23 100  | 13 900     | 9 250   | 46 300  | 10h 40m |
| 12  | 32 400  | 19 400     | 13 000  | 64 800  | 16h 33m |
| 13  | 45 400  | 27 200     | 18 100  | 90 700  | 1j 01h  |
| 14  | 63 500  | 38 100     | 25 400  | 127 000 | 1j 15h  |
| 15  | 88 900  | 53 300     | 35 600  | 178 000 | 2j 13h  |
| 16  | 124 500 | 74 700     | 49 800  | 249 000 | 3j 23h  |
| 17  | 174 000 | 104 500    | 69 700  | 348 500 | 6j 04h  |
| 18  | 244 000 | 146 500    | 97 600  | 488 000 | 9j 13h  |

_Cumul : 1 703 500 ressources · 26j 22h de recherche._

### Raffinage du thorium

`coût(n) = 2400 × 1.4^(n-1)` réparti 50/30/20 (M/N/T) · `temps(n) = 10 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 1 200   | 720        | 480     | 2 400   | 10m     |
| 2   | 1 675   | 1 000      | 670     | 3 350   | 16m     |
| 3   | 2 350   | 1 400      | 940     | 4 700   | 24m     |
| 4   | 3 300   | 1 975      | 1 325   | 6 575   | 37m     |
| 5   | 4 600   | 2 775      | 1 850   | 9 225   | 58m     |
| 6   | 6 450   | 3 875      | 2 575   | 12 900  | 1h 29m  |
| 7   | 9 025   | 5 425      | 3 625   | 18 100  | 2h 19m  |
| 8   | 12 600  | 7 600      | 5 050   | 25 300  | 3h 35m  |
| 9   | 17 700  | 10 600     | 7 075   | 35 400  | 5h 33m  |
| 10  | 24 800  | 14 900     | 9 925   | 49 600  | 8h 36m  |
| 11  | 34 700  | 20 800     | 13 900  | 69 400  | 13h 20m |
| 12  | 48 600  | 29 200     | 19 400  | 97 200  | 20h 41m |
| 13  | 68 000  | 40 800     | 27 200  | 136 000 | 1j 08h  |
| 14  | 95 200  | 57 100     | 38 100  | 190 500 | 2j 01h  |
| 15  | 133 500 | 80 000     | 53 300  | 266 500 | 3j 05h  |

_Cumul : 927 500 ressources · 9j 00h de recherche._

### Conversion énergétique

`coût(n) = 800 × 1.45^(n-1)` réparti 40/25/35 (M/N/T) · `temps(n) = 6 min × 1.6^(n-1)`

| Niv | Métal | Nourriture | Thorium | Total  | Temps  |
| --- | ----- | ---------- | ------- | ------ | ------ |
| 1   | 320   | 200        | 280     | 800    | 6m     |
| 2   | 465   | 290        | 405     | 1 150  | 10m    |
| 3   | 675   | 420        | 590     | 1 675  | 15m    |
| 4   | 975   | 610        | 855     | 2 450  | 25m    |
| 5   | 1 425 | 885        | 1 250   | 3 525  | 39m    |
| 6   | 2 050 | 1 275      | 1 800   | 5 125  | 1h 03m |
| 7   | 2 975 | 1 850      | 2 600   | 7 425  | 1h 41m |
| 8   | 4 300 | 2 700      | 3 775   | 10 800 | 2h 41m |
| 9   | 6 250 | 3 900      | 5 475   | 15 600 | 4h 18m |
| 10  | 9 075 | 5 675      | 7 925   | 22 700 | 6h 52m |

_Cumul : 71 300 ressources · 18h 10m de recherche._

### Armement

`coût(n) = 1600 × 1.4^(n-1)` réparti 45/20/35 (M/N/T) · `temps(n) = 8 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 720     | 320        | 560     | 1 600   | 8m      |
| 2   | 1 000   | 450        | 785     | 2 250   | 12m     |
| 3   | 1 400   | 625        | 1 100   | 3 125   | 19m     |
| 4   | 1 975   | 880        | 1 525   | 4 400   | 30m     |
| 5   | 2 775   | 1 225      | 2 150   | 6 150   | 46m     |
| 6   | 3 875   | 1 725      | 3 000   | 8 600   | 1h 12m  |
| 7   | 5 425   | 2 400      | 4 225   | 12 000  | 1h 51m  |
| 8   | 7 600   | 3 375      | 5 900   | 16 900  | 2h 52m  |
| 9   | 10 600  | 4 725      | 8 275   | 23 600  | 4h 27m  |
| 10  | 14 900  | 6 600      | 11 600  | 33 100  | 6h 53m  |
| 11  | 20 800  | 9 250      | 16 200  | 46 300  | 10h 40m |
| 12  | 29 200  | 13 000     | 22 700  | 64 800  | 16h 33m |
| 13  | 40 800  | 18 100     | 31 700  | 90 700  | 1j 01h  |
| 14  | 57 100  | 25 400     | 44 400  | 127 000 | 1j 15h  |
| 15  | 80 000  | 35 600     | 62 200  | 178 000 | 2j 13h  |
| 16  | 112 000 | 49 800     | 87 100  | 249 000 | 3j 23h  |
| 17  | 157 000 | 69 700     | 122 000 | 348 500 | 6j 04h  |
| 18  | 219 500 | 97 600     | 171 000 | 488 000 | 9j 13h  |

_Cumul : 1 703 500 ressources · 26j 22h de recherche._

### Blindage tactique

`coût(n) = 1600 × 1.4^(n-1)` réparti 45/20/35 (M/N/T) · `temps(n) = 8 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 720     | 320        | 560     | 1 600   | 8m      |
| 2   | 1 000   | 450        | 785     | 2 250   | 12m     |
| 3   | 1 400   | 625        | 1 100   | 3 125   | 19m     |
| 4   | 1 975   | 880        | 1 525   | 4 400   | 30m     |
| 5   | 2 775   | 1 225      | 2 150   | 6 150   | 46m     |
| 6   | 3 875   | 1 725      | 3 000   | 8 600   | 1h 12m  |
| 7   | 5 425   | 2 400      | 4 225   | 12 000  | 1h 51m  |
| 8   | 7 600   | 3 375      | 5 900   | 16 900  | 2h 52m  |
| 9   | 10 600  | 4 725      | 8 275   | 23 600  | 4h 27m  |
| 10  | 14 900  | 6 600      | 11 600  | 33 100  | 6h 53m  |
| 11  | 20 800  | 9 250      | 16 200  | 46 300  | 10h 40m |
| 12  | 29 200  | 13 000     | 22 700  | 64 800  | 16h 33m |
| 13  | 40 800  | 18 100     | 31 700  | 90 700  | 1j 01h  |
| 14  | 57 100  | 25 400     | 44 400  | 127 000 | 1j 15h  |
| 15  | 80 000  | 35 600     | 62 200  | 178 000 | 2j 13h  |
| 16  | 112 000 | 49 800     | 87 100  | 249 000 | 3j 23h  |
| 17  | 157 000 | 69 700     | 122 000 | 348 500 | 6j 04h  |
| 18  | 219 500 | 97 600     | 171 000 | 488 000 | 9j 13h  |

_Cumul : 1 703 500 ressources · 26j 22h de recherche._

### Guerre électronique

`coût(n) = 2400 × 1.4^(n-1)` réparti 45/20/35 (M/N/T) · `temps(n) = 10 min × 1.55^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 1 075   | 480        | 840     | 2 400   | 10m     |
| 2   | 1 500   | 670        | 1 175   | 3 350   | 16m     |
| 3   | 2 125   | 940        | 1 650   | 4 700   | 24m     |
| 4   | 2 975   | 1 325      | 2 300   | 6 575   | 37m     |
| 5   | 4 150   | 1 850      | 3 225   | 9 225   | 58m     |
| 6   | 5 800   | 2 575      | 4 525   | 12 900  | 1h 29m  |
| 7   | 8 125   | 3 625      | 6 325   | 18 100  | 2h 19m  |
| 8   | 11 400  | 5 050      | 8 850   | 25 300  | 3h 35m  |
| 9   | 15 900  | 7 075      | 12 400  | 35 400  | 5h 33m  |
| 10  | 22 300  | 9 925      | 17 400  | 49 600  | 8h 36m  |
| 11  | 31 200  | 13 900     | 24 300  | 69 400  | 13h 20m |
| 12  | 43 700  | 19 400     | 34 000  | 97 200  | 20h 41m |
| 13  | 61 200  | 27 200     | 47 600  | 136 000 | 1j 08h  |
| 14  | 85 700  | 38 100     | 66 700  | 190 500 | 2j 01h  |
| 15  | 120 000 | 53 300     | 93 300  | 266 500 | 3j 05h  |

_Cumul : 927 500 ressources · 9j 00h de recherche._

### Cartographie stellaire

`coût(n) = 1000 × 1.45^(n-1)` réparti 40/25/35 (M/N/T) · `temps(n) = 6 min × 1.6^(n-1)`

| Niv | Métal  | Nourriture | Thorium | Total  | Temps  |
| --- | ------ | ---------- | ------- | ------ | ------ |
| 1   | 400    | 250        | 350     | 1 000  | 6m     |
| 2   | 580    | 360        | 505     | 1 450  | 10m    |
| 3   | 840    | 525        | 735     | 2 100  | 15m    |
| 4   | 1 225  | 760        | 1 075   | 3 050  | 25m    |
| 5   | 1 775  | 1 100      | 1 550   | 4 425  | 39m    |
| 6   | 2 575  | 1 600      | 2 250   | 6 400  | 1h 03m |
| 7   | 3 725  | 2 325      | 3 250   | 9 300  | 1h 41m |
| 8   | 5 400  | 3 375      | 4 725   | 13 500 | 2h 41m |
| 9   | 7 825  | 4 875      | 6 850   | 19 500 | 4h 18m |
| 10  | 11 300 | 7 075      | 9 925   | 28 300 | 6h 52m |

_Cumul : 89 100 ressources · 18h 10m de recherche._

### Technologie Cristal

`coût(n) = 2000 × 1.0^(n-1)` réparti 40/20/40 (M/N/T) · `temps(n) = 30 min × 1.0^(n-1)`

| Niv | Métal | Nourriture | Thorium | Total | Temps |
| --- | ----- | ---------- | ------- | ----- | ----- |
| 1   | 800   | 400        | 800     | 2 000 | 30m   |

_Cumul : 2 000 ressources · 30m de recherche._

### Renseignement

`coût(n) = 1800 × 1.45^(n-1)` réparti 40/25/35 (M/N/T) · `temps(n) = 6 min × 1.6^(n-1)`

| Niv | Métal  | Nourriture | Thorium | Total  | Temps  |
| --- | ------ | ---------- | ------- | ------ | ------ |
| 1   | 720    | 450        | 630     | 1 800  | 6m     |
| 2   | 1 050  | 650        | 915     | 2 600  | 10m    |
| 3   | 1 525  | 945        | 1 325   | 3 775  | 15m    |
| 4   | 2 200  | 1 375      | 1 925   | 5 500  | 25m    |
| 5   | 3 175  | 2 000      | 2 775   | 7 950  | 39m    |
| 6   | 4 625  | 2 875      | 4 050   | 11 500 | 1h 03m |
| 7   | 6 700  | 4 175      | 5 850   | 16 700 | 1h 41m |
| 8   | 9 700  | 6 075      | 8 500   | 24 300 | 2h 41m |
| 9   | 14 100 | 8 800      | 12 300  | 35 200 | 4h 18m |
| 10  | 20 400 | 12 800     | 17 900  | 51 000 | 6h 52m |

_Cumul : 160 500 ressources · 18h 10m de recherche._

### Colonisation

Coûts manuels (paliers uniques, pas de courbe).

| Niv | Métal  | Nourriture | Thorium | Temps  |
| --- | ------ | ---------- | ------- | ------ |
| 1   | 20 000 | 15 000     | 15 000  | 1j 00h |
| 2   | 60 000 | 45 000     | 45 000  | 3j 00h |

### Régénération cellulaire

`coût(n) = 60000 × 1.6^(n-1)` réparti 35/25/40 (M/N/T) · `temps(n) = 720 min × 1.7^(n-1)`

| Niv | Métal   | Nourriture | Thorium | Total   | Temps   |
| --- | ------- | ---------- | ------- | ------- | ------- |
| 1   | 21 000  | 15 000     | 24 000  | 60 000  | 12h 00m |
| 2   | 33 600  | 24 000     | 38 400  | 96 000  | 20h 24m |
| 3   | 53 800  | 38 400     | 61 400  | 153 500 | 1j 10h  |
| 4   | 86 000  | 61 400     | 98 300  | 246 000 | 2j 10h  |
| 5   | 137 500 | 98 300     | 157 500 | 393 000 | 4j 04h  |

_Cumul : 948 500 ressources · 9j 10h de recherche._

---

_Proposition v1 - générée et validée par `research_sim.py` (simulation d'ouverture intégrée)._
