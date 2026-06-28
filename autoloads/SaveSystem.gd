extends Node

const SAVE_PATH := "user://save.json"

var data: Dictionary = {}

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var result := JSON.parse_string(file.get_as_text())
	if result is Dictionary:
		data = result
		return true
	return false

func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	data = {}
