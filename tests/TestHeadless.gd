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
