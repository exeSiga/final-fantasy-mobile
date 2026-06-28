extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var player_unit = null
var gold: int = 0
var spells: Array = []
var inventory: Dictionary = {}
var return_after_battle: String = "res://scenes/world/WorldMap.tscn"

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
	player_unit = load("res://resources/units/hero.tres").duplicate()
	gold = 0
	inventory = {}
	spells.clear()
	spells.append(load("res://resources/spells/fire.tres"))
	spells.append(load("res://resources/spells/cure.tres"))
	spells.append(load("res://resources/spells/haste.tres"))

func add_item(item: Resource, qty: int = 1) -> void:
	var key: String = item.resource_path
	inventory[key] = min(item.max_stack, inventory.get(key, 0) + qty)

func use_item(item: Resource) -> bool:
	var key: String = item.resource_path
	if inventory.get(key, 0) <= 0 or player_unit == null:
		return false
	match item.effect_type:
		0:  # HEAL_HP
			if player_unit.hp >= player_unit.max_hp:
				return false
			player_unit.hp = min(player_unit.max_hp, player_unit.hp + item.effect_value)
		1:  # HEAL_MP
			if player_unit.mp >= player_unit.max_mp:
				return false
			player_unit.mp = min(player_unit.max_mp, player_unit.mp + item.effect_value)
		2:  # REVIVE
			if player_unit.is_alive():
				return false
			player_unit.hp = item.effect_value
	inventory[key] -= 1
	if inventory[key] <= 0:
		inventory.erase(key)
	return true

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
	if player_unit == null:
		return
	var total_xp: int = 0
	var total_gold: int = 0
	for e in BattleManager.enemies:
		total_xp += e.xp_reward
		total_gold += e.gold_reward
	add_gold(total_gold)
	var leveled_up: bool = player_unit.add_xp(total_xp)
	if leveled_up:
		AudioManager.play_sfx_levelup()
		level_up.emit(player_unit.level)
	BattleManager.last_xp = total_xp
	BattleManager.last_gold = total_gold
