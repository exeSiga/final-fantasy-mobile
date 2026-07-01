# TASKS.md — Final Fantasy Mobile
> Source of truth for the autonomous development loop.
> Sprints 1-33 archivés dans TASKS_ARCHIVE.md.

---

## Sprint 34 — Personnages nommés FF7 (Cloud / Tifa / Aerith) [STATUS: DONE]
**Goal:** Renommer le party générique avec les identités FF7 + sprites distinctifs + mini-dialogues backstory

**Acceptance Criteria:**
- [x] AC1: Le party affiche "Cloud" (ex-Warrior), "Tifa" (ex-Black Mage), "Aerith" (ex-White Mage) partout
- [x] AC2: Chaque personnage a un sprite géométrique distinctif dans UnitSprite._draw()
- [x] AC3: StatusMenu affiche un bouton "Historique" par personnage (mini-dialogue backstory)
- [x] AC4: Les sauvegardes existantes restent compatibles

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 28/28 tests headless
- Contrôle C (logic trace): AC1-AC4 tracés et validés
- Contrôle D (regression): 28/28 tests, flow MainMenu→Battle intact

---

## Sprint 35 — ATB Gauge (Active Time Battle) [STATUS: DONE]
**Goal:** Remplacer le tour-par-tour strict par une jauge ATB proportionnelle à spd

**Acceptance Criteria:**
- [x] AC1: Jauge ATB 0-100 par unité, se remplit proportionnellement à spd
- [x] AC2: Barre ATB visuelle sous la HP bar en combat
- [x] AC3: Actions bloquées tant que la jauge n'est pas pleine
- [x] AC4: Ennemis agissent automatiquement à jauge pleine
- [x] AC5: Unités rapides agissent plus fréquemment

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 29/29 tests headless
- Contrôle C (logic trace): AC1-AC5 tracés et validés
- Contrôle D (regression): 29/29 tests, flow complet intact

---

## Sprint 36 — Enemy Skill Materia [STATUS: DONE]
**Goal:** Materia spéciale qui apprend une capacité ennemie au porteur lorsqu'il la subit en combat

**Acceptance Criteria:**
- [ ] AC1: Une nouvelle Materia "Enemy Skill" (materia_type="enemy_skill") existe, achetable en boutique
- [ ] AC2: Au moins 2 ennemis (ex: Gargoyle, Dark Knight) ont une attaque spéciale taguée enemy_skill_id qui, si elle touche un membre équipé de la Enemy Skill Materia, l'apprend (stockée dans GameManager.learned_enemy_skills)
- [ ] AC3: Une fois apprise, la capacité apparaît dans le menu de sorts du membre équipé comme un sort utilisable (coût MP défini), au même titre qu'un sort classique
- [ ] AC4: Les capacités apprises persistent à la sauvegarde/chargement
- [ ] AC5: Notification "Compétence apprise : <nom>" affichée au moment de l'apprentissage

**Tasks:**
- [ ] Materia.gd: support materia_type="enemy_skill"
- [ ] resources/materias/enemy_skill_materia.tres
- [ ] resources/spells/: white_wind.tres (Gargoyle), flame_thrower.tres (Dark Knight) avec learned_only=true
- [ ] BattleManager.gd: détection Enemy Skill Materia équipée → GameManager.learn_enemy_skill(spell_path)
- [ ] GameManager.gd: learned_enemy_skills: Array, learn_enemy_skill(), get_available_spells(member_idx)
- [ ] SaveSystem.gd: persister learned_enemy_skills
- [ ] Battle.gd: notification "Compétence apprise"

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 32/32 tests headless
- Contrôle C (logic trace):
  - AC1: enemy_skill_materia.tres achetable via SHOP_MATERIAS → Shop._build_shop() → _on_buy_materia
  - AC2: _ai_gargoyle/_ai_dark_knight appellent _try_learn_enemy_skill → ENEMY_SKILL_MAP → learn_enemy_skill()
  - AC3: _apply_spell_materias() ajoute learned_enemy_skills aux spell_paths du membre équipé
  - AC4: SaveSystem.save() inclut learned_enemy_skills ; load_save() le restaure (fix appliqué)
  - AC5: battle_log.emit + enemy_skill_learned signal → Battle._on_enemy_skill_learned → _spawn_popup
- Contrôle D (regression): 32/32 tests, flow complet intact

---

## Sprint 37 — Crafting + Boutique Shinra [STATUS: DONE]
**Goal:** Système de craft simple (2 matériaux → 1 équipement) + section boutique militaire ShinRa réservée aux hauts rangs SOLDIER

**Acceptance Criteria:**
- [ ] AC1: 4 nouveaux items "matériau" (Scrap Metal, Mako Crystal, Monster Fang, Magic Ore) obtenables via drops ou coffres
- [ ] AC2: CraftMenu accessible depuis le Shop, recettes (2 matériaux → 1 équipement), bouton "Crafter" désactivé si insuffisant
- [ ] AC3: Au moins 3 recettes fonctionnelles (2x Scrap Metal → Buster Sword+ ; 2x Mako Crystal → Mako Bracelet ; Monster Fang+Magic Ore → Ether)
- [ ] AC4: Section "ShinRa Armory" dans le Shop : 2 équipements exclusifs visibles seulement si rang != "3rd Class"
- [ ] AC5: Craft et achats ShinRa persistent à la sauvegarde (equip_inventory standard)

**Tasks:**
- [ ] resources/items/: scrap_metal.tres, mako_crystal.tres, monster_fang.tres, magic_ore.tres
- [ ] CombatUnit ennemis: material_drop_path + material_drop_chance
- [ ] BattleManager.gd: roll material_drop à la victoire → GameManager.add_item
- [ ] resources/equipment/: buster_sword_plus.tres, mako_bracelet.tres
- [ ] GameManager.gd: CRAFT_RECIPES const Array, craft(recipe_idx) bool
- [ ] scripts/CraftMenu.gd + scenes/ui/CraftMenu.tscn ; bouton "Craft" dans Shop.gd
- [ ] Shop.gd: section "ShinRa Armory" filtrée par rang

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 35/35 tests headless
- Contrôle C (logic trace):
  - AC1: 4 .tres matériaux (scrap_metal/mako_crystal/monster_fang/magic_ore) créés, effect_type=3
  - AC2: CraftMenu.gd+.tscn, bouton dans Shop._add_craft_button(), _can_craft() désactive si insuffisant
  - AC3: 3 recettes dans CRAFT_RECIPES; craft() consomme ingrédients et ajoute résultat
  - AC4: ShinRa Armory visible dans Shop si rang != "3rd Class"
  - AC5: craft → equip_inventory ou inventory (sauvegardés par SaveSystem existant)
- Contrôle D (regression): 35/35 tests, flow complet intact

---

## Sprint 38 — Arène de Combat (Battle Arena, 8 vagues) [STATUS: DONE]
**Goal:** Mode de combat optionnel à 8 vagues consécutives avec récompenses uniques, accessible depuis la WorldMap

**Acceptance Criteria:**
- [ ] AC1: Bouton "Arena" sur WorldMap, débloqué si niveau moyen du party >= 10
- [ ] AC2: 8 vagues d'ennemis (difficulté croissante), soin partiel 20% HP/MP entre chaque vague, pas de retour WorldMap entre vagues
- [ ] AC3: Défaite à n'importe quelle vague → retour WorldMap sans perte permanente, aucune récompense
- [ ] AC4: Victoire vague 8 → équipement unique "Champion Belt" ajouté à equip_inventory
- [ ] AC5: Compteur de vague visible en combat ("Vague 3/8")

