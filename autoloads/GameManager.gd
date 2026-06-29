extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var party: Array = []          # 3 CombatUnit: [Warrior, BlackMage, WhiteMage]
var player_unit = null         # alias for party[0] (Warrior) — kept for compatibility
var gold: int = 0
var inventory: Dictionary = {}
var equip_inventory: Dictionary = {}   # resource_path → count (unequipped gear owned)
var equipment: Array = [               # one dict per party member
	{"weapon": null, "armor": null},
	{"weapon": null, "armor": null},
	{"weapon": null, "armor": null},
]
var materia_inventory: Dictionary = {} # resource_path → count
var materia_equipped: Dictionary = {}  # "member_weapon_0" → resource_path
var base_party_spell_paths: Array = [[], [], []]
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
	equip_inventory = {}
	equipment = [
		{"weapon": null, "armor": null},
		{"weapon": null, "armor": null},
		{"weapon": null, "armor": null},
	]
	materia_inventory = {}
	materia_equipped = {}
	base_party_spell_paths = []
	for m in party:
		base_party_spell_paths.append(m.spell_paths.duplicate())
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

func buy_equipment(item: Resource) -> bool:
	if gold < item.price:
		return false
	gold -= item.price
	gold_changed.emit(gold)
	var key: String = item.resource_path
	equip_inventory[key] = equip_inventory.get(key, 0) + 1
	return true

func equip(member_idx: int, item: Resource) -> bool:
	if member_idx < 0 or member_idx >= party.size():
		return false
	var member = party[member_idx]
	var slot_name: String = "weapon" if item.slot == 0 else "armor"
	if item.allowed_classes.size() > 0 and not item.allowed_classes.has(member.character_class):
		return false
	var key: String = item.resource_path
	if equip_inventory.get(key, 0) <= 0:
		return false
	equip_inventory[key] -= 1
	if equip_inventory[key] <= 0:
		equip_inventory.erase(key)
	var old_item = equipment[member_idx].get(slot_name)
	if old_item != null:
		_remove_equip_bonus(member, old_item)
		var old_key: String = old_item.resource_path
		equip_inventory[old_key] = equip_inventory.get(old_key, 0) + 1
	equipment[member_idx][slot_name] = item
	_apply_equip_bonus(member, item)
	return true

func unequip_slot(member_idx: int, slot_name: String) -> void:
	if member_idx < 0 or member_idx >= party.size():
		return
	var old_item = equipment[member_idx].get(slot_name)
	if old_item == null:
		return
	_remove_equip_bonus(party[member_idx], old_item)
	var key: String = old_item.resource_path
	equip_inventory[key] = equip_inventory.get(key, 0) + 1
	equipment[member_idx][slot_name] = null

func _apply_equip_bonus(member, item: Resource) -> void:
	if item.slot == 0:
		member.atk += item.stat_bonus
	else:
		member.def += item.stat_bonus

func _remove_equip_bonus(member, item: Resource) -> void:
	if item.slot == 0:
		member.atk -= item.stat_bonus
	else:
		member.def -= item.stat_bonus

func buy_materia(mat: Resource) -> bool:
	if gold < mat.price:
		return false
	gold -= mat.price
	gold_changed.emit(gold)
	var key: String = mat.resource_path
	materia_inventory[key] = materia_inventory.get(key, 0) + 1
	return true

func equip_materia(member_idx: int, slot_name: String, slot_idx: int, mat_path: String) -> bool:
	if member_idx < 0 or member_idx >= party.size():
		return false
	if materia_inventory.get(mat_path, 0) <= 0:
		return false
	var key: String = "%d_%s_%d" % [member_idx, slot_name, slot_idx]
	var old_path: String = materia_equipped.get(key, "")
	if old_path != "":
		unequip_materia(member_idx, slot_name, slot_idx)
	materia_inventory[mat_path] -= 1
	if materia_inventory[mat_path] <= 0:
		materia_inventory.erase(mat_path)
	materia_equipped[key] = mat_path
	var mat = load(mat_path)
	if mat != null and mat.materia_type == "passive":
		var member = party[member_idx]
		if mat.passive_stat == "hp":
			var bonus: int = int(member.max_hp * mat.passive_pct)
			member.max_hp += bonus
			member.hp = min(member.hp + bonus, member.max_hp)
		elif mat.passive_stat == "mp":
			var bonus: int = int(member.max_mp * mat.passive_pct)
			member.max_mp += bonus
			member.mp = min(member.mp + bonus, member.max_mp)
	return true

func unequip_materia(member_idx: int, slot_name: String, slot_idx: int) -> void:
	var key: String = "%d_%s_%d" % [member_idx, slot_name, slot_idx]
	var mat_path: String = materia_equipped.get(key, "")
	if mat_path == "":
		return
	materia_equipped.erase(key)
	materia_inventory[mat_path] = materia_inventory.get(mat_path, 0) + 1
	var mat = load(mat_path)
	if mat != null and mat.materia_type == "passive":
		var member = party[member_idx]
		if mat.passive_stat == "hp":
			var bonus: int = int(member.max_hp * mat.passive_pct / (1.0 + mat.passive_pct))
			member.max_hp = max(1, member.max_hp - bonus)
			member.hp = min(member.hp, member.max_hp)
		elif mat.passive_stat == "mp":
			var bonus: int = int(member.max_mp * mat.passive_pct / (1.0 + mat.passive_pct))
			member.max_mp = max(0, member.max_mp - bonus)
			member.mp = min(member.mp, member.max_mp)

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
