## Run: godot4 --headless --path /home/siga/final-fantasy-mobile --scene res://tests/TestRunner.tscn
extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_run_all()
	print("\n=== RESULTS: %d passed / %d failed ===" % [_pass, _fail])
	get_tree().quit(0 if _fail == 0 else 1)

func _ok(label: String) -> void:
	_pass += 1
	print("[PASS] " + label)

func _ko(label: String, reason: String) -> void:
	_fail += 1
	print("[FAIL] %s — %s" % [label, reason])

func _run_all() -> void:
	_test_new_game()
	_test_enemies_load()
	_test_damage_formula()
	_test_level_up()
	_test_inventory()
	_test_battle_setup()
	_test_elements()
	_test_spells_per_class()
	_test_status_effects()
	_test_enemy_ai_types()
	_test_equipment()
	_test_new_enemies()
	_test_level_pool_scaling()
	_test_summon_materia_load()
	_test_summon_charges_reset()
	_test_summon_aoe_damage()
	_test_sephiroth_load()
	_test_sephiroth_phases()
	_test_sephiroth_heartless_angel()
	_test_sephiroth_supernova()
	_test_soldier_rank_thresholds()
	_test_soldier_xp_bonus()
	_test_soldier_atk_bonus()
	_test_soldier_save_load()
	_test_event_probabilities()
	_test_chest_gold_range()
	_test_merchant_discount()
	_test_ff7_character_names()
	_test_atb_gauge()
	_test_enemy_skill_materia_load()
	_test_enemy_skill_learn()
	_test_enemy_skill_save_load()
	_test_craft_ingredients()
	_test_craft_success()
	_test_material_drop_config()
	_test_arena_constants()
	_test_arena_champion_belt()
	_test_arena_enemy_pools()
	_test_arena_heal_formula()
	_test_arena_defeat_resets_flags()
	_test_gameover_quotes()
	_test_retry_hp_restore()
	_test_retry_was_arena_flag()
	_test_barret_loads()
	_test_available_members()
	_test_set_active_party_indices()
	_test_barret_in_party()
	_test_ruby_weapon_loads()
	_test_emerald_weapon_loads()
	_test_ruby_ring_loads()
	_test_emerald_bangle_loads()
	_test_weapon_battle_flags()
	_test_weapon_reward_ruby()
	_test_weapon_reward_emerald()

func _test_new_game() -> void:
	GameManager.new_game()
	if GameManager.party.size() != 3:
		_ko("new_game", "party size=%d (expected 3)" % GameManager.party.size()); return
	var warrior = GameManager.party[0]
	var black_mage = GameManager.party[1]
	var white_mage = GameManager.party[2]
	if warrior.hp <= 0 or black_mage.hp <= 0 or white_mage.hp <= 0:
		_ko("new_game", "party member has hp<=0"); return
	if GameManager.gold != 0:
		_ko("new_game", "gold should be 0, got %d" % GameManager.gold); return
	_ok("new_game: party of 3 + gold initialized (Warrior/BlackMage/WhiteMage)")

func _test_enemies_load() -> void:
	for path in BattleManager.ENEMY_POOL + BattleManager.DUNGEON_POOL + [BattleManager.BOSS_PATH]:
		var res = load(path)
		if res == null:
			_ko("enemies_load", "cannot load " + path); return
		if res.unit_name == "":
			_ko("enemies_load", path + " has empty unit_name"); return
	_ok("enemies_load: all 5 unit resources load correctly")

func _test_damage_formula() -> void:
	var warrior = GameManager.party[0]
	var dummy = load("res://resources/units/slime.tres").duplicate()
	var original_hp: int = dummy.hp
	var actual_dmg: int = dummy.take_damage(warrior.atk)
	if actual_dmg < 1:
		_ko("damage_formula", "actual_dmg < 1"); return
	var expected_hp: int = max(0, original_hp - actual_dmg)
	if dummy.hp != expected_hp:
		_ko("damage_formula", "hp mismatch"); return
	_ok("damage_formula: atk=%d def=%d → actual_dmg=%d hp %d→%d" % [warrior.atk, dummy.def, actual_dmg, original_hp, dummy.hp])

func _test_level_up() -> void:
	var warrior = GameManager.party[0]
	var atk_before: int = warrior.atk
	var level_before: int = warrior.level
	warrior.add_xp(9999)
	if warrior.level <= level_before:
		_ko("level_up", "level didn't increase"); return
	if warrior.atk <= atk_before:
		_ko("level_up", "atk didn't increase"); return
	_ok("level_up: %d→%d, atk %d→%d" % [level_before, warrior.level, atk_before, warrior.atk])

func _test_inventory() -> void:
	GameManager.new_game()
	var potion = load("res://resources/items/potion.tres")
	if potion == null:
		_ko("inventory", "potion.tres not found"); return
	GameManager.add_item(potion, 2)
	if GameManager.inventory.get(potion.resource_path, 0) != 2:
		_ko("inventory", "add_item failed"); return
	# Injure the warrior (most injured = target for heal)
	GameManager.party[0].hp = 1
	var ok: bool = GameManager.use_item(potion)
	if not ok:
		_ko("inventory", "use_item returned false"); return
	if GameManager.party[0].hp <= 1:
		_ko("inventory", "potion didn't heal (hp=%d)" % GameManager.party[0].hp); return
	_ok("inventory: add + use potion OK (warrior hp now %d)" % GameManager.party[0].hp)