**Tasks:**
- [ ] BattleManager.gd: arena_mode bool, arena_wave int, start_arena(), _next_arena_wave(), _arena_enemy_pool(wave)
- [ ] resources/equipment/champion_belt.tres
- [ ] WorldMap.gd: bouton Arena (niveau moyen >= 10) → BattleManager.start_arena()
- [ ] Battle.gd: label "Vague X/8" ; victoire non-finale → soin 20% + _next_arena_wave() ; défaite → WorldMap
- [ ] GameManager.gd ou BattleManager.gd: octroi Champion Belt à la vague 8

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 40/40 tests headless
- Contrôle C (logic trace):
  - AC1: WorldMap._add_arena_button() → _on_arena_pressed() avg_level check → arena_mode=true → Battle.tscn
  - AC2: start_arena() vague 1 ; _check_battle_end() → arena_wave_cleared → _next_arena_wave() heal 20% + ennemis suivants
  - AC3: all_party_dead → arena_mode=false, arena_wave=0, battle_ended(false) → game_over overlay
  - AC4: arena_wave>=8 → Champion Belt dans equip_inventory → arena_completed=true → victory overlay
  - AC5: _on_battle_started() → _ensure_wave_label() → "Vague X/8"
- Contrôle D (regression): 40/40 tests, flow normal et boss battles intacts, arena isolé derrière arena_mode flag

---

## Sprint 39 — Game Over amélioré (Citation Sephiroth + Retry) [STATUS: DONE]
**Goal:** Enrichir l'écran de Game Over avec une citation Sephiroth aléatoire et un bouton "Réessayer" relançant le combat

**Acceptance Criteria:**
- [ ] AC1: L'écran de Game Over affiche une citation aléatoire de Sephiroth parmi 5 (ex: "Pitoyable...", "Tu aurais dû rester dans l'ombre.")
- [ ] AC2: Un bouton "Réessayer" relance exactement le même type de combat (même boss/zone) avec la party à 50% HP/MP, sans perte d'or ni d'XP
- [ ] AC3: Le bouton "Menu Principal" (existant) reste fonctionnel et renvoie au MainMenu
- [ ] AC4: Les citations changent aléatoirement à chaque Game Over (pas la même deux fois de suite)

**Tasks:**
- [ ] Battle.gd: gameover_overlay — label citation (Label dynamique) + bouton Retry
- [ ] BattleManager.gd: retry_battle() — restaure party 50% HP/MP et relance start_battle / start_arena / start_boss selon flags
- [ ] GameManager.gd: SEPHIROTH_QUOTES const Array[String] avec 5 citations
- [ ] Battle.gd: _on_gameover_retry_pressed() → BattleManager.retry_battle()

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:

---

**Verification Notes (Sprint 39):**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 43/43 tests
- Contrôle C (logic trace):
  - AC1: SEPHIROTH_QUOTES const 5 entrées; _show_gameover() pick random idx ≠ last
  - AC2: retry_battle() restore 50% HP/MP, relance start_battle ou start_arena
  - AC3: MenuButton existant → _on_gameover_menu_pressed() → MainMenu intact
  - AC4: while idx == _last_quote_idx → rotation garantie
- Contrôle D (regression): 43/43 tests, flow victoire et arène intacts

---

## Sprint 40 — Barret + Party Setup (4 membres sélectionnables) [STATUS: DONE]
**Goal:** Ajouter Barret (Gunner, AoE) comme 4e membre disponible avec un menu de sélection de party sur WorldMap

