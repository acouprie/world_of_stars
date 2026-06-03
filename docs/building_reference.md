# World of Stars — Référence complète des bâtiments
> Version 1.1 — Document de conception
> Complément au game_design.md et architecture.md

---

## Règles structurelles

### Slots de la grille planète

**15 slots** sur chaque planète, + **1 orbital** (radar satellite uniquement), total = 15 sol + 1 orbital = 16 emplacements physiques pour 16 bâtiments.* :

Les 15 bâtiments distincts occupent exactement 15 slots — le joueur ne choisit pas quoi construire, il choisit dans quel ordre et sur quel emplacement. Le `command_center` occupe un slot sol comme tous les autres.

| # | Bâtiment | Type de slot |
|---|---|---|
| 1 | command_center | Sol |
| 2 | solar_station | Sol |
| 3 | nuclear_plant | Sol |
| 4 | metal_mine | Sol |
| 5 | farm | Sol |
| 6 | thorium_mine | Sol |
| 7 | food_silo | Sol |
| 8 | metal_warehouse | Sol |
| 9 | thorium_warehouse | Sol |
| 10 | research_lab | Sol |
| 11 | quantum_portal | Sol |
| 12 | training_camp | Sol |
| 13 | military_camp | Sol |
| 14 | ship_factory | Sol |
| 15 | bunker | Sol |
| 16 | radar_satellite | **Orbital** |

*(Le radar occupe le 16e emplacement — l'anneau orbital — distinct des 15 slots sol.)*

---

### Plafonds de niveaux par catégorie

| Catégorie | Bâtiment | Niveaux max |
|---|---|---|
| Énergie | solar_station | 13 |
| Énergie | nuclear_plant | 10 |
| Production | metal_mine, farm, thorium_mine | 20 |
| Stockage | food_silo, metal_warehouse, thorium_warehouse | 20 |
| Infrastructure | command_center | 13 |
| Infrastructure | research_lab, quantum_portal | 10 |
| Infrastructure | radar_satellite | **10** |
| Militaire | training_camp, military_camp, bunker | 10 |
| Militaire | ship_factory | 15 |

---

### Command Center — prérequis de niveau

Le niveau du Centre de Commandement plafonne le niveau maximum accessible pour chaque bâtiment. Un bâtiment ne peut pas dépasser le plafond autorisé par le Centre de Commandement, même si les ressources sont disponibles.

| Centre de Commandement niv | solar | nuclear | mines/farm | stockage | research_lab | portal | radar | training | military | ship | bunker |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1  | niv 3  | —      | niv 3  | niv 3  | —      | —      | —      | niv 1  | —      | —      | —      |
| 2  | —      | —      | niv 5  | niv 6  | niv 1  | —      | —      | —      | niv 1  | —      | niv 1  |
| 3  | niv 6  | —      | niv 8  | —      | —      | —      | niv 1  | niv 4  | —      | niv 1  | —      |
| 4  | —      | —      | —      | niv 10 | niv 4  | niv 1  | —      | —      | niv 4  | —      | niv 4  |
| 5  | niv 9  | niv 1  | niv 12 | —      | —      | niv 5  | niv 4  | —      | —      | niv 5  | —      |
| 6  | —      | —      | —      | —      | niv 7  | —      | —      | niv 8  | —      | —      | —      |
| 7  | —      | niv 5  | niv 15 | niv 15 | —      | —      | —      | —      | niv 7  | —      | niv 8  |
| 8  | niv 12 | —      | —      | —      | —      | —      | niv 7  | —      | —      | niv 10 | —      |
| 9  | —      | —      | —      | —      | niv 10 | niv 10 | —      | niv 10 | —      | —      | —      |
| 10 | niv 13 | niv 10 | niv 18 | niv 20 | —      | —      | —      | —      | niv 10 | —      | niv 10 |
| 11 | —      | —      | —      | —      | —      | —      | niv 10 | —      | —      | niv 15 | —      |
| 13 | —      | —      | niv 20 | —      | —      | —      | —      | —      | —      | —      | —      |

**Points de design notables :**
- Le radar niv 10 (vision totale) et la ship_factory niv 15 (vaisseaux end game) requièrent Centre de Commandement niv 11 — objectifs de très long terme.
- La nuclear_plant s'ouvre à Centre de Commandement niv 5 — c'est un bâtiment mid-game.
- Le portail quantique s'ouvre à Centre de Commandement niv 4 — décision stratégique tôt dans la partie.
- Le labo de recherche s'ouvre à Centre de Commandement niv 2 — accéder à l'arbre techno est une priorité early game.

---

### Consommation d'énergie — règles générales

**Bâtiments qui consomment de l'énergie :**
- Mines et ferme (production)
- Portail quantique (infrastructure)
- training_camp, military_camp, ship_factory (militaire)

**Bâtiments sans consommation d'énergie (0 ⚡) :**
- solar_station, nuclear_plant (producteurs)
- food_silo, metal_warehouse, thorium_warehouse (stockage passif)
- command_center, research_lab (infrastructure administrative)
- radar_satellite (panneaux solaires dédiés)
- bunker (abri passif)

### Budget énergétique — scénario tout au niveau maximum

| Bâtiment | Consommation max (⚡) |
|---|---|
| metal_mine niv 20 | 478 |
| farm niv 20 | 478 |
| thorium_mine niv 20 | 478 |
| quantum_portal niv 10 | 348 |
| training_camp niv 10 | 150 |
| military_camp niv 10 | 200 |
| ship_factory niv 15 | 600 |
| **TOTAL** | **2 732 ⚡** |

**Couvertures minimales viables :**

| Configuration | Production | Marge |
|---|---|---|
| 1 solar niv 13 + 1 nuclear niv 10 | 2 858 ⚡ | +126 (serré, stratégique) |
| 2 solar niv 13 + 1 nuclear niv 10 | 3 549 ⚡ | +817 (recommandé) |
| 4 solar niv 13 | 2 764 ⚡ | +32 (solar-only, très serré) |

Un joueur peut tout monter au maximum avec **2 solaires + 1 nucléaire** en restant confortable, ou avec **1 solaire + 1 nucléaire** s'il joue précisément (aucune marge d'erreur).