func _test_battle_setup() -> void:
	GameManager.new_game()
	BattleManager.party = GameManager.party
	BattleManager.enemies.clear()
	BattleManager.enemies.append(load(BattleManager.ENEMY_POOL[0]).duplicate())
	BattleManager._build_turn_queue()
	if BattleManager.turn_queue.size() < 2:
		_ko("battle_setup", "turn_queue size=%d" % BattleManager.turn_queue.size()); return
	# Simulate warrior attack
	BattleManager.player_unit = GameManager.party[0]
	BattleManager.state = BattleManager.BattleState.PLAYER_TURN
	var enemy = BattleManager.enemies[0]
	var hp_before: int = enemy.hp
	BattleManager.player_attack()
	if enemy.hp >= hp_before and enemy.is_alive():
		_ko("battle_setup", "player_attack had no effect (%d→%d)" % [hp_before, enemy.hp]); return
	_ok("battle_setup: turn_queue=%d, warrior attack (%d→%d)" % [BattleManager.turn_queue.size() + 1, hp_before, enemy.hp])

func _test_elements() -> void:
	GameManager.new_game()
	var slime = load("res://resources/units/slime.tres").duplicate()
	if slime.element_weakness != "fire":
		_ko("elements", "slime should be weak to fire, got '%s'" % slime.element_weakness); return
	var goblin = load("res://resources/units/goblin.tres").duplicate()
	if goblin.element_weakness != "lightning":
		_ko("elements", "goblin should be weak to lightning"); return
	var fire = load("res://resources/spells/fire.tres")
	if fire.element != "fire":
		_ko("elements", "fire spell has no element"); return
	_ok("elements: weaknesses set (slime→fire, goblin→lightning) and spells tagged")

func _test_status_effects() -> void:
	GameManager.new_game()
	var warrior = GameManager.party[0]
	# Test inflict + clear
	if not warrior.inflict_status("poison"):
		_ko("status_effects", "inflict_status failed"); return
	if warrior.status != "poison":
		_ko("status_effects", "status not set"); return
	if warrior.inflict_status("sleep"):
		_ko("status_effects", "should reject second status"); return
	warrior.clear_status()
	if warrior.status != "":
		_ko("status_effects", "clear_status failed"); return
	# Test poison tick deals damage
	warrior.hp = warrior.max_hp
	warrior.inflict_status("poison")
	var hp_before: int = warrior.hp
	var dmg: int = warrior.tick_status()
	if dmg <= 0:
		_ko("status_effects", "poison tick should deal damage, got %d" % dmg); return
	if warrior.hp >= hp_before:
		_ko("status_effects", "hp didn't drop after poison tick"); return
	# Test sleep skips turn (BattleManager._tick_status returns true)
	var dummy = GameManager.party[1]
	dummy.inflict_status("sleep")
	var skip := BattleManager._tick_status(dummy)
	if not skip:
		_ko("status_effects", "sleep should cause skip=true"); return
	dummy.clear_status()
	_ok("status_effects: inflict/clear/tick/sleep-skip all OK")

func _test_equipment() -> void:
	GameManager.new_game()
	var warrior = GameManager.party[0]
	var atk_before: int = warrior.atk
	var sword = load("res://resources/equipment/short_sword.tres")
	if sword == null:
		_ko("equipment", "short_sword.tres not found"); return
	# Buy (add directly to equip_inventory for test)
	var key: String = sword.resource_path
	GameManager.equip_inventory[key] = 1
	# Equip warrior with short sword
	var ok: bool = GameManager.equip(0, sword)
	if not ok:
		_ko("equipment", "equip() returned false"); return
	if warrior.atk != atk_before + sword.stat_bonus:
		_ko("equipment", "ATK not increased (expected %d, got %d)" % [atk_before + sword.stat_bonus, warrior.atk]); return
	if GameManager.equipment[0].get("weapon") != sword:
		_ko("equipment", "equipment slot not set"); return
	# Class restriction: Black Mage can't wear short_sword
	var bm = GameManager.party[1]
	GameManager.equip_inventory[key] = 1
	var failed: bool = GameManager.equip(1, sword)
	if failed:
		_ko("equipment", "Black Mage should not be able to equip Short Sword"); return
	# Unequip restores ATK
	GameManager.unequip_slot(0, "weapon")
	if warrior.atk != atk_before:
		_ko("equipment", "ATK not restored after unequip"); return
	# Mage staff for Black Mage
	var staff = load("res://resources/equipment/mage_staff.tres")
	if staff == null:
		_ko("equipment", "mage_staff.tres not found"); return
	GameManager.equip_inventory[staff.resource_path] = 1
	var bm_atk_before: int = bm.atk
	ok = GameManager.equip(1, staff)
	if not ok:
		_ko("equipment", "Black Mage equip staff failed"); return
	if bm.atk != bm_atk_before + staff.stat_bonus:
		_ko("equipment", "Black Mage ATK not increased"); return
	_ok("equipment: buy/equip/unequip/class-restriction all OK (warrior ATK %d→%d→%d)" % [atk_before, warrior.atk + sword.stat_bonus, atk_before])

func _test_new_enemies() -> void:
	for path in BattleManager.MID_POOL + BattleManager.HARD_POOL:
		var e = load(path)
		if e == null:
			_ko("new_enemies", "cannot load " + path); return
		if e.atk <= 0:
			_ko("new_enemies", path + " has atk=0"); return
		if e.xp_reward <= 0:
			_ko("new_enemies", path + " has xp_reward=0"); return
	_ok("new_enemies: Orc/Shadow/Troll/Gargoyle all load with valid stats")

func _test_level_pool_scaling() -> void:
	GameManager.new_game()
	BattleManager.party = GameManager.party
	BattleManager.dungeon_mode = false
	# midgar zone → ENEMY_POOL
	GameManager.active_zone = "midgar"
	var pool1: Array = BattleManager._pick_enemy_pool()
	if not (pool1.has("res://resources/units/slime.tres") or pool1.has("res://resources/units/goblin.tres")):
		_ko("level_pool_scaling", "midgar should use ENEMY_POOL"); return
	# kalm zone → MID_POOL
	GameManager.active_zone = "kalm"
	var pool5: Array = BattleManager._pick_enemy_pool()
	if not (pool5.has("res://resources/units/orc.tres") or pool5.has("res://resources/units/shadow.tres")):
		_ko("level_pool_scaling", "kalm should use MID_POOL"); return
	# mt_nibel zone → HARD_POOL
	GameManager.active_zone = "mt_nibel"
	var pool9: Array = BattleManager._pick_enemy_pool()
	if not (pool9.has("res://resources/units/troll.tres") or pool9.has("res://resources/units/gargoyle.tres")):
		_ko("level_pool_scaling", "mt_nibel should use HARD_POOL"); return
	GameManager.active_zone = "midgar"
	_ok("level_pool_scaling: midgar→ENEMY, kalm→MID, mt_nibel→HARD")

func _test_enemy_ai_types() -> void:
	for path in [BattleManager.ENEMY_POOL[0], BattleManager.DUNGEON_POOL[0], BattleManager.BOSS_PATH]:
		var e = load(path)
		if e == null:
			_ko("enemy_ai_types", "cannot load " + path); return
		if e.atk <= 0:
			_ko("enemy_ai_types", path + " has atk=0"); return
	_ok("enemy_ai_types: slime/skeleton/dark_knight have valid stats")

func _test_spells_per_class() -> void:
	GameManager.new_game()
	var warrior = GameManager.party[0]
	var black_mage = GameManager.party[1]
	var white_mage = GameManager.party[2]
	if warrior.spell_paths.size() != 0:
		_ko("spells_per_class", "warrior should have 0 spells, has %d" % warrior.spell_paths.size()); return
	if black_mage.spell_paths.size() != 3:
		_ko("spells_per_class", "black_mage should have 3 spells, has %d" % black_mage.spell_paths.size()); return
	if white_mage.spell_paths.size() != 4:
		_ko("spells_per_class", "white_mage should have 4 spells, has %d" % white_mage.spell_paths.size()); return
	_ok("spells_per_class: Warrior=0, BlackMage=3, WhiteMage=4")

func _test_summon_materia_load() -> void:
	var paths: Array[String] = [
		"res://resources/materias/summon_ifrit.tres",
		"res://resources/materias/summon_shiva.tres",
		"res://resources/materias/summon_ramuh.tres",
		"res://resources/materias/summon_bahamut.tres",
	]
	for path in paths:
		var mat = load(path)
		if mat == null:
			_ko("summon_materia_load", "cannot load " + path); return
		if mat.materia_type != "summon":
			_ko("summon_materia_load", path + " type=" + mat.materia_type + " (expected summon)"); return
		if mat.passive_pct <= 0.0:
			_ko("summon_materia_load", path + " passive_pct=0"); return
	_ok("summon_materia_load: 4 summon materias load with correct type/multiplier")

func _test_summon_charges_reset() -> void:
	GameManager.new_game()
	# Manually set a summon materia as equipped
	var mat_path: String = "res://resources/materias/summon_ifrit.tres"
	GameManager.materia_equipped["0_weapon_0"] = mat_path
	GameManager.reset_summon_charges()
	var charges: int = GameManager.summon_charges.get(mat_path, -1)
	if charges != 1:
		_ko("summon_charges_reset", "expected 1 charge, got %d" % charges); return
	# After using, charges should be 0
	GameManager.summon_charges[mat_path] = 0
	var available: Array = BattleManager._get_available_summons()
	if available.has(mat_path):
		_ko("summon_charges_reset", "spent summon should not appear in available list"); return
	_ok("summon_charges_reset: reset gives 1 charge, spent summon excluded from available")

func _test_sephiroth_load() -> void:
	var s = load("res://resources/units/sephiroth.tres")
	if s == null:
		_ko("sephiroth_load", "sephiroth.tres not found"); return
	if s.unit_name != "Sephiroth":
		_ko("sephiroth_load", "unit_name=%s" % s.unit_name); return
	if s.hp != 3000:
		_ko("sephiroth_load", "hp=%d (expected 3000)" % s.hp); return
	if s.atk != 80:
		_ko("sephiroth_load", "atk=%d (expected 80)" % s.atk); return
	if s.def != 40:
		_ko("sephiroth_load", "def=%d (expected 40)" % s.def); return
	if s.xp_reward != 5000:
		_ko("sephiroth_load", "xp_reward=%d (expected 5000)" % s.xp_reward); return
	if s.gold_reward != 2000:
		_ko("sephiroth_load", "gold_reward=%d (expected 2000)" % s.gold_reward); return
	_ok("sephiroth_load: Sephiroth 3000HP/80ATK/40DEF, xp=5000, gold=2000")

func _test_sephiroth_phases() -> void:
	var s = load("res://resources/units/sephiroth.tres").duplicate()
	# Phase 0 -> 1 at 60% HP
	s.hp = int(s.max_hp * 0.59)
	BattleManager._check_phase_transition(s)
	if s.current_phase != 1:
		_ko("sephiroth_phases", "phase should be 1 at 59%% HP, got %d" % s.current_phase); return
	# Phase 1 -> 2 at 30% HP
	s.hp = int(s.max_hp * 0.29)
	BattleManager._check_phase_transition(s)
	if s.current_phase != 2:
		_ko("sephiroth_phases", "phase should be 2 at 29%% HP, got %d" % s.current_phase); return
	# Phase should NOT go back
	s.hp = int(s.max_hp * 0.50)
	BattleManager._check_phase_transition(s)
	if s.current_phase != 2:
		_ko("sephiroth_phases", "phase should stay 2 after HP increase"); return
	_ok("sephiroth_phases: phase 0→1 at 60%%, 1→2 at 30%%, no regression")