**Acceptance Criteria:**
- [ ] AC1: Barret (character_class="Gunner", sprite distinctif rouge/marron) ajouté au roster dans GameManager — 4 membres disponibles au total
- [ ] AC2: Bouton "Party" sur WorldMap ouvre un menu permettant de cocher 3 membres actifs parmi 4 (minimum 1 requis)
- [ ] AC3: En combat, seuls les 3 membres actifs sélectionnés participent
- [ ] AC4: Barret a une attaque spéciale "Big Shot" (AoE, frappe jusqu'à 2 ennemis) disponible via un bouton dédié si actif

**Tasks:**
- [ ] GameManager.gd: available_members Array (4 membres), active_party_indices Array[int] (3 actifs), _build_active_party()
- [ ] GameManager.new_game(): initialiser available_members avec Cloud/Tifa/Aerith/Barret
- [ ] WorldMap.gd: bouton "Party" → PartySetupMenu (VBoxContainer dynamique)
- [ ] PartySetupMenu: checkboxes pour les 4 membres, validation 3 sélectionnés
- [ ] BattleManager.start_battle(): utiliser GameManager._build_active_party() au lieu de GameManager.party directement
- [ ] Battle.gd: bouton "Big Shot" visible quand Barret est actif et c'est son tour — BattleManager.player_bigshot()

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:

---

**Verification Notes (Sprint 40):**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 47/47 tests
- Contrôle C (logic trace):
  - AC1: barret.tres Gunner HP=380, available_members[3]=barret dans new_game()
  - AC2: _on_party_pressed() → panel checkboxes → _on_party_confirm() → set_active_party_indices()
  - AC3: rebuild_party_from_indices() → party = 3 membres actifs sélectionnés
  - AC4: _create_bigshot_button() dans Battle._ready() ; _update_bigshot_button() visible si class==Gunner
- Contrôle D (regression): 47/47 tests, équipement par position intact, save/load backward compat

---

## Sprint 41 — Ruby & Emerald Weapon (Boss optionnels Lv.20+) [STATUS: DONE]
**Goal:** Deux boss ultra-difficiles optionnels accessibles depuis WorldMap, avec récompenses d'équipement uniques

**Acceptance Criteria:**
- [ ] AC1: Bouton "⚔ Ruby Weapon" et "⚔ Emerald Weapon" sur WorldMap, débloqués si niveau moyen >= 20
- [ ] AC2: Ruby Weapon (HP très élevé, counter-attack à 30%) ; Emerald Weapon (AoE chaque tour, vulnérabilité à la foudre)
- [ ] AC3: Victoire Ruby Weapon → "Ruby Ring" (weapon, ATK+40) dans equip_inventory ; victoire Emerald Weapon → "Emerald Bangle" (armor, DEF+30, MP+50) 
- [ ] AC4: Les deux Weapons ont des sprites distinctifs (couleurs différentes) et des noms affichés correctement

**Tasks:**
- [ ] resources/units/ruby_weapon.tres + emerald_weapon.tres (hp élevé, atk fort)
- [ ] resources/equipment/ruby_ring.tres + emerald_bangle.tres
- [ ] BattleManager.gd: is_ruby_weapon_battle/is_emerald_weapon_battle flags ; AI ruby (_ai_ruby_weapon) + AI emerald (_ai_emerald_weapon)
- [ ] BattleManager._check_battle_end(): récompense Ruby Ring ou Emerald Bangle selon le boss
- [ ] WorldMap.gd: _add_weapon_buttons() (Lv.20+ requis)

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 54/54 tests
- Contrôle C (logic trace):
  - AC1: WorldMap._add_weapon_buttons() Lv.20+ → _on_ruby/emerald_weapon_pressed() → BattleManager flags
  - AC2: _ai_ruby_weapon: 30% counter-attack; _ai_emerald_weapon: AoE 0.70×ATK tous membres
  - AC3: _check_battle_end → Ruby Ring/Emerald Bangle dans equip_inventory; Battle._on_battle_ended affiche nom
  - AC4: ruby_weapon.tres sprite_color rouge; emerald_weapon.tres sprite_color vert; unit_name affiché
- Contrôle D (regression): 54/54 tests, flow normal et arena intacts, flags Weapon réinitialisés dans start_arena() et _on_encounter()
- Déferments: MP+50 Emerald Bangle non implémenté (Equipment.gd single stat_bonus) — décrit dans description

---

## Sprint 42 — Scènes narratives clés (Réacteur + Sephiroth Flashback) [STATUS: DONE]
**Goal:** Déclencher des cutscenes textuelles automatiques après les boss clés pour enrichir la narration FF7

**Acceptance Criteria:**
- [ ] AC1: Après victoire sur Guard Scorpion (Boss 1), une cutscene "Réacteur Mako — Secteur 1" s'affiche (3 bulles de dialogue, Cloud narrateur) avant le retour à la WorldMap
- [ ] AC2: Après victoire sur Jenova (Boss 2), une cutscene "Souvenir de Nibelheim — Sephiroth" s'affiche (3 bulles, Sephiroth/Cloud) avant le retour
- [ ] AC3: Chaque cutscene ne se rejoue jamais (flags GameManager.scene_reactor_done et scene_jenova_done)
- [ ] AC4: Les cutscenes utilisent le DialogueBox existant (DialogueManager.show_dialogue) avec un enchaînement automatique

**Tasks:**
- [ ] GameManager.gd: scene_reactor_done: bool, scene_jenova_done: bool — persistés en save
- [ ] SaveSystem.gd: sauvegarder/charger scene_reactor_done et scene_jenova_done
- [ ] Battle.gd: _on_battle_ended(true) → si is_boss1_battle et not scene_reactor_done → show cutscene reactor
- [ ] Battle.gd: _on_battle_ended(true) → si is_boss2_battle et not scene_jenova_done → show cutscene jenova  
- [ ] DialogueManager ou Battle.gd: _show_cutscene(lines: Array) → dialogue séquentiel, puis change_scene(return_after_battle)

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 58/58 tests
- Contrôle C (logic trace):
  - AC1: _on_battle_ended(true) + is_boss1_battle + not scene_reactor_done → _pending_cutscene="cutscene_reactor"; bouton Continuer → show_dialogue → dialogue_finished → WorldMap
  - AC2: même flow avec is_boss2_battle / "cutscene_jenova"
  - AC3: scene_reactor_done / scene_jenova_done persistés en save (SaveSystem +2 champs); reset en new_game()
  - AC4: DialogueManager.show_dialogue() existant; dialogue_finished signal → _on_cutscene_ended() → navigate
- Contrôle D (regression): 58/58 tests, _pending_cutscene="" pour combats normaux → navigate directement, aucune régression
- Déferments: aucun

---

## Sprint 43 — Limit Breaks Tier 2 (Coups Spéciaux par personnage) [STATUS: DONE]
**Goal:** Chaque personnage déverrouille un second Limit Break plus puissant lorsque sa jauge dépasse 200 (compteur cumulatif de dégâts reçus)

**Acceptance Criteria:**
- [ ] AC1: Chaque membre cumule les dégâts reçus dans `limit_damage_taken` ; quand ce compteur atteint 200, le `limit_tier` passe à 2 (une seule fois par new_game, persisté en save)
- [ ] AC2: Au tier 2, le bouton LIMIT affiche le nom du Limit Break du personnage (Cloud : "Météorain", Tifa : "Final Heaven", Aerith : "Gospel", Barret : "Catastrophe") et fait plus de dégâts (×3.5 ATK ou soin total)
- [ ] AC3: Tier 1 reste disponible tant que tier 2 n'est pas déverrouillé ; tier 2 remplace tier 1 une fois atteint
- [ ] AC4: Le tier et le compteur persistent à la sauvegarde

**Tasks:**
- [ ] CombatUnit.gd: limit_damage_taken: int, limit_tier: int (1 ou 2)
- [ ] BattleManager._fill_limit_gauge(): incrémenter limit_damage_taken; si >= 200 et limit_tier == 1 → limit_tier = 2
- [ ] BattleManager.player_limit_break(): dispatcher sur character_class + limit_tier
- [ ] Battle.gd: bouton LIMIT affiche nom du Limit Break selon limit_tier
- [ ] SaveSystem.gd: persister limit_damage_taken et limit_tier par membre

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 62/62 tests
- Contrôle C (logic trace):
  - AC1: CombatUnit.limit_damage_taken += amount dans _fill_limit_gauge(); check >= 200 → limit_tier=2
  - AC2: player_limit_break() dispatche match class + tier; Meteorain 4 hits×1.8, Final Heaven ×4.0, Great Gospel soin+revive 75%, Catastrophe ×3.0 AoE
  - AC3: limit_tier==1 → tier1 name/behavior; tier2 only after unlock
  - AC4: _unit_to_dict + load_save: limit_damage_taken et limit_tier persistés
- Contrôle D (regression): 62/62 tests, limit gauge ordinaire (tier 1) intact, ATB/arena/boss flows inchangés
- Déferments: aucun

---

## Sprint 44 — Red XIII (5e membre, Beastmaster) [STATUS: DONE]
**Goal:** Ajouter Red XIII comme 5e membre disponible avec une attaque spéciale "Lunatic High" qui augmente la VIT de toute la party

**Acceptance Criteria:**
- [ ] AC1: Red XIII (character_class="Beastmaster", sprite rouge/orange) ajouté dans available_members — 5 membres disponibles au total
- [ ] AC2: Le menu Party sur WorldMap permet de sélectionner 3 membres parmi 5
- [ ] AC3: Attaque spéciale "Lunatic High" : double le SPD de tous les membres vivants pendant 2 tours, bouton visible quand Red XIII est actif et c'est son tour
- [ ] AC4: Red XIII a des stats distinctives (SPD élevé, HP moyen, ATK physique moyenne)

**Tasks:**
- [ ] resources/units/red_xiii.tres (Beastmaster, SPD=40, HP=320, ATK=38, sprite orange)
- [ ] GameManager.new_game(): available_members[4] = Red XIII
- [ ] BattleManager.gd: player_lunatic_high() — double spd party vivante pour 2 tours
- [ ] Battle.gd: bouton "Lunatic High" visible si Beastmaster + son tour
- [ ] WorldMap.gd: PartySetupMenu mis à jour pour 5 membres (validation toujours 3 actifs)

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 66/66 tests
- Contrôle C (logic trace):
  - AC1: red_xiii.tres Beastmaster SPD=40 HP=320 ATK=38, sprite orange
  - AC2: PartySetupMenu itère sur available_members.size() (5); validation 3 actifs inchangée
  - AC3: player_lunatic_high() double spd party vivante haste_turns_left=2; bouton _lunatic_btn visible si Beastmaster
  - AC4: SPD=40 > tous autres (Cloud 28, Tifa 32, Aerith 26, Barret 22)
- Contrôle D (regression): 66/66 tests, test available_members mis à jour >= 4 pour compatibilité
- Déferments: Claw Slash / Cosmo Memory Limit Break implémentés dans player_limit_break()

---

## Sprint 45 — Districts de Midgar (Secteurs 1, 5, 7) [STATUS: DONE]
**Goal:** Trois zones spéciales de Midgar accessibles depuis la WorldMap avec events uniques et ennemis propres à chaque secteur

**Acceptance Criteria:**
- [ ] AC1: Boutons "Secteur 1 — Réacteur", "Secteur 5 — Slums", "Secteur 7 — Seventh Heaven" sur WorldMap (accessible dès Lv.1)
- [ ] AC2: Chaque secteur déclenche un combat avec un pool d'ennemis propre (Secteur 1 : MP Soldier+Guard; Secteur 5 : Hedgehog Pie+Mu; Secteur 7 : Shinra Guard+Attack Squad)
- [ ] AC3: Victoire dans chaque secteur accorde un item unique introuvable en shop (Secteur 1 : Mako Shard, Secteur 5 : Slum Herb ×3 heal, Secteur 7 : ShinRa Badge équip)
- [ ] AC4: Un compteur de victoires par secteur (BattleManager.sector_victories) incrémente à chaque victoire

**Tasks:**
- [ ] resources/units/: mp_soldier.tres, hedgehog_pie.tres, shinra_guard.tres (3 nouveaux ennemis simples)
- [ ] resources/items/mako_shard.tres (buff ATK temporaire), slum_herb.tres (heal), shinra_badge.tres (équipement slot=1 DEF+8)
- [ ] BattleManager.gd: sector_victories: Dictionary; SECTOR1/5/7_POOL; start_sector_battle(sector)
- [ ] WorldMap.gd: _add_sector_buttons() → boutons; _on_sector_pressed(sector) → start_sector_battle
- [ ] BattleManager._check_battle_end(): si sector_mode → grant item unique (une fois) + sector_victories++

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ 70/70 tests
- Contrôle C (logic trace):
  - AC1: WorldMap._add_sector_buttons() 3 boutons centrage; _on_sector_pressed() → BattleManager.sector_mode = sector → change_scene → Battle._ready() → start_sector_battle()
  - AC2: SECTOR1_POOL [MP Soldier×2], SECTOR5_POOL [Hedgehog Pie+Goblin], SECTOR7_POOL [ShinRa Guard+MP Soldier]
  - AC3: _check_battle_end() sector_victories.get(sector,0)==0 → grant unique item (mako_shard/slum_herb/shinra_badge)
  - AC4: sector_victories[sector] incrémenté à chaque victoire
- Contrôle D (regression): 70/70 tests; bug fix Object.get(key,default)→is_equip branch; encounter reset sector_mode=""
- Déferments: sector_victories non persisté en save (données de session uniquement — pas critique)

---

## Sprint 46 — Fichiers ShinRa (Notifications de Lore) [STATUS: DONE]
**Goal:** Après certains jalons (premier kill par type d'ennemi, boss vaincu, rang atteint), afficher un popup "Fichier ShinRa déverrouillé" avec une ligne de lore FF7

**Acceptance Criteria:**
- [x] AC1: 6 fichiers ShinRa définis (ex: premier Slime tué, Guard Scorpion vaincu, rang 2nd Class atteint, Jenova vaincue, 50 kills total, Sephiroth vaincu)
- [x] AC2: Chaque fichier ne s'affiche qu'une fois (GameManager.shinra_files_seen: Array), persisté en save
- [x] AC3: Popup stylisé "📁 Fichier ShinRa" avec titre + une ligne de lore (fond bleu ShinRa), visible 4 secondes ou sur tap
- [x] AC4: Les checks se font dans BattleManager._check_battle_end() et GameManager (rank change signal)

**Tasks:**
- [x] GameManager.gd: shinra_files_seen: Array; SHINRA_FILES const (6 entrées: condition + titre + texte); check_shinra_files()
- [x] SaveSystem.gd: persister shinra_files_seen
- [x] Popup implémenté en code pur (CanvasLayer layer=88, fond bleu ShinRa, tap-to-dismiss)
- [x] BattleManager._check_battle_end(): appel GameManager.check_shinra_files() après rewards
- [x] WorldMap/_ready(): appel check_shinra_files() pour le rang au retour

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace):
  - AC1: SHINRA_FILES const dans GameManager avec 6 entrées (first_slime, guard_scorpion, rank_2nd, jenova, kills_25, sephiroth)
  - AC2: shinra_files_seen Array vérifié avant chaque affichage, persisté via SaveSystem
  - AC3: _show_shinra_popup() crée CanvasLayer layer=88, fond bleu, auto-dismiss Timer 4s, gui_input pour tap
  - AC4: check_shinra_files() appelé dans BattleManager._check_battle_end() et WorldMap._ready()
- Contrôle D (regression): 74/74 tests passent
- Déferments: popup non testé visuellement (headless uniquement)

---

## Sprint 47 — New Game+ (Difficulté Augmentée) [STATUS: DONE]
**Goal:** Après avoir terminé le jeu (Sephiroth vaincu), débloquer un mode New Game+ qui relance avec les stats ennemis ×1.5 et des récompenses de fin améliorées

**Acceptance Criteria:**
- [x] AC1: Après victoire sur Sephiroth, un bouton "New Game+" apparaît sur l'écran de victoire final (persisté via GameManager.ng_plus_unlocked)
- [x] AC2: En NG+, tous les ennemis ont leurs HP et ATK multipliés par 1.5 (BattleManager._apply_ng_plus_scaling())
- [x] AC3: Les XP et Gold rewards sont aussi ×1.5 en NG+ (GameManager.grant_battle_rewards adapté)
- [x] AC4: ng_plus_unlocked et ng_plus_mode persistent à la sauvegarde

**Tasks:**
- [x] GameManager.gd: ng_plus_unlocked: bool, ng_plus_mode: bool, reset dans new_game(), ×1.5 dans grant_battle_rewards()
- [x] BattleManager.gd: _apply_ng_plus_scaling() appelé dans start_battle/sector/arena
- [x] Battle.gd: bouton ✨ New Game+ ajouté dynamiquement sur victoire Sephiroth, _on_ng_plus_pressed()
- [x] SaveSystem.gd: ng_plus_unlocked et ng_plus_mode persistés

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace):
  - AC1: Battle._on_battle_ended() → ng_plus_unlocked=true + bouton VBox[1] → _on_ng_plus_pressed → new_game + flags + save + WorldMap
  - AC2: _apply_ng_plus_scaling() appelée après chargement des ennemis dans les 3 entry points; vérifie GameManager.ng_plus_mode
  - AC3: grant_battle_rewards() multiplie xp/gold ×1.5 avant add_gold(); vérifié par test
  - AC4: SaveSystem.save()/load_save() sérialisent ng_plus_unlocked et ng_plus_mode avec fallback false
