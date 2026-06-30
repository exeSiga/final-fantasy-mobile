extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func _unit_to_dict(u) -> Dictionary:
	return {
		"unit_name": u.unit_name,
		"hp": u.hp, "max_hp": u.max_hp,
		"mp": u.mp, "max_mp": u.max_mp,
		"atk": u.atk, "def": u.def, "spd": u.spd,
		"level": u.level, "xp": u.xp,
		"xp_to_next_level": u.xp_to_next_level,
	}

func _equipment_to_array() -> Array:
	var result: Array = []
	for i in 3:
		var w = GameManager.equipment[i].get("weapon")
		var a = GameManager.equipment[i].get("armor")
		result.append({
			"weapon": w.resource_path if w != null else "",
			"armor":  a.resource_path if a != null else "",
		})
	return result

func save(slot: int) -> void:
	if GameManager.party.is_empty():
		return
	var members: Array = []
	for m in GameManager.party:
		members.append(_unit_to_dict(m))
	var all_members: Array = []
	for m in GameManager.available_members:
		all_members.append(_unit_to_dict(m))
	var d: Dictionary = {
		"party": members,
		"all_members": all_members,
		"active_party_indices": GameManager.active_party_indices,
		"gold": GameManager.gold,
		"equip_inventory": GameManager.equip_inventory,
		"equipment": _equipment_to_array(),
		"materia_inventory": GameManager.materia_inventory,
		"materia_equipped": GameManager.materia_equipped,
		"learned_enemy_skills": GameManager.learned_enemy_skills,
		"active_zone": GameManager.active_zone,
		"story_intro_done": GameManager.story_intro_done,
		"total_kills": GameManager.total_kills,
		"quest_kills": QuestManager.kill_counts,
		"quest_completed": QuestManager.completed,
		"timestamp": Time.get_datetime_string_from_system(),
		"playtime": Time.get_ticks_msec() / 1000,
	}
	var file: FileAccess = FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(d))

func load_save(slot: int) -> bool:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var d: Dictionary = parsed as Dictionary
	GameManager.new_game()
	GameManager.gold = d.get("gold", 0)
	# Load all 4 members (or fall back to legacy 3-member party data)
	var all_members_data: Array = d.get("all_members", [])
	if all_members_data.is_empty():
		all_members_data = d.get("party", [])
	for i in min(all_members_data.size(), GameManager.available_members.size()):
		var md: Dictionary = all_members_data[i]
		var m = GameManager.available_members[i]
		m.hp = md.get("hp", m.max_hp)
		m.max_hp = md.get("max_hp", m.max_hp)
		m.mp = md.get("mp", m.max_mp)
		m.max_mp = md.get("max_mp", m.max_mp)
		m.atk = md.get("atk", m.atk)
		m.def = md.get("def", m.def)
		m.spd = md.get("spd", m.spd)
		m.level = md.get("level", 1)
		m.xp = md.get("xp", 0)
		m.xp_to_next_level = md.get("xp_to_next_level", 100)
	var saved_indices: Array = d.get("active_party_indices", [0, 1, 2])
	GameManager.active_party_indices = saved_indices
	GameManager.rebuild_party_from_indices()
	GameManager.equip_inventory = d.get("equip_inventory", {})
	GameManager.materia_inventory = d.get("materia_inventory", {})
	GameManager.materia_equipped = d.get("materia_equipped", {})
	GameManager.active_zone = d.get("active_zone", "midgar")
	GameManager.story_intro_done = d.get("story_intro_done", false)
	GameManager.total_kills = d.get("total_kills", 0)
	GameManager.learned_enemy_skills = d.get("learned_enemy_skills", [])
	QuestManager.kill_counts = d.get("quest_kills", {})
	QuestManager.completed = d.get("quest_completed", {})
	var equip_data: Array = d.get("equipment", [])
	for i in min(equip_data.size(), 3):
		var ed: Dictionary = equip_data[i]
		var w_path: String = ed.get("weapon", "")
		var a_path: String = ed.get("armor", "")
		# Note: stats in save already include equipment bonuses — just set references
		GameManager.equipment[i]["weapon"] = load(w_path) if w_path != "" else null
		GameManager.equipment[i]["armor"] = load(a_path) if a_path != "" else null
	return true

func get_slot_info(slot: int) -> Dictionary:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var d: Dictionary = parsed as Dictionary
	var party_data: Array = d.get("party", [])
	var level: int = 1
	if not party_data.is_empty():
		level = party_data[0].get("level", 1)
	return {
		"level": level,
		"timestamp": d.get("timestamp", ""),
	}

func delete_save(slot: int) -> void:
	DirAccess.remove_absolute(_slot_path(slot))
