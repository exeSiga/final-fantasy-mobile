# Final Fantasy Mobile — v0.1.0-demo DONE

## Status
All 12 sprints completed. The project is a fully playable demo RPG.

## What was built

| Sprint | Feature | Status |
|--------|---------|--------|
| 1 | Project bootstrap — Godot 4 structure, autoloads, main menu | DONE |
| 2 | Player movement + WorldMap (3200×3200, 3 terrain types) | DONE |
| 3 | Turn-based battle system — CombatUnit, BattleManager, Hero/Slime/Goblin | DONE |
| 4 | Battle UI — animated HP bars, damage popups, Victory/GameOver overlays | DONE |
| 5 | Progression — XP/level-up, gold, WorldMap HUD | DONE |
| 6 | Magic system — Fire/Cure/Haste spells, MP bar, dynamic spell menu | DONE |
| 7 | Save system — 3 JSON slots, auto-save, Load from main menu | DONE |
| 8 | Audio & polish — procedural BGM/SFX (sine waves), screen shake, fade transitions, settings | DONE |
| 9 | Mobile controls — virtual joystick, swipe detector, README export guide | DONE |
| 10 | First dungeon — 5 rooms, Skeleton/Bat, DarkKnight boss (double attack), treasure chests | DONE |
| 11 | Item system — 4 consumables, inventory, battle item menu, item shop NPC | DONE |
| 12 | Final polish — bug fixes, splash screen, DONE.md, git tag | DONE |

## Architecture

```
res://
├── autoloads/        GameManager, AudioManager, SaveSystem, BattleManager, TransitionManager
├── scenes/
│   ├── ui/           Main, MainMenu, HPBar, WorldHUD, VirtualJoystick, SaveMenu, Shop, SettingsMenu
│   ├── combat/       Battle
│   └── world/        WorldMap, Dungeon
├── scenes/characters Player
├── scripts/          All GDScript controllers (one per scene)
├── resources/
│   ├── CombatUnit.gd + units/*.tres (hero, slime, goblin, skeleton, bat, dark_knight)
│   ├── Spell.gd + spells/*.tres (fire, cure, haste)
│   └── Item.gd + items/*.tres (potion, hi_potion, ether, phoenix_down)
└── assets/sprites/   icon.svg, splash.svg
```

## Key design decisions

- **Zero asset files** — all audio procedural (AudioStreamGenerator), all visuals via ColorRect
- **Signal-driven** — BattleManager communicates via signals only, Battle.gd is pure UI
- **Resource-based data** — CombatUnit/Spell/Item as .tres resources, easy to extend
- **GameManager as state hub** — persists player, gold, spells, inventory between scenes
- **TransitionManager** — fade black on every scene change via CanvasLayer layer=100

## Known issues / limitations

- AnimatedSprite2D not used (no sprites) — player and enemies are colored rectangles
- Dungeon has no wall collision — player can walk through colored terrain
- Boss battle returns to WorldMap (not back to dungeon)
- Audio uses float32 PCM via AudioStreamGenerator — may have slight buffer latency on low-end devices
- No pause menu in WorldMap (Save & Quit deferred to backlog)
- TileMap not used — terrain is ColorRect-based (no tileset system)

## Export

See README.md for Android/iOS export instructions.

## How to run

1. Open Godot 4.3+
2. Import project: File → Import → select `project.godot`
3. Press F5 to run
