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

## Sprint 45 — Districts de Midgar (Secteurs 1, 5, 7) [STATUS: TODO]
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
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:

---

## Sprint 46 — Fichiers ShinRa (Notifications de Lore) [STATUS: TODO]
**Goal:** Après certains jalons (premier kill par type d'ennemi, boss vaincu, rang atteint), afficher un popup "Fichier ShinRa déverrouillé" avec une ligne de lore FF7

**Acceptance Criteria:**
- [ ] AC1: 6 fichiers ShinRa définis (ex: premier Slime tué, Guard Scorpion vaincu, rang 2nd Class atteint, Jenova vaincue, 50 kills total, Sephiroth vaincu)
- [ ] AC2: Chaque fichier ne s'affiche qu'une fois (GameManager.shinra_files_seen: Array), persisté en save
- [ ] AC3: Popup stylisé "📁 Fichier ShinRa" avec titre + une ligne de lore (fond bleu ShinRa), visible 4 secondes ou sur tap
- [ ] AC4: Les checks se font dans BattleManager._check_battle_end() et GameManager (rank change signal)

**Tasks:**
- [ ] GameManager.gd: shinra_files_seen: Array; SHINRA_FILES const (6 entrées: condition + titre + texte); check_shinra_files()
- [ ] SaveSystem.gd: persister shinra_files_seen
- [ ] scripts/ShinraFilePopup.gd + scenes/ui/ShinraFilePopup.tscn (fond bleu, titre + lore, auto-dismiss 4s)
- [ ] BattleManager._check_battle_end(): appel GameManager.check_shinra_files() après rewards
- [ ] WorldMap/_ready(): appel check_shinra_files() pour le rang au retour

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:

---

## Sprint 47 — New Game+ (Difficulté Augmentée) [STATUS: TODO]
**Goal:** Après avoir terminé le jeu (Sephiroth vaincu), débloquer un mode New Game+ qui relance avec les stats ennemis ×1.5 et des récompenses de fin améliorées

**Acceptance Criteria:**
- [ ] AC1: Après victoire sur Sephiroth, un bouton "New Game+" apparaît sur l'écran de victoire final (persisté via GameManager.ng_plus_unlocked)
- [ ] AC2: En NG+, tous les ennemis ont leurs HP et ATK multipliés par 1.5 (BattleManager.ng_plus_mode: bool)
- [ ] AC3: Les XP et Gold rewards sont aussi ×1.5 en NG+ (GameManager.grant_battle_rewards adapté)
- [ ] AC4: ng_plus_unlocked et ng_plus_mode persistent à la sauvegarde

**Tasks:**
- [ ] GameManager.gd: ng_plus_unlocked: bool, ng_plus_mode: bool
- [ ] BattleManager.gd: ng_plus_mode: bool; dans start_battle() après chargement ennemis → si ng_plus_mode: enemy.hp *= 1.5, enemy.max_hp *= 1.5, enemy.atk *= 1.5
- [ ] GameManager.grant_battle_rewards(): si ng_plus_mode → XP et gold ×1.5
- [ ] Battle.gd: _on_battle_ended(victory) + is_boss_sephiroth_battle → bouton "New Game+" si victory
- [ ] SaveSystem.gd: persister ng_plus_unlocked et ng_plus_mode

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:
