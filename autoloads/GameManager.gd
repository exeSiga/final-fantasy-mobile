extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var party: Array = []          # 3 CombatUnit: [Warrior, BlackMage, WhiteMage]
var player_unit = null         # alias for party[0] (Warrior) — kept for compatibility
var gold: int = 0
var inventory: Dictionary = {}
var return_after_battle: String = "res://scenes/world/WorldMap.tscn"
var dungeon_boss_cleared = false
var dungeon_return_room: int = -1

signal gold_changed(new_amount: int)
signal level_up(new_level: int)

func _ready() -> void:
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func _on_root_child_entered(node: Node) -> void:
	current_scene = node

func change_scene(path: String) -> void:
	TransitionManager.fade_to(path)

func set_state(new_state: GameState) -> void:
	current_state = new_state

func new_game() -> void:
	party.clear()
	var warrior = load("res://resources/units/hero.tres").duplicate()
	var black_mage = load("res://resources/units/black_mage.tres").duplicate()
	var white_mage = load("res://resources/units/white_mage.tres").duplicate()
	party.append(warrior)
	party.append(black_mage)
	party.append(white_mage)
	player_unit = warrior
	gold = 0
	inventory = {}
	dungeon_boss_cleared = false
	dungeon_return_room = -1

func alive_party() -> Array:
	return party.filter(func(m) -> bool: return m.is_alive())

func add_item(item: Resource, qty: int = 1) -> void:
	var key: String = item.resource_path
	inventory[key] = min(item.max_stack, inventory.get(key, 0) + qty)

func use_item(item: Resource) -> bool:
	var key: String = item.resource_path
	if inventory.get(key, 0) <= 0:
		return false
	var used := false
	match item.effect_type:
		0:  # HEAL_HP — target most injured alive member
			var target = _most_injured_hp()
			if target == null or target.hp >= target.max_hp:
				return false
			target.hp = min(target.max_hp, target.hp + item.effect_value)
			used = true
		1:  # HEAL_MP — target most depleted MP
			var target = _most_depleted_mp()
			if target == null or target.mp >= target.max_mp:
				return false
			target.mp = min(target.max_mp, target.mp + item.effect_value)
			used = true
		2:  # REVIVE — first dead member
			var target = _first_dead()
			if target == null:
				return false
			target.hp = item.effect_value
			used = true
	if used:
		inventory[key] -= 1
		if inventory[key] <= 0:
			inventory.erase(key)
	return used

func _most_injured_hp():
	var best = null
	var best_pct: float = 1.0
	for m in alive_party():
		var pct: float = float(m.hp) / float(m.max_hp)
		if pct < best_pct:
			best_pct = pct
			best = m
	return best

func _most_depleted_mp():
	var best = null
	var best_pct: float = 1.0
	for m in alive_party():
		if m.max_mp <= 0:
			continue
		var pct: float = float(m.mp) / float(m.max_mp)
		if pct < best_pct:
			best_pct = pct
			best = m
	return best

func _first_dead():
	for m in party:
		if not m.is_alive():
			return m
	return null

func buy_item(item: Resource) -> bool:
	if gold < item.price:
		return false
	var key: String = item.resource_path
	if inventory.get(key, 0) >= item.max_stack:
		return false
	gold -= item.price
	gold_changed.emit(gold)
	add_item(item)
	return true

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func grant_battle_rewards() -> void:
	var total_xp: int = 0
	var total_gold: int = 0
	for e in BattleManager.enemies:
		total_xp += e.xp_reward
		total_gold += e.gold_reward
	add_gold(total_gold)
	var any_levelup := false
	for m in alive_party():
		if m.add_xp(total_xp):
			any_levelup = true
	if any_levelup:
		AudioManager.play_sfx_levelup()
		var max_level: int = 0
		for m in party:
			if m.level > max_level:
				max_level = m.level
		level_up.emit(max_level)
	BattleManager.last_xp = total_xp
	BattleManager.last_gold = total_gold
	# Restore 20% MP to all party members after victory
	for m in party:
		if m.max_mp > 0:
			m.mp = min(m.max_mp, m.mp + int(m.max_mp * 0.20))
