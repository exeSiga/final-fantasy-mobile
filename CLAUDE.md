# Final Fantasy Mobile — Autonomous Development System

## Project Identity
Mobile RPG inspired by Final Fantasy, built with Godot 4 (GDScript).
Target: Android & iOS. Dev mode: fully autonomous agile loop.

## Stack
- Engine: Godot 4.6+ (GDScript)
- Architecture: Scene-based, Resource-driven
- Version control: Git (commit after each sprint)
- Task management: TASKS.md (source of truth)

---

## Autonomous Loop — 4 Phases par Sprint

Au démarrage de chaque session :
1. Lire SESSION_LOG.md — voir le dernier sprint terminé
2. Lire TASKS.md — trouver le premier sprint STATUS: TODO ou IN_PROGRESS
3. Exécuter les 4 phases ci-dessous pour ce sprint
4. Passer au sprint suivant sans pause
5. Si plus aucun sprint TODO : générer 3 à 5 nouveaux sprints dans la direction Final Fantasy 7 (voir section ci-dessous), les ajouter à TASKS.md avec STATUS: TODO, puis continuer la boucle immédiatement

---

### Phase 1 — LECTURE (ne pas écrire de code encore)

- Lire les **Acceptance Criteria** du sprint dans TASKS.md
- Identifier les fichiers impactés via `grep`/`find` uniquement — ne pas lire un fichier non nécessaire
- Dresser la liste des changements à effectuer avant d'ouvrir un seul fichier

### Phase 2 — IMPLÉMENTATION

- Écrire le code complet et correct du premier coup — pas de brouillons exploratoires
- Ne pas relire un fichier qu'on vient d'écrire sauf en cas d'erreur avérée
- Préférer plusieurs petits fichiers plutôt qu'un gros
- Pour créer une scène Godot : écrire le format .tscn texte directement

### Phase 3 — CONTRÔLE OBLIGATOIRE (ne pas passer à DONE sans)

#### Contrôle A — Compatibilité statique Godot 4.6+
```bash
bash check_compat.sh
```
→ Doit afficher `✅ All clear`. Si ❌ : corriger avant de continuer.

#### Contrôle B — Parse Godot headless
```bash
timeout 12 /home/siga/godot4 --headless --check-only . 2>&1 | grep "SCRIPT ERROR"
```
→ Résultat doit être **vide**. Si une erreur apparaît : corriger avant de continuer.

#### Contrôle C — Trace logique par Acceptance Criterion
Pour chaque AC du sprint, répondre mentalement à :
1. Quel signal ou fonction déclenche ce comportement ?
2. Quel fichier:ligne implémente la logique principale ?
3. Y a-t-il des guards null là où un objet peut être absent ?
4. Que se passe-t-il si un tableau est vide, ou si l'état initial est nul ?

#### Contrôle D — Régression du chemin critique
Tracer mentalement ce flow complet après chaque sprint :
```
MainMenu → New Game → WorldMap → (mouvement) → Battle → (combat) → Victory → WorldMap
```
Ne pas marquer DONE si un maillon de ce flow est cassé.

### Phase 4 — CLÔTURE

- Remplir **Verification Notes** dans TASKS.md avec les résultats des 4 contrôles
- Marquer STATUS: **DONE** seulement si les 4 contrôles passent
  - Si un contrôle échoue → corriger et recommencer ce contrôle
  - Si bloqué → STATUS: BLOCKED + noter le blocage dans Verification Notes
- `git add -A && git commit -m "feat(sprint-N): name"`
- `git push origin master`
- Appender une ligne à SESSION_LOG.md
- `git add SESSION_LOG.md && git commit -m "log: sprint N" && git push origin master`
- Passer au sprint suivant

---

## TASKS.md Format (avec Acceptance Criteria)

```
## Sprint N — [Name] [STATUS: TODO | IN_PROGRESS | DONE | BLOCKED]
**Goal:** One-line description

**Acceptance Criteria:**
- [ ] AC1: (observable, testable — ex: "Player can cast Fire, loses 10 MP")
- [ ] AC2: (ex: "Enemy dies when HP reaches 0, disparaît de l'arène")
- [ ] AC3: (ex: "Victory screen shows correct XP and gold")

**Tasks:**
- [ ] Task description
- [x] Completed task

**Verification Notes:** (rempli pendant la Phase 3)
- Contrôle A (static): ✅ / ❌
- Contrôle B (godot parse): ✅ / ❌
- Contrôle C (logic trace):
  - AC1: [chemin de code tracé]
  - AC2: [chemin de code tracé]
- Contrôle D (regression): [ce qui a été vérifié]
- Déferments: [problèmes délibérément reportés]

**Review notes:** (rempli après completion)
```

---

## SESSION_LOG.md Format

Appender une ligne par sprint :
```
[YYYY-MM-DD HH:MM] Sprint N (name) — DONE — ~XXXX tokens used
```

---

## Règle API

Jamais d'appel réseau ou API externe (HTTP, Supabase, curl, clé API, etc.). Le jeu doit fonctionner 100% offline.

**Contexte :**
- Exécuter `/compact` dès que le contexte devient lourd (beaucoup de fichiers lus, long sprint). Avant de compacter : écrire le statut du sprint dans TASKS.md.

---

## Godot 4.6+ Compatibility — FORBIDDEN Patterns

Ces patterns compilent en 4.3 mais CASSENT en 4.6+. À mémoriser.

**Dans tous les autoloads (GameManager, BattleManager, SaveSystem, etc.) :**
Les `class_name` définis par l'utilisateur NE SONT PAS disponibles au parse-time des autoloads.

- ❌ `var x: UserClass = null` → utiliser `var x = null` (non typé)
- ❌ `var arr: Array[UserClass] = []` → utiliser `var arr: Array = []`
- ❌ `signal foo(param: UserClass)` → utiliser `signal foo(param)`
- ❌ `var x := expr as UserClass` → walrus + as-cast = erreur INFER_VARIANT
- ❌ `for e: UserClass in array:` → utiliser `for e in array:`
- ❌ `class_name Foo` + signal typé dans le même fichier .gd
- ✅ Duck-typing à l'exécution : `player_unit.hp` fonctionne sur var non typée
- ✅ Types built-in OK : `Array[int]`, `Array[String]`, `Array[float]`, `Array[Vector2]`

---

## Project Architecture (Godot 4)

```
res://
├── autoloads/         # GameManager, AudioManager, SaveSystem, BattleManager
├── scenes/
│   ├── ui/            # HUD, menus, dialogue
│   ├── combat/        # Battle scene, action menus
│   ├── world/         # WorldMap, Dungeon
│   └── characters/    # Player, NPCs, enemies
├── scripts/           # Pure GDScript
├── resources/         # .tres (CombatUnit, Spell, Item)
└── assets/            # sprites, audio, fonts
```

## Behavior Rules

- Engine: Godot 4, GDScript only (no C# unless plugin requires it)
- Prioritize playable features over perfect architecture
- Each sprint must produce something runnable
- Never refactor a DONE sprint unless in a dedicated Refactor sprint
- No exploratory reads — every file read must have a clear purpose

---

## Génération Autonome de Sprints — Direction Final Fantasy 7

Quand il n'y a plus de sprint TODO, tu dois **générer toi-même** les prochains sprints et les ajouter à TASKS.md.

### Règle de génération
- Génère 3 à 5 sprints d'un coup, numérotés à la suite du dernier sprint existant
- Chaque sprint doit faire avancer le jeu vers l'expérience Final Fantasy 7
- Priorise les features qui ont le plus d'impact gameplay visible en premier
- Chaque sprint doit être faisable en une session (scope raisonnable)
- Utilise le format complet avec Acceptance Criteria + Verification Notes vides

### Vision FF7 — Features à implémenter (par priorité décroissante)

**Couche Narrative & Personnages :**
- Personnages nommés FF7 : Cloud (Warrior), Tifa (Monk physique), Aerith (White Mage), Barret (Gunner AoE), Red XIII (Beastmaster)
- Chaque personnage a un sprite géométrique distinctif et des stats propres à sa classe
- Backstory mini-dialogues : chaque personnage a 2-3 lignes de dialogue contextuels
- Scènes narratives clés : Réacteur Mako, Slums Midgar, Rencontre avec Sephiroth

**Système de Combat Avancé :**
- Invocations (Summons) : Ifrit (feu AoE), Shiva (glace AoE), Ramuh (foudre AoE), Bahamut (néant AoE fort) — chargées via Materia Invocation
- Limit Breaks tier 2 : chaque personnage a 2 niveaux de Limit (jauge se remplit avec dégâts reçus)
- Enemy Skill Materia : apprendre les capacités ennemies en les subissant
- ATB (Active Time Battle) : jauge qui se remplit, action disponible quand pleine

**Monde & Exploration :**
- Districts de Midgar : Secteur 1 (Réacteur), Secteur 5 (Slums), Sector 7 (Bar Seventh Heaven), Shinra HQ
- Choix de dialogues avec conséquences (flags booléens simples)
- Mini-carte du monde avec zones nommées et niveau requis
- Événements aléatoires sur la world map (pas que des combats) : marchands itinérants, coffres cachés, PNJ aide

**Économie & Progression :**
- Boutique Shinra : équipements de faction (armes militaires, armures Shinra)
- Système de crafting simple : 2 matériaux → 1 item/équipement
- Rang de Soldat : 3rd Class → 2nd Class → 1st Class basé sur ennemis tués et boss vaincus
- Récompenses de donjon uniques (équipements introuvables en shop)

**Boss & Contenu Endgame :**
- Sephiroth comme boss final (3 phases, One Winged Angel BGM procédural)
- Jenova améliorée avec phases supplémentaires
- Arène de combat optionnelle (8 vagues, récompenses uniques)
- New Game+ : difficulté augmentée, ennemis avec stats ×1.5

**Polish & Immersion :**
- BGM procédural thématique par zone (thème Aerith, One Winged Angel, Bombing Mission)
- Effets météo visuels sur WorldMap (pluie = ColorRect semi-transparent animé)
- Notifications de lore (pop-up "Fichier Shinra" débloqué après certains combats)
- Écran de titre animé (texte défilant, étoiles clignotantes)

### Règles de priorisation pour la génération
1. **Ne génère jamais deux fois la même feature** — consulte la liste des sprints déjà DONE
2. **Commence par les features les plus visibles** — un joueur doit voir la différence immédiatement
3. **Évite les features trop dépendantes d'assets** — tout doit rester procédural (pas de vraies images/sons)
4. **Un sprint = une feature cohérente** — pas de mélanges de systèmes non liés
5. **Scope réaliste** — si une feature est trop grande, la découper en 2 sprints

### Format à ajouter dans TASKS.md
```
## Sprint N — [Nom feature FF7] [STATUS: TODO]
**Goal:** Description une ligne

**Acceptance Criteria:**
- [ ] AC1: (observable, testable)
- [ ] AC2:
- [ ] AC3:

**Tasks:**
- [ ] Tâche 1
- [ ] Tâche 2

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:
```
