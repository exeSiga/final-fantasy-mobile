extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

const CRAFT_RECIPES: Array = [
	{
		"name": "Buster Sword+",
		"ingredients": {"res://resources/items/scrap_metal.tres": 2},
		"result": "res://resources/equipment/buster_sword_plus.tres",
		"result_type": "equip",
	},
	{
		"name": "Mako Bracelet",
		"ingredients": {"res://resources/items/mako_crystal.tres": 2},
		"result": "res://resources/equipment/mako_bracelet.tres",
		"result_type": "equip",
	},
	{
		"name": "Ether",
		"ingredients": {
			"res://resources/items/monster_fang.tres": 1,
			"res://resources/items/magic_ore.tres": 1,
		},
		"result": "res://resources/items/ether.tres",
		"result_type": "item",
	},
]

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var party: Array = []              # 3 active CombatUnit
var available_members: Array = []  # 5 CombatUnit: [Cloud, Tifa, Aerith, Barret, Red XIII]
var active_party_indices: Array = [0, 1, 2]  # which 3 of 4 are active
var player_unit = null             # alias for party[0] — kept for compatibility
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
var learned_enemy_skills: Array = []   # Array of spell resource_paths learned via Enemy Skill Materia
var summon_charges: Dictionary = {}    # materia_path → charges_left (reset each battle)
var base_party_spell_paths: Array = [[], [], []]
var return_after_battle: String = "res://scenes/world/WorldMap.tscn"
var dungeon_boss_cleared = false
var dungeon_return_room: int = -1
var active_zone: String = "midgar"
var story_intro_done: bool = false
var scene_reactor_done: bool = false
var scene_jenova_done: bool = false
var sephiroth_defeated: bool = false
var total_kills: int = 0
var shinra_files_seen: Array = []

const SHINRA_FILES: Array = [
	{
		"id": "first_slime",
		"title": "Fichier ShinRa #001 — Créature Mako",
		"lore": "Les Slimes sont des résidus de Mako qui mutent dans les conduits des réacteurs abandonnés.",
	},
	{
		"id": "guard_scorpion",
		"title": "Fichier ShinRa #002 — Unité Guard Scorpion",
		"lore": "Le Guard Scorpion est un proto-arme ShinRa déployé dans les réacteurs Mako prioritaires.",
	},
	{
		"id": "rank_2nd",
		"title": "Fichier ShinRa #003 — Rang SOLDIER 2nd Class",
		"lore": "Un SOLDIER de 2nd Class a prouvé sa valeur au combat. ShinRa note ces agents pour promotion.",
	},
	{
		"id": "jenova",
		"title": "Fichier ShinRa #004 — Projet Jenova [CLASSIFIÉ]",
		"lore": "Le projet J. implique un être extraterrestre découvert sous Nibelheim. Dossier top secret — accès refusé.",
	},
	{
		"id": "kills_25",
		"title": "Fichier ShinRa #005 — Rapport d'engagements",
		"lore": "25 ennemis neutralisés. Ce soldat est opérationnel. Recommandation : promotion à l'étude.",
	},
	{
		"id": "sephiroth",
		"title": "Fichier ShinRa #006 — Incident Sephiroth [ULTRA-CLASSIFIÉ]",
		"lore": "Sephiroth... ce nom ne doit plus jamais être prononcé dans les rangs de ShinRa. Dossier scellé.",
	},
]
var pending_rank_notification: String = ""
var merchant_discount: float = 1.0

signal gold_changed(new_amount: int)
signal level_up(new_level: int)
signal rank_changed(new_rank: String)

func _ready() -> void:
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func _on_root_child_entered(node: Node) -> void:
	current_scene = node

func change_scene(path: String) -> void:
	TransitionManager.fade_to(path)

func set_state(new_state: GameState) -> void:
	current_state = new_state

func rebuild_party_from_indices() -> void:
	party.clear()
	for idx in active_party_indices:
		if idx < available_members.size():
			party.append(available_members[idx])
	player_unit = party[0] if not party.is_empty() else null
	base_party_spell_paths = []
	for m in party:
		base_party_spell_paths.append(m.spell_paths.duplicate())

func set_active_party_indices(indices: Array) -> void:
	if indices.size() != 3:
		return
	var seen: Dictionary = {}
	for idx in indices:
		if idx < 0 or idx >= available_members.size() or seen.has(idx):
			return
		seen[idx] = true
	active_party_indices = indices.duplicate()
	rebuild_party_from_indices()

func new_game() -> void:
	available_members.clear()
	party.clear()
	var warrior = load("res://resources/units/hero.tres").duplicate()
	var black_mage = load("res://resources/units/black_mage.tres").duplicate()
	var white_mage = load("res://resources/units/white_mage.tres").duplicate()
	var barret = load("res://resources/units/barret.tres").duplicate()
	var red_xiii = load("res://resources/units/red_xiii.tres").duplicate()
	available_members = [warrior, black_mage, white_mage, barret, red_xiii]
	active_party_indices = [0, 1, 2]
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
	learned_enemy_skills = []
	summon_charges = {}
	base_party_spell_paths = []
	active_zone = "midgar"
	story_intro_done = false
	scene_reactor_done = false
	scene_jenova_done = false
	sephiroth_defeated = false
	shinra_files_seen = []
	total_kills = 0
	pending_rank_notification = ""
	for m in party:
		base_party_spell_paths.append(m.spell_paths.duplicate())
	dungeon_boss_cleared = false
	dungeon_return_room = -1

func alive_party() -> Array:
	return party.filter(func(m) -> bool: return m.is_alive())

func check_shinra_files() -> void:
	for entry in SHINRA_FILES:
		if entry.id in shinra_files_seen:
			continue
		if _check_shinra_condition(entry.id):
			shinra_files_seen.append(entry.id)
			_show_shinra_popup(entry.title, entry.lore)

func _check_shinra_condition(file_id: String) -> bool:
	match file_id:
		"first_slime":    return QuestManager.kill_counts.get("Slime", 0) >= 1
		"guard_scorpion": return scene_reactor_done
		"rank_2nd":       return total_kills >= 50
		"jenova":         return scene_jenova_done
		"kills_25":       return total_kills >= 25
		"sephiroth":      return sephiroth_defeated
	return false

func _show_shinra_popup(title: String, lore: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 88
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -220.0
	panel.offset_bottom = -10.0
	panel.offset_left = 10.0
	panel.offset_right = -10.0
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var header := Label.new()
	header.text = "📁 " + title
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lore_lbl := Label.new()
	lore_lbl.text = lore
	lore_lbl.add_theme_font_size_override("font_size", 20)
	lore_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1))
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	vbox.add_child(lore_lbl)
	panel.add_child(vbox)
	canvas.add_child(panel)
	panel.gui_input.connect(func(ev): if ev is InputEventScreenTouch and ev.pressed: canvas.queue_free())
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

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
	var cost: int = get_discounted_price(item.price)
	if gold < cost:
		return false
	gold -= cost
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

func reset_summon_charges() -> void:
	for key in materia_equipped:
		var mat_path: String = materia_equipped[key]
		var mat = load(mat_path)
		if mat != null and mat.materia_type == "summon":
			summon_charges[mat_path] = 1

func buy_materia(mat: Resource) -> bool:
	var cost: int = get_discounted_price(mat.price)
	if gold < cost:
		return false
	gold -= cost
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

func has_enemy_skill_materia(member_idx: int) -> bool:
	if member_idx < 0 or member_idx >= equipment.size():
		return false
	for slot_name in ["weapon", "armor"]:
		var item = equipment[member_idx].get(slot_name)
		if item == null:
			continue
		var slots: int = item.materia_slots if "materia_slots" in item else 0
		for s in range(slots):
			var mkey: String = "%d_%s_%d" % [member_idx, slot_name, s]
			var mat_path: String = materia_equipped.get(mkey, "")
			if mat_path == "":
				continue
			var mat = load(mat_path)
			if mat != null and mat.materia_type == "enemy_skill":
				return true
	return false

func learn_enemy_skill(spell_path: String) -> bool:
	if spell_path in learned_enemy_skills:
		return false
	learned_enemy_skills.append(spell_path)
	return true

func craft(recipe_idx: int) -> bool:
	if recipe_idx < 0 or recipe_idx >= CRAFT_RECIPES.size():
		return false
	var recipe: Dictionary = CRAFT_RECIPES[recipe_idx]
	for ing_path in recipe.ingredients:
		var needed: int = recipe.ingredients[ing_path]
		if inventory.get(ing_path, 0) < needed:
			return false
	for ing_path in recipe.ingredients:
		inventory[ing_path] = inventory.get(ing_path, 0) - recipe.ingredients[ing_path]
		if inventory[ing_path] <= 0:
			inventory.erase(ing_path)
	var result_path: String = recipe.result
	if recipe.result_type == "equip":
		equip_inventory[result_path] = equip_inventory.get(result_path, 0) + 1
	else:
		var item = load(result_path)
		if item != null:
			add_item(item)
	return true

func get_discounted_price(price: int) -> int:
	return int(price * merchant_discount)

func get_soldier_rank() -> String:
	if total_kills >= 150:
		return "1st Class"
	if total_kills >= 50:
		return "2nd Class"
	return "3rd Class"

func get_rank_xp_mult() -> float:
	if total_kills >= 50:
		return 1.10
	return 1.0

func get_rank_atk_mult() -> float:
	if total_kills >= 150:
		return 1.15
	return 1.0

func buy_item(item: Resource) -> bool:
	var cost: int = get_discounted_price(item.price)
	if gold < cost:
		return false
	var key: String = item.resource_path
	if inventory.get(key, 0) >= item.max_stack:
		return false
	gold -= cost
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
	var is_named_boss: bool = BattleManager.is_boss1_battle or BattleManager.is_boss2_battle
	if is_named_boss:
		total_xp *= 3
		total_gold += 500
	add_gold(total_gold)
	var xp_mult: float = get_rank_xp_mult()
	var xp_with_bonus: int = int(total_xp * xp_mult)
	var any_levelup := false
	for m in alive_party():
		if m.add_xp(xp_with_bonus):
			any_levelup = true
	if any_levelup:
		AudioManager.play_sfx_levelup()
		var max_level: int = 0
		for m in party:
			if m.level > max_level:
				max_level = m.level
		level_up.emit(max_level)
	BattleManager.last_xp = xp_with_bonus
	BattleManager.last_gold = total_gold
	# Restore 20% MP to all party members after victory
	for m in party:
		if m.max_mp > 0:
			m.mp = min(m.max_mp, m.mp + int(m.max_mp * 0.20))