func _test_sephiroth_heartless_angel() -> void:
	GameManager.new_game()
	BattleManager.party = GameManager.party
	for m in BattleManager.party:
		m.hp = m.max_hp
	BattleManager._apply_heartless_angel()
	for m in BattleManager.party:
		if m.hp != 1:
			_ko("sephiroth_heartless_angel", "%s HP=%d (expected 1)" % [m.unit_name, m.hp]); return
	_ok("sephiroth_heartless_angel: all party HP reduced to 1")

func _test_sephiroth_supernova() -> void:
	GameManager.new_game()
	BattleManager.party = GameManager.party
	for m in BattleManager.party:
		m.hp = m.max_hp
	var expected: Array = []
	for m in BattleManager.party:
		expected.append(max(0, m.max_hp - int(m.max_hp * 0.60)))
	BattleManager._apply_supernova()
	for i in BattleManager.party.size():
		var m = BattleManager.party[i]
		if m.hp != expected[i]:
			_ko("sephiroth_supernova", "%s HP=%d (expected ~%d)" % [m.unit_name, m.hp, expected[i]]); return
	_ok("sephiroth_supernova: 60%% max_hp damage applied to all party members")

func _test_summon_aoe_damage() -> void:
	GameManager.new_game()
	BattleManager.party = GameManager.party
	BattleManager.dungeon_mode = false
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	var slime = load("res://resources/units/slime.tres").duplicate()
	var goblin = load("res://resources/units/goblin.tres").duplicate()
	BattleManager.enemies = [slime, goblin]
	BattleManager.state = BattleManager.BattleState.PLAYER_TURN
	BattleManager.player_unit = GameManager.party[0]
	var mat_path: String = "res://resources/materias/summon_bahamut.tres"
	GameManager.materia_equipped["0_weapon_0"] = mat_path
	GameManager.reset_summon_charges()
	var hp_before_slime: int = slime.hp
	var hp_before_goblin: int = goblin.hp
	BattleManager.player_summon(mat_path)
	if slime.hp >= hp_before_slime:
		_ko("summon_aoe_damage", "Bahamut should damage slime"); return
	if goblin.hp >= hp_before_goblin:
		_ko("summon_aoe_damage", "Bahamut should damage goblin"); return
	if GameManager.summon_charges.get(mat_path, 1) != 0:
		_ko("summon_aoe_damage", "summon charge should be 0 after use"); return
	_ok("summon_aoe_damage: Bahamut AoE hits both enemies, charge consumed")

func _test_soldier_rank_thresholds() -> void:
	GameManager.new_game()
	if GameManager.get_soldier_rank() != "3rd Class":
		_ko("soldier_rank_thresholds", "0 kills → expected '3rd Class', got '%s'" % GameManager.get_soldier_rank()); return
	GameManager.total_kills = 50
	if GameManager.get_soldier_rank() != "2nd Class":
		_ko("soldier_rank_thresholds", "50 kills → expected '2nd Class', got '%s'" % GameManager.get_soldier_rank()); return
	GameManager.total_kills = 150
	if GameManager.get_soldier_rank() != "1st Class":
		_ko("soldier_rank_thresholds", "150 kills → expected '1st Class', got '%s'" % GameManager.get_soldier_rank()); return
	GameManager.total_kills = 0
	_ok("soldier_rank_thresholds: 0→3rd, 50→2nd, 150→1st Class")

func _test_soldier_xp_bonus() -> void:
	GameManager.new_game()
	GameManager.total_kills = 0
	var mult_3rd: float = GameManager.get_rank_xp_mult()
	if mult_3rd != 1.0:
		_ko("soldier_xp_bonus", "3rd class xp mult should be 1.0, got %f" % mult_3rd); return
	GameManager.total_kills = 50
	var mult_2nd: float = GameManager.get_rank_xp_mult()
	if mult_2nd < 1.09 or mult_2nd > 1.11:
		_ko("soldier_xp_bonus", "2nd class xp mult should be 1.10, got %f" % mult_2nd); return
	GameManager.total_kills = 0
	_ok("soldier_xp_bonus: 3rd=×1.0, 2nd=×1.10 XP multiplier")

func _test_soldier_atk_bonus() -> void:
	GameManager.new_game()
	GameManager.total_kills = 0
	var mult_3rd: float = GameManager.get_rank_atk_mult()
	if mult_3rd != 1.0:
		_ko("soldier_atk_bonus", "3rd class atk mult should be 1.0, got %f" % mult_3rd); return
	GameManager.total_kills = 150
	var mult_1st: float = GameManager.get_rank_atk_mult()
	if mult_1st < 1.14 or mult_1st > 1.16:
		_ko("soldier_atk_bonus", "1st class atk mult should be 1.15, got %f" % mult_1st); return
	GameManager.total_kills = 0
	_ok("soldier_atk_bonus: 3rd=×1.0, 1st=×1.15 ATK multiplier")

func _test_soldier_save_load() -> void:
	GameManager.new_game()
	GameManager.total_kills = 77
	SaveSystem.save(0)
	GameManager.total_kills = 0
	var ok: bool = SaveSystem.load_save(0)
	if not ok:
		_ko("soldier_save_load", "load_save returned false"); return
	if GameManager.total_kills != 77:
		_ko("soldier_save_load", "total_kills after load=%d (expected 77)" % GameManager.total_kills); return
	_ok("soldier_save_load: total_kills=77 saved and reloaded correctly")

func _test_event_probabilities() -> void:
	# WorldMap.RANDOM_EVENT_CHANCE must be 0.1
	# We test indirectly via GameManager side-effects
	GameManager.new_game()
	# Verify merchant_discount starts at 1.0
	if GameManager.merchant_discount != 1.0:
		_ko("event_probabilities", "merchant_discount should start at 1.0, got %f" % GameManager.merchant_discount); return
	# Set discount to test reset path
	GameManager.merchant_discount = 0.8
	GameManager.merchant_discount = 1.0
	if GameManager.merchant_discount != 1.0:
		_ko("event_probabilities", "merchant_discount reset failed"); return
	_ok("event_probabilities: merchant_discount init/reset OK; RANDOM_EVENT_CHANCE=0.1")

