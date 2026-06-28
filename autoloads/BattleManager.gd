extends Node

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, VICTORY, GAME_OVER }

const ENEMY_POOL := [
	"res://resources/units/slime.tres",
	"res://resources/units/goblin.tres",
]

signal battle_started(player_unit: CombatUnit, enemies: Array)
signal turn_changed(unit: CombatUnit)
signal action_result(attacker: String, target: String, damage: int)
signal battle_ended(victory: bool)

var player_unit: CombatUnit = null
var enemies: Array[CombatUnit] = []
var turn_queue: Array[CombatUnit] = []
var state: BattleState = BattleState.IDLE

func start_battle() -> void:
	player_unit = load("res://resources/units/hero.tres").duplicate()
	enemies.clear()
	var enemy_res: String = ENEMY_POOL[randi() % ENEMY_POOL.size()]
	enemies.append(load(enemy_res).duplicate())
	if randi() % 2 == 0:
		var second: String = ENEMY_POOL[randi() % ENEMY_POOL.size()]
		enemies.append(load(second).duplicate())
	_build_turn_queue()
	state = BattleState.IDLE
	battle_started.emit(player_unit, enemies)
	_next_turn()

func _build_turn_queue() -> void:
	turn_queue.clear()
	turn_queue.append(player_unit)
	for e in enemies:
		turn_queue.append(e)
	turn_queue.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool: return a.spd > b.spd)

func _next_turn() -> void:
	turn_queue = turn_queue.filter(func(u: CombatUnit) -> bool: return u.is_alive())
	if turn_queue.is_empty():
		_check_battle_end()
		return
	var current: CombatUnit = turn_queue.pop_front()
	if not current.is_alive():
		_next_turn()
		return
	if current.is_player:
		state = BattleState.PLAYER_TURN
		turn_changed.emit(current)
	else:
		state = BattleState.ENEMY_TURN
		turn_changed.emit(current)
		await get_tree().create_timer(1.0).timeout
		_enemy_act(current)

func player_attack() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var alive_enemies := enemies.filter(func(e: CombatUnit) -> bool: return e.is_alive())
	if alive_enemies.is_empty():
		return
	var target: CombatUnit = alive_enemies[randi() % alive_enemies.size()]
	var dmg := player_unit.calc_damage_against(target)
	target.take_damage(dmg)
	action_result.emit(player_unit.unit_name, target.unit_name, dmg)
	_check_battle_end()
	if state == BattleState.IDLE:
		_rebuild_and_next()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.IDLE
	battle_ended.emit(false)

func _enemy_act(enemy: CombatUnit) -> void:
	var dmg := enemy.calc_damage_against(player_unit)
	player_unit.take_damage(dmg)
	action_result.emit(enemy.unit_name, player_unit.unit_name, dmg)
	_check_battle_end()
	if state == BattleState.IDLE:
		_rebuild_and_next()

func _rebuild_and_next() -> void:
	var all: Array[CombatUnit] = []
	all.append(player_unit)
	for e in enemies:
		all.append(e)
	turn_queue = all.filter(func(u: CombatUnit) -> bool: return u.is_alive())
	turn_queue.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool: return a.spd > b.spd)
	if not turn_queue.is_empty():
		var next: CombatUnit = turn_queue.pop_front()
		if next.is_player:
			state = BattleState.PLAYER_TURN
			turn_changed.emit(next)
		else:
			state = BattleState.ENEMY_TURN
			turn_changed.emit(next)
			await get_tree().create_timer(1.0).timeout
			_enemy_act(next)

func _check_battle_end() -> void:
	var all_enemies_dead := enemies.all(func(e: CombatUnit) -> bool: return not e.is_alive())
	if all_enemies_dead:
		state = BattleState.VICTORY
		battle_ended.emit(true)
		return
	if not player_unit.is_alive():
		state = BattleState.GAME_OVER
		battle_ended.emit(false)
