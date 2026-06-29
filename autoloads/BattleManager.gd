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
const MID_POOL := [
	"res://resources/units/orc.tres",
	"res://resources/units/shadow.tres",
]
const HARD_POOL := [
	"res://resources/units/troll.tres",
	"res://resources/units/gargoyle.tres",
]
const BOSS_PATH  := "res://resources/units/dark_knight.tres"
const BOSS1_PATH := "res://resources/units/guard_scorpion.tres"
const BOSS2_PATH := "res://resources/units/jenova.tres"

const SPELL_DAMAGE := 0
const SPELL_HEAL   := 1
const SPELL_HASTE  := 2
const SPELL_REVIVE := 3

const CRIT_CHANCE  := 0.10
const CRIT_MULT    := 1.5
const HASTE_TURNS  := 2

var is_boss_battle: bool = false
var is_boss1_battle: bool = false
var is_boss2_battle: bool = false
var dungeon_mode: bool = false

signal battle_started(party, enemies)
signal turn_changed(unit)
signal action_result(attacker: String, target: String, damage: int, is_crit: bool)
signal battle_log(message: String)
signal battle_ended(victory: bool)
signal limit_gauge_updated(unit)

var party: Array = []
var player_unit = null
var enemies: Array = []
var turn_queue: Array = []
var state: BattleState = BattleState.IDLE
var last_xp: int = 0
var last_gold: int = 0

func _avg_party_level() -> int:
	if party.is_empty():
		return 1
	var total: int = 0
	for m in party:
		total += m.level
	return total / party.size()

func _pick_enemy_pool() -> Array:
	if dungeon_mode:
		return DUNGEON_POOL
	match GameManager.active_zone:
		"kalm":
			return MID_POOL
		"mt_nibel":
			return HARD_POOL
		_:
			return ENEMY_POOL

func _apply_spell_materias() -> void:
	for i in party.size():
		var member = party[i]
		if i < GameManager.base_party_spell_paths.size():
			member.spell_paths = GameManager.base_party_spell_paths[i].duplicate()
		for slot_name in ["weapon", "armor"]:
			var item = GameManager.equipment[i].get(slot_name)
			if item == null:
				continue
			var slots: int = item.materia_slots if "materia_slots" in item else 0
			for s in range(slots):
				var mkey: String = "%d_%s_%d" % [i, slot_name, s]
				var mat_path: String = GameManager.materia_equipped.get(mkey, "")
				if mat_path == "":
					continue
				var mat = load(mat_path)
				if mat == null or mat.materia_type != "spell" or mat.spell_path == "":
					continue
				if not mat.spell_path in member.spell_paths:
					member.spell_paths.append(mat.spell_path)

func start_battle(dungeon: bool = false, boss: bool = false) -> void:
	is_boss_battle = boss
	dungeon_mode = dungeon
	if GameManager.party.is_empty():
		GameManager.new_game()
	party = GameManager.party
	_apply_spell_materias()
	player_unit = null
	enemies.clear()
	if is_boss1_battle:
		enemies.append(load(BOSS1_PATH).duplicate())
	elif is_boss2_battle:
		enemies.append(load(BOSS2_PATH).duplicate())
	elif is_boss_battle:
		enemies.append(load(BOSS_PATH).duplicate())
	else:
		var pool: Array = _pick_enemy_pool()
		enemies.append(load(pool[randi() % pool.size()]).duplicate())
		if randi() % 2 == 0:
			enemies.append(load(pool[randi() % pool.size()]).duplicate())
	_build_turn_queue()
	state = BattleState.IDLE
	battle_started.emit(party, enemies)
	_advance_turn()

func _build_turn_queue() -> void:
	turn_queue.clear()
	for m in party:
		if m.is_alive():
			turn_queue.append(m)
	for e in enemies:
		turn_queue.append(e)
	turn_queue.sort_custom(func(a, b) -> bool: return a.spd > b.spd)

func _rebuild_queue() -> void:
	var all: Array = []
	for m in party:
		if m.is_alive():
			all.append(m)
	for e in enemies:
		if e.is_alive():
			all.append(e)
	turn_queue = all
	turn_queue.sort_custom(func(a, b) -> bool: return a.spd > b.spd)

# Central turn dispatcher — applies status ticks and routes to player or enemy
func _advance_turn() -> void:
	# Try to find the next acting unit (skip dead, handle status)
	while true:
		turn_queue = turn_queue.filter(func(u) -> bool: return u.is_alive())
		if turn_queue.is_empty():
			_check_battle_end()
			return
		var current = turn_queue.pop_front()
		if not current.is_alive():
			continue
		# Apply status tick and check if turn is skipped
		var skip := _tick_status(current)
		if state == BattleState.VICTORY or state == BattleState.GAME_OVER:
			return
		if skip:
			continue  # loop to next unit
		# Unit acts
		if current.is_player:
			player_unit = current
			state = BattleState.PLAYER_TURN
			turn_changed.emit(current)
			return
		else:
			state = BattleState.ENEMY_TURN
			turn_changed.emit(current)
			await get_tree().create_timer(1.0).timeout
			await _enemy_act(current)
			return

# Returns true if the unit's turn should be skipped (sleep, or died from poison)
func _tick_status(unit) -> bool:
	if unit.status == "":
		return false
	if unit.status == "sleep":
		battle_log.emit("%s is asleep!" % unit.unit_name)
		unit.status_turns -= 1
		if unit.status_turns <= 0:
			unit.clear_status()
			battle_log.emit("%s woke up!" % unit.unit_name)
		return true  # skip turn
	if unit.status == "poison":
		var dmg: int = unit.tick_status()
		if dmg > 0:
			action_result.emit("Poison", unit.unit_name, dmg, false)
		if unit.status == "":
			battle_log.emit("%s recovered from poison!" % unit.unit_name)
		_check_battle_end()
		return not unit.is_alive()  # skip if died
	if unit.status == "silence":
		battle_log.emit("%s is silenced!" % unit.unit_name)
		unit.status_turns -= 1
		if unit.status_turns <= 0:
			unit.clear_status()
		return false  # silence only blocks spells, not physical
	return false

func _fill_limit_gauge(unit, amount: int) -> void:
	if not unit.is_player:
		return
	unit.limit_gauge = min(100, unit.limit_gauge + amount)
	limit_gauge_updated.emit(unit)

func _compute_phys_damage(atk: int, target) -> Dictionary:
	var variance: float = randf_range(0.85, 1.15)
	var is_crit: bool = randf() < CRIT_CHANCE
	var raw: int = int(atk * variance * (CRIT_MULT if is_crit else 1.0))
	var dmg: int = target.take_damage(raw)
	_fill_limit_gauge(target, 20)
	return {dmg = dmg, crit = is_crit}

func player_limit_break() -> void:
	if state != BattleState.PLAYER_TURN or player_unit == null:
		return
	if player_unit.limit_gauge < 100:
		return
	player_unit.limit_gauge = 0
	limit_gauge_updated.emit(player_unit)
	match player_unit.character_class:
		"Warrior":
			battle_log.emit("⚡ BLADE FURY!")
			var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
			for e in alive:
				var dmg: int = int(player_unit.atk * 2.5 * randf_range(0.90, 1.10))
				e.take_damage_ignore_def(dmg)
				action_result.emit(player_unit.unit_name, e.unit_name, dmg, true)
		"Black Mage":
			battle_log.emit("⚡ METEOR!")
			var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
			for e in alive:
				var dmg: int = int(player_unit.atk * 3.0 * randf_range(0.90, 1.10))
				e.hp = max(0, e.hp - dmg)
				action_result.emit(player_unit.unit_name, e.unit_name, dmg, true)
		"White Mage":
			battle_log.emit("⚡ HOLY LIGHT!")
			for m in party:
				if m.is_alive():
					m.hp = m.max_hp
					action_result.emit(player_unit.unit_name, m.unit_name, -m.max_hp, false)
				else:
					m.hp = int(m.max_hp * 0.5)
					m.clear_status()
					battle_log.emit("%s revived!" % m.unit_name)
					action_result.emit(player_unit.unit_name, m.unit_name, 0, false)
		_:
			battle_log.emit("⚡ LIMIT BREAK!")
			var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
			for e in alive:
				var dmg: int = int(player_unit.atk * 2.0 * randf_range(0.90, 1.10))
				e.take_damage_ignore_def(dmg)
				action_result.emit(player_unit.unit_name, e.unit_name, dmg, true)
	_after_player_turn()