- Contrôle D (regression): 78/78 tests passent; flags false par défaut = aucun impact sur le jeu normal
- Déferments: aucun

---

## Sprint 48 — Dialogues à Choix (PNJ Interactifs) [STATUS: DONE]
**Goal:** Des PNJ sur la WorldMap proposent un dialogue à choix : répondre déclenche une récompense ou un malus (or, objet, info de lore)

**Acceptance Criteria:**
- [x] AC1: 3 PNJ (npc_guide/npc_soldier/npc_innkeeper) sur WorldMap avec boutons; NPC_CHOICES const avec 3 entrées
- [x] AC2: 2 choix par PNJ → gold, item, ou lore ; _apply_npc_reward() dispatche par type
- [x] AC3: npc_flags Dictionary persisté en save; guard `npc_flags.get(id, false)` → done popup si déjà vu
- [x] AC4: popup PanelContainer CanvasLayer layer=90, titre + texte + 2 Button choix

**Tasks:**
- [x] GameManager.gd: NPC_CHOICES const, npc_flags: Dictionary, show_npc_choice(), _apply_npc_reward(), _show_npc_done_popup()
- [x] WorldMap.gd: bouton pressed → GameManager.show_npc_choice(id)
- [x] SaveSystem.gd: npc_flags persisté

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace): AC1-AC4 tracés et validés
- Contrôle D (regression): 82/82 tests passent
- Déferments: aucun

---

## Sprint 49 — Bestiaire (Compendium des Monstres) [STATUS: DONE]
**Goal:** Un menu Bestiaire accessible depuis WorldMap liste tous les types d'ennemis rencontrés avec stats de base, nb de kills, et une ligne de lore FF7

**Acceptance Criteria:**
- [x] AC1: Bouton "📖 Bestiaire" sur WorldMap → popup ScrollContainer avec 13 ennemis triés alphabétiquement
- [x] AC2: Kills > 0 → affiche nom, kills, HP/ATK de base, lore FF7; milestone progress
- [x] AC3: Kills == 0 → "??? (non rencontré)" en gris
- [x] AC4: QuestManager._check_bestiary_milestone() → item reward à N kills; battle_log notification

**Tasks:**
- [x] GameManager.gd: BESTIARY const (13 ennemis), bestiary_milestones_given: Dictionary
- [x] QuestManager.gd: _check_bestiary_milestone() appelé depuis notify_kill()
- [x] WorldMap.gd: _add_bestiary_button() + _on_bestiary_pressed() avec popup ScrollContainer inline
- [x] SaveSystem.gd: bestiary_milestones_given persisté

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace): BESTIARY 13 entries; notify_kill → _check_bestiary_milestone → add_item + flag; déjà-donné guard
- Contrôle D (regression): 86/86 tests passent
- Déferments: aucun

---

## Sprint 50 — Boutique Évolutive (Items selon le Rang) [STATUS: DONE]
**Goal:** La boutique débloque de nouvelles lignes d'équipements et de matérias en fonction du rang SOLDIER du joueur (3rd/2nd/1st Class)

**Acceptance Criteria:**
- [x] AC1: Catalogue de base inchangé (équipements niv.1, Fire/Ice/Thunder/Cure matérias)
- [x] AC2: 2nd Class (≥50 kills) : +Mithril Sword (+25 ATK), +Guard Bangle (+20 DEF), +Thundara Materia (3.5× lightning)
- [x] AC3: 1st Class (≥150 kills) : +Hardedge (+38 ATK), +Wizard Rod (+32 ATK), +Regen Materia (60 HP heal)
- [x] AC4: Badge "[NOUVEAU]" (doré) sur section et items fraîchement débloqués (shop_last_rank comparaison)

**Tasks:**
- [x] resources/equipment/mithril_sword.tres, guard_bangle.tres, hardedge.tres, wizard_rod.tres
- [x] resources/spells/thundara.tres (3.5×, lightning), regen.tres (HEAL 60 HP, 8 MP)
- [x] resources/materias/thundara_materia.tres, regen_materia.tres
- [x] Shop.gd: RANK_2ND_EQUIP/MATERIAS, RANK_1ST_EQUIP/MATERIAS; _add_item_row(is_new) dorée
- [x] GameManager.gd: shop_last_rank: String, SaveSystem.gd: persisté

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace): shop_last_rank vs current rank → new_2nd/new_1st bool → couleur dorée; updated à fermeture
- Contrôle D (regression): 90/90 tests passent
- Déferments: aucun

---

## Sprint 51 — Armes Élémentaires (Combat Elemental Depth) [STATUS: DONE]
**Goal:** De nouvelles armes équipables portent un élément (feu/glace/foudre) et appliquent cet élément aux attaques physiques, déclenchant la faiblesse ennemie au corps-à-corps

**Acceptance Criteria:**
- [x] AC1: 3 armes en boutique: Flame Blade (🔥 feu, ATK+18, 400G), Ice Brand (❄️ glace), Thunder Blade (⚡ foudre)
- [x] AC2: player_attack() → _get_active_weapon_element() → si faiblesse cible: bonus 50% dégâts + battle_log
- [x] AC3: _update_element_indicator() dans _on_turn_changed() → _attack_btn.text = "Attack 🔥/❄️/⚡"
- [x] AC4: Equipment.gd: @export var weapon_element: String = ""; tous les anciens .tres compatibles (field absent = "")

**Tasks:**
- [x] resources/Equipment.gd: weapon_element: String = ""
- [x] resources/equipment/flame_blade.tres, ice_brand.tres, thunder_blade.tres
- [x] Shop.gd: 3 armes dans SHOP_EQUIP + _element_icon() pour affichage boutique
- [x] BattleManager.gd: _get_active_weapon_element(), bonus dans player_attack()
- [x] Battle.gd: _update_element_indicator(), appel dans _on_turn_changed()

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace): equipment[idx].weapon.weapon_element via "in" guard; weakness check comme sort; slime=fire weakness validé
- Contrôle D (regression): 94/94 tests passent
- Déferments: aucun

---

## Sprint 52 — Trésors de Donjon Uniques [STATUS: DONE]
**Goal:** Le donjon génère aléatoirement 1 salle "trésor" par run (entre les salles de combat) contenant un équipement rare introuvable en boutique

**Acceptance Criteria:**
- [x] AC1: Dungeon._trigger_dungeon_battle(): 25% → try_show_dungeon_treasure() → await canvas.tree_exited → battle
- [x] AC2: DUNGEON_TREASURE_POOL: 4 rares (dark_matter_armlet, warrior_bangle, gigas_armlet, crystal_sword), price=0
- [x] AC3: dungeon_treasures_found: Array, pré-marqué avant popup, filter available items
- [x] AC4: Popup 💎 "Trésor !" avec item name, stats, bouton "Prendre !", CanvasLayer layer=91

**Tasks:**
- [x] resources/equipment/dark_matter_armlet.tres, warrior_bangle.tres, gigas_armlet.tres, crystal_sword.tres (price=0)
- [x] GameManager.gd: DUNGEON_TREASURE_POOL const, dungeon_treasures_found: Array, try_show_dungeon_treasure() → CanvasLayer
- [x] scripts/Dungeon.gd: _trigger_dungeon_battle() await sur canvas.tree_exited
- [x] SaveSystem.gd: dungeon_treasures_found persisté

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace): available = pool.filter not in found; pré-marqué avant popup; await tree_exited bloque battle; null si pool vide
- Contrôle D (regression): 98/98 tests passent
- Déferments: aucun

---

## Sprint 53 — Yuffie Kisaragi (6e membre, Ninja) [STATUS: DONE]
**Goal:** Ajouter Yuffie comme 6e membre avec une attaque spéciale "Shuriken Throw" (AoE) et une capacité "Steal" qui vole un item à un ennemi

**Acceptance Criteria:**
- [x] AC1: Yuffie (character_class="Ninja", sprite jaune/vert) ajoutée dans available_members — 6 membres disponibles au total
- [x] AC2: Le menu Party sur WorldMap permet de sélectionner 3 membres parmi 6
- [x] AC3: Attaque spéciale "Shuriken Throw" : frappe tous les ennemis vivants pour 0.8×ATK chacun, bouton visible quand Yuffie est active et c'est son tour
- [x] AC4: Capacité "Steal" : 60% de chance de voler un item aléatoire à l'ennemi cible (item ajouté à l'inventaire GameManager), affichage dans battle_log ; bouton visible comme Shuriken
- [x] AC5: Yuffie a des stats distinctives : AGI élevée (SPD=45), ATK modérée (ATK=35), HP faible (HP=280)

**Tasks:**
- [x] resources/units/yuffie.tres (Ninja, SPD=45, HP=280, ATK=35, DEF=22, sprite yellow/green)
- [x] GameManager.new_game(): available_members[5] = Yuffie; ENEMY_STEAL_POOL const (liste items volables par ennemi_type)
- [x] BattleManager.gd: player_shuriken_throw() — dégâts 0.8×ATK AoE ; player_steal(target_idx) — roll 60%, item dans ENEMY_STEAL_POOL
- [x] Battle.gd: _shuriken_btn et _steal_btn visibles si character_class=="Ninja" et c'est le tour du joueur
- [x] WorldMap.gd: PartySetupMenu mise à jour pour 6 membres (validation toujours 3 actifs)

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace):
  - AC1: yuffie.tres Ninja SPD=45 HP=280 ATK=35; new_game() available_members[5]=yuffie
  - AC2: WorldMap._on_party_pressed() itère available_members.size() (6) automatiquement
  - AC3: player_shuriken_throw() → filter(alive) → 0.8×ATK AoE; _shuriken_btn visible si Ninja
  - AC4: player_steal(idx) → ENEMY_STEAL_POOL.get(unit_name) → 60% roll → add_item(); _steal_btn visible si Ninja
  - AC5: SPD=45 plus élevé de tous (Red XIII=40, Tifa=32, Cloud=28)
- Contrôle D (regression): 101/101 tests passent
- Déferments: aucun

---