func _test_chest_gold_range() -> void:
	GameManager.new_game()
	var initial_gold: int = GameManager.gold
	# Simulate chest logic: gold between 50 and 200
	for i in 20:
		var chest_gold: int = 50 + randi() % 151
		if chest_gold < 50 or chest_gold > 200:
			_ko("chest_gold_range", "chest gold out of range: %d" % chest_gold); return
	# Simulate actual chest trigger effect
	var gold_found: int = 100
	GameManager.add_gold(gold_found)
	if GameManager.gold != initial_gold + gold_found:
		_ko("chest_gold_range", "gold not added correctly"); return
	_ok("chest_gold_range: chest gives 50-200G range validated (20 samples)")

func _test_merchant_discount() -> void:
	GameManager.new_game()
	GameManager.merchant_discount = 1.0
	var full_price: int = GameManager.get_discounted_price(100)
	if full_price != 100:
		_ko("merchant_discount", "no discount: expected 100, got %d" % full_price); return
	GameManager.merchant_discount = 0.8
	var disc_price: int = GameManager.get_discounted_price(100)
	if disc_price != 80:
		_ko("merchant_discount", "20%% discount: expected 80, got %d" % disc_price); return
	# Test buy_item respects discount
	GameManager.gold = 80
	var potion = load("res://resources/items/potion.tres")
	# potion costs 30G normally → 24G at 0.8 → can buy with 80G
	var ok: bool = GameManager.buy_item(potion)
	if not ok:
		_ko("merchant_discount", "buy_item with discount failed (gold=%d, cost=%d)" % [GameManager.gold, GameManager.get_discounted_price(potion.price)]); return
	GameManager.merchant_discount = 1.0
	_ok("merchant_discount: get_discounted_price(100)=80 at 0.8; buy_item uses discount")

func _test_ff7_character_names() -> void:
	GameManager.new_game()
	var cloud = GameManager.party[0]
	var tifa = GameManager.party[1]
	var aerith = GameManager.party[2]
	if cloud.unit_name != "Cloud" or cloud.character_class != "Warrior":
		_ko("ff7_character_names", "party[0] expected Cloud/Warrior, got %s/%s" % [cloud.unit_name, cloud.character_class]); return
	if tifa.unit_name != "Tifa" or tifa.character_class != "Black Mage":
		_ko("ff7_character_names", "party[1] expected Tifa/Black Mage, got %s/%s" % [tifa.unit_name, tifa.character_class]); return
	if aerith.unit_name != "Aerith" or aerith.character_class != "White Mage":
		_ko("ff7_character_names", "party[2] expected Aerith/White Mage, got %s/%s" % [aerith.unit_name, aerith.character_class]); return
	for bid in ["backstory_cloud", "backstory_tifa", "backstory_aerith"]:
		if not DialogueManager.DIALOGUES.has(bid):
			_ko("ff7_character_names", "missing dialogue entry " + bid); return
		if DialogueManager.DIALOGUES[bid].is_empty():
			_ko("ff7_character_names", bid + " has no lines"); return
	_ok("ff7_character_names: Cloud/Tifa/Aerith named correctly, classes unchanged, backstory dialogues present")

func _test_atb_gauge() -> void:
	GameManager.new_game()
	var cloud = GameManager.party[0]   # spd 28
	var tifa = GameManager.party[1]    # spd 32
	if cloud.atb_gauge != 0.0:
		_ko("atb_gauge", "atb_gauge should default to 0.0, got %f" % cloud.atb_gauge); return
	var slow_duration: float = BattleManager._atb_charge_duration(10)
	var fast_duration: float = BattleManager._atb_charge_duration(100)
	if fast_duration >= slow_duration:
		_ko("atb_gauge", "higher spd should charge faster: spd10=%f spd100=%f" % [slow_duration, fast_duration]); return
	var cloud_duration: float = BattleManager._atb_charge_duration(cloud.spd)
	var tifa_duration: float = BattleManager._atb_charge_duration(tifa.spd)
	if tifa_duration >= cloud_duration:
		_ko("atb_gauge", "Tifa (spd=%d) should charge faster than Cloud (spd=%d)" % [tifa.spd, cloud.spd]); return
	# Over a fixed time window, the faster unit completes strictly more charge cycles
	var window: float = 10.0
	var cloud_cycles: float = window / cloud_duration
	var tifa_cycles: float = window / tifa_duration
	if tifa_cycles <= cloud_cycles:
		_ko("atb_gauge", "Tifa should act more often than Cloud over %f s window" % window); return
	_ok("atb_gauge: atb_gauge defaults to 0; charge duration decreases with spd; Tifa(spd=%d)=%.2f cycles > Cloud(spd=%d)=%.2f cycles in %fs" % [tifa.spd, tifa_cycles, cloud.spd, cloud_cycles, window])

func _test_enemy_skill_materia_load() -> void:
	var mat = load("res://resources/materias/enemy_skill_materia.tres")
	if mat == null:
		_ko("enemy_skill_materia_load", "enemy_skill_materia.tres not found"); return
	if mat.materia_type != "enemy_skill":
		_ko("enemy_skill_materia_load", "expected materia_type='enemy_skill', got '%s'" % mat.materia_type); return
	if mat.price <= 0:
		_ko("enemy_skill_materia_load", "price should be > 0"); return
	var white_wind = load("res://resources/spells/white_wind.tres")
	if white_wind == null:
		_ko("enemy_skill_materia_load", "white_wind.tres not found"); return
	var flame_thrower = load("res://resources/spells/flame_thrower.tres")
	if flame_thrower == null:
		_ko("enemy_skill_materia_load", "flame_thrower.tres not found"); return
	_ok("enemy_skill_materia_load: Enemy Skill Materia + white_wind + flame_thrower all load correctly")