func player_attack(target = null) -> void:
	if state != BattleState.PLAYER_TURN or player_unit == null:
		return
	if target == null or not target.is_alive():
		var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
		if alive.is_empty():
			return
		target = alive[randi() % alive.size()]
	var result: Dictionary = _compute_phys_damage(player_unit.atk, target)
	action_result.emit(player_unit.unit_name, target.unit_name, result.dmg, result.crit)
	_after_player_turn()

func _check_phase_transition(enemy) -> void:
	if enemy == null or not enemy.is_alive():
		return
	var hp_pct: float = float(enemy.hp) / float(enemy.max_hp)
	match enemy.unit_name:
		"Guard Scorpion":
			if enemy.current_phase == 0 and hp_pct <= 0.5:
				enemy.current_phase = 1
				enemy.atk = int(enemy.atk * 2.0)
				enemy.spell_immune = true
				battle_log.emit("Guard Scorpion raises its tail! Phase 2 — LASER MODE! Spells blocked!")
		"Jenova":
			if enemy.current_phase == 0 and hp_pct <= 0.3:
				enemy.current_phase = 1
				battle_log.emit("Jenova mutates! Phase 2 — life drain mode!")

func player_cast_spell(spell, target = null) -> void:
	if state != BattleState.PLAYER_TURN or player_unit == null:
		return
	if player_unit.status == "silence":
		battle_log.emit("%s is silenced — can't cast!" % player_unit.unit_name)
		return
	if target != null and target.spell_immune:
		battle_log.emit("%s is immune to magic!" % target.unit_name)
		return
	if player_unit.mp < spell.mp_cost:
		action_result.emit(player_unit.unit_name, "—", -1, false)
		return
	player_unit.mp -= spell.mp_cost
	match spell.effect_type:
		SPELL_DAMAGE:
			if target == null or not target.is_alive():
				var alive: Array = enemies.filter(func(e) -> bool: return e.is_alive())
				if alive.is_empty():
					_after_player_turn()
					return
				target = alive[randi() % alive.size()]
			var variance: float = randf_range(0.90, 1.10)
			var dmg: int = int(player_unit.atk * spell.damage_multiplier * variance)
			if spell.element != "" and target.element_weakness == spell.element:
				dmg = int(dmg * 1.5)
				battle_log.emit("Weakness! %s takes extra damage!" % target.unit_name)
			target.hp = max(0, target.hp - dmg)
			action_result.emit(player_unit.unit_name, target.unit_name, dmg, false)
		SPELL_HEAL:
			var tgt = target if (target != null and target.is_alive()) else _weakest_alive_ally()
			if tgt == null:
				_after_player_turn()
				return
			tgt.hp = min(tgt.max_hp, tgt.hp + spell.heal_value)
			action_result.emit(player_unit.unit_name, tgt.unit_name, -spell.heal_value, false)
		SPELL_HASTE:
			var tgt = target if target != null else player_unit
			if not tgt.is_alive():
				tgt = player_unit
			tgt.base_spd = tgt.spd
			tgt.spd = tgt.spd * 2
			tgt.haste_turns_left = HASTE_TURNS
			action_result.emit(player_unit.unit_name, tgt.unit_name, 0, false)
		SPELL_REVIVE:
			var dead = target if (target != null and not target.is_alive()) else _first_dead_ally()
			if dead == null:
				player_unit.mp += spell.mp_cost
				action_result.emit(player_unit.unit_name, "—", -1, false)
				return
			dead.hp = int(dead.max_hp * 0.25)
			dead.clear_status()
			battle_log.emit("%s revived!" % dead.unit_name)
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
	_rebuild_queue()
	_advance_turn()

func player_run() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.IDLE
	battle_ended.emit(false)

# ── Enemy AI ────────────────────────────────────────────────────────────────

func _enemy_act(enemy) -> void:
	match enemy.unit_name:
		"Slime":          _ai_slime(enemy)
		"Goblin":         await _ai_goblin(enemy)
		"Skeleton":       _ai_skeleton(enemy)
		"Bat":            _ai_bat(enemy)
		"Orc":            _ai_orc(enemy)
		"Shadow":         await _ai_shadow(enemy)
		"Troll":          await _ai_troll(enemy)
		"Gargoyle":       _ai_gargoyle(enemy)
		"Dark Knight":    await _ai_dark_knight(enemy)
		"Guard Scorpion": await _ai_guard_scorpion(enemy)
		"Jenova":         await _ai_jenova(enemy)
		_:                _ai_basic_attack(enemy)
	_check_battle_end()
	if state != BattleState.ENEMY_TURN:
		return
	_rebuild_queue()
	_advance_turn()

func _random_alive_ally():
	var alive: Array = party.filter(func(m) -> bool: return m.is_alive())
	if alive.is_empty():
		return null
	return alive[randi() % alive.size()]

func _ai_basic_attack(enemy) -> void:
	var target = _random_alive_ally()
	if target == null:
		return
	var result: Dictionary = _compute_phys_damage(enemy.atk, target)
	action_result.emit(enemy.unit_name, target.unit_name, result.dmg, result.crit)

func _ai_slime(enemy) -> void:
	if randf() < 0.40:
		var target = _random_alive_ally()
		if target == null:
			return
		if target.inflict_status("poison"):
			battle_log.emit("Poison Spit! %s is poisoned!" % target.unit_name)
			action_result.emit(enemy.unit_name, target.unit_name, 0, false)
			return
	_ai_basic_attack(enemy)

func _ai_goblin(enemy) -> void:
	if randf() < 0.35:
		var target = _random_alive_ally()
		if target == null:
			return
		var raw: int = int(enemy.atk * 1.5 * randf_range(0.85, 1.15))
		var dmg: int = target.take_damage(raw)
		_fill_limit_gauge(target, 20)
		battle_log.emit("Headbutt!")
		action_result.emit(enemy.unit_name, target.unit_name, dmg, false)
		if randf() < 0.30 and target.is_alive():
			if target.inflict_status("sleep"):
				battle_log.emit("%s fell asleep!" % target.unit_name)
	else:
		_ai_basic_attack(enemy)

func _ai_skeleton(enemy) -> void:
	if randf() < 0.40:
		var target = _random_alive_ally()
		if target == null:
			return
		var dmg: int = int(enemy.atk * 1.2 * randf_range(0.90, 1.10))
		target.take_damage_ignore_def(dmg)
		_fill_limit_gauge(target, 20)
		battle_log.emit("Dark Blast!")
		action_result.emit(enemy.unit_name, target.unit_name, dmg, false)
	else:
		_ai_basic_attack(enemy)

func _ai_bat(enemy) -> void:
	if randf() < 0.40:
		var mage = _find_alive_mage()
		var target = mage if mage != null else _random_alive_ally()
		if target == null:
			return
		if target.inflict_status("silence"):
			battle_log.emit("Ultrasonic! %s is silenced!" % target.unit_name)
			action_result.emit(enemy.unit_name, target.unit_name, 0, false)
			return
	_ai_basic_attack(enemy)

func _find_alive_mage():
	for m in party:
		if m.is_alive() and m.spell_paths.size() > 0 and m.status != "silence":
			return m
	return null

func _ai_orc(enemy) -> void:
	if randf() < 0.30:
		# War Cry: ATK buff for 1 turn
		enemy.atk = int(enemy.atk * 1.3)
		battle_log.emit("War Cry! %s rages!" % enemy.unit_name)
		action_result.emit(enemy.unit_name, enemy.unit_name, 0, false)
	else:
		_ai_basic_attack(enemy)

func _ai_shadow(enemy) -> void:
	if randf() < 0.40:
		# Soul Drain: attack + drain MP from a mage
		var mage = _find_alive_mage()
		var target = mage if mage != null else _random_alive_ally()
		if target == null:
			return
		battle_log.emit("Soul Drain!")
		var dmg: int = int(enemy.atk * 0.7 * randf_range(0.85, 1.15))
		var actual: int = target.take_damage(dmg)
		_fill_limit_gauge(target, 20)
		action_result.emit(enemy.unit_name, target.unit_name, actual, false)
		if target.max_mp > 0 and target.is_alive():
			var mp_drain: int = min(target.mp, 15)
			target.mp -= mp_drain
			battle_log.emit("%s lost %d MP!" % [target.unit_name, mp_drain])
	else:
		_ai_basic_attack(enemy)

func _ai_troll(enemy) -> void:
	if randf() < 0.25:
		# Regenerate: heal 10% max HP
		var regen: int = int(enemy.max_hp * 0.10)
		enemy.hp = min(enemy.max_hp, enemy.hp + regen)
		battle_log.emit("Troll regenerates!")
		action_result.emit(enemy.unit_name, enemy.unit_name, -regen, false)
		await get_tree().create_timer(0.4).timeout
	_ai_basic_attack(enemy)

func _ai_gargoyle(enemy) -> void:
	if randf() < 0.35:
		# Stone Gaze: 40% petrify chance — simplified as sleep for 2 turns
		var target = _random_alive_ally()
		if target == null:
			return
		battle_log.emit("Stone Gaze!")
		if target.inflict_status("sleep"):
			target.status_turns = 2
			battle_log.emit("%s is petrified!" % target.unit_name)
			action_result.emit(enemy.unit_name, target.unit_name, 0, false)
			return
	_ai_basic_attack(enemy)

func _ai_dark_knight(enemy) -> void:
	if randf() < 0.35:
		battle_log.emit("Dark Wave!")
		var alive: Array = party.filter(func(m) -> bool: return m.is_alive())
		for target in alive:
			var dmg: int = int(enemy.atk * 0.60 * randf_range(0.85, 1.15))
			var actual: int = target.take_damage(dmg)
			_fill_limit_gauge(target, 20)
			action_result.emit(enemy.unit_name, target.unit_name, actual, false)
			await get_tree().create_timer(0.25).timeout
	else:
		# Double physical attack
		_ai_basic_attack(enemy)
		_check_battle_end()
		if state != BattleState.ENEMY_TURN:
			return
		await get_tree().create_timer(0.6).timeout
		_ai_basic_attack(enemy)

func _ai_guard_scorpion(enemy) -> void:
	if enemy.current_phase == 0:
		_ai_basic_attack(enemy)
	else:
		# Phase 2: Tail Laser — hits all party members
		battle_log.emit("Tail Laser!")
		var alive: Array = party.filter(func(m) -> bool: return m.is_alive())
		for target in alive:
			var dmg: int = int(enemy.atk * 0.7 * randf_range(0.85, 1.15))
			var actual: int = target.take_damage(dmg)
			_fill_limit_gauge(target, 20)
			action_result.emit(enemy.unit_name, target.unit_name, actual, false)
			await get_tree().create_timer(0.2).timeout
	_check_phase_transition(enemy)

func _ai_jenova(enemy) -> void:
	if enemy.current_phase == 0:
		# Phase 1: Calamity — multi-target magic
		battle_log.emit("Calamity from the Skies!")
		var alive: Array = party.filter(func(m) -> bool: return m.is_alive())
		for target in alive:
			var dmg: int = int(enemy.atk * 0.65 * randf_range(0.85, 1.15))
			var actual: int = target.take_damage(dmg)
			_fill_limit_gauge(target, 20)
			action_result.emit(enemy.unit_name, target.unit_name, actual, false)
			await get_tree().create_timer(0.2).timeout
	else:
		# Phase 2: Life Drain — heals self from a random ally
		var target = _random_alive_ally()
		if target == null:
			_ai_basic_attack(enemy)
			return
		battle_log.emit("Jenova drains life!")
		var drain: int = int(target.max_hp * 0.3)
		var actual: int = target.take_damage_ignore_def(drain)
		_fill_limit_gauge(target, 20)
		action_result.emit(enemy.unit_name, target.unit_name, actual, false)
		enemy.hp = min(enemy.max_hp, enemy.hp + actual)
	_check_phase_transition(enemy)

# Called by Battle.gd after item use
func rebuild_and_next() -> void:
	_rebuild_queue()
	_advance_turn()

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
