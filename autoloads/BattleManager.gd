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

const SPELL_DAMAGE := 0
const SPELL_HEAL   := 1
const SPELL_HASTE  := 2
const SPELL_REVIVE := 3

const CRIT_CHANCE  := 0.10
const CRIT_MULT    := 1.5
const HASTE_TURNS  := 2

var is_boss_battle: bool = false
var dungeon_mode: bool = false

signal battle_started(party, enemies)
signal turn_changed(unit)
signal action_result(attacker: String, target: String, damage: int, is_crit: bool)
signal battle_ended(victory: bool)

var party: Array = []
var player_unit = null    # current active party member this turn
var enemies: Array = []
var turn_queue: Array = []
var state: BattleState = BattleState.IDLE
var last_xp: int = 0
var last_gold: int = 0

func start_battle(dungeon: bool = false, boss: bool = false) -> void:
	is_boss_battle = boss
	dungeon_mode = dungeon
	if GameManager.party.is_empty():
		GameManager.new_game()
	party = GameManager.party
	player_unit = null
	enemies.clear()
	if is_boss_battle:
		enemies.append(load(BOSS_PATH).duplicate())
	else:
		var pool: Array = DUNGEON_POOL if dungeon_mode else ENEMY_POOL
		enemies.append(load(pool[randi() % pool.size()]).duplicate())
		if randi() % 2 == 0:
			enemies.append(load(pool[randi() % pool.size()]).duplicate())
	_build_turn_queue()
	state = BattleState.IDLE
	battle_started.emit(party, enemies)
	_next_turn()

func _build_turn_queue() -> void:
	turn_queue.clear()
	for m in party:
		if m.is_alive():
			turn_queue.append(m)
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
		player_unit = current
		state = BattleState.PLAYER_TURN
		turn_changed.emit(current)
	else:
		state = BattleState.ENEMY_TURN
		turn_changed.emit(current)
		await get_tree().create_timer(1.0).timeout
		_enemy_act(current)

func _compute_phys_damage(atk: int, target) -> Dictionary:
	var variance: float = randf_range(0.85, 1.15)
	var is_crit: bool = randf() < CRIT_CHANCE
	var raw: int = int(atk * variance * (CRIT_MULT if is_crit else 1.0))
	var dmg: int = target.take_damage(raw)
	return {dmg = dmg, crit = is_crit}

func player_attack() -> void:
	if state != BattleState.PLAYER_TURN or player_unit == null:
		return
	var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
	if alive.is_empty():
		return
	var target = alive[randi() % alive.size()]
	var result: Dictionary = _compute_phys_damage(player_unit.atk, target)
	action_result.emit(player_unit.unit_name, target.unit_name, result.dmg, result.crit)
	_after_player_turn()

func player_cast_spell(spell) -> void:
	if state != BattleState.PLAYER_TURN or player_unit == null:
		return
	if player_unit.mp < spell.mp_cost:
		action_result.emit(player_unit.unit_name, "—", -1, false)
		return
	player_unit.mp -= spell.mp_cost
	match spell.effect_type:
		SPELL_DAMAGE:
			var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
			if alive.is_empty():
				_after_player_turn()
				return
			var target = alive[randi() % alive.size()]
			var variance: float = randf_range(0.90, 1.10)
			var dmg: int = int(player_unit.atk * spell.damage_multiplier * variance)
			# Element weakness: 1.5x bonus
			if spell.element != "" and target.element_weakness == spell.element:
				dmg = int(dmg * 1.5)
			target.hp = max(0, target.hp - dmg)
			action_result.emit(player_unit.unit_name, target.unit_name, dmg, false)
		SPELL_HEAL:
			var tgt = _weakest_alive_ally()
			if tgt == null:
				_after_player_turn()
				return
			var healed: int = spell.heal_value
			tgt.hp = min(tgt.max_hp, tgt.hp + healed)
			action_result.emit(player_unit.unit_name, tgt.unit_name, -healed, false)
		SPELL_HASTE:
			player_unit.base_spd = player_unit.spd
			player_unit.spd = player_unit.spd * 2
			player_unit.haste_turns_left = HASTE_TURNS
			action_result.emit(player_unit.unit_name, player_unit.unit_name, 0, false)
		SPELL_REVIVE:
			var dead = _first_dead_ally()
			if dead == null:
				player_unit.mp += spell.mp_cost  # refund
				action_result.emit(player_unit.unit_name, "—", -1, false)
				return
			dead.hp = int(dead.max_hp * 0.25)
			action_result.emit(player_unit.unit_name, dead.unit_name, 0, false)
	_after_player_turn()

func _weakest_alive_ally():
	var best = null
	var best_ratio: float = 2.0
	for m in party:
		if m.is_alive():
			var r: float = float(m.hp) / float(m.max_hp)
			if r < best_ratio:
				best_ratio = r
				best = m
	return best

func _first_dead_ally():
	for m in party:
		if not m.is_alive():
			return m
	return null

func _after_player_turn() -> void:
	_check_battle_end()
	if state != BattleState.PLAYER_TURN:
		return
	if player_unit != null and player_unit.haste_turns_left > 0:
		player_unit.haste_turns_left -= 1
		if player_unit.haste_turns_left == 0 and player_unit.base_spd > 0:
			player_unit.spd = player_unit.base_spd
			player_unit.base_spd = 0
	rebuild_and_next()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.IDLE
	battle_ended.emit(false)

func _enemy_act(enemy) -> void:
	# Target a random alive party member
	var alive_allies: Array = party.filter(func(m) -> bool: return m.is_alive())
	if alive_allies.is_empty():
		_check_battle_end()
		return
	var target = alive_allies[randi() % alive_allies.size()]
	var result: Dictionary = _compute_phys_damage(enemy.atk, target)
	action_result.emit(enemy.unit_name, target.unit_name, result.dmg, result.crit)
	_check_battle_end()
	if state != BattleState.ENEMY_TURN:
		return
	# Boss double attack
	if is_boss_battle and enemy.unit_name == "Dark Knight":
		await get_tree().create_timer(0.6).timeout
		alive_allies = party.filter(func(m) -> bool: return m.is_alive())
		if not alive_allies.is_empty():
			var target2 = alive_allies[randi() % alive_allies.size()]
			var result2: Dictionary = _compute_phys_damage(enemy.atk, target2)
			action_result.emit(enemy.unit_name, target2.unit_name, result2.dmg, result2.crit)
			_check_battle_end()
			if state != BattleState.ENEMY_TURN:
				return
	rebuild_and_next()

func rebuild_and_next() -> void:
	var all: Array = []
	for m in party:
		if m.is_alive():
			all.append(m)
	for e in enemies:
		if e.is_alive():
			all.append(e)
	turn_queue = all
	turn_queue.sort_custom(func(a, b) -> bool: return a.spd > b.spd)
	if turn_queue.is_empty():
		_check_battle_end()
		return
	var next = turn_queue.pop_front()
	if next.is_player:
		player_unit = next
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
		battle_ended.emit(true)
		return
	var all_party_dead: bool = party.all(func(m) -> bool: return not m.is_alive())
	if all_party_dead:
		state = BattleState.GAME_OVER
		battle_ended.emit(false)
