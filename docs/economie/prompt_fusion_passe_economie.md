# Prompt Claude Code - Fusion de la passe économie dans les fichiers de référence

## Contexte

La passe d'équilibrage économique de World of Stars est terminée et validée. Trois documents de calibration en sont issus et doivent maintenant être fusionnés dans les fichiers de référence du projet. Ce prompt est la spécification complète de la fusion. Travail de **documentation uniquement** : aucun fichier de code n'est modifié.

## Sources de vérité (à lire intégralement avant de commencer)

1. `docs/technos/research_costs_v1.md` - coûts de recherche, checkpoints chiffrés, courbe d'exploration ×1,7
2. `docs/exploration/exploration_magnitude_v1.md` (ou son emplacement actuel) - mécanismes d'exploration, poids de risque, calendrier military_camp
3. `docs/technos/tech_reference.md` (v1.0) - structure de l'arbre, à mettre à jour en v1.1
4. Les décisions complémentaires listées ci-dessous, qui priment en cas de conflit

## Décisions complémentaires (postérieures aux documents de calibration)

- **Supraconductivité est supprimée du roster** (doublon d'effet avec Conversion énergétique : les deux desserrent la contrainte énergétique). Elle rejoint le backlog d'enrichissement. Le roster passe à **12 technologies**.
- **Conversion énergétique est redéfinie** : bonus sur la **production de la centrale solaire uniquement**, **+4 %/niveau, 10 niveaux max** (au max : +276 ⚡ late, marge énergétique +126 → +402, la contrainte reste vivante ; mid-game : +128 ⚡ à solaire 6, soit ~2,4 niveaux de solaire). Coût : famille support, base 800, f 1,45 (table déjà dans `research_costs_v1.md`). Le gate de la centrale nucléaire reste **Conversion énergétique niveau 4**.
- **Vaisseau de colonie** : exige **Colonisation 1 + chantier spatial niveau 10 (placeholder)**. Intention : la colonisation est le relais de progression late game, quand la planète principale approche de la saturation (~jour 25-40). Le niveau exact sera calé avec la branche vaisseaux.
- **Unité Officier : probablement abandonnée.** Rétrogradée d'« idée future » à « non planifiée » dans le backlog. Le camp militaire 8 rejoint les niveaux « à enrichir ». Guerre électronique ne débloque plus rien (bonus INT uniquement).
- **Backlog d'enrichissement** : créer une section dédiée dans `game_design.md` (voir fichier 2 ci-dessous) regroupant tout ce qui est noté « à enrichir » ou « plus tard ».

---

## Fichier 1 : `docs/technos/tech_reference.md` (v1.0 → v1.1)

1. **Bandeau de statut** : passer de « valeurs placeholders » à « valeurs calibrées v1 (passe économie) ; coûts et checkpoints : voir Annexe D du game_design.md ».
2. **Supprimer Supraconductivité partout** : roster §7 (le tableau passe à 9 technos initiales), barème §9, structure de données §13, cross-dépendance Conversion 3 → Supra. L'ajouter au §11 (évolutions futures) avec la note « retirée : doublon d'effet avec Conversion énergétique ; candidate à réintroduction si la contrainte énergétique late devient trop dure ».
3. **Conversion énergétique** : mettre à jour effet (`+4 %/niv production de la centrale solaire uniquement`, max 10), §7, §9 et §13 (`effect: { type: :solar_production_bonus, per_level: 0.04 }`, `max_level: 10`).
4. **§9 Barème** : remplacer les placeholders par les valeurs calibrées : économie +6 %/niv (inchangé, confirmé), combat r = 0,04 (figé, inchangé), **Cartographie stellaire : +4 %/niv XP UNIQUEMENT et -2 %/niv pertes hors palier critique, zéro bonus butin** (la répartition est désormais définie), Régénération +5 %/niv max 5 (inchangé, coûts posés à confirmer). Supprimer le point de vigilance sur Conversion+Supra (résolu) ; conserver une note « la contrainte énergétique late est maintenue par design (marge +126 → +402 max) ».
5. **§13 Structure de données** : remplacer les valeurs de `LEVEL_PREREQUISITES` par les checkpoints chiffrés du §4 de `research_costs_v1.md` (labo / exploration / military_camp). Retirer la mention « ALL VALUES ARE PLACEHOLDERS », remplacer par « calibrated v1 (economy pass) - see game_design.md Annexe D ». Ajouter dans le commentaire du registre la clé `levels` pointant vers les tables de coûts de l'Annexe D.
6. **§14 Questions ouvertes** : retirer les lignes résolues (per_level hors combat, paliers checkpoints, tables de coûts, niveau Conversion pour la nucléaire, répartition Cartographie, contrainte énergétique late). Conserver : portée de Régénération cellulaire, nom « Technologie Cristal », cross-dépendance Colonisation ← Cartographie, coûts Colonisation/Régénération « à confirmer plus tard » (validés provisoirement à 50k/150k et base 60k).
7. **§10** : ajouter au Vaisseau de colonie la condition chantier spatial 10 (placeholder). Retirer la ligne Officier du tableau des unités avancées (la déplacer en backlog).

## Fichier 2 : `docs/game_design.md`

1. **§7 Exploration** :
   - Corriger « une seule mission à la fois » → « **jusqu'à 5 missions simultanées** » et adapter la phrase sur le débit (le débit est borné par la durée croissante des missions et la taille des équipes, plus la file unique).
   - Intégrer les mécanismes précisés (section 2 de `exploration_magnitude_v1.md`) : poids de risque par classe (recon 0,6 / sci 1,0 / combat 1,1 / mule 1,2), formule des pertes avec réduction d'escorte (0,5 × part de combat) et Cartographie (-2 %/niv), **palier critique qui ignore tous les modificateurs**, butin pondéré par le risque sur les unités non-combat uniquement, plafonné par le transport.
   - Courbe d'exploration : remplacer « ×1,2 » par « **×1,7** » (niveau 1 = 400 XP inchangé), lister les 10 seuils (400, 680, 1 156, 1 965, 3 341, 5 680, 9 656, 16 415, 27 906, 47 440). Bases d'XP unitaires : Scientifique 60, Sonde 25, Spectre 25, autres 10. Conserver le multiplicateur de gains ×1,0292.
   - Mettre à jour l'effet Cartographie stellaire (XP seul + pertes, pas de butin).
   - Mettre à jour le repère chiffré (« une équipe de 10 Sondes... ») avec les valeurs k=5 mesurées : ~-100 net/mission, ratio ~0,66, le coût d'exploration ≈ 1-2 % du revenu journalier de l'explorateur actif.
2. **Annexe A** : vérifier qu'elle correspond à la version « refonte » (réseau de dépendances, checkpoints, exploration ×1,7) ; retirer Supraconductivité du périmètre initial (12 technos), mettre à jour la ligne Conversion énergétique, et mentionner que les valeurs sont calibrées (Annexe D).
3. **Annexe D - Équilibrage** : y intégrer les tables complètes de `research_costs_v1.md` §7 (coûts et temps par niveau des 12 technos), le modèle (coût f 1,40-1,45, temps g 1,55-1,70, familles), les ancres validées (CC 5 = j10-14, CC 10 = j50-60, payback 72-168 h, recherche = portée compte entier, k = 5), et la table des coûts d'unités à k = 5 : Maraudeur 500, Régulier 575, Sentinelle 800, Scientifique 650, Sonde 750, Spectre 675, Mule 550 (répartition métal/nourriture/thorium ×5 sur la table k=1 existante de `unit_reference.md`).
4. **§12 (tableau de statut)** : passer « Calibration exploration » à **Tranché** (pointer §7 et Annexe D), « Valeur des niveaux military_camp 4/7-10 » à **Tranché** (checkpoints + calendrier, pointer `unit_reference.md` §4), ajouter une ligne « Coûts de recherche » **Tranché** (Annexe D). Ligne « Unité officier » → **Non planifiée** (backlog).
5. **Créer une section « Backlog d'enrichissement »** (sous-section du §12 ou annexe dédiée, au choix le plus propre) regroupant : military_camp niveaux 6, 8 et 10 (capacité de garnison, bonus de formation...), Supraconductivité (réintroduction conditionnelle), Officier (non planifié), Ingénierie parallèle, Chaîne de production, étiquettes de paliers (noms originaux), techno vitesse de recherche, techno capacité de stockage, files de recherche parallèles, bonus de combat par type d'unité, ligne Colonisation enrichie, cooldown d'exploration par planète, branche vaisseaux, technologies exclusives Elyrans, restriction « planètes propres » de Régénération cellulaire. Dédupliquer avec les mentions existantes éparpillées (les remplacer par un pointeur vers cette section).

## Fichier 3 : `docs/buildings/building_reference.md`

1. **Bunker** : ajouter le prérequis **Technologie Cristal niveau 1** (gate dès la construction).
2. **Centrale nucléaire** : ajouter le prérequis **Conversion énergétique niveau 4**, avec la note de calibration (crossover de coût marginal solaire/nucléaire vers solaire 7-8 ; la nucléaire 1 offre 119 ⚡ à 17,6 res/⚡).
3. **Section « couvertures minimales viables » (budget énergétique)** : corriger l'incohérence : les configurations à 2 ou 4 centrales solaires sont **impossibles** (un seul bâtiment de chaque type). Seule configuration tout-max : 1 solaire 13 + 1 nucléaire 10 = 2 858 ⚡ pour 2 732 de demande, marge +126. Ajouter : le bilan est volontairement déficitaire du CC 1 au CC 9 si l'on maxe tout au plafond CC (l'énergie est la contrainte du mid-game) ; Conversion énergétique porte la marge late à +402 max.
4. Retirer la question ouverte sur les files de production parallèles (pointer le backlog).

## Fichier 4 : `docs/units/unit_reference.md`

1. **§4** : remplacer le calendrier de déblocage par celui de `exploration_magnitude_v1.md` §4 (camp 1 Maraudeur+Sonde, 2 Sentinelle+Mule, 3 Régulier+Armement 1, 4/7/9 checkpoints, 5 Spectre+Renseignement 1, 6/8/10 à enrichir → pointer le backlog). Supprimer le paragraphe « fenêtre de vulnérabilité (voulue) » et le remplacer par une phrase actant le kit complet early (décision : les factions IA agressives rendent l'unité défensive de base indispensable dès le départ).
2. **Coûts** : appliquer k = 5 aux tables de coûts (ancre WoSG validée : soldat lourd 850 ↔ Sentinelle 800, scientifique 600 ↔ Scientifique 650). Conserver la table k=1 en référence relative si elle existe, sinon la remplacer.
3. **Scientifique** : conditions = research_lab construit + Cartographie stellaire recherchée. **Spectre** : camp 5 + Renseignement 1. **Vaisseau de colonie** : Colonisation 1 + chantier spatial 10 (placeholder).
4. **§7 Exploration** : ajouter les poids de risque et la mécanique d'escorte chiffrée (renvoyer au §7 du GDD comme source de vérité, ne dupliquer que le tableau des poids).
5. Tableau de statut : « Valeur des niveaux military_camp » → Tranché ; « Unité officier » → Non planifiée (backlog).

## Fichier 5 : `docs/combat/combat_reference.md`

1. Corriger les mentions de déblocage obsolètes : Blindage tactique ne débloque plus la Sentinelle (disponible camp 2), Guerre électronique ne débloque plus le Spectre (désormais Renseignement). 
2. Vérifier que r = 0,04 est bien noté comme figé (il l'est normalement depuis la v1.0 du tech_reference).

## Ce que tu ne fais PAS

- Tu ne modifies **aucun fichier de code** (`buildings.rb`, modèles, etc.) : les gates dans `Buildings::REGISTRY` et le futur `Technologies::REGISTRY` seront ajoutés lors de l'implémentation du système d'unités/technos. Le commentaire périmé du `training_camp` dans `buildings.rb` sera corrigé à ce moment-là.
- Tu ne recalcules ni ne modifies aucune valeur chiffrée des documents de calibration : tu fusionnes, tu ne ré-équilibres pas. En cas de contradiction entre sources, les « décisions complémentaires » de ce prompt priment, puis `exploration_magnitude_v1.md`, puis `research_costs_v1.md`.
- Tu ne réécris pas les sections qui ne sont pas listées ci-dessus.
- Tu ne supprimes pas les fichiers de calibration : ajoute-leur un bandeau « fusionné dans les fichiers de référence le [date] - conservé pour historique », ou déplace-les dans un dossier d'archives si le projet en a un.

## Critères de fin

- [ ] Plus aucune occurrence de Supraconductivité hors backlog et note de retrait
- [ ] Conversion énergétique : solaire-only +4 %/niv max 10, partout cohérent (tech_reference §7/§9/§13, GDD, building_reference)
- [ ] « Une seule mission à la fois » n'apparaît plus ; 5 missions simultanées partout
- [ ] Courbe ×1,7 et les 10 seuils dans le GDD §7 ; plus aucune mention de ×1,2
- [ ] Checkpoints chiffrés dans tech_reference §13 = tableau de research_costs_v1 §4
- [ ] Tables de coûts complètes dans l'Annexe D ; k = 5 dans unit_reference
- [ ] Calendrier military_camp remplacé ; fenêtre de vulnérabilité supprimée
- [ ] Backlog d'enrichissement créé et dédupliqué ; Officier marqué non planifié
- [ ] Incohérence « 2/4 solaires » corrigée dans building_reference
- [ ] Versions et dates des documents incrémentées (tech_reference v1.1, GDD +0.1, unit_reference +0.1, building_reference +0.1)