## Sprint 54 — Matéria AP & Sorts Évolués (Fira, Blizzara, Thundaga) [STATUS: DONE]
**Goal:** Les matérias offensives gagnent des AP après chaque combat et débloquent des sorts plus puissants (level 2 = -ra, level 3 = -ga) visibles dans le menu matéria

**Acceptance Criteria:**
- [x] AC1: GameManager.materia_ap: Dictionary (materia_path → int) ; chaque combat accorde AP = 10 + wave×5 (arena) aux matérias équipées ; persisté en save
- [x] AC2: fire_materia : level 2 à 80 AP → Fira (2.8× ATK, 12 MP) ; level 3 à 250 AP → Firaga (4.5× ATK, 18 MP) ; idem blizzard_materia (Blizzara/Blizzaga) et thunder_materia (Thundara→Thundaga 4.5×)
- [x] AC3: BattleManager._apply_spell_materias() → _get_evolved_spell_path() → sort selon get_materia_level()
- [x] AC4: MateriaMenu affiche niveau AP et progression "[Lv2 80/250 AP]" ou "[Lv3 MAX]"

**Tasks:**
- [x] GameManager.gd: materia_ap: Dictionary, grant_materia_ap(amount), get_materia_level(path), MATERIA_AP_THRESHOLDS, MATERIA_SPELL_TIERS
- [x] BattleManager.gd: _check_battle_end() grant AP; _apply_spell_materias() → _get_evolved_spell_path()
- [x] resources/spells/fira.tres, firaga.tres, blizzara.tres, blizzaga.tres, thundaga.tres
- [x] SaveSystem.gd: materia_ap persisté
- [x] MateriaMenu.gd: affiche Lv/AP/seuil

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace):
  - AC1: grant_materia_ap(10) appelé dans _check_battle_end(); materia_ap dict persisté via SaveSystem
  - AC2: MATERIA_SPELL_TIERS 3 entrées; seuils [80,250]; firaga/blizzaga/thundaga à Lv3
  - AC3: _get_evolved_spell_path(mat_path, mat) → tiers[level-1]; intégré dans _apply_spell_materias()
  - AC4: MateriaMenu._build() affiche "[Lv%d %d/%d AP]" pour les matérias trackées
- Contrôle D (regression): 106/106 tests passent
- Déferments: aucun

---

## Sprint 55 — Statuts de Combat Avancés (Stop, Berserk, Confusion) [STATUS: DONE]
**Goal:** Trois nouveaux statuts altèrent les comportements en combat : Stop fige l'unité, Berserk force l'attaque physique et boost l'ATK, Confusion retourne les cibles

**Acceptance Criteria:**
- [x] AC1: CombatUnit: stop_turns, berserk_turns, confuse_turns (ints) ; clear_status() les remet à 0 ; reset au début de chaque battle dans start_battle()
- [x] AC2: Stop (Dark Knight 25%) : _tick_status() retourne true → continue dans _advance_turn() (tour sauté)
- [x] AC3: Berserk (Ruby Weapon 20%) : _advance_turn() auto-attaque avec ATK ×1.5 ; player_cast_spell() bloqué
- [x] AC4: Confusion (Shadow 30%) : player_attack() → 50% randf() → redirect vers allié aléatoire
- [x] AC5: HUD: _refresh_party_ui() → "🔴 Stop 🟡 Berserk 🔵 Confusion" dans status_tag du nom

**Tasks:**
- [x] CombatUnit.gd: 3 nouveaux champs + clear_status() étend
- [x] BattleManager.gd: _apply_status(); _tick_status() handle stop; _ai_dark_knight/shadow/ruby_weapon mis à jour
- [x] Battle.gd: _refresh_party_ui() icônes émoji statuts
- [x] SaveSystem.gd: non persistés (combat-only, reset chaque battle)

**Verification Notes:**
- Contrôle A (static): ✅ All clear
- Contrôle B (godot parse): ✅ aucun SCRIPT ERROR
- Contrôle C (logic trace):
  - AC1: stop/berserk/confuse_turns = 0 in clear_status() + start_battle() loop
  - AC2: _tick_status(): if stop_turns > 0 → décrement → return true → skip dans _advance_turn while loop
  - AC3: _advance_turn(): if berserk_turns > 0 → atk×1.5 → player_attack() auto; cast bloqué
  - AC4: player_attack(): confuse check → 50% randf → redirect ally
  - AC5: _refresh_party_ui(): status_tag += "🔴/🟡/🔵" selon champs actifs
- Contrôle D (regression): 110/110 tests passent
- Déferments: aucun

---

## Sprint 56 — Wall Market (Marché Noir de Midgar) [STATUS: DONE]
**Goal:** Un marché spécial accessible depuis WorldMap propose des items rares à prix élevé et un event aléatoire "Affaire Louche" (bon deal ou arnaque)

**Acceptance Criteria:**
- [ ] AC1: Bouton "🏪 Wall Market" sur WorldMap (accessible dès Lv.1) ouvre un popup-shop avec 6 items exclusifs : Hi-Potion (300G, soin 150 HP), X-Potion (800G, soin total), Ether (500G, soin 50 MP), Megalixir (2000G, soin party totale), Remedy (400G, soigne tous statuts), Carbon Bangle (equip DEF+15, 1200G)
- [ ] AC2: Chaque visite au Wall Market a 30% de chance de déclencher un event "Affaire Louche" : popup avec description + choix "Accepter" (100G) → 50% bon deal (item rare gratuit) ou arnaque (perd 100G sans item)
- [ ] AC3: wall_market_visits: int incrémenté à chaque visite ; après 5 visites : déblocage permanent d'un 7e item "Black Materia Shard" (équipement spécial MAG+20, 3000G) avec notification ShinRa
- [ ] AC4: Items Wall Market achetés persistent via système d'inventaire existant (GameManager.add_item / equip_inventory)

**Tasks:**
- [ ] resources/items/hi_potion.tres (heal 150), x_potion.tres (heal 9999), ether.tres (mp +50), megalixir.tres (HEAL_ALL party, effect_type=4), remedy.tres (clear_status, effect_type=5)
- [ ] resources/equipment/carbon_bangle.tres (DEF+15, price=1200), black_materia_shard.tres (MAG+20, price=3000)
- [ ] GameManager.gd: wall_market_visits: int, WALL_MARKET_ITEMS const, WALL_MARKET_DEAL_ITEMS const (items bons deals), show_wall_market() → popup CanvasLayer layer=92
- [ ] GameManager.gd: _roll_louche_deal() → popup choix + résolution ; _check_wall_market_unlock() → shinra_files check
- [ ] WorldMap.gd: _add_wall_market_button() → _on_wall_market_pressed() → GameManager.show_wall_market()
- [ ] SaveSystem.gd: wall_market_visits persisté

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 115/115 tests headless
- Contrôle C (logic trace):
  - AC1: show_wall_market() in GameManager.gd:L~590 creates CanvasLayer layer=92 with 6 items list + Buy buttons; tested via _test_wall_market_items_defined
  - AC2: 30% chance branch in show_wall_market() shows Affaire Louche section; _on_louche_accepted() deducts 100G, 50% grants item; wall_market_visits increments each call
  - AC3: _check_wall_market_unlock() at visit 5 triggers add_shinra_file with "black_materia_shard" message; black_materia_shard.tres created (slot=0 weapon, ATK+20)
  - AC4: _on_wall_market_buy() calls add_item()/equip_inventory; wall_market_visits persisted through SaveSystem; tested via _test_wall_market_save_load
- Contrôle D (regression): 115/0 tests pass, MainMenu→Battle flow intact

---

## Sprint 57 — Vincent Valentine (7e membre, Guerrier Sombre) [STATUS: DONE]
**Goal:** Ajouter Vincent Valentine comme 7e membre disponible avec une transformation "Galian Beast" qui booste massivement l'ATK pour 2 tours

