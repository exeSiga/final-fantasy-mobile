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
5. Si plus aucun sprint TODO : lire **FF7_VISION.md**, générer 3 à 5 nouveaux sprints, les ajouter à TASKS.md avec STATUS: TODO, puis continuer la boucle immédiatement

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

## Génération Autonome de Sprints

Si plus aucun sprint STATUS: TODO dans TASKS.md :
1. Lire **FF7_VISION.md** pour les features restantes et les règles de génération
2. Générer 3 à 5 nouveaux sprints dans TASKS.md (STATUS: TODO)
3. Continuer la boucle immédiatement
