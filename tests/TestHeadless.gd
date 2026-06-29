## Run: godot4 --headless --path /home/siga/final-fantasy-mobile --scene res://tests/TestRunner.tscn
## Tests game logic (no async / no scene rendering required)
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

func _test_new_game() -> void:
	GameManager.new_game()
	if GameManager.player_unit == null:
		_ko("new_game", "player_unit null"); return
	if GameManager.player_unit.hp <= 0:
		_ko("new_game", "player hp=%d" % GameManager.player_unit.hp); return
	if GameManager.spells.size() != 3:
		_ko("new_game", "spells count=%d" % GameManager.spells.size()); return
	if GameManager.gold != 0:
		_ko("new_game", "gold should be 0, got %d" % GameManager.gold); return
	_ok("new_game: player + spells + gold initialized")

func _test_enemies_load() -> void:
	for path in BattleManager.ENEMY_POOL + BattleManager.DUNGEON_POOL + [BattleManager.BOSS_PATH]:
		var res = load(path)
		if res == null:
			_ko("enemies_load", "cannot load " + path); return
		if res.unit_name == "":
			_ko("enemies_load", path + " has empty unit_name"); return
	_ok("enemies_load: all 5 unit resources load correctly")

func _test_damage_formula() -> void:
	var hero = GameManager.player_unit
	var dummy = load("res://resources/units/slime.tres").duplicate()
	var original_hp: int = dummy.hp
	# take_damage(atk) = max(1, atk - def) — defense applied once
	var actual_dmg: int = dummy.take_damage(hero.atk)
	if actual_dmg < 1:
		_ko("damage_formula", "actual_dmg < 1 (atk=%d def=%d)" % [hero.atk, dummy.def]); return
	var expected_hp: int = max(0, original_hp - actual_dmg)
	if dummy.hp != expected_hp:
		_ko("damage_formula", "hp mismatch: expected %d got %d" % [expected_hp, dummy.hp]); return
	_ok("damage_formula: atk=%d def=%d → actual_dmg=%d hp %d→%d" % [hero.atk, dummy.def, actual_dmg, original_hp, dummy.hp])

func _test_level_up() -> void:
	var hero = GameManager.player_unit
	var atk_before: int = hero.atk
	var level_before: int = hero.level
	# Add enough XP to level up (xp_to_next_level is typically 100 at lvl 1)
	hero.add_xp(9999)
	if hero.level <= level_before:
		_ko("level_up", "level didn't increase (%d→%d)" % [level_before, hero.level]); return
	if hero.atk <= atk_before:
		_ko("level_up", "atk didn't increase (%d→%d)" % [atk_before, hero.atk]); return
	_ok("level_up: %d→%d, atk %d→%d" % [level_before, hero.level, atk_before, hero.atk])

func _test_inventory() -> void:
	var potion = load("res://resources/items/potion.tres")
	if potion == null:
		_ko("inventory", "potion.tres not found"); return
	GameManager.add_item(potion, 2)
	if GameManager.inventory.get(potion.resource_path, 0) != 2:
		_ko("inventory", "add_item failed"); return
	GameManager.player_unit.hp = 1
	var ok: bool = GameManager.use_item(potion)
	if not ok:
		_ko("inventory", "use_item returned false"); return
	if GameManager.player_unit.hp <= 1:
		_ko("inventory", "potion didn't heal (hp=%d)" % GameManager.player_unit.hp); return
	_ok("inventory: add + use potion OK (hp now %d)" % GameManager.player_unit.hp)

func _test_battle_setup() -> void:
	BattleManager.dungeon_mode = false
	BattleManager.is_boss_battle = false
	# Manually load enemies (don't call start_battle — it triggers async enemy turns)
	BattleManager.enemies.clear()
	BattleManager.enemies.append(load(BattleManager.ENEMY_POOL[0]).duplicate())
	BattleManager.player_unit = GameManager.player_unit
	BattleManager._build_turn_queue()
	if BattleManager.turn_queue.size() < 2:
		_ko("battle_setup", "turn_queue size=%d" % BattleManager.turn_queue.size()); return
	# Simulate player attack manually
	BattleManager.state = BattleManager.BattleState.PLAYER_TURN
	var enemy = BattleManager.enemies[0]
	var hp_before: int = enemy.hp
	BattleManager.player_attack()
	var hp_after: int = enemy.hp
	if hp_after >= hp_before and enemy.is_alive():
		_ko("battle_setup", "player_attack had no effect (%d→%d)" % [hp_before, hp_after]); return
	_ok("battle_setup: turn_queue built, player_attack deals damage (%d→%d)" % [hp_before, hp_after])
