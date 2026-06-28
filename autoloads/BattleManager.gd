extends Node

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, VICTORY, GAME_OVER }

const ENEMY_POOL := [
	"res://resources/units/slime.tres",
	"res://resources/units/goblin.tres",
]
const DUNGEON_POOL := [
	"res://resources/units/skeleton.tres",
	"res://resources/units/bat.tres",
]
const BOSS_PATH := "res://resources/units/dark_knight.tres"

# Spell effect types (mirrors Spell.EffectType — can't reference class_name in autoload)
const SPELL_DAMAGE := 0
const SPELL_HEAL := 1
const SPELL_HASTE := 2

var is_boss_battle: bool = false
var dungeon_mode: bool = false

signal battle_started(player_unit, enemies)
signal turn_changed(unit)
signal action_result(attacker: String, target: String, damage: int)
signal battle_ended(victory: bool)

var player_unit = null
var enemies: Array = []
var turn_queue: Array = []
var state: BattleState = BattleState.IDLE
var last_xp: int = 0
var last_gold: int = 0

func start_battle(dungeon: bool = false, boss: bool = false) -> void:
	is_boss_battle = boss
	dungeon_mode = dungeon
	if GameManager.player_unit != null:
		player_unit = GameManager.player_unit
	else:
		GameManager.new_game()
		player_unit = GameManager.player_unit
	enemies.clear()
	if is_boss_battle:
		enemies.append(load(BOSS_PATH).duplicate())
	else:
		var pool: Array = DUNGEON_POOL if dungeon_mode else ENEMY_POOL
		var enemy_res: String = pool[randi() % pool.size()]
		enemies.append(load(enemy_res).duplicate())
		if randi() % 2 == 0:
			var second: String = pool[randi() % pool.size()]
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
	turn_queue.sort_custom(func(a, b) -> bool: return a.spd > b.spd)

func _next_turn() -> void:
	turn_queue = turn_queue.filter(func(u) -> bool: return u.is_alive())
	if turn_queue.is_empty():
		_check_battle_end()
		return
	var current = turn_queue.pop_front()
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
	var alive_enemies: Array = enemies.filter(func(e) -> bool: return e.is_alive())
	if alive_enemies.is_empty():
		return
	var target = alive_enemies[randi() % alive_enemies.size()]
	var dmg: int = player_unit.calc_damage_against(target)
	target.take_damage(dmg)
	action_result.emit(player_unit.unit_name, target.unit_name, dmg)
	_after_player_turn()

const HASTE_TURNS := 2
var _haste_turns_left: int = 0

func player_cast_spell(spell) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	if player_unit.mp < spell.mp_cost:
		action_result.emit("Hero", "—", -1)
		return
	player_unit.mp -= spell.mp_cost
	match spell.effect_type:
		SPELL_DAMAGE:
			var alive_enemies: Array = enemies.filter(func(e) -> bool: return e.is_alive())
			if alive_enemies.is_empty():
				return
			var target = alive_enemies[randi() % alive_enemies.size()]
			var dmg: int = int(player_unit.atk * spell.damage_multiplier)
			target.hp = max(0, target.hp - dmg)
			action_result.emit("Hero", target.unit_name, dmg)
		SPELL_HEAL:
			var heal: int = 60
			player_unit.hp = min(player_unit.max_hp, player_unit.hp + heal)
			action_result.emit("Hero", "Hero", -heal)
		SPELL_HASTE:
			var old_spd: int = player_unit.spd
			player_unit.spd = old_spd * 2
			_haste_turns_left = HASTE_TURNS
			action_result.emit("Hero", "Hero", 0)
	_after_player_turn()

func _after_player_turn() -> void:
	_check_battle_end()
	if state != BattleState.PLAYER_TURN:
		return
	if _haste_turns_left > 0:
		_haste_turns_left -= 1
		if _haste_turns_left == 0:
			player_unit.spd = player_unit.spd / 2
	rebuild_and_next()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.IDLE
	battle_ended.emit(false)

func _enemy_act(enemy) -> void:
	var dmg: int = enemy.calc_damage_against(player_unit)
	player_unit.take_damage(dmg)
	action_result.emit(enemy.unit_name, player_unit.unit_name, dmg)
	_check_battle_end()
	if state != BattleState.ENEMY_TURN:
		return
	if is_boss_battle and enemy.unit_name == "Dark Knight":
		await get_tree().create_timer(0.6).timeout
		var dmg2: int = enemy.calc_damage_against(player_unit)
		player_unit.take_damage(dmg2)
		action_result.emit(enemy.unit_name, player_unit.unit_name, dmg2)
		_check_battle_end()
		if state != BattleState.ENEMY_TURN:
			return
	rebuild_and_next()

func rebuild_and_next() -> void:
	var all: Array = []
	all.append(player_unit)
	for e in enemies:
		all.append(e)
	turn_queue = all.filter(func(u) -> bool: return u.is_alive())
	turn_queue.sort_custom(func(a, b) -> bool: return a.spd > b.spd)
	if not turn_queue.is_empty():
		var next = turn_queue.pop_front()
		if next.is_player:
			state = BattleState.PLAYER_TURN
			turn_changed.emit(next)
		else:
			state = BattleState.ENEMY_TURN
			turn_changed.emit(next)
			await get_tree().create_timer(1.0).timeout
			_enemy_act(next)

func _check_battle_end() -> void:
	var all_enemies_dead: bool = enemies.all(func(e) -> bool: return not e.is_alive())
	if all_enemies_dead:
		state = BattleState.VICTORY
		GameManager.grant_battle_rewards()
		var mp_restore: int = int(player_unit.max_mp * 0.2)
		player_unit.mp = min(player_unit.max_mp, player_unit.mp + mp_restore)
		battle_ended.emit(true)
		return
	if not player_unit.is_alive():
		state = BattleState.GAME_OVER
		battle_ended.emit(false)
