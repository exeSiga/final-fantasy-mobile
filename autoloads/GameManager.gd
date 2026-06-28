extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var player_unit: CombatUnit = null
var gold: int = 0

signal gold_changed(new_amount: int)
signal level_up(new_level: int)

func _ready() -> void:
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func _on_root_child_entered(node: Node) -> void:
	current_scene = node

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func set_state(new_state: GameState) -> void:
	current_state = new_state

func new_game() -> void:
	player_unit = load("res://resources/units/hero.tres").duplicate()
	gold = 0

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func grant_battle_rewards() -> void:
	if player_unit == null:
		return
	var total_xp := 0
	var total_gold := 0
	for e in BattleManager.enemies:
		total_xp += e.xp_reward
		total_gold += e.gold_reward
	add_gold(total_gold)
	var leveled_up := player_unit.add_xp(total_xp)
	if leveled_up:
		level_up.emit(player_unit.level)
	BattleManager.last_xp = total_xp
	BattleManager.last_gold = total_gold
