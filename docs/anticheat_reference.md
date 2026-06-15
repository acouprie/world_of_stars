# World of Stars — Référence anti-triche & abus

> Version 0.1 — Document de cadrage
> Complément au `game_design.md`, `combat_reference.md`, `unit_reference.md`, `tech_reference.md`, `building_reference.md`
> Statut : **aucune décision actée. Document de conscience et de référence pour un chantier futur (non implémenté).**

Ce document recense les abus de gameplay typiques d'un MMORTS par navigateur (type Ogame / Travian) et les contre-mesures envisageables. Il vise les abus de **gameplay et d'usage**, pas les failles de code (injection, IDOR, etc.), qui relèvent de la sécurité applicative classique et sont couvertes ailleurs (lock pessimiste, jobs idempotents, autorisation serveur, cf. `architecture.md`).

Rien ici n'est tranché. C'est un cadre de décision pour le jour où le chantier anti-abus sera ouvert.

---

## Table des matières

1. [Principe directeur](#1-principe-directeur)
2. [Modèle de menace (récapitulatif)](#2-modèle-de-menace-récapitulatif)
3. [Famille A — Multi-compte](#3-famille-a--multi-compte)
4. [Famille B — Automatisation](#4-famille-b--automatisation)
5. [Famille C — Exploitation des incitations](#5-famille-c--exploitation-des-incitations)
6. [Famille D — Méta sociale](#6-famille-d--méta-sociale)
7. [Les trois leviers de réponse](#7-les-trois-leviers-de-réponse)
8. [Mapping exploit vers contre-mesure](#8-mapping-exploit-vers-contre-mesure)
9. [Priorisation recommandée](#9-priorisation-recommandée)
10. [Questions ouvertes](#10-questions-ouvertes)

---

## 1. Principe directeur

**On ne prévient pas totalement le multi-compte ni le botting.** Au niveau HTTP, un bot qui imite des délais humains est indétectable de façon fiable, et un humain déterminé créera toujours un second compte. L'objectif n'est donc pas l'éradication mais l'élévation du coût et la réduction de l'intérêt.

Trois leviers, par ordre d'efficacité décroissante :

1. **Retirer l'intérêt de l'exploit par le design.** Le plus puissant et le moins coûteux à maintenir. Si l'avantage capturé par l'exploit n'existe plus, le bot ou le multi devient inutile et il n'y a plus rien à détecter.
2. **Détecter les patterns** (comportemental + empreinte device/navigateur), puis flagger pour revue manuelle.
3. **Ajouter de la friction ou un coût** (cooldowns, taxes, plafonds, vérification d'inscription).

**Observation clé pour ce projet :** les files de construction / recherche / production déjà conçues neutralisent l'essentiel des macros de timing. Une action où « réagir à la seconde près » donne un avantage est un appel au bot. Étendre cette discipline (pas d'avantage à la réactivité instantanée) est la meilleure défense structurelle, et elle est gratuite.

---

## 2. Modèle de menace (récapitulatif)

| #   | Exploit                                               | Famille | Couplé à un choix de design WoS ?                    | Sévérité estimée    |
| --- | ----------------------------------------------------- | ------- | ---------------------------------------------------- | ------------------- |
| 1   | Pushing par transfert de ressources                   | A       | Transferts inter-joueurs (à définir)                 | Élevée              |
| 2   | Auto-farm de soi-même via combat                      | A + C   | **Oui : table d'XP de combat inversée**              | Élevée              |
| 3   | Pushing par combat (multi gavé, pillé volontairement) | A       | Pillage hors bunker                                  | Moyenne             |
| 4   | Macros de timing (clic UI sur fin de tâche)           | B       | Largement neutralisé par les files                   | Faible              |
| 5   | Bots backend (scripts appelant les routes)            | B       | Atténué par serveur-autoritaire                      | Moyenne             |
| 6   | Auto-dodge / fleet-save automatisé                    | B       | **Oui : radar à détection anticipée**                | Moyenne à élevée    |
| 7   | Point dumping / parking de score                      | C       | **Oui : range de points + ciblage Varek par points** | Élevée              |
| 8   | Farm de comptes inactifs                              | C       | Économie de pillage                                  | Moyenne             |
| 9   | Blocage / hoarding de planètes vides                  | C       | **Oui : nombre de planètes fixé à l'init**           | Moyenne             |
| 10  | Wash-trading de réputation Elyrans                    | C       | **Oui : réputation par commerce (à définir)**        | Faible à moyenne    |
| 11  | Sitting, vente de compte, alliance-hopping            | D       | Méta sociale                                         | Faible (modération) |

---

## 3. Famille A — Multi-compte

Créer plusieurs comptes pour alimenter un compte principal.

### 3.1 Pushing par transfert direct

Le canal numéro un. Des comptes secondaires transfèrent leurs ressources au principal. Le signal le plus fiable n'est pas l'IP partagée, c'est le **flux net unidirectionnel** entre deux comptes qui n'interagissent qu'entre eux.

### 3.2 Pushing par combat

Variante furtive : le multi accumule des ressources hors bunker et se laisse piller par le principal. Pas de transfert explicite à détecter, seulement un combat « légitime » répété toujours dans le même sens.

### 3.3 Auto-farm de soi-même (voir aussi §5)

Le multi sert de partenaire d'entraînement pour farmer ce que le combat récompense. Critique dans WoS à cause de la table d'XP inversée (détaillé en §5.1).

---

## 4. Famille B — Automatisation

Faire jouer la machine à la place de l'humain.

### 4.1 Macros de timing

Programmer des clics UI déclenchés sur la fin d'une tâche (lancer la construction suivante à la seconde où la précédente finit). **Déjà largement neutralisé** par les files de construction / recherche / production : empiler des tâches retire l'avantage de la réactivité instantanée. À étendre comme principe général.

### 4.2 Bots backend

Scripts appelant directement les routes pour construire, produire ou déplacer à des instants prédéfinis. Atténué (pas annulé) par une architecture strictement serveur-autoritaire : l'état attendu (fin de construction, heure d'arrivée) est persisté et recalculé côté serveur, le client ne fait jamais autorité. Un bot peut toujours déclencher des actions valides au bon moment.

### 4.3 Auto-dodge / fleet-save automatisé

Sous-cas le plus dangereux, **amplifié par le radar de WoS**. Le radar (niveaux 5-7-9) détecte les flottes en approche à distance croissante. Un bot qui surveille ce signal et met automatiquement la flotte à l'abri dès qu'une attaque approche rend le PvP offensif quasi impossible contre un joueur botté.

**Nuance de design importante :** le fleet-save manuel est une stratégie **légitime et centrale** du genre. Seule son automatisation pose problème, et la frontière entre les deux est floue. Toute contre-mesure doit éviter de pénaliser le joueur honnête qui anticipe une attaque à la main.

---

## 5. Famille C — Exploitation des incitations

Aucun bot ni faux compte : on joue les règles à contre-sens de leur intention. C'est la famille la plus directement liée aux choix de design de WoS, donc la plus importante à arbitrer en amont.

### 5.1 Auto-farm via la table d'XP de combat inversée

`combat_reference.md` définit une table de multiplicateurs d'XP **volontairement inversée pour récompenser le combat serré**. C'est élégant pour le game feel mais c'est un vecteur direct : amener un multi à une force quasi égale, puis farmer de l'XP via des combats serrés contrôlés des deux côtés. Plus dur à détecter qu'un transfert de ressources, car le combat paraît légitime.

**C'est la conséquence la plus structurante d'un choix de design existant. À traiter en priorité.**

### 5.2 Point dumping / parking de score

WoS cumule deux mécaniques dépendant du score : la **range de points** (interdiction d'attaquer trop en dessous de soi) et le **ciblage Varek par range de points**. Conséquence : intérêt à manipuler son score à la baisse pour rester sous un seuil de protection ou sortir du radar Varek, tout en gardant son économie. Selon la formule de score, faisable en ne construisant pas, en gardant des unités au bunker, voire en sacrifiant des unités.

### 5.3 Farm de comptes inactifs

Les comptes morts deviennent des fermes à ressources sans risque, déséquilibrant l'économie. Combinable avec un multi laissé mourir gavé de ressources (rejoint §3.2).

### 5.4 Blocage / hoarding de planètes vides

Le nombre de planètes est **fixé à l'initialisation**, avec un pool réservé à l'exploration et à l'expansion. Un joueur ou une alliance peut coloniser massivement pour priver les autres, ou squatter les planètes vides proches d'une cible. La rareté volontairement conçue crée l'incitation.

### 5.5 Wash-trading de réputation Elyrans

Si le commerce qui améliore la réputation Elyrans implique des échanges chiffrés, classique du wash-trading : faire tourner des ressources en boucle (potentiellement avec un multi) pour monter la réputation sans coût réel. À cadrer au moment de designer ce système.

---

## 6. Famille D — Méta sociale

Hors mécanique pure, difficile à traiter par le code, surtout en solo.

- **Sitting** : partage de compte qui glisse vers du jeu à plusieurs.
- **Vente de compte** contre argent réel.
- **Alliance-hopping** : sauter d'alliance pour esquiver une guerre ou récupérer une protection.

Traitement réaliste : connu, accepté, géré par modération au cas par cas si le problème se matérialise.

---

## 7. Les trois leviers de réponse

### Levier 1 — Retirer l'incitation (à privilégier)

Gratuit et durable. Exemples appliqués à WoS :

- **XP de combat (§5.1)** : plafonner l'XP par adversaire unique et par fenêtre de temps, avec rendements décroissants sur les cibles répétées. Un combat serré rapporte, farmer le même multi 50 fois ne rapporte presque plus. Casse l'auto-farm sans toucher au game feel du joueur honnête.
- **Point dumping (§5.2)** : baser le score sur un **high-water-mark** (pic historique de production / puissance) plutôt que sur l'état instantané ; ou rendre coûteux / impossible de détruire ses propres bâtiments ; ou ne pas faire dépendre le ciblage Varek **uniquement** du score.
- **Auto-dodge (§4.3)** : pistes à arbitrer, aucune n'est gratuite. Un coût en ressources au rappel anticipé (thorium ?), ou une fenêtre d'engagement où l'attaque se verrouille passé un certain point. À mettre en regard de la légitimité du fleet-save manuel.
- **Principe général macros (§4.1)** : étendre la logique « files partout », aucune action ne doit récompenser la réactivité à la seconde.

### Levier 2 — Détecter les patterns

Pour ce qui ne peut pas être designé away (surtout le multi-compte).

- **Multi-compte** : empreinte navigateur + **device ID Capacitor** (l'app native est un atout : l'ID device est plus stable qu'une IP), couplé à de l'**analyse de flux**. Logger transferts et combats, calculer un flux net par paire de comptes, flagger les paires fortement asymétriques pour revue manuelle.
- **Botting** : la régularité inhumaine est le tell (activité 24/7, réactions sub-200 ms, intervalles trop réguliers). Logger les timestamps d'action, chercher les distributions non humaines. Imparfait, produit des faux positifs, donc revue manuelle.

Réalisme solo : **détecter et flagger, sanctionner à la main.** Pas de sanction automatique.

### Levier 3 — Friction et coût

- **Transferts de ressources inter-joueurs** : canal numéro un du pushing. Du plus doux au plus dur : taxe, cooldown, plafond proportionnel au score du receveur, ou **interdiction du don direct** hors mécaniques encadrées. Pour une vitrine, l'absence de transfert direct est l'option la plus simple et la plus robuste.
- **Vérification à l'inscription** : email obligatoire, éventuelle limite de comptes par device. Friction faible, efficacité partielle.
- **Rate limiting par endpoint** : nécessaire de toute façon, gêne les bots grossiers, n'arrête pas les bots patients.

---

## 8. Mapping exploit vers contre-mesure

| Exploit                        | Levier principal   | Contre-mesure pressentie                                                  |
| ------------------------------ | ------------------ | ------------------------------------------------------------------------- |
| Pushing par transfert (§3.1)   | Friction           | Pas de don direct, ou plafond + cooldown + taxe                           |
| Pushing par combat (§3.2)      | Détection          | Analyse de flux net par paire de comptes                                  |
| Auto-farm via XP combat (§5.1) | Design             | Plafond d'XP par cible unique, rendements décroissants                    |
| Macros de timing (§4.1)        | Design             | Files partout (déjà en place), à généraliser                              |
| Bots backend (§4.2)            | Design + détection | Serveur-autoritaire strict + détection de régularité                      |
| Auto-dodge (§4.3)              | Design             | Coût au rappel anticipé ou fenêtre d'engagement verrouillée               |
| Point dumping (§5.2)           | Design             | Score en high-water-mark ; ciblage Varek non purement basé sur les points |
| Comptes inactifs (§5.3)        | Design             | Décroissance / nettoyage des comptes morts (à définir)                    |
| Hoarding de planètes (§5.4)    | Design             | Coût croissant de colonisation, ou cooldown par planète                   |
| Wash-trading Elyrans (§5.5)    | Design             | Réputation sur flux net, pas sur volume brut                              |
| Méta sociale (§6)              | Modération         | Traitement manuel au cas par cas                                          |

---

## 9. Priorisation recommandée

Contexte : projet solo, vitrine technique et terrain d'apprentissage. Construire une usine anti-triche aurait un mauvais ratio effort / valeur et ne servirait pas l'objectif de showcase. Ordre conseillé le jour où le chantier s'ouvre :

1. **Design d'abord** (gratuit, durable) : XP de combat plafonnée par cible, score en high-water-mark, discipline « files partout ». Règle les exploits les plus liés aux choix de design existants.
2. **Serveur-autoritaire strict** : déjà dans la checklist `architecture.md` (jobs idempotents, état persisté, locks pessimistes). C'est ce qui empêche le botting de devenir aussi du cheat de code.
3. **Logging + flag manuel** pour le multi-compte, sans automatisation de sanction. Suffisant à l'échelle d'un serveur solo.
4. **Pas de transfert direct de ressources**, ou très encadré. Coupe le pushing classique à la racine.
5. **Méta sociale** : connu, accepté, traité par modération si ça se matérialise.

---

## 10. Questions ouvertes

| Sujet                                  | Statut                                | Note                                                                                                 |
| -------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Transferts de ressources inter-joueurs | À trancher                            | Autorisés (encadrés) ou interdits ? Détermine l'ampleur du chantier pushing                          |
| Formule de score                       | À trancher                            | High-water-mark vs état instantané : décision structurante pour le point dumping ET le ciblage Varek |
| Plafond d'XP de combat par cible       | À concevoir                           | Forme exacte des rendements décroissants, fenêtre de temps                                           |
| Coût / fenêtre du fleet-save           | À arbitrer                            | Comment freiner l'auto-dodge sans pénaliser le fleet-save manuel légitime                            |
| Nettoyage des comptes inactifs         | À définir                             | Décroissance, suppression, ou conservation comme cibles PvE                                          |
| Réputation Elyrans                     | À définir avec le système de commerce | Calage sur flux net pour éviter le wash-trading                                                      |
| Empreinte device / seuils de détection | À concevoir                           | Quels signaux logger, quels seuils de flag                                                           |

---

_Document vivant — à mettre à jour si le chantier anti-abus est ouvert._
