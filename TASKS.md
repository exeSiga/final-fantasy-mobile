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

## Sprint 2 — Player & World Map [STATUS: DONE]
**Goal:** Overworld map with a walking player character
**Tasks:**
- [x] Create Player.gd with 4-directional movement (WASD / touch joystick)
- [x] Create Player.tscn (CharacterBody2D + ColorRect placeholder)
- [x] Create simple 4-direction walk animation (placeholder colored rect)
- [x] Create WorldMap.tscn (3 terrain types: grass, mountain/lake avec ColorRect)
- [x] Add camera that follows player with smooth lerp
- [x] Add world boundary (StaticBody2D walls sur les 4 bords)
- [x] Wire "New Game" button → WorldMap scene
**Review notes:** AnimatedSprite2D remplacé par ColorRect (pas de textures). step_counter déclenche encounter_triggered signal. Camera2D lerp via position_smoothing + _process override.

---

## Sprint 3 — Battle System Core [STATUS: DONE]
**Goal:** Turn-based battle scene triggered by random encounter on the map
**Tasks:**
- [x] Create BattleManager autoload (turn queue, battle state machine)
- [x] Create Battle.tscn (battle background, player party panel, enemy panel)
- [x] Create CombatUnit resource (.tres) with: name, hp, max_hp, mp, atk, def, spd
- [x] Create 1 player unit (Hero) and 2 enemy types (Slime, Goblin) as resources
- [x] Implement turn order by speed stat
- [x] Implement "Attack" action: damage formula = max(1, attacker.atk - defender.def)
- [x] Implement enemy AI: random attack on player
- [x] Battle ends: victory (all enemies dead) or game over (hero hp = 0)
- [x] Random encounter trigger sur WorldMap (STEPS_PER_ENCOUNTER = 80)
- [ ] Transition WorldMap ↔ Battle avec fade effect (reporté au Sprint 4)
**Review notes:** BattleManager utilise les signaux pour tout découpler. Turn queue rebuilt à chaque tour. Transition fade reportée au Sprint 4 pour rester dans le budget token.

---

## Sprint 4 — Battle UI & Feedback [STATUS: DONE]
**Goal:** Proper battle UI with menus, HP bars, damage numbers
**Tasks:**
- [x] Create ActionMenu (Fight / Magic / Item / Run buttons dans Battle.tscn)
- [x] HP bar component (HPBar.gd + HPBar.tscn avec tween animé et rouge si <25%)
- [x] Damage number popup (Label flottant avec tween position+alpha)
- [x] Status text log (3 lignes max, LogLabel dans LogPanel)
- [x] Player turn: action buttons visibles → input → execute
- [x] Enemy turn: BattleManager attend 1s → attaque → signaux mis à jour
- [x] Victory screen: overlay "Victory!" avec ContinueButton
- [x] Game Over screen: overlay "Game Over" avec MenuButton
**Review notes:** PopupLayer sur layer=10 pour que les floats passent devant tout. Magic/Item greyés fonctionnellement (log message). HPBar réutilisable instanciée dynamiquement par code pour les ennemis.

---

## Sprint 5 — Progression System [STATUS: DONE]
**Goal:** XP, leveling, and gold economy
**Tasks:**
- [x] Add to CombatUnit: xp_reward, gold_reward, level, xp, xp_to_next_level
- [x] Implement XP gain after battle victory (GameManager.grant_battle_rewards)
- [x] Implement level-up: atk+3/def+2/spd+1/max_hp+20, heal to full, signal level_up
- [x] Gold system: gain gold from battles, store in GameManager.gold
- [x] Persist player stats between battles (GameManager.player_unit réutilisé par BattleManager)
- [x] Display level and gold on WorldMap HUD (WorldHUD.tscn)
**Review notes:** xp_to_next_level *= 1.4 à chaque level. Victory overlay affiche XP et Gold gagnés. WorldHUD se connecte aux signaux gold_changed et level_up.

---

## Sprint 6 — Magic System [STATUS: DONE]
**Goal:** MP-based spell casting with 3 spells
**Tasks:**
- [x] mp/max_mp déjà dans CombatUnit depuis Sprint 3
- [x] Create Spell resource: name, mp_cost, damage_multiplier, effect_type
- [x] Create 3 spells: Fire (×2.2 dmg), Cure (+60 HP), Haste (spd×2 pour 2 tours)
- [x] Magic menu: boutons dynamiques avec nom+coût MP, bouton Retour
- [x] Implement spell effects in BattleManager.player_cast_spell
- [x] MP restore: 20% après victoire
- [x] Display MP label en bleu dans battle UI
**Review notes:** Sorts chargés au new_game dans GameManager.spells. Menu Magic remplace ActionButtons puis se cache. Heal utilise valeur négative dans action_result pour être distingué.

---

## Sprint 7 — Save System [STATUS: DONE]
**Goal:** Working save/load with 3 save slots
**Tasks:**
- [x] Implement SaveSystem.save(slot) → JSON file in user://saves/slot_N.json
- [x] Implement SaveSystem.load_save(slot) → restaure GameManager.player_unit
- [x] Save data: stats, level, xp, gold, timestamp
- [x] Save Menu scene (3 slots avec level + timestamp)
- [x] Auto-save slot 0 après chaque victoire
- [x] Load menu accessible depuis MainMenu (bouton "Load Game")
- [ ] "Save & Quit" pause menu (reporté — non critique)
**Review notes:** get_slot_info pour lire les métadonnées sans charger. Auto-save toujours sur slot 0. Map position non sauvegardée (non critique pour la démo).

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