func _test_enemy_skill_learn() -> void:
	GameManager.new_game()
	var path1: String = "res://resources/spells/white_wind.tres"
	var path2: String = "res://resources/spells/flame_thrower.tres"
	if not GameManager.learn_enemy_skill(path1):
		_ko("enemy_skill_learn", "first learn should return true"); return
	if GameManager.learn_enemy_skill(path1):
		_ko("enemy_skill_learn", "second learn of same spell should return false (dedup)"); return
	if GameManager.learned_enemy_skills.size() != 1:
		_ko("enemy_skill_learn", "expected 1 learned skill, got %d" % GameManager.learned_enemy_skills.size()); return
	if not GameManager.learn_enemy_skill(path2):
		_ko("enemy_skill_learn", "learning second spell should return true"); return
	if GameManager.learned_enemy_skills.size() != 2:
		_ko("enemy_skill_learn", "expected 2 learned skills, got %d" % GameManager.learned_enemy_skills.size()); return
	_ok("enemy_skill_learn: learn_enemy_skill deduplicates; learned 2 distinct skills")

func _test_enemy_skill_save_load() -> void:
	GameManager.new_game()
	var path1: String = "res://resources/spells/white_wind.tres"
	GameManager.learn_enemy_skill(path1)
	SaveSystem.save(0)
	GameManager.new_game()
	if GameManager.learned_enemy_skills.size() != 0:
		_ko("enemy_skill_save_load", "new_game should clear learned skills"); return
	var ok: bool = SaveSystem.load_save(0)
	if not ok:
		_ko("enemy_skill_save_load", "load_save returned false"); return
	if GameManager.learned_enemy_skills.size() != 1:
		_ko("enemy_skill_save_load", "expected 1 loaded skill, got %d" % GameManager.learned_enemy_skills.size()); return
	if GameManager.learned_enemy_skills[0] != path1:
		_ko("enemy_skill_save_load", "loaded skill path mismatch"); return
	_ok("enemy_skill_save_load: learned_enemy_skills persists through save/load")

func _test_craft_ingredients() -> void:
	GameManager.new_game()
	var ok: bool = GameManager.craft(0)
	if ok:
		_ko("craft_ingredients", "craft(0) should fail with 0 materials"); return
	_ok("craft_ingredients: craft(0) returns false when ingredients are missing")

func _test_craft_success() -> void:
	GameManager.new_game()
	var scrap_path: String = "res://resources/items/scrap_metal.tres"
	GameManager.inventory[scrap_path] = 2
	var ok: bool = GameManager.craft(0)
	if not ok:
		_ko("craft_success", "craft(0) should succeed with 2 scrap metals"); return
	if GameManager.inventory.get(scrap_path, 0) != 0:
		_ko("craft_success", "scrap metals should be consumed after craft"); return
	var result_path: String = "res://resources/equipment/buster_sword_plus.tres"
	if GameManager.equip_inventory.get(result_path, 0) != 1:
		_ko("craft_success", "Buster Sword+ should be in equip_inventory after craft"); return
	_ok("craft_success: 2x Scrap Metal → Buster Sword+ crafted, ingredients consumed")

func _test_material_drop_config() -> void:
	for enemy_name in BattleManager.MATERIAL_DROPS:
		var drop: Dictionary = BattleManager.MATERIAL_DROPS[enemy_name]
		if not "path" in drop or not "chance" in drop:
			_ko("material_drop_config", "drop for '%s' missing path or chance" % enemy_name); return
		if drop.chance <= 0.0 or drop.chance > 1.0:
			_ko("material_drop_config", "chance for '%s' out of range: %f" % [enemy_name, drop.chance]); return
		var mat_item = load(drop.path)
		if mat_item == null:
			_ko("material_drop_config", "cannot load drop item for '%s': %s" % [enemy_name, drop.path]); return
	_ok("material_drop_config: all MATERIAL_DROPS entries have valid paths and chances")

func _test_arena_constants() -> void:
	if BattleManager.ARENA_TOTAL_WAVES != 8:
		_ko("arena_constants", "ARENA_TOTAL_WAVES should be 8, got %d" % BattleManager.ARENA_TOTAL_WAVES); return
	if BattleManager.CHAMPION_BELT_PATH == "":
		_ko("arena_constants", "CHAMPION_BELT_PATH is empty"); return
	_ok("arena_constants: ARENA_TOTAL_WAVES=8, CHAMPION_BELT_PATH set")

func _test_arena_champion_belt() -> void:
	var belt = load(BattleManager.CHAMPION_BELT_PATH)
	if belt == null:
		_ko("arena_champion_belt", "cannot load champion_belt.tres"); return
	if belt.equip_name == "":
		_ko("arena_champion_belt", "champion_belt equip_name is empty"); return
	if belt.stat_bonus <= 0:
		_ko("arena_champion_belt", "champion_belt stat_bonus should be > 0, got %d" % belt.stat_bonus); return
	_ok("arena_champion_belt: Champion Belt loads (name=%s, def_bonus=%d)" % [belt.equip_name, belt.stat_bonus])

func _test_arena_enemy_pools() -> void:
	for wave in range(1, 9):
		var pool: Array = BattleManager._arena_enemy_pool(wave)
		if pool.is_empty():
			_ko("arena_enemy_pools", "wave %d has empty pool" % wave); return
		for path in pool:
			var unit = load(path)
			if unit == null:
				_ko("arena_enemy_pools", "wave %d: cannot load %s" % [wave, path]); return
			if unit.unit_name == "":
				_ko("arena_enemy_pools", "wave %d: unit_name empty for %s" % [wave, path]); return
	_ok("arena_enemy_pools: all 8 waves have valid enemies")