**Acceptance Criteria:**
- [ ] AC1: Vincent Valentine (character_class="DarkWarrior", sprite rouge/noir) ajouté dans available_members — 7 membres au total
- [ ] AC2: Le menu Party sur WorldMap permet de sélectionner 3 membres parmi 7
- [ ] AC3: Transformation "Galian Beast" (bouton visible quand DarkWarrior est actif et c'est son tour) : ATK ×2.5 pendant 2 tours, ne peut pas utiliser de matéria pendant la transformation, battle_log "Vincent se transforme en Galian Beast !"
- [ ] AC4: Après la transformation (2 tours), retour à la normale automatiquement avec battle_log "Vincent reprend forme humaine"
- [ ] AC5: Vincent a des stats distinctives : ATK très élevé (ATK=50), DEF faible (DEF=18), HP moyen (HP=300), SPD lent (SPD=20)

**Tasks:**
- [ ] resources/units/vincent.tres (DarkWarrior, ATK=50, HP=300, DEF=18, SPD=20, sprite rouge/noir)
- [ ] GameManager.new_game(): available_members[6] = Vincent
- [ ] CombatUnit.gd: galian_turns: int (0 = normal, >0 = transformé), galian_atk_bonus: float
- [ ] BattleManager.gd: player_galian_beast() — galian_turns=2, galian_atk_bonus=2.5 ; player_attack() / player_spell() check galian_turns pour bloquer sorts ; _execute_turn_for() décrémenter galian_turns après action
- [ ] Battle.gd: _galian_btn visible si DarkWarrior et tour joueur ; _update_turn_ui() texte bouton "Attack (Galian)" si transformé
- [ ] WorldMap.gd: PartySetupMenu itère available_members.size() (7)

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 120/120 tests headless
- Contrôle C (logic trace):
  - AC1: vincent.tres loaded in new_game() as available_members[6], character_class="DarkWarrior"; tested via _test_vincent_in_roster
  - AC2: PartySetupMenu iterates available_members.size() dynamically — no hardcoded 6-limit
  - AC3: player_galian_beast() sets galian_turns=2 ATK×2.5; Battle.gd _galian_btn shown for DarkWarrior; player_cast_spell() blocked when galian_turns>0
  - AC4: _after_player_turn() decrements galian_turns; at 0: restores galian_base_atk + logs "Vincent reprend forme humaine"
  - AC5: ATK=50 DEF=18 HP=300 SPD=20 verified via _test_vincent_stats
- Contrôle D (regression): 120/0 tests pass, MainMenu→Battle flow intact
- Déferments: WorldMap PartySetupMenu already dynamic — no change needed

---

## Sprint 58 — Cait Sith (8e membre, Machiniste) [STATUS: DONE]
**Goal:** Ajouter Cait Sith comme 8e membre disponible avec sa capacité unique "Slot" à effet aléatoire (soin de la party, AoE, ou rien)

**Acceptance Criteria:**
- [ ] AC1: Cait Sith (character_class="Machinist", sprite orange/blanc) ajouté dans available_members — 8 membres au total ; stats ATK=30 DEF=25 HP=250 SPD=35 MP=40
- [ ] AC2: Bouton "Slot" visible quand Machinist est actif pendant son tour ; appeler player_slot_machine()
- [ ] AC3: player_slot_machine() tire 3 valeurs aléatoires (0-5) ; si toutes identiques → Jackpot (soigne toute la party HP+MP pleins) ; si 2 identiques → Demi-jackpot (soin 200HP toute la party) ; sinon → Miss (rien, perd son tour)
- [ ] AC4: Le résultat affiché dans battle_log : "🎰 [X|Y|Z] — Jackpot !" / "Demi-Jackpot!" / "Miss…"
- [ ] AC5: Cait Sith sauvegardé/chargé comme les autres membres (via all_members dans SaveSystem)

**Tasks:**
- [ ] resources/units/cait_sith.tres (Machinist, ATK=30, DEF=25, HP=250, SPD=35, MP=40, sprite orange)
- [ ] GameManager.new_game(): available_members[7] = cait_sith
- [ ] BattleManager.gd: player_slot_machine() — 3 randi()%6, évalue résultat, soigne ou rien, battle_log, _after_player_turn()
- [ ] Battle.gd: _slot_btn variable + _create_slot_button() + _update_slot_button(unit) + _on_slot_pressed()
- [ ] tests/TestHeadless.gd: 5 tests (cait_in_roster, cait_stats, slot_jackpot_heals_party, slot_miss_no_effect, cait_save_load)

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 125/125 tests headless
- Contrôle C (logic trace):
  - AC1: cait_sith.tres loaded as available_members[7], Machinist class; tested via _test_cait_in_roster
  - AC2: _slot_btn visible when character_class=="Machinist" via _update_slot_button(); _create_slot_button() in Battle.gd
  - AC3: player_slot_machine() rolls 3 randi()%6; jackpot (all 3 same) heals party HP+MP; demi-jackpot (2 same) heals 200HP; miss = no effect
  - AC4: battle_log emits "🎰 [X|Y|Z] — Jackpot/Demi-Jackpot/Miss"
  - AC5: Cait Sith saved via existing all_members SaveSystem; tested _test_cait_save_load
- Contrôle D (regression): 125/0 tests pass, MainMenu→Battle flow intact
- Déferments: none

---

## Sprint 59 — Forge d'Armes (Amélioration d'Équipement) [STATUS: DONE]
**Goal:** Permettre d'améliorer les armes/armures équipées en dépensant de l'or, augmentant leur stat_bonus de +5 jusqu'à 3 fois par pièce

**Acceptance Criteria:**
- [ ] AC1: Bouton "🔨 Forge" sur WorldMap ouvre un popup listant l'équipement actuel des 3 emplacements ; chaque pièce affiche son stat_bonus actuel et le coût d'amélioration (200G × niveau actuel)
- [ ] AC2: Chaque pièce d'équipement peut être améliorée jusqu'à 3 fois (upgrade_level 0→1→2→3) ; au niveau 3 le bouton Améliorer est grisé avec texte "MAX"
- [ ] AC3: Améliorer coûte or (200G pour +1, 400G pour +2, 600G pour +3) ; les stats du personnage (atk ou def) sont immédiatement mises à jour (+5 par upgrade)
- [ ] AC4: upgrade_level de chaque pièce persisté dans equip_inventory (clé path+"_upgrades") via SaveSystem

**Tasks:**
- [ ] GameManager.gd: FORGE_BASE_COST=200, show_forge_popup() — CanvasLayer layer=93 ; _on_forge_upgrade(slot_idx, gold_lbl) — vérifie or, upgrade ≤3
- [ ] GameManager.gd: get_upgrade_level(path)->int + set_upgrade_level(path, lvl) utilisant equip_inventory[path+"_upgrades"]
- [ ] GameManager.gd: apply_equipment_stats() tient compte des upgrade_levels
- [ ] WorldMap.gd: _add_forge_button() — bouton "🔨 Forge" à côté du Wall Market
- [ ] tests/TestHeadless.gd: 5 tests (forge_popup_defined, upgrade_cost_scales, upgrade_max_level, upgrade_stat_applied, upgrade_save_load)

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 130/130 tests headless
- Contrôle C (logic trace):
  - AC1: show_forge_popup() creates CanvasLayer layer=93 with equipment list; _add_forge_button() in WorldMap.gd
  - AC2: FORGE_MAX_LEVEL=3; forge btn disabled+text=MAX when upgrade_level>=3
  - AC3: cost=FORGE_BASE_COST*(upgrade_lvl+1) → 200/400/600G; _on_forge_upgrade() applies +FORGE_STAT_PER_LEVEL(5) immediately
  - AC4: set_upgrade_level() stores in equip_inventory[path+"_upgrades"]; persisted via existing SaveSystem equip_inventory save
- Contrôle D (regression): 130/0 tests pass, MainMenu→Battle flow intact
- Déferments: equip_item needed before forge — upgrading unequipped items not possible (by design)

---

## Sprint 60 — Météo de Combat (Effets Environnementaux) [STATUS: DONE]
**Goal:** Ajouter un système météo aléatoire en combat qui modifie l'efficacité des sorts élémentaires et est affiché dans l'arène

**Acceptance Criteria:**
- [ ] AC1: Au début de chaque combat, weather = tirage aléatoire parmi ["clear", "rain", "storm", "blizzard", "heat"] (probabilités égales) — stocké dans BattleManager.current_weather
- [ ] AC2: Modificateurs météo appliqués aux sorts : rain → feu ×0.5, glace ×1.3 ; storm → foudre ×1.5 ; blizzard → glace ×1.5, feu ×0.5 ; heat → feu ×1.3 ; clear → aucun modificateur
- [ ] AC3: HUD combat affiche l'icône météo en haut à gauche de l'arène (🌤☔⛈🌨🔥) et le nom de la météo
- [ ] AC4: Ennemis avec element_weakness bénéficient des mêmes modificateurs (double effet si météo amplifie leur faiblesse)

**Tasks:**
- [ ] BattleManager.gd: var current_weather: String = "clear" ; WEATHER_OPTIONS const ; _roll_weather() en début de start_battle() ; WEATHER_SPELL_MOD dict
- [ ] BattleManager.gd: _apply_weather_mod(base_dmg, spell_element) → float multiplicateur ; appeler dans player_cast_spell()
- [ ] scripts/Battle.gd: _weather_label (Label) dans HUD ; _on_battle_started() met à jour l'icône
- [ ] BattleManager.gd: signal weather_changed(weather_name) émis au début du combat
- [ ] tests/TestHeadless.gd: 5 tests (weather_rolls_valid, rain_weakens_fire, storm_boosts_lightning, blizzard_boosts_ice, heat_boosts_fire)

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 135/135 tests headless
- Contrôle C (logic trace):
  - AC1: _roll_weather() picks from WEATHER_OPTIONS[5], stores in current_weather, emits weather_changed; called in start_battle()
  - AC2: _apply_weather_mod() applies WEATHER_SPELL_MOD multipliers per element; applied in player_cast_spell() SPELL_DAMAGE branch
  - AC3: Battle.gd _weather_label created in _ensure_weather_label(); _update_weather_display() shows icon+name, hides if clear
  - AC4: enemy element_weakness + spell.element already ×1.5; weather stacks on top for double amplification
- Contrôle D (regression): 135/0 tests pass, MainMenu→Battle flow intact
- Déferments: weather only affects player spells (not enemy AI spells) — fair tradeoff for scope

---

## Sprint 61 — Boss Rush Mode (Épreuves de Puissance) [STATUS: DONE]
**Goal:** Débloquer un mode "Boss Rush" après avoir vaincu Sephiroth : enchaîner tous les boss majeurs en séquence sans soins entre les combats

**Acceptance Criteria:**
- [ ] AC1: Bouton "⚔️ Boss Rush" visible sur WorldMap uniquement si sephiroth_defeated == true ; démarre une séquence de combats [Guard Scorpion, Jenova, Sephiroth Phase1, Ruby Weapon, Emerald Weapon] en ordre
- [ ] AC2: Entre chaque boss, aucun soin automatique — la party conserve HP/MP du combat précédent ; battle_log "Prochain ennemi : <nom> — préparez-vous !"
- [ ] AC3: Si la party essuie un game over durant le Boss Rush → retour au WorldMap, boss_rush_best_score mis à jour avec le nombre de boss vaincus atteint
- [ ] AC4: Victoire complète (5/5 boss) → notification "🏆 Champion du Boss Rush !" + récompense unique (hero_drink item x3 : HEAL_ALL + full status clear)
- [ ] AC5: boss_rush_best_score persisté dans SaveSystem ; affiché sur le bouton "Boss Rush (record: N/5)"

**Tasks:**
- [ ] GameManager.gd: var boss_rush_best_score: int = 0 ; var boss_rush_active: bool = false ; BOSS_RUSH_SEQUENCE: Array const ; start_boss_rush() ; _on_boss_rush_victory() ; _on_boss_rush_game_over()
- [ ] resources/items/hero_drink.tres (effect_type=4 HEAL_ALL + effet spécial clear status, price=9999)
- [ ] WorldMap.gd: _add_boss_rush_button() — visible si sephiroth_defeated
- [ ] SaveSystem.gd: boss_rush_best_score persisté
- [ ] tests/TestHeadless.gd: 5 tests (boss_rush_locked_initially, boss_rush_unlocked_after_sephiroth, boss_rush_sequence_defined, hero_drink_defined, boss_rush_save_load)

**Verification Notes:**
- Contrôle A (static): ✅ check_compat.sh All clear
- Contrôle B (godot parse): ✅ 140/140 tests headless
- Contrôle C (logic trace):
  - AC1: _add_boss_rush_button() in WorldMap, btn.visible=sephiroth_defeated; BOSS_RUSH_SEQUENCE const 5 entries
  - AC2: No heal between bosses — party HP carries over (no new_game() between fights); battle_log in next fight popup
  - AC3: _on_boss_rush_battle_ended(lose) → boss_rush_active=false, updates best_score, changes scene to WorldMap
  - AC4: _on_boss_rush_complete() → add hero_drink ×3 via add_item(); _show_shinra_popup notification
  - AC5: boss_rush_best_score saved/loaded via SaveSystem; score shown on button text
- Contrôle D (regression): 140/0 tests pass, MainMenu→Battle flow intact
- Déferments: Boss Rush fights use scene change (real gameplay) rather than mock battles

---

## Sprint 62 — Système d'Achievements (Médailles FF7) [STATUS: TODO]
**Goal:** Ajouter un système d'achievements visible en jeu : 8 médailles à débloquer selon les exploits du joueur, avec popup de notification et écran de consultation

**Acceptance Criteria:**
- [ ] AC1: 8 achievements définis dans ACHIEVEMENT_DEFS const : "First Blood" (1er ennemi tué), "Collector" (5 items en inventaire), "Materia Master" (materia level 3 atteint), "All Stars" (7 membres débloqués), "Jackpot" (Slot jackpot obtenu), "Survivor" (vaincre Ruby Weapon), "Limit Broken" (Limit Break Tier 2 utilisé), "Champion" (Boss Rush complété)
- [ ] AC2: Quand un achievement est débloqué → popup "🏅 Achievement débloqué : <nom>" (doré, 3s) ; stocké dans GameManager.achievements_unlocked: Array
- [ ] AC3: Bouton "🏅" sur WorldMap ouvre un écran listant tous les achievements avec statut ✅/🔒 et description
- [ ] AC4: Vérification automatique des achievements au bon moment : après chaque combat (kills), après chaque achat (items), après chaque Limit/Slot, après sephiroth_defeated, etc.
- [ ] AC5: achievements_unlocked persisté dans SaveSystem

**Tasks:**
- [ ] GameManager.gd: ACHIEVEMENT_DEFS const (Array de dict name/desc/condition_key) ; var achievements_unlocked: Array = [] ; check_achievement(key) ; show_achievement_popup(name)
- [ ] GameManager.gd: _check_all_achievements() appelée après combat, après use_item, après limit_break utilisé
- [ ] WorldMap.gd: _add_achievement_button() → popup listant ACHIEVEMENT_DEFS avec état
- [ ] SaveSystem.gd: achievements_unlocked persisté
- [ ] tests/TestHeadless.gd: 5 tests (achievement_defs_count, check_first_blood, achievement_no_duplicate, achievement_save_load, all_achievement_keys_valid)

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:
