# Final Fantasy Mobile — Autonomous Development System

## Project Identity
Mobile RPG inspired by Final Fantasy, built with Godot 4 (GDScript).
Target: Android & iOS. Dev mode: fully autonomous agile loop.

## Stack
- Engine: Godot 4.3+ (GDScript)
- Architecture: Scene-based, Resource-driven
- Version control: Git (commit after each sprint)
- Task management: TASKS.md (source of truth)

## Autonomous Loop

At the start of every session:
1. Check SESSION_LOG.md — see what was last done
2. Read TASKS.md — find first sprint STATUS: TODO or IN_PROGRESS
3. Implement all tasks in that sprint
4. Self code-review (checklist below)
5. Mark sprint DONE in TASKS.md, fill review notes
6. Git commit: `git add -A && git commit -m "feat(sprint-N): name"`
7. Append one line to SESSION_LOG.md: date + sprint done + token estimate
8. Start next sprint immediately — no pause between sprints
9. If no more TODO sprints: write DONE.md and stop

## Token Budget Rules (CRITICAL — read first)

The Pro plan ($20/month) has ~44,000 tokens per 5-hour window.
This is a HARD budget. Violating it wastes money. Always optimize.

### Rules to follow every sprint:

**Files:**
- Never read a file you don't need. Check filename before opening.
- Read only the relevant section of large files (use line ranges).
- Never cat the entire project tree — use targeted reads.

**Writing code:**
- Write complete, correct code on the first attempt. No exploratory drafts.
- Do not re-read files you just wrote unless debugging a specific error.
- Prefer writing multiple small files over one large file.

**Context hygiene:**
- Run `/compact` when context reaches ~60% full (check with `/cost`).
- Before compacting: write current sprint status to TASKS.md so you can resume.
- After compacting: re-read only TASKS.md and the files needed for the current task.

**Efficient patterns:**
- Use grep/find to locate specific code, not cat on whole files.
- When creating a Godot scene, write the .tscn text format directly — no exploration needed.
- Reuse patterns from previous sprints — check git log for reference, not re-reading files.

### When the session limit is near:
1. Complete the current task (don't stop mid-implementation)
2. Update TASKS.md with exact task status
3. Commit everything
4. Append to SESSION_LOG.md
5. Stop cleanly — the next `bash run.sh` will resume correctly

## SESSION_LOG.md Format

Append one line per sprint:
```
[YYYY-MM-DD HH:MM] Sprint N (name) — DONE — ~XXXX tokens used
```

## TASKS.md Format

```
## Sprint N — [Name] [STATUS: TODO | IN_PROGRESS | DONE | BLOCKED]
**Goal:** One-line description
**Tasks:**
- [ ] Task description
- [x] Completed task
**Review notes:** (filled after completion)
```

## Code Review Checklist

Before marking a sprint DONE:
- [ ] All sprint tasks implemented
- [ ] No hardcoded magic numbers (use constants)
- [ ] Scenes cleanly separated (no monolithic scripts)
- [ ] Signals used for decoupled communication
- [ ] No orphan nodes (queue_free used properly)
- [ ] Code: snake_case, typed variables where possible
- [ ] Godot 4.6+: no `Array[UserClass]` anywhere (use `Array`)
- [ ] Godot 4.6+: no typed signal params with user class_names
- [ ] Run `bash check_compat.sh` — must output ✅ All clear
- [ ] Run `/home/siga/godot4 --headless --check-only . 2>&1 | grep -i "SCRIPT ERROR"` — must be empty
- [ ] Git commit done

## Godot 4.6+ Compatibility — FORBIDDEN Patterns

These patterns compile in 4.3 but BREAK in 4.6+. Memorize them.

### Autoload #1 (GameManager) — class_names NOT yet registered at parse time:
- ❌ `var x: UserClass = null` → use `var x = null` (untyped)
- ❌ `var arr: Array[UserClass] = []` → use `var arr: Array = []`
- ❌ `signal foo(param: UserClass)` → use `signal foo(param)`
- ❌ `var x := expr as UserClass` → walrus + as-cast = INFER_VARIANT error
- ❌ `for e: UserClass in array:` → use `for e in array:`
- ✅ Duck-type at runtime: `player_unit.hp` works on untyped var

### Everywhere (all autoloads and scene scripts):
- ❌ `Array[UserClass]` — always use plain `Array`
- ❌ `signal foo(p: UserClass)` — remove type annotation from signal params
- ❌ `class_name Foo` + typed signal in same .gd file
- ✅ Built-in typed arrays are OK: `Array[int]`, `Array[float]`, `Array[String]`, `Array[Vector2]`, `Array[bool]`

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