---

### Le bunker — structure de données spéciale

```ruby
production: { resources: 5_000, soldiers: 50 }
```

La capacité est **globale** : 5 000 unités réparties librement entre métal, nourriture et thorium.

```ruby
def protected_resources
  production.is_a?(Hash) ? production[:resources] : 0
end

def protected_soldiers
  production.is_a?(Hash) ? production[:soldiers] : 0
end
```

---

### Le radar satellite — progression informationnelle

| Niveau | Information révélée |
|---|---|
| 1 | Présence d'une flotte en orbite (oui/non) |
| 2 | Pseudo du joueur propriétaire de la flotte en orbite |
| 3 | Composition complète de la flotte en orbite |
| 4 | Détection d'une flotte en approche (oui/non) |
| 5 | Pseudo du joueur de la flotte en approche |
| 6 | Distance approximative (loin / proche / imminent) |
| 7 | ~35% de la composition de la flotte en approche révélée |
| 8 | ~65% de la composition révélée |
| 9 | ~85% de la composition révélée |
| **10** | **100% — vision totale, aucun fog of war** |

Le niveau 10 est end game (Centre de Commandement niv 11 requis). C'est le seul niveau qui révèle tout sans exception.

---

## REGISTRY complet — valeurs par bâtiment

---

### solar_station
**Catégorie** : énergie | **Prérequis** : command_center | **energy_producer** : true | **13 niveaux**

| Niv | Métal | Nourriture | Thorium | Énergie conso. | Production (⚡) | Temps |
|---|---|---|---|---|---|---|
| 1  | 50      | 25      | 0 | 0 | 55    | 1m 30s   |
| 2  | 75      | 37      | 0 | 0 | 108   | 2m 51s   |
| 3  | 112     | 56      | 0 | 0 | 161   | 5m 25s   |
| 4  | 168     | 84      | 0 | 0 | 214   | 10m 17s  |
| 5  | 253     | 126     | 0 | 0 | 267   | 19m 32s  |
| 6  | 379     | 189     | 0 | 0 | 320   | 37m 08s  |
| 7  | 569     | 284     | 0 | 0 | 373   | 1h 10m   |
| 8  | 854     | 427     | 0 | 0 | 426   | 2h 14m   |
| 9  | 1 281   | 640     | 0 | 0 | 479   | 4h 14m   |
| 10 | 1 922   | 961     | 0 | 0 | 532   | 8h 04m   |
| 11 | 2 883   | 1 441   | 0 | 0 | 585   | 15h 19m  |
| 12 | 4 324   | 2 162   | 0 | 0 | 638   | 1j 05h   |
| 13 | 6 487   | 3 243   | 0 | 0 | 691   | 2j 07h   |