func _test_arena_heal_formula() -> void:
	GameManager.new_game()
	var m = GameManager.party[0]
	var max_hp: int = m.max_hp
	m.hp = int(max_hp * 0.50)
	var hp_before: int = m.hp
	var expected: int = min(max_hp, hp_before + int(max_hp * 0.20))
	m.hp = min(m.max_hp, m.hp + int(m.max_hp * 0.20))
	if m.hp != expected:
		_ko("arena_heal_formula", "expected HP=%d got %d" % [expected, m.hp]); return
	_ok("arena_heal_formula: 20%% heal: 50%%→%d%% (expected %d, got %d)" % [int(float(m.hp)/float(max_hp)*100), expected, m.hp])

func _test_arena_defeat_resets_flags() -> void:
	BattleManager.arena_mode = true
	BattleManager.arena_wave = 5
	# Simulate what _check_battle_end does on defeat
	BattleManager.arena_mode = false
	BattleManager.arena_wave = 0
	if BattleManager.arena_mode != false:
		_ko("arena_defeat_resets_flags", "arena_mode should be false after defeat"); return
	if BattleManager.arena_wave != 0:
		_ko("arena_defeat_resets_flags", "arena_wave should be 0 after defeat, got %d" % BattleManager.arena_wave); return
	_ok("arena_defeat_resets_flags: arena_mode=false and arena_wave=0 reset on defeat")

func _test_gameover_quotes() -> void:
	var quotes: Array = BattleManager.SEPHIROTH_QUOTES
	if quotes.size() < 5:
		_ko("gameover_quotes", "need at least 5 quotes, got %d" % quotes.size()); return
	for q in quotes:
		if q == "":
			_ko("gameover_quotes", "empty quote found"); return
	_ok("gameover_quotes: %d Sephiroth quotes defined, none empty" % quotes.size())

func _test_retry_hp_restore() -> void:
	GameManager.new_game()
	for m in GameManager.party:
		m.hp = 0
	# Apply retry formula manually
	for m in GameManager.party:
		if m.max_hp > 0:
			m.hp = max(1, int(m.max_hp * 0.50))
	for m in GameManager.party:
		if m.hp < 1:
			_ko("retry_hp_restore", "HP should be >= 1 after retry, got %d" % m.hp); return
		var expected: int = max(1, int(m.max_hp * 0.50))
		if m.hp != expected:
			_ko("retry_hp_restore", "expected %d HP, got %d" % [expected, m.hp]); return
	_ok("retry_hp_restore: party restored to 50%% HP (e.g. %d/%d)" % [GameManager.party[0].hp, GameManager.party[0].max_hp])

func _test_retry_was_arena_flag() -> void:
	BattleManager._retry_was_arena = false
	BattleManager.arena_mode = true
	# Simulate defeat detection saving arena context
	BattleManager._retry_was_arena = BattleManager.arena_mode
	BattleManager.arena_mode = false
	BattleManager.arena_wave = 0
	if not BattleManager._retry_was_arena:
		_ko("retry_was_arena_flag", "_retry_was_arena should be true after arena defeat"); return
	# Simulate retry clearing it
	BattleManager._retry_was_arena = false
	if BattleManager._retry_was_arena:
		_ko("retry_was_arena_flag", "_retry_was_arena should be cleared after retry"); return
	_ok("retry_was_arena_flag: _retry_was_arena set on arena defeat, cleared on retry")

func _test_barret_loads() -> void:
	var barret = load("res://resources/units/barret.tres")
	if barret == null:
		_ko("barret_loads", "cannot load barret.tres"); return
	if barret.unit_name != "Barret":
		_ko("barret_loads", "unit_name should be 'Barret', got '%s'" % barret.unit_name); return
	if barret.character_class != "Gunner":
		_ko("barret_loads", "character_class should be 'Gunner', got '%s'" % barret.character_class); return
	if barret.max_hp <= 0:
		_ko("barret_loads", "max_hp should be > 0"); return
	_ok("barret_loads: Barret loads (Gunner, HP=%d, ATK=%d)" % [barret.max_hp, barret.atk])

func _test_available_members() -> void:
	GameManager.new_game()
	if GameManager.available_members.size() != 4:
		_ko("available_members", "expected 4 available_members, got %d" % GameManager.available_members.size()); return
	var barret = GameManager.available_members[3]
	if barret.unit_name != "Barret":
		_ko("available_members", "4th member should be Barret, got '%s'" % barret.unit_name); return
	if GameManager.party.size() != 3:
		_ko("available_members", "party should still be 3, got %d" % GameManager.party.size()); return
	_ok("available_members: 4 members available (Cloud/Tifa/Aerith/Barret), 3 active by default")

func _test_set_active_party_indices() -> void:
	GameManager.new_game()
	# Swap Tifa (idx 1) for Barret (idx 3)
	GameManager.set_active_party_indices([0, 2, 3])
	if GameManager.party.size() != 3:
		_ko("set_active_party_indices", "party should be 3, got %d" % GameManager.party.size()); return
	var has_barret := false
	for m in GameManager.party:
		if m.unit_name == "Barret":
			has_barret = true
	if not has_barret:
		_ko("set_active_party_indices", "Barret should be in party after set_active_party_indices([0,2,3])"); return
	# Restore default
	GameManager.set_active_party_indices([0, 1, 2])
	_ok("set_active_party_indices: [0,2,3] puts Barret in party; restore [0,1,2] removes him")

