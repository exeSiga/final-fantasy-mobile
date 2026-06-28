extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func save(slot: int) -> void:
	var p = GameManager.player_unit
	if p == null:
		return
	var d: Dictionary = {
		"unit_name": p.unit_name,
		"hp": p.hp, "max_hp": p.max_hp,
		"mp": p.mp, "max_mp": p.max_mp,
		"atk": p.atk, "def": p.def, "spd": p.spd,
		"level": p.level, "xp": p.xp, "xp_to_next_level": p.xp_to_next_level,
		"gold": GameManager.gold,
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
	var p = GameManager.player_unit
	p.hp = d.get("hp", p.max_hp)
	p.max_hp = d.get("max_hp", p.max_hp)
	p.mp = d.get("mp", p.max_mp)
	p.max_mp = d.get("max_mp", p.max_mp)
	p.atk = d.get("atk", p.atk)
	p.def = d.get("def", p.def)
	p.spd = d.get("spd", p.spd)
	p.level = d.get("level", 1)
	p.xp = d.get("xp", 0)
	p.xp_to_next_level = d.get("xp_to_next_level", 100)
	GameManager.gold = d.get("gold", 0)
	return true

func get_slot_info(slot: int) -> Dictionary:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

func delete_save(slot: int) -> void:
	DirAccess.remove_absolute(_slot_path(slot))