---

### nuclear_plant
**Catégorie** : énergie | **Prérequis** : command_center (niv 5) | **energy_producer** : true | **10 niveaux**

| Niv | Métal    | Nourriture | Thorium | Énergie conso. | Production (⚡) | Temps   |
|---|---|---|---|---|---|---|
| 1  | 1 200    | 900        | 0       | 0              | 119             | 2m 30s  |
| 2  | 2 280    | 1 710      | 0       | 0              | 150             | 6m 00s  |
| 3  | 4 332    | 3 249      | 0       | 0              | 198             | 10m 17s |
| 4  | 8 230    | 6 173      | 0       | 0              | 271             | 18m 23s |
| 5  | 15 638   | 11 728     | 0       | 0              | 378             | 33m 50s |
| 6  | 29 713   | 22 284     | 0       | 0              | 534             | 1h 03m  |
| 7  | 56 455   | 42 341     | 0       | 0              | 758             | 1h 58m  |
| 8  | 107 264  | 80 448     | 0       | 0              | 1 078           | 3h 44m  |
| 9  | 203 802  | 152 852    | 0       | 0              | 1 531           | 7h 05m  |
| 10 | 387 225  | 290 418    | 0       | 0              | 2 167           | 13h 27m |

---

### metal_mine
**Catégorie** : production | **Prérequis** : command_center | **20 niveaux**

| Niv | Métal    | Nourriture | Thorium | Énergie conso. | Production (métal/h) | Temps   |
|---|---|---|---|---|---|---|
| 1  | 60       | 20         | 0       | 11             | 24                   | 53s     |
| 2  | 105      | 30         | 0       | 46             | 57                   | 1m 35s  |
| 3  | 157      | 45         | 0       | 70             | 103                  | 2m 50s  |
| 4  | 236      | 67         | 0       | 94             | 165                  | 5m 06s  |
| 5  | 354      | 101        | 0       | 118            | 248                  | 9m 11s  |
| 6  | 531      | 151        | 0       | 142            | 358                  | 16m 32s |
| 7  | 797      | 227        | 0       | 166            | 501                  | 29m 45s |
| 8  | 1 196    | 341        | 0       | 190            | 687                  | 53m 34s |
| 9  | 1 794    | 512        | 0       | 214            | 928                  | 1h 36m  |
| 10 | 2 691    | 768        | 0       | 238            | 1 238                | 2h 53m  |
| 11 | 4 036    | 1 153      | 0       | 262            | 1 634                | 5h 12m  |
| 12 | 6 054    | 1 729      | 0       | 286            | 2 139                | 9h 22m  |
| 13 | 9 082    | 2 594      | 0       | 310            | 2 781                | 16h 51m |
| 14 | 13 623   | 3 892      | 0       | 334            | 3 594                | 1j 06h  |
| 15 | 20 435   | 5 838      | 0       | 358            | 4 622                | 2j 06h  |
| 16 | 30 652   | 8 757      | 0       | 382            | 5 916                | 4j 02h  |
| 17 | 45 978   | 13 136     | 0       | 406            | 7 543                | 7j 09h  |
| 18 | 68 968   | 19 705     | 0       | 430            | 9 584                | 13j 07h |
| 19 | 103 452  | 29 557     | 0       | 454            | 12 140               | 23j 21h |
| 20 | 155 178  | 44 336     | 0       | 478            | 15 355               | 43j 02h |

---

### farm
**Catégorie** : production | **Prérequis** : command_center | **20 niveaux**

| Niv | Métal    | Nourriture | Thorium | Énergie conso. | Production (nourr./h) | Temps   |
|---|---|---|---|---|---|---|
| 1  | 60       | 50         | 0       | 22             | 18                    | 53s     |
| 2  | 90       | 75         | 0       | 46             | 21                    | 1m 35s  |
| 3  | 135      | 112        | 0       | 70             | 51                    | 2m 50s  |
| 4  | 202      | 168        | 0       | 94             | 93                    | 5m 06s  |
| 5  | 303      | 253        | 0       | 118            | 149                   | 9m 11s  |
| 6  | 405      | 379        | 0       | 142            | 223                   | 16m 32s |
| 7  | 683      | 569        | 0       | 166            | 322                   | 29m 45s |
| 8  | 1 025    | 854        | 0       | 190            | 451                   | 53m 34s |
| 9  | 1 537    | 1 281      | 0       | 214            | 619                   | 1h 36m  |
| 10 | 2 306    | 1 922      | 0       | 238            | 835                   | 2h 53m  |
| 11 | 3 459    | 2 883      | 0       | 262            | 1 114                 | 5h 12m  |
| 12 | 5 189    | 4 324      | 0       | 286            | 1 471                 | 9h 22m  |
| 13 | 7 784    | 6 487      | 0       | 310            | 1 925                 | 16h 51m |
| 14 | 11 677   | 9 730      | 0       | 334            | 2 503                 | 1j 06h  |
| 15 | 17 515   | 14 596     | 0       | 358            | 3 235                 | 2j 06h  |
| 16 | 26 273   | 21 894     | 0       | 382            | 4 159                 | 4j 02h  |
| 17 | 45 978   | 32 842     | 0       | 406            | 5 324                 | 7j 09h  |
| 18 | 68 968   | 49 263     | 0       | 430            | 6 788                 | 13j 07h |
| 19 | 88 673   | 73 894     | 0       | 454            | 8 625                 | 23j 21h |
| 20 | 133 010  | 110 841    | 0       | 478            | 10 926                | 43j 02h |

---

### thorium_mine
**Catégorie** : production | **Prérequis** : command_center | **20 niveaux**

| Niv | Métal    | Nourriture | Thorium | Énergie conso. | Production (thor./h) | Temps   |
|---|---|---|---|---|---|---|
| 1  | 50       | 40         | 0       | 22             | 18                   | 53s     |
| 2  | 75       | 60         | 0       | 46             | 43                   | 1m 35s  |
| 3  | 112      | 90         | 0       | 70             | 77                   | 2m 50s  |
| 4  | 168      | 135        | 0       | 94             | 124                  | 5m 06s  |
| 5  | 253      | 202        | 0       | 118            | 186                  | 9m 11s  |
| 6  | 379      | 303        | 0       | 142            | 268                  | 16m 32s |
| 7  | 569      | 455        | 0       | 166            | 376                  | 29m 45s |
| 8  | 854      | 683        | 0       | 190            | 515                  | 53m 34s |
| 9  | 1 281    | 1 025      | 0       | 214            | 696                  | 1h 36m  |
| 10 | 1 922    | 1 537      | 0       | 238            | 928                  | 2h 53m  |
| 11 | 2 883    | 2 306      | 0       | 262            | 1 225                | 5h 12m  |
| 12 | 4 324    | 3 459      | 0       | 286            | 1 604                | 9h 22m  |
| 13 | 6 487    | 5 189      | 0       | 310            | 2 086                | 16h 51m |
| 14 | 9 730    | 7 784      | 0       | 334            | 2 696                | 1j 06h  |
| 15 | 14 596   | 11 677     | 0       | 358            | 3 466                | 2j 06h  |
| 16 | 21 894   | 17 515     | 0       | 382            | 4 437                | 4j 02h  |
| 17 | 32 842   | 26 273     | 0       | 406            | 5 657                | 7j 09h  |
| 18 | 49 263   | 39 410     | 0       | 430            | 7 188                | 13j 07h |
| 19 | 73 894   | 59 115     | 0       | 454            | 9 105                | 23j 21h |
| 20 | 110 841  | 88 673     | 0       | 478            | 11 501               | 43j 02h |

---

### food_silo
**Catégorie** : stockage | **Prérequis** : command_center | **20 niveaux** | Énergie conso. : 0

