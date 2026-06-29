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
	# At level 1 → ENEMY_POOL
	var pool1: Array = BattleManager._pick_enemy_pool()
	if not (pool1.has("res://resources/units/slime.tres") or pool1.has("res://resources/units/goblin.tres")):
		_ko("level_pool_scaling", "level 1 should use ENEMY_POOL"); return
	# Artificially raise level to 5 → MID_POOL
	for m in GameManager.party:
		m.level = 5
	var pool5: Array = BattleManager._pick_enemy_pool()
	if not (pool5.has("res://resources/units/orc.tres") or pool5.has("res://resources/units/shadow.tres")):
		_ko("level_pool_scaling", "level 5 should use MID_POOL"); return
	# Level 9 → HARD_POOL
	for m in GameManager.party:
		m.level = 9
	var pool9: Array = BattleManager._pick_enemy_pool()
	if not (pool9.has("res://resources/units/troll.tres") or pool9.has("res://resources/units/gargoyle.tres")):
		_ko("level_pool_scaling", "level 9 should use HARD_POOL"); return
	_ok("level_pool_scaling: lv1→ENEMY, lv5→MID, lv9→HARD")

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