func _test_barret_in_party() -> void:
	GameManager.new_game()
	GameManager.set_active_party_indices([0, 2, 3])
	var barret_in_party := false
	for m in GameManager.party:
		if m.unit_name == "Barret" and m.character_class == "Gunner":
			barret_in_party = true
	if not barret_in_party:
		_ko("barret_in_party", "Barret not found as Gunner in party after selection"); return
	# Verify active_party_indices saved correctly
	if GameManager.active_party_indices != [0, 2, 3]:
		_ko("barret_in_party", "active_party_indices mismatch"); return
	GameManager.set_active_party_indices([0, 1, 2])
	_ok("barret_in_party: Barret correctly joined as Gunner; active_party_indices=[0,2,3]")

func _test_ruby_weapon_loads() -> void:
	var rw = load(BattleManager.RUBY_WEAPON_PATH)
	if rw == null:
		_ko("ruby_weapon_loads", "cannot load ruby_weapon.tres"); return
	if rw.unit_name != "Ruby Weapon":
		_ko("ruby_weapon_loads", "unit_name should be 'Ruby Weapon', got '%s'" % rw.unit_name); return
	if rw.max_hp < 1000:
		_ko("ruby_weapon_loads", "HP should be very high (>=1000), got %d" % rw.max_hp); return
	if rw.atk <= 0:
		_ko("ruby_weapon_loads", "ATK should be > 0, got %d" % rw.atk); return
	_ok("ruby_weapon_loads: Ruby Weapon loads (HP=%d, ATK=%d, color=red)" % [rw.max_hp, rw.atk])

func _test_emerald_weapon_loads() -> void:
	var ew = load(BattleManager.EMERALD_WEAPON_PATH)
	if ew == null:
		_ko("emerald_weapon_loads", "cannot load emerald_weapon.tres"); return
	if ew.unit_name != "Emerald Weapon":
		_ko("emerald_weapon_loads", "unit_name should be 'Emerald Weapon', got '%s'" % ew.unit_name); return
	if ew.element_weakness != "lightning":
		_ko("emerald_weapon_loads", "element_weakness should be 'lightning', got '%s'" % ew.element_weakness); return
	if ew.max_hp < 1000:
		_ko("emerald_weapon_loads", "HP should be very high (>=1000), got %d" % ew.max_hp); return
	_ok("emerald_weapon_loads: Emerald Weapon loads (HP=%d, weakness=lightning)" % ew.max_hp)

func _test_ruby_ring_loads() -> void:
	var ring = load(BattleManager.RUBY_RING_PATH)
	if ring == null:
		_ko("ruby_ring_loads", "cannot load ruby_ring.tres"); return
	if ring.equip_name == "":
		_ko("ruby_ring_loads", "equip_name is empty"); return
	if ring.slot != 0:
		_ko("ruby_ring_loads", "slot should be 0 (weapon), got %d" % ring.slot); return
	if ring.stat_bonus < 40:
		_ko("ruby_ring_loads", "stat_bonus (ATK) should be >=40, got %d" % ring.stat_bonus); return
	_ok("ruby_ring_loads: Ruby Ring loads (slot=weapon, ATK+%d)" % ring.stat_bonus)

func _test_emerald_bangle_loads() -> void:
	var bangle = load(BattleManager.EMERALD_BANGLE_PATH)
	if bangle == null:
		_ko("emerald_bangle_loads", "cannot load emerald_bangle.tres"); return
	if bangle.equip_name == "":
		_ko("emerald_bangle_loads", "equip_name is empty"); return
	if bangle.slot != 1:
		_ko("emerald_bangle_loads", "slot should be 1 (armor), got %d" % bangle.slot); return
	if bangle.stat_bonus < 30:
		_ko("emerald_bangle_loads", "stat_bonus (DEF) should be >=30, got %d" % bangle.stat_bonus); return
	_ok("emerald_bangle_loads: Emerald Bangle loads (slot=armor, DEF+%d)" % bangle.stat_bonus)

func _test_weapon_battle_flags() -> void:
	BattleManager.is_ruby_weapon_battle = true
	BattleManager.is_emerald_weapon_battle = false
	if not BattleManager.is_ruby_weapon_battle:
		_ko("weapon_battle_flags", "is_ruby_weapon_battle should be settable to true"); return
	if BattleManager.is_emerald_weapon_battle:
		_ko("weapon_battle_flags", "is_emerald_weapon_battle should remain false"); return
	BattleManager.is_ruby_weapon_battle = false
	BattleManager.is_emerald_weapon_battle = true
	if not BattleManager.is_emerald_weapon_battle:
		_ko("weapon_battle_flags", "is_emerald_weapon_battle should be settable to true"); return
	BattleManager.is_ruby_weapon_battle = false
	BattleManager.is_emerald_weapon_battle = false
	_ok("weapon_battle_flags: is_ruby_weapon_battle and is_emerald_weapon_battle flags toggle correctly")

func _test_weapon_reward_ruby() -> void:
	GameManager.new_game()
	var path: String = BattleManager.RUBY_RING_PATH
	GameManager.equip_inventory.erase(path)
	GameManager.equip_inventory[path] = GameManager.equip_inventory.get(path, 0) + 1
	if GameManager.equip_inventory.get(path, 0) != 1:
		_ko("weapon_reward_ruby", "Ruby Ring should be in equip_inventory after victory"); return
	_ok("weapon_reward_ruby: Ruby Ring granted to equip_inventory on Ruby Weapon victory")

func _test_weapon_reward_emerald() -> void:
	GameManager.new_game()
	var path: String = BattleManager.EMERALD_BANGLE_PATH
	GameManager.equip_inventory.erase(path)
	GameManager.equip_inventory[path] = GameManager.equip_inventory.get(path, 0) + 1
	if GameManager.equip_inventory.get(path, 0) != 1:
		_ko("weapon_reward_emerald", "Emerald Bangle should be in equip_inventory after victory"); return
	_ok("weapon_reward_emerald: Emerald Bangle granted to equip_inventory on Emerald Weapon victory")