| Niv | Métal    | Nourriture | Thorium | Capacité (nourr.) | Temps    |
|---|---|---|---|---|---|
| 1  | 65       | 65         | 0       | 21 000            | 49s      |
| 2  | 97       | 97         | 0       | 28 000            | 1m 32s   |
| 3  | 146      | 146        | 0       | 47 000            | 2m 56s   |
| 4  | 219      | 219        | 0       | 84 000            | 4m 22s   |
| 5  | 329      | 329        | 0       | 145 000           | 10m 35s  |
| 6  | 493      | 493        | 0       | 236 000           | 20m 07s  |
| 7  | 740      | 740        | 0       | 363 000           | 38m 13s  |
| 8  | 1 110    | 1 110      | 0       | 532 000           | 1h 12m   |
| 9  | 1 665    | 1 665      | 0       | 749 000           | 2h 17m   |
| 10 | 2 498    | 2 498      | 0       | 1 020 000         | 4h 21m   |
| 11 | 3 748    | 3 748      | 0       | 1 351 000         | 8h 18m   |
| 12 | 5 622    | 5 622      | 0       | 1 748 000         | 15h 46m  |
| 13 | 8 433    | 8 433      | 0       | 2 217 000         | 1j 05h   |
| 14 | 12 650   | 12 650     | 0       | 2 764 000         | 2j 09h   |
| 15 | 18 975   | 18 975     | 0       | 3 395 000         | 4j 12h   |
| 16 | 28 463   | 28 463     | 0       | 4 116 000         | 11j 09h  |
| 17 | 42 694   | 42 694     | 0       | 4 933 000         | 21j 16h  |
| 18 | 64 041   | 64 041     | 0       | 5 852 000         | 41j 06h  |
| 19 | 96 062   | 96 062     | 0       | 6 879 000         | 78j 08h  |
| 20 | 144 094  | 144 094    | 0       | 8 020 000         | 148j 17h |

---

### metal_warehouse
**Catégorie** : stockage | **Prérequis** : command_center | **20 niveaux** | Énergie conso. : 0

| Niv | Métal    | Nourriture | Thorium | Capacité (métal) | Temps    |
|---|---|---|---|---|---|
| 1  | 100      | 30         | 0       | 21 000           | 49s      |
| 2  | 150      | 45         | 0       | 28 000           | 1m 32s   |
| 3  | 225      | 67         | 0       | 47 000           | 2m 56s   |
| 4  | 337      | 101        | 0       | 84 000           | 4m 22s   |
| 5  | 506      | 151        | 0       | 145 000          | 10m 35s  |
| 6  | 759      | 227        | 0       | 236 000          | 20m 07s  |
| 7  | 1 139    | 341        | 0       | 363 000          | 38m 13s  |
| 8  | 1 708    | 512        | 0       | 532 000          | 1h 12m   |
| 9  | 2 562    | 768        | 0       | 749 000          | 2h 17m   |
| 10 | 3 844    | 1 153      | 0       | 1 020 000        | 4h 21m   |
| 11 | 5 766    | 1 729      | 0       | 1 351 000        | 8h 18m   |
| 12 | 8 649    | 2 594      | 0       | 1 748 000        | 15h 46m  |
| 13 | 12 974   | 3 892      | 0       | 2 217 000        | 1j 05h   |
| 14 | 19 461   | 5 838      | 0       | 2 764 000        | 2j 09h   |
| 15 | 29 192   | 8 757      | 0       | 3 395 000        | 4j 12h   |
| 16 | 43 789   | 13 136     | 0       | 4 116 000        | 11j 09h  |
| 17 | 65 684   | 19 705     | 0       | 4 933 000        | 21j 16h  |
| 18 | 98 526   | 29 557     | 0       | 5 852 000        | 41j 06h  |
| 19 | 147 789  | 44 336     | 0       | 6 879 000        | 78j 08h  |
| 20 | 221 683  | 66 505     | 0       | 8 020 000        | 148j 17h |

---

### thorium_warehouse
**Catégorie** : stockage | **Prérequis** : command_center | **20 niveaux** | Énergie conso. : 0

| Niv | Métal    | Nourriture | Thorium | Capacité (thor.) | Temps    |
|---|---|---|---|---|---|
| 1  | 30       | 100        | 0       | 21 000           | 49s      |
| 2  | 45       | 150        | 0       | 28 000           | 1m 32s   |
| 3  | 67       | 225        | 0       | 47 000           | 2m 56s   |
| 4  | 101      | 337        | 0       | 84 000           | 4m 22s   |
| 5  | 151      | 506        | 0       | 145 000          | 10m 35s  |
| 6  | 227      | 759        | 0       | 236 000          | 20m 07s  |
| 7  | 341      | 1 139      | 0       | 363 000          | 38m 13s  |
| 8  | 512      | 1 708      | 0       | 532 000          | 1h 12m   |
| 9  | 768      | 2 562      | 0       | 749 000          | 2h 17m   |
| 10 | 1 153    | 3 844      | 0       | 1 020 000        | 4h 21m   |
| 11 | 1 729    | 5 766      | 0       | 1 351 000        | 8h 18m   |
| 12 | 2 594    | 8 649      | 0       | 1 748 000        | 15h 46m  |
| 13 | 3 892    | 12 974     | 0       | 2 217 000        | 1j 05h   |
| 14 | 5 838    | 19 461     | 0       | 2 764 000        | 2j 09h   |
| 15 | 8 757    | 29 192     | 0       | 3 395 000        | 4j 12h   |
| 16 | 13 136   | 43 789     | 0       | 4 116 000        | 11j 09h  |
| 17 | 19 705   | 65 684     | 0       | 4 933 000        | 21j 16h  |
| 18 | 29 557   | 98 526     | 0       | 5 852 000        | 41j 06h  |
| 19 | 44 336   | 147 789    | 0       | 6 879 000        | 78j 08h  |
| 20 | 66 505   | 221 683    | 0       | 8 020 000        | 148j 17h |

---

### command_center
**Catégorie** : infrastructure | **Prérequis** : aucun | **13 niveaux** | Énergie conso. : 0

| Niv | Métal      | Nourriture  | Thorium | Temps   |
|---|---|---|---|---|
| 1  | 50         | 25          | 0       | 1m 30s  |
| 2  | 1 260      | 315         | 0       | 7m 08s  |
| 3  | 2 646      | 661         | 0       | 13m 32s |
| 4  | 5 556      | 1 389       | 0       | 25m 43s |
| 5  | 11 668     | 2 917       | 0       | 48m 52s |
| 6  | 24 504     | 6 126       | 0       | 1h 32m  |
| 7  | 51 549     | 12 864      | 0       | 2h 56m  |
| 8  | 108 865    | 27 016      | 0       | 5h 35m  |
| 9  | 226 937    | 56 734      | 0       | 10h 37m |
| 10 | 476 568    | 119 142     | 0       | 20h 10m |
| 11 | 1 000 792  | 250 168     | 0       | 1j 14h  |
| 12 | 2 101 665  | 525 416     | 0       | 3j 00h  |
| 13 | 4 413 496  | 1 103 374   | 0       | 5j 00h  |

---

### research_lab
**Catégorie** : infrastructure | **Prérequis** : command_center (niv 2) | **10 niveaux** | Énergie conso. : 0

| Niv | Métal    | Nourriture | Thorium   | Temps   |
|---|---|---|---|---|
| 1  | 300      | 100        | 250       | 1m 00s  |
| 2  | 600      | 200        | 500       | 1m 54s  |
| 3  | 1 200    | 400        | 1 000     | 3m 36s  |
| 4  | 2 400    | 800        | 2 000     | 6m 51s  |
| 5  | 4 800    | 1 600      | 4 000     | 13m 02s |
| 6  | 8 000    | 3 200      | 8 000     | 24m 45s |
| 7  | 16 000   | 6 400      | 16 000    | 47m 02s |
| 8  | 38 400   | 12 800     | 32 000    | 1h 29m  |
| 9  | 76 800   | 25 600     | 64 000    | 2h 49m  |
| 10 | 153 000  | 51 200     | 128 000   | 5h 22m  |

---

### quantum_portal
**Catégorie** : infrastructure | **Prérequis** : command_center (niv 4) | **10 niveaux**

| Niv | Métal      | Nourriture   | Thorium      | Énergie conso. | Temps    |
|---|---|---|---|---|---|
| 1  | 2 500      | 2 500        | 7 500        | 33             | 12m 30s  |
| 2  | 5 000      | 5 000        | 15 000       | 68             | 25m 00s  |
| 3  | 10 000     | 10 000       | 30 000       | 103            | 50m 00s  |
| 4  | 20 000     | 20 000       | 60 000       | 138            | 1h 40m   |
| 5  | 40 000     | 40 000       | 120 000      | 173            | 3h 20m   |
| 6  | 80 000     | 80 000       | 240 000      | 208            | 6h 40m   |
| 7  | 160 000    | 160 000      | 480 000      | 243            | 13h 20m  |
| 8  | 320 000    | 320 000      | 960 000      | 278            | 1j 02h   |
| 9  | 640 000    | 640 000      | 1 920 000    | 313            | 2j 05h   |
| 10 | 1 280 000  | 1 280 000    | 3 840 000    | 348            | 4j 01h   |

---

### radar_satellite
**Catégorie** : infrastructure (orbital) | **Prérequis** : command_center (niv 3) | **10 niveaux** | Énergie conso. : 0

| Niv | Métal      | Nourriture   | Thorium      | Information révélée | Temps   |
|---|---|---|---|---|---|
| 1  | 8 000      | 8 000        | 16 000       | Présence flotte en orbite | 1m 30s  |
| 2  | 16 000     | 16 000       | 32 000       | + Pseudo du propriétaire | 2m 51s  |
| 3  | 32 000     | 32 000       | 64 000       | + Composition orbite complète | 5m 25s  |
| 4  | 64 000     | 64 000       | 128 000      | + Présence flotte en approche | 10m 17s |
| 5  | 128 000    | 128 000      | 256 000      | + Pseudo flotte en approche | 19m 32s |
| 6  | 256 000    | 256 000      | 512 000      | + Distance (loin/proche/imminent) | 37m 08s |
| 7  | 512 000    | 512 000      | 1 024 000    | + ~35% composition approche | 1h 10m  |
| 8  | 1 024 000  | 1 024 000    | 2 048 000    | + ~65% composition approche | 2h 14m  |
| 9  | 2 048 000  | 2 048 000    | 4 096 000    | + ~85% composition approche | 4h 14m  |
| 10 | 4 096 000  | 4 096 000    | 8 192 000    | **Vision totale — 100%, aucun fog of war** | 8h 04m  |

*Niveau 10 requis : Centre de Commandement niv 11. C'est un objectif end game.*

---

### training_camp
**Catégorie** : militaire | **Prérequis** : command_center (niv 1) | **10 niveaux**

| Niv | Métal    | Nourriture | Thorium  | Énergie conso. | Unités débloquées | Temps   |
|---|---|---|---|---|---|---|
| 1  | 250      | 250        | 100      | 20             | Unités légères | 45s     |
| 2  | 500      | 500        | 128      | 35             | Unités légères améliorées | 1m 26s  |
| 3  | 1 000    | 1 000      | 400      | 50             | Unités lourdes | 2m 42s  |
| 4  | 1 344    | 1 344      | 800      | 65             | Unités lourdes améliorées | 5m 08s  |
| 5  | 2 688    | 4 000      | 1 024    | 80             | Scientifiques | 18m 34s |
| 6  | 5 376    | 5 376      | 2 048    | 95             | Archéologues | 33m 50s |
| 7  | 10 752   | 10 752     | 4 092    | 110            | Malp | 45m 17s |
| 8  | 21 504   | 21 504     | 8 192    | 125            | UAV | 1h 07m  |
| 9  | 43 008   | 43 008     | 16 384   | 135            | Unités d'élite (à définir) | 2h 07m  |
| 10 | 86 016   | 86 016     | 32 768   | 150            | Unités spéciales (à définir) | 4h 00m  |

---

### military_camp
**Catégorie** : militaire | **Prérequis** : command_center (niv 2) | **10 niveaux**

| Niv | Métal    | Nourriture | Thorium  | Énergie conso. | Temps   |
|---|---|---|---|---|---|
| 1  | 300      | 200        | 150      | 30             | 45s     |
| 2  | 600      | 400        | 300      | 50             | 1m 26s  |
| 3  | 1 200    | 800        | 600      | 70             | 2m 42s  |
| 4  | 2 400    | 1 600      | 1 200    | 90             | 5m 08s  |
| 5  | 4 800    | 3 200      | 2 400    | 110            | 18m 34s |
| 6  | 9 600    | 6 400      | 4 800    | 130            | 33m 50s |
| 7  | 19 200   | 12 800     | 9 600    | 155            | 45m 17s |
| 8  | 38 400   | 25 600     | 19 200   | 175            | 1h 07m  |
| 9  | 76 800   | 51 200     | 38 400   | 185            | 2h 07m  |
| 10 | 153 600  | 102 400    | 76 800   | 200            | 4h 00m  |

---

### ship_factory
**Catégorie** : militaire | **Prérequis** : command_center (niv 3) | **15 niveaux**

| Niv | Métal      | Nourriture  | Thorium     | Énergie conso. | Temps    |
|---|---|---|---|---|---|
| 1  | 250        | 100         | 320         | 50             | 1m 00s   |
| 2  | 500        | 200         | 640         | 90             | 1m 54s   |
| 3  | 1 000      | 400         | 1 280       | 130            | 3m 36s   |
| 4  | 2 000      | 800         | 2 560       | 165            | 6m 51s   |
| 5  | 4 000      | 1 600       | 5 120       | 205            | 13m 02s  |
| 6  | 8 000      | 3 200       | 10 240      | 245            | 24m 45s  |
| 7  | 16 000     | 6 400       | 20 480      | 285            | 47m 02s  |
| 8  | 32 000     | 12 800      | 40 960      | 325            | 1h 29m   |
| 9  | 64 000     | 25 600      | 81 920      | 365            | 2h 49m   |
| 10 | 128 000    | 51 200      | 163 840     | 405            | 5h 22m   |
| 11 | 256 000    | 102 400     | 327 680     | 445            | 10h 13m  |
| 12 | 512 000    | 204 000     | 655 360     | 480            | 19h 25m  |
| 13 | 1 024 000  | 409 600     | 1 310 720   | 520            | 1j 12h   |
| 14 | 2 048 000  | 819 200     | 2 621 440   | 560            | 2j 12h   |
| 15 | 4 096 000  | 1 638 400   | 5 242 880   | 600            | 5j 13h   |

---

### bunker
**Catégorie** : militaire | **Prérequis** : command_center (niv 2) | **10 niveaux** | Énergie conso. : 0

`production: { resources: Integer, soldiers: Integer }`

| Niv | Métal    | Nourriture | Thorium  | Ressources prot. | Soldats prot. | Temps   |
|---|---|---|---|---|---|---|
| 1  | 1 000    | 1 000      | 3 000    | 5 000            | 50            | 1m 30s  |
| 2  | 2 000    | 2 000      | 6 000    | 12 000           | 120           | 2m 51s  |
| 3  | 4 000    | 4 000      | 12 000   | 25 000           | 250           | 5m 25s  |
| 4  | 8 000    | 8 000      | 24 000   | 50 000           | 500           | 10m 17s |
| 5  | 16 000   | 16 000     | 48 000   | 100 000          | 1 000         | 19m 32s |
| 6  | 32 000   | 32 000     | 96 000   | 175 000          | 2 000         | 37m 08s |
| 7  | 64 000   | 64 000     | 192 000  | 275 000          | 4 000         | 1h 10m  |
| 8  | 128 000  | 128 000    | 348 000  | 375 000          | 7 000         | 2h 14m  |
| 9  | 256 000  | 256 000    | 768 000  | 450 000          | 12 000        | 4h 14m  |
| 10 | 512 000  | 512 000    | 1 536 000| 500 000          | 20 000        | 8h 04m  |

---

## Questions ouvertes à résoudre en tests

- Vitesse de formation des unités dans military_camp et training_camp : slots parallèles selon le niveau à définir.
- Coût d'utilisation du portail quantique (thorium par trajet) : toujours non tranché (voir questions ouvertes GDD).
- Niveaux 9-10 du training_camp : unités d'élite et spéciales à définir en Annexe C du GDD.
- Les Centre de Commandement requirements sont des paliers (Centre de Commandement niv X → bâtiment niv Y max) : à implémenter comme une table de lookup dans le modèle `Building`.
- Le radar niv 10 coûte 4M métal + 4M nourriture + 8M thorium : vérifier que ce n'est pas prohibitif au point de ne jamais être construit, ou assumer que c'est un objectif d'alliance.

---

*Document vivant v1.1 — à maintenir en parallèle de buildings.rb*