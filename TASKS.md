# TASKS.md — Final Fantasy Mobile
> Source of truth for the autonomous development loop.
> Claude reads this at the start of every session and updates it after each sprint.

---

## Sprint 1 — Project Bootstrap [STATUS: DONE]
**Goal:** Initialize Godot 4 project structure, autoloads, and main scene entry point
**Tasks:**
- [x] Create Godot 4 project.godot with correct settings (mobile portrait, 1080x1920)
- [x] Create folder structure (autoloads/, scenes/, scripts/, resources/, assets/)
- [x] Create GameManager autoload (global state: current_scene, game_state enum)
- [x] Create AudioManager autoload (placeholder BGM/SFX methods)
- [x] Create SaveSystem autoload (placeholder save/load with JSON)
- [x] Create Main.tscn as entry point (loads MainMenu on ready)
- [x] Create MainMenu.tscn (placeholder with "New Game" button)
- [x] Git init + first commit
**Review notes:** Tous les autoloads enregistrés dans project.godot. MainMenu avec titre, sous-titre doré et bouton New Game. SaveSystem JSON complet. Icon SVG placeholder créé.

---

## Sprint 2 — Player & World Map [STATUS: TODO]
**Goal:** Overworld map with a walking player character
**Tasks:**
- [ ] Create Player.gd with 4-directional movement (WASD / touch joystick)
- [ ] Create Player.tscn (CharacterBody2D + AnimatedSprite2D)
- [ ] Create simple 4-direction walk animation (placeholder colored rect, 2 frames per dir)
- [ ] Create WorldMap.tscn (TileMap with 3 terrain types: grass, mountain, water)
- [ ] Add camera that follows player with smooth lerp
- [ ] Add world boundary (player cannot walk out of map)
- [ ] Wire "New Game" button → WorldMap scene
**Review notes:**

---

## Sprint 3 — Battle System Core [STATUS: TODO]
**Goal:** Turn-based battle scene triggered by random encounter on the map
**Tasks:**
- [ ] Create BattleManager autoload (turn queue, battle state machine)
- [ ] Create Battle.tscn (battle background, player party panel, enemy panel)
- [ ] Create CombatUnit resource (.tres) with: name, hp, max_hp, mp, atk, def, spd
- [ ] Create 1 player unit (Hero) and 2 enemy types (Slime, Goblin) as resources
- [ ] Implement turn order by speed stat
- [ ] Implement "Attack" action: damage formula = max(1, attacker.atk - defender.def)
- [ ] Implement enemy AI: random attack on player
- [ ] Battle ends: victory (all enemies dead) or game over (hero hp = 0)
- [ ] Random encounter trigger on WorldMap (every N steps, configurable)
- [ ] Transition WorldMap ↔ Battle with fade effect
**Review notes:**

---

## Sprint 4 — Battle UI & Feedback [STATUS: TODO]
**Goal:** Proper battle UI with menus, HP bars, damage numbers
**Tasks:**
- [ ] Create ActionMenu.tscn (Fight / Magic / Item / Run buttons)
- [ ] HP bar component (custom ProgressBar with animated fill)
- [ ] Damage number popup (label that floats up and fades)
- [ ] Status text log (scrollable panel showing last 3 actions)
- [ ] Player turn: show action menu → wait for input → execute
- [ ] Enemy turn: show "Enemy attacks!" → animate → deal damage
- [ ] Victory screen: "Victory! +XP +Gold" with continue button
- [ ] Game Over screen with "Return to Menu" button
**Review notes:**

---

## Sprint 5 — Progression System [STATUS: TODO]
**Goal:** XP, leveling, and gold economy
**Tasks:**
- [ ] Add to CombatUnit: xp_reward, gold_reward, level, xp, xp_to_next_level
- [ ] Implement XP gain after battle victory
- [ ] Implement level-up: increase atk/def/hp_max, heal to full, show level-up popup
- [ ] Gold system: gain gold from battles, store in GameManager
- [ ] Persist player stats between battles (GameManager.player_unit)
- [ ] Display level and gold on WorldMap HUD
**Review notes:**

---

## Sprint 6 — Magic System [STATUS: TODO]
**Goal:** MP-based spell casting with 3 spells
**Tasks:**
- [ ] Add mp, max_mp to CombatUnit
- [ ] Create Spell resource: name, mp_cost, damage_multiplier, effect_type (damage/heal/buff)
- [ ] Create 3 spells: Fire (damage), Cure (heal), Haste (speed buff 2 turns)
- [ ] Magic menu in battle: list available spells with MP cost, greyed out if not enough MP
- [ ] Implement spell effects in BattleManager
- [ ] MP restore: 20% MP restore after battle victory
- [ ] Display MP bar in battle UI alongside HP bar
**Review notes:**

---

## Sprint 7 — Save System [STATUS: TODO]
**Goal:** Working save/load with 3 save slots
**Tasks:**
- [ ] Implement SaveSystem.save(slot, data) → JSON file in user://
- [ ] Implement SaveSystem.load(slot) → returns dict or null
- [ ] Save data includes: player stats, level, xp, gold, map position, spells
- [ ] Save Menu scene (3 slots showing level + playtime + timestamp)
- [ ] Auto-save after each battle victory
- [ ] Load menu accessible from MainMenu
- [ ] "Save & Quit" option in pause menu on WorldMap
**Review notes:**

---

## Sprint 8 — Audio & Polish [STATUS: TODO]
**Goal:** Music, SFX, and basic visual polish
**Tasks:**
- [ ] Generate placeholder BGM loops with Godot's AudioStreamGenerator (simple sine tones)
- [ ] WorldMap BGM, Battle BGM, Victory jingle (3 distinct tones)
- [ ] SFX: attack hit, spell cast, level up, button click (Godot AudioStreamGenerator)
- [ ] Screen shake on hit (Camera2D offset tween)
- [ ] Flash white on damage (modulate tween on sprite)
- [ ] Smooth scene transitions (ColorRect fade in/out)
- [ ] Settings menu: BGM volume, SFX volume (sliders saved to config)
**Review notes:**

---

## Sprint 9 — Mobile Controls [STATUS: TODO]
**Goal:** Touch-native controls for Android/iOS
**Tasks:**
- [ ] Virtual joystick for WorldMap movement (TouchScreenButton or custom)
- [ ] All battle UI buttons sized minimum 44dp for touch targets
- [ ] Swipe gesture detection (reserved for future use, log swipe direction)
- [ ] Test all UI at 1080x1920 portrait — no elements cropped
- [ ] Export template setup instructions in README (Android + iOS)
- [ ] Add mobile-specific project.godot settings (orientations, icon, splash)
**Review notes:**

---

## Sprint 10 — First Dungeon [STATUS: TODO]
**Goal:** A 5-room dungeon with a boss encounter
**Tasks:**
- [ ] Create Dungeon.tscn (TileMap, darker palette, torchlight via PointLight2D)
- [ ] 5 rooms connected by doors (player triggers room transition on door collision)
- [ ] Dungeon-specific enemies: Skeleton (high def), Bat (high spd)
- [ ] Boss enemy resource: DarkKnight (high hp/atk, 2 attacks per turn)
- [ ] Boss room trigger (no random encounters in boss room, scripted battle)
- [ ] Treasure chest mechanic (open → get item/gold)
- [ ] Dungeon entrance on WorldMap (walk into a specific tile)
- [ ] Victory over boss → return to WorldMap with fanfare
**Review notes:**

---

## Sprint 11 — Item System [STATUS: TODO]
**Goal:** Consumable items usable in and out of battle
**Tasks:**
- [ ] Create Item resource: name, description, effect_type, effect_value, max_stack
- [ ] 4 items: Potion (+50 HP), Hi-Potion (+150 HP), Ether (+30 MP), Phoenix Down (revive at 1HP)
- [ ] Inventory: Dictionary[item_resource] = quantity, max 9 per item
- [ ] Item menu in battle (use item on turn)
- [ ] Item shop NPC on WorldMap (buy items with gold)
- [ ] Shop UI: item list with price, gold balance, buy button
**Review notes:**

---

## Sprint 12 — Final Polish & Release Build [STATUS: TODO]
**Goal:** Build a playable demo APK with a full game loop
**Tasks:**
- [ ] Full play-through review: menu → world → 3 battles → dungeon → boss → win
- [ ] Fix any critical bugs found during review
- [ ] Add proper game icon (512x512 placeholder gradient)
- [ ] Add splash screen (2 seconds, project name)
- [ ] Write export instructions in README.md (Godot → Android APK)
- [ ] Final git tag: v0.1.0-demo
- [ ] Write DONE.md: summary of all sprints, architecture overview, known issues
**Review notes:**

---

## Backlog (Not Scheduled)
- Multiple party members
- Equipment system
- World map expansion (3 regions)
- Story & dialogue system
- Cloud save via Supabase
- Leaderboard (fastest boss clear)
