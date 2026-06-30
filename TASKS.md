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

## Sprint 41 — Ruby & Emerald Weapon (Boss optionnels Lv.20+) [STATUS: TODO]
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
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:

---

## Sprint 42 — Scènes narratives clés (Réacteur + Sephiroth Flashback) [STATUS: TODO]
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
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:
